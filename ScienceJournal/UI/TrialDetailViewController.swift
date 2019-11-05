/*
 *  Copyright 2019 Google LLC. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

// swiftlint:disable file_length

import UIKit

import third_party_objective_c_material_components_ios_components_BottomSheet_BottomSheet
import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Snackbar_Snackbar
// swiftlint:disable line_length
import third_party_objective_c_material_components_ios_components_private_KeyboardWatcher_KeyboardWatcher
// swiftlint:enable line_length

protocol TrialDetailViewControllerDelegate: class {
  /// Informs the delegate a note should be shown.
  ///
  /// - Parameters:
  ///   - displayNote: The display note to show.
  ///   - jumpToCaption: Whether to jump to the caption input when showing the note.
  func trialDetailViewControllerShowNote(_ displayNote: DisplayNote, jumpToCaption: Bool)

  /// Informs the delegate a trial picture note delete has completed.
  ///
  /// - Parameters:
  ///   - pictureNote: The picture note.
  ///   - experiment: The experiment the trial belonged to.
  func trialDetailViewControllerDeletePictureNoteCompleted(_ pictureNote: PictureNote,
                                                           forExperiment experiment: Experiment)
}

// swiftlint:disable type_body_length
/// The detail view of a Trial which shows all the information, sensors and notes from a Trial,
/// and allows more notes to be added. Sensors are shown in a paginated, sticky view.
class TrialDetailViewController: MaterialHeaderViewController,
                                 CropRangeViewControllerDelegate,
                                 ExperimentCardCellDelegate,
                                 ExperimentUpdateListener,
                                 ImageSelectorDelegate,
                                 PlaybackViewControllerDelegate,
                                 TrialDetailAddNoteCellDelegate,
                                 TrialDetailDataSourceDelegate,
                                 TrialDetailSensorsViewDelegate,
                                 UICollectionViewDataSource,
                                 UICollectionViewDelegate,
                                 UICollectionViewDelegateFlowLayout,
                                 CameraImageProviderDelegate {

  typealias TimestampUpdate = (String) -> Void

  enum State {
    case playback
    case timeSelect
    case crop
  }

  /// Represents a note that is in the process of being created.
  private struct PendingNote {
    var text: String?
    var imageData: Data?
    var imageMetaData: NSDictionary?
    var timestamp: Int64?
    var relativeTimestamp: Int64
  }

  // MARK: - Constants

  private enum Metrics {
    static let timeSelectionMargin: CGFloat = 10
    static let timeSelectionLandscapeOffsetPadding: CGFloat = 83
    static let dimmingViewHeight: CGFloat = 1000
    static let archivedFlagCellLayoutMargins = UIEdgeInsets(top: 16,
                                                            left: 16,
                                                            bottom: 2,
                                                            right: 0)
  }

  let archivedFlagCellIdentifier = "ArchivedFlagCell"
  let textNoteCardCellIdentifier = "TrialDetailTextNoteCardCell"
  let pictureCardCellIdentifier = "TrialDetailPictureCardCell"
  let snapshotCardCellIdentifier = "TrialDetailSnapshotCardCell"
  let trialDetailAddNoteCellIdentifier = "TrialDetailAddNoteCell"
  let trialDetailHeaderCellIdentifier = "TrialDetailHeaderCell"
  let trialDetailSensorsViewIdentifier = "TrialDetailSensorsView"
  let triggerCardCellIdentifier = "TrialDetailTriggerCardCell"
  let noteDetailEditCaptionCellIdentifier = "NoteDetailEditCaptionCell"

  private let trialNoteDeleteUndoSnackbarCategory = "TrialNoteDeleteUndoSnackbarCategory"

  // MARK: - Properties

  // The trial detail data source. Exposed for testing.
  let trialDetailDataSource: TrialDetailDataSource

  // The editable status of this trial. Observable.
  @objc dynamic var isEditable: Bool

  // The experiment interaction options. Exposed for testing.
  let experimentInteractionOptions: ExperimentInteractionOptions

  private let collectionView: UICollectionView
  private let flowLayout = UICollectionViewFlowLayout()
  private var isEditingCaption: Bool = false
  private let metadataManager: MetadataManager
  private weak var delegate: TrialDetailViewControllerDelegate?
  private weak var itemDelegate: ExperimentItemDelegate?
  lazy var trialHeaderCellHeight: CGFloat = {
    return TrialDetailHeaderCell.height
  }()
  lazy var trialSensorsViewHeight: CGFloat = {
    return TrialDetailSensorsView.height
  }()

  var timestampString: String = "" {
    didSet {
      timeSelectionView.timestampLabel.text = timestampString
      timestampSubscribers.forEach { $0(timestampString) }
    }
  }

  private(set) lazy var notesViewController: NotesViewController =
    NotesViewController(analyticsReporter: analyticsReporter)

  private(set) lazy var photoLibraryViewController: PhotoLibraryViewController =
    PhotoLibraryViewController(selectionMode: .single, analyticsReporter: analyticsReporter)

  private(set) lazy var cameraViewController: StandaloneCameraViewController =
    StandaloneCameraViewController(analyticsReporter: analyticsReporter)

  private lazy var cameraImageProvider: CameraImageProvider = {
    let cameraImageProvider = CameraImageProvider()
    cameraImageProvider.delegate = self
    return cameraImageProvider
  }()

  private var editBarButton = MaterialBarButtonItem()
  private var cancelBarButton: MaterialCloseBarButtonItem?
  private var menuBarButton = MaterialMenuBarButtonItem()
  private var saveBarButton = MaterialBarButtonItem()
  private var dialogTransitionController: MDCDialogTransitionController?
  private var renameDialog: RenameTrialViewController?
  private var addNoteDialog: AddTrialNoteViewController?
  private let timeFormat = ElapsedTimeFormatter()
  private var dimmingViewTopAnchor: NSLayoutConstraint?
  private var pendingNote: PendingNote?
  private var backMenuItem: MaterialBackBarButtonItem?
  private var trialShareViewController: TrialShareSettingsViewController?
  private var cropRangeController: CropRangeViewController
  private let cropValidator: CropValidator
  private var currentCaption: String?
  private let preferenceManager: PreferenceManager
  private let sensorDataManager: SensorDataManager
  private let exportType: UserExportType
  private let saveToFilesHandler = SaveToFilesHandler()
  private var timestampSubscribers: [TimestampUpdate] = []

  private var cellHorizontalInset: CGFloat {
    var inset: CGFloat {
      switch displayType {
      case .compact, .compactWide:
        return MaterialCardCell.cardInsets.left + MaterialCardCell.cardInsets.right
      case .regular:
        return ViewConstants.cellHorizontalInsetRegularDisplayType +
            MaterialCardCell.cardInsets.left + MaterialCardCell.cardInsets.right
      case .regularWide:
        return ViewConstants.cellHorizontalInsetRegularWideDisplayType +
            MaterialCardCell.cardInsets.left + MaterialCardCell.cardInsets.right
      }
    }
    return inset + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  private var sectionInsets: UIEdgeInsets {
    return UIEdgeInsets(top: MaterialCardCell.cardInsets.top,
                        left: cellHorizontalInset / 2,
                        bottom: MaterialCardCell.cardInsets.bottom,
                        right: cellHorizontalInset / 2)
  }

  private lazy var dimmingView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(white: 0, alpha: 0.5)
    return view
  }()

  private lazy var timeSelectionView: TimeSelectionView = {
    let view = TimeSelectionView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.confirmButton.addTarget(self,
                                 action: #selector(timeSelectionConfirmPressed),
                                 for: .touchUpInside)
    return view
  }()

  private var state = State.playback {
    didSet {
      guard oldValue != state else { return }
      updateForState()
    }
  }

  // A dictionary of chart controllers keyed by sensor ID.
  private var playbackViewControllers = [String: PlaybackViewController]()

  // A tuple of the currently displayed playback controller and its associated sensor ID.
  private var currentPlaybackViewController: (String, PlaybackViewController)? {
    guard let sensor = sensorsView?.currentSensor,
        let playbackController = playbackViewControllers[sensor.ID] else {
      return nil
    }
    return (sensor.ID, playbackController)
  }

  /// A cached reference to the sensors view vended by the collection view.
  private weak var sensorsView: TrialDetailSensorsView?

  // The experiment that owns the displayed trial.
  private var experiment: Experiment

  /// Returns a sharing filename from the experiment and trial names.
  ///
  /// - Parameters:
  ///   - experimentName: The experiment name.
  ///   - trialName: The trial name.
  /// - Returns: A filename with ".csv" extension.
  private var exportFilename: String {
    let displayTrial = trialDetailDataSource.displayTrial
    let experimentName = experiment.title ?? String.localizedUntitledExperiment
    let trialName = displayTrial.title ?? displayTrial.alternateTitle
    return experimentName.sanitizedForFilename.truncatedWithHex(maxLength: 40)
        + " - "
        + trialName.sanitizedForFilename.truncatedWithHex(maxLength: 35)
        + ".csv"
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - experiment: The experiment that owns the trial.
  ///   - experimentInteractionOptions: Experiment interaction options.
  ///   - exportType: The export option type to show.
  ///   - shouldAllowSharing: Whether the trial should be shareable.
  ///   - delegate: The delegate.
  ///   - itemDelegate: The experiment item delegate.
  ///   - analyticsReporter: An AnalyticsReporter.
  ///   - experimentDataParser: The experiment data parser.
  ///   - metadataManager: The metadata manager.
  ///   - preferenceManager: The preference manager.
  ///   - sensorDataManager: The sensor data manager.
  init(trial: Trial,
       experiment: Experiment,
       experimentInteractionOptions: ExperimentInteractionOptions,
       exportType: UserExportType,
       delegate: TrialDetailViewControllerDelegate,
       itemDelegate: ExperimentItemDelegate?,
       analyticsReporter: AnalyticsReporter,
       experimentDataParser: ExperimentDataParser,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager,
       sensorDataManager: SensorDataManager) {
    trialDetailDataSource =
        TrialDetailDataSource(trial: trial,
                              experimentDataParser: experimentDataParser,
                              experimentInteractionOptions: experimentInteractionOptions)
    self.isEditable = !trialDetailDataSource.displayTrial.isArchived
    self.experiment = experiment
    self.experimentInteractionOptions = experimentInteractionOptions
    self.exportType = exportType
    self.delegate = delegate
    self.itemDelegate = itemDelegate
    self.metadataManager = metadataManager
    self.preferenceManager = preferenceManager
    self.sensorDataManager = sensorDataManager
    cropValidator = CropValidator(trialRecordingRange: trial.recordingRange)
    cropRangeController = CropRangeViewController(trialRecordingRange: trial.recordingRange)

    // MDCCollectionViewFlowLayout currently has a bug that breaks sectionHeadersPinToVisibleBounds
    // so we need to use a UICollectionViewFlowLayout instead until it's fixed. See issue:
    // https://goo.gl/tqbul7
    flowLayout.minimumLineSpacing = MaterialCardCell.cardInsets.bottom
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    super.init(analyticsReporter: analyticsReporter)

    trialDetailDataSource.delegate = self
    cropRangeController.delegate = self
  }

  func configurePlaybackViewController(forSensor sensor: DisplaySensor) {
    guard playbackViewControllers[sensor.ID] == nil else {
      return
    }
    let displayTrial = trialDetailDataSource.displayTrial
    let playbackViewController = PlaybackViewController(trialID: displayTrial.ID,
                                                        sensorID: sensor.ID,
                                                        sensorStats: sensor.stats,
                                                        cropRange: displayTrial.cropRange,
                                                        notes: displayTrial.notes,
                                                        colorPalette: sensor.colorPalette,
                                                        sensorDataManager: sensorDataManager)
    playbackViewController.delegate = self

      // Set stats.
      if let min = sensor.stats.minValue,
          let max = sensor.stats.maxValue,
          let average = sensor.stats.averageValue {
        playbackViewController.setStats(min: min, max: max, average: average)
      }

    // Store the playback controller keyed by sensor ID.
    playbackViewControllers[sensor.ID] = playbackViewController

    // Update the data source with the presentation view.
    trialDetailDataSource.setChartPresentationView(playbackViewController.view,
                                                   forSensorID: sensor.ID)

    // Update the sensors view as well.
    sensorsView?.updateChartView(playbackViewController.view, forSensorWithID: sensor.ID)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView.register(ArchivedFlagCell.self,
                            forCellWithReuseIdentifier: archivedFlagCellIdentifier)
    collectionView.register(TrialDetailHeaderCell.self,
                            forCellWithReuseIdentifier: trialDetailHeaderCellIdentifier)
    collectionView.register(TrialDetailSensorsView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: trialDetailSensorsViewIdentifier)
    collectionView.register(TrialDetailAddNoteCell.self,
                            forCellWithReuseIdentifier: trialDetailAddNoteCellIdentifier)
    collectionView.register(TextNoteCardCell.self,
                            forCellWithReuseIdentifier: textNoteCardCellIdentifier)
    collectionView.register(PictureCardCell.self,
                            forCellWithReuseIdentifier: pictureCardCellIdentifier)
    collectionView.register(SnapshotCardCell.self,
                            forCellWithReuseIdentifier: snapshotCardCellIdentifier)
    collectionView.register(TriggerCardCell.self,
                            forCellWithReuseIdentifier: triggerCardCellIdentifier)
    collectionView.register(NoteDetailEditCaptionCell.self,
                            forCellWithReuseIdentifier: noteDetailEditCaptionCellIdentifier)

    appBar.headerViewController.headerView.backgroundColor = .appBarReviewBackgroundColor

    collectionView.backgroundColor = MDCPalette.grey.tint200
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    collectionView.pinToEdgesOfView(view)
    collectionView.alwaysBounceVertical = true
    collectionView.delegate = self
    collectionView.dataSource = self

    // Bar buttons.
    backMenuItem = MaterialBackBarButtonItem(target: self,
                                             action: #selector(backButtonPressed))
    navigationItem.hidesBackButton = true
    navigationItem.leftBarButtonItem = backMenuItem

    // Configure right bar buttons for playback state.
    editBarButton.button.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
    editBarButton.button.setImage(UIImage(named: "ic_edit"), for: .normal)
    editBarButton.button.accessibilityLabel = String.editRunBtnContentDescription
    editBarButton.button.accessibilityHint = String.editRunBtnContentDetails

    menuBarButton.button.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuBarButton.button.setImage(UIImage(named: "ic_more_horiz"), for: .normal)

    // Configure close button for time select state.
    cancelBarButton = MaterialCloseBarButtonItem(target: self,
                                                 action: #selector(cancelButtonPressed))

    saveBarButton.button.addTarget(self,
                                   action: #selector(saveButtonPressed),
                                   for: .touchUpInside)
    saveBarButton.button.setImage(UIImage(named: "ic_check"), for: .normal)
    saveBarButton.button.accessibilityLabel = String.saveBtnContentDescription

    // Inset the scroll indicator to be under the sticky header.
    let indicatorTopInset =
        ViewConstants.toolbarHeight + UIApplication.shared.statusBarFrame.size.height +
        trialHeaderCellHeight + trialSensorsViewHeight
    collectionView.scrollIndicatorInsets =
        UIEdgeInsets(top: indicatorTopInset, left: 0, bottom: 0, right: 0)

    // Headers pin depending on screen orientation. Landscape doesn't offer enough room for the
    // headers to pin properly.
    if view.frame.size.isWiderThanTall {
      flowLayout.sectionHeadersPinToVisibleBounds = false
    } else {
      flowLayout.sectionHeadersPinToVisibleBounds = true
    }

    addChild(cropRangeController)

    if FeatureFlags.isActionAreaEnabled {
      notesViewController.delegate = self
      photoLibraryViewController.delegate = self
      cameraViewController.delegate = self
    }

    updateForState()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Register for keyboard notifications.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardDidShow(_:)),
                                           name: UIResponder.keyboardDidShowNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardWillHide(_:)),
                                           name: UIResponder.keyboardWillHideNotification,
                                           object: nil)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    NotificationCenter.default.removeObserver(self,
                                              name: UIResponder.keyboardDidShowNotification,
                                              object: nil)
    NotificationCenter.default.removeObserver(self,
                                              name: UIResponder.keyboardWillHideNotification,
                                              object: nil)

    MDCSnackbarManager.dismissAndCallCompletionBlocks(
        withCategory: trialNoteDeleteUndoSnackbarCategory)
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    // Adjust header pinning for orientation.
    if size.isWiderThanTall {
      flowLayout.sectionHeadersPinToVisibleBounds = false
    } else {
      flowLayout.sectionHeadersPinToVisibleBounds = true
    }

    flowLayout.invalidateLayout()

    let timeSelectLayoutUpdates = {
      self.collectionView.contentOffset = self.timeSelectionContentOffset(forViewSize: size)
      self.dimmingViewTopAnchor?.constant = self.dimmingViewTopMargin(forViewSize: size)
    }
    if state == .timeSelect || state == .crop {
      // The contentOffset and dimming view changes only look correct rotating when they are set
      // before animating as well as in the animation block.
      timeSelectLayoutUpdates()
    }

    coordinator.animateAlongsideTransition(in: view, animation: { (_) in
      if self.state == .timeSelect || self.state == .crop { timeSelectLayoutUpdates() }
      guard let sensorsView = self.sensorsView else { return }
      sensorsView.scrollSensorsToCurrentPage()
      self.playbackViewControllers.values.forEach { $0.updateOverlays() }
    })
  }

  override var trackedScrollView: UIScrollView? {
    return collectionView
  }

  func reloadTrial(_ trial: Trial) {
    // Update the display trial.
    trialDetailDataSource.trial = trial
    updateDisplayTrial()

    // Update the charts for any new crops.
    let displayTrial = trialDetailDataSource.displayTrial
    for (_, playbackViewController) in playbackViewControllers {
      playbackViewController.resetAndloadData(cropRange: displayTrial.cropRange)
    }

    // Reload collection view items.
    collectionView.reloadData()
  }

  func prepareToAddNote() {
    guard let sensor = sensorsView?.currentSensor,
      playbackViewControllers[sensor.ID] != nil else { return }
    notesViewController.title = String.localizedAddTextNoteTo(with: timestampString)
  }

  func subscribeToTimestampUpdate(with updateBlock: @escaping TimestampUpdate) {
    timestampSubscribers.append(updateBlock)
  }

  // MARK: - Notifications

  @objc func handleKeyboardDidShow(_ notification: Notification) {
    // Set bottom inset to keyboard height. Only set it in playback mode because changing content
    // inset can scroll view improperly in crop mode.
    if state == .playback {
      collectionView.contentInset.bottom = MDCKeyboardWatcher.shared().visibleKeyboardHeight
    }
  }

  @objc func handleKeyboardWillHide(_ notification: Notification) {
    // When in time select mode, setting content inset can prevent scrolling to the correct offset.
    if state == .playback {
      collectionView.contentInset.bottom = 0
    }
  }

  // MARK: - UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return trialDetailDataSource.numberOfItemsInSection(section)
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    // One section for the trial header cell, one section for the sticky sensors view and timeline
    // cells, one section for the caption.
    return TrialDetailDataSource.Section.numberOfSections
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    let supplementaryView = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: trialDetailSensorsViewIdentifier,
        for: indexPath)
    if let trialDetailSensorsView = supplementaryView as? TrialDetailSensorsView {
      self.sensorsView = trialDetailSensorsView
      trialDetailSensorsView.delegate = self
      trialDetailSensorsView.sensors = trialDetailDataSource.displayTrial.sensors
    }
    return supplementaryView
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    if trialDetailDataSource.isArchivedFlagSection(indexPath.section) {
      // Archived flag cell.
      return CGSize(width: collectionView.bounds.size.width,
                    height: ArchivedFlagCell.height + Metrics.archivedFlagCellLayoutMargins.top +
                        Metrics.archivedFlagCellLayoutMargins.bottom)
    } else if trialDetailDataSource.isTrialHeaderIndexPath(indexPath) {
      // Trial header cell.
      return CGSize(width: collectionView.bounds.size.width, height: trialHeaderCellHeight)
    }

    // Constrain the width based on the collection view and the insets (and iPad additional inset).
    let constrainedWidth = collectionView.bounds.size.width - cellHorizontalInset -
        MaterialCardCell.cardInsets.left - MaterialCardCell.cardInsets.right

    if trialDetailDataSource.isAddNoteIndexPath(indexPath) {
      // Add note cell.
      return CGSize(width: constrainedWidth, height: TrialDetailAddNoteCell.height)
    } else {
      // Timeline cells.
      let note = trialDetailDataSource.displayNoteForIndexPath(indexPath)
      var calculatedCellHeight: CGFloat
      switch note.noteType {
      case .textNote(let textNote):
        calculatedCellHeight = TextNoteCardCell.height(inWidth: constrainedWidth,
                                                       textNote: textNote,
                                                       showingHeader: true,
                                                       showingInlineTimestamp: false)
      case .snapshotNote(let snapshotNote):
        calculatedCellHeight = SnapshotCardCell.height(inWidth: constrainedWidth,
                                                       snapshotNote: snapshotNote,
                                                       showingHeader: true)
      case .pictureNote(let pictureNote):
        calculatedCellHeight = PictureCardCell.height(inWidth: constrainedWidth,
                                                      pictureNote: pictureNote,
                                                      pictureStyle: .large,
                                                      showingHeader: true)
      case .triggerNote(let triggerNote):
        calculatedCellHeight = TriggerCardCell.height(inWidth: constrainedWidth,
                                                      triggerNote: triggerNote,
                                                      showingHeader: true,
                                                      showingInlineTimestamp: false)
      }

      return CGSize(width: constrainedWidth,
                    height: ceil(calculatedCellHeight))
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if trialDetailDataSource.isArchivedFlagSection(indexPath.section) {
      // Archived flag cell.
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: archivedFlagCellIdentifier,
                                                    for: indexPath)
      if let cell = cell as? ArchivedFlagCell {
        cell.backgroundColor = .white
        cell.layoutMargins = Metrics.archivedFlagCellLayoutMargins
      }
      return cell
    } else if trialDetailDataSource.isTrialHeaderIndexPath(indexPath) {
      // Trial header cell.
      let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: trialDetailHeaderCellIdentifier,
          for: indexPath)
      if let cell = cell as? TrialDetailHeaderCell {
        cell.timestampLabel.text = trialDetailDataSource.displayTrial.timestamp.string
        cell.titleLabel.text = trialDetailDataSource.trialTitle
        cell.durationLabel.text = trialDetailDataSource.displayTrial.duration
        cell.durationLabel.accessibilityLabel =
            trialDetailDataSource.displayTrial.accessibleDuration
      }
      return cell
    } else if trialDetailDataSource.isAddNoteIndexPath(indexPath) {
      // Add note cell.
      let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: trialDetailAddNoteCellIdentifier,
          for: indexPath)
      if let cell = cell as? TrialDetailAddNoteCell {
        cell.delegate = self
      }
      return cell
    } else {
      // Timeline cells.
      let note = trialDetailDataSource.displayNoteForIndexPath(indexPath)
      switch note.noteType {
      case .textNote(let textNote):
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: textNoteCardCellIdentifier,
            for: indexPath)
        if let cell = cell as? TextNoteCardCell {
          cell.setTextNote(textNote, showHeader: true, showInlineTimestamp: false)
          cell.delegate = self
        }
        return cell
      case .snapshotNote(let snapshotNote):
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: snapshotCardCellIdentifier,
            for: indexPath)
        if let cell = cell as? SnapshotCardCell {
          let showCaptionButton = experimentInteractionOptions.shouldAllowEdits
          cell.setSnapshotNote(snapshotNote,
                               showHeader: true,
                               showInlineTimestamp: false,
                               showCaptionButton: showCaptionButton)
          cell.delegate = self
        }
        return cell
      case .pictureNote(let pictureNote):
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: pictureCardCellIdentifier,
            for: indexPath)
        if let cell = cell as? PictureCardCell {
          let showCaptionButton = experimentInteractionOptions.shouldAllowEdits
          cell.setPictureNote(pictureNote,
                              withPictureStyle: .large,
                              metadataManager: metadataManager,
                              showHeader: true,
                              showInlineTimestamp: false,
                              showCaptionButton: showCaptionButton)
          cell.delegate = self
        }
        return cell
      case .triggerNote(let triggerNote):
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: triggerCardCellIdentifier,
            for: indexPath)
        if let cell = cell as? TriggerCardCell {
          let showCaptionButton = experimentInteractionOptions.shouldAllowEdits
          cell.setTriggerNote(triggerNote,
                              showHeader: true,
                              showInlineTimestamp: false,
                              showCaptionButton: showCaptionButton)
          cell.delegate = self
        }
        return cell
      }
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      willDisplay cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    if trialDetailDataSource.isTrialNotesSection(indexPath.section),
        let pictureNoteCell = cell as? PictureCardCell {
      pictureNoteCell.displayImage()
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      didEndDisplaying cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    if trialDetailDataSource.isTrialNotesSection(indexPath.section),
        let pictureNoteCell = cell as? PictureCardCell {
      pictureNoteCell.removeImage()
    }
  }

  // MARK: - UICollectionViewDelegate

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    switch TrialDetailDataSource.Section(collectionViewSection: section) {
    case .archivedFlag: return .zero
    case .header: return .zero
    case .chartAndNotes: return sectionInsets
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      referenceSizeForHeaderInSection section: Int) -> CGSize {
    guard section == TrialDetailDataSource.Section.chartAndNotes.rawValue else { return .zero }

    return CGSize(width: collectionView.bounds.size.width - cellHorizontalInset,
                  height: trialSensorsViewHeight)
  }

  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    guard !trialDetailDataSource.isArchivedFlagSection(indexPath.section) else { return }

    if trialDetailDataSource.isTrialNoteIndexPath(indexPath) {
      let note = trialDetailDataSource.displayNoteForIndexPath(indexPath)
      displayDetailViewController(for: note)
    }
  }

  // Displays a detail view controller for the display item, optionally jumping to the caption
  // field when it loads.
  private func displayDetailViewController(for note: DisplayNote, jumpToCaption: Bool = false) {
    delegate?.trialDetailViewControllerShowNote(note, jumpToCaption: jumpToCaption)
  }

  // MARK: - ExperimentCardCellDelegate

  func experimentCardCellCommentButtonPressed(_ cell: MaterialCardCell) {
    guard let indexPath = collectionView.indexPath(for: cell) else { return }
    let note = trialDetailDataSource.displayNoteForIndexPath(indexPath)
    displayDetailViewController(for: note, jumpToCaption: true)
  }

  func experimentCardCellMenuButtonPressed(_ cell: MaterialCardCell, button: MenuButton) {
    guard let indexPath = collectionView.indexPath(for: cell) else { return }
    let note = trialDetailDataSource.displayNoteForIndexPath(indexPath)

    let popUpMenu = PopUpMenuViewController()

    func addEditAction() {
      popUpMenu.addAction(PopUpMenuAction(title: String.actionEdit,
                                          icon: UIImage(named: "ic_edit")) { _ -> Void in
        self.displayDetailViewController(for: note)
      })
    }

    func addViewAction() {
      popUpMenu.addAction(PopUpMenuAction(title: String.actionViewDetails,
                                          icon: UIImage(named: "ic_visibility")) { _ -> Void in
        self.displayDetailViewController(for: note)
      })
    }

    func addAddCaptionAction() {
      popUpMenu.addAction(PopUpMenuAction(title: String.actionAddCaption,
                                          icon: UIImage(named: "ic_comment")) { _ -> Void in
        self.experimentCardCellCommentButtonPressed(cell)
      })
    }

    switch note.itemType {
    case .textNote:
      if experimentInteractionOptions.shouldAllowEdits {
        addEditAction()
      } else {
        addViewAction()
      }
    default:
      addViewAction()
      if experimentInteractionOptions.shouldAllowEdits {
        addAddCaptionAction()
      }
    }

    // Export
    if let displayPictureNote = note as? DisplayPictureNote,
        displayPictureNote.imageFileExists,
        let imagePath = displayPictureNote.imagePath {
      switch exportType {
      case .saveToFiles:
        popUpMenu.addAction(PopUpMenuAction.saveToFiles(withFilePath: imagePath,
                                                        presentingViewController: self,
                                                        saveToFilesHandler: saveToFilesHandler))
      case .share:
        popUpMenu.addAction(PopUpMenuAction.share(withFilePath: imagePath,
                                                  presentingViewController: self,
                                                  sourceView: button))
      }
    }

    // Delete.
    func addDeleteAction() {
      popUpMenu.addAction(PopUpMenuAction(title: String.actionDelete,
                                          icon: UIImage(named: "ic_delete")) { _ -> Void in
        self.itemDelegate?.detailViewControllerDidDeleteNote(note)
      })
    }

    if experimentInteractionOptions.shouldAllowDeletes {
      addDeleteAction()
    }

    popUpMenu.present(from: self, position: .sourceView(button))
  }

  func experimentCardCellTimestampButtonPressed(_ cell: MaterialCardCell) {
    guard let indexPath = collectionView.indexPath(for: cell) else { return }
    let note = trialDetailDataSource.displayNoteForIndexPath(indexPath)
    let timestamp = note.timestamp.milliseconds
    playbackViewControllers.forEach { $0.value.movePlayheadToTimestamp(timestamp) }

    // If headers are not pinned, chart may be off screen, so scroll the chart to visible.
    if !flowLayout.sectionHeadersPinToVisibleBounds {
      collectionView.scrollToItem(at: trialDetailDataSource.chartAndNotesFirstIndexPath,
                                  at: .bottom,
                                  animated: true)
    }
  }

  // MARK: - ExperimentUpdateListener

  func experimentUpdateTrialDeleted(_ trial: Trial,
                                    fromExperiment experiment: Experiment,
                                    undoBlock: (() -> Void)?) {
    guard trialDetailDataSource.trial.ID == trial.ID && experiment.ID == self.experiment.ID else {
      return
    }

    // Shutdown this view controller by stopping all actions and dismissing.
    stopPlayback()
  }

  func experimentUpdateTrialNoteAdded(_ note: Note, toTrial trial: Trial) {
    guard trial.ID == trialDetailDataSource.trial.ID,
        let displayNote = trialDetailDataSource.addNote(note, sorted: true) else {
      return
    }
    playbackViewControllers.forEach { $0.value.addNote(displayNote) }
  }

  func experimentUpdateTrialNoteDeleted(_ note: Note,
                                        trial: Trial,
                                        experiment: Experiment,
                                        undoBlock: @escaping () -> Void) {
    guard trial.ID == trialDetailDataSource.trial.ID else {
      return
    }
    trialDetailDataSource.removeNote(withID: note.ID)
    playbackViewControllers.forEach { controller in
      controller.value.removeNote(withID: note.ID, atTimestamp: note.timestamp)
    }

    var didUndo = false
    showUndoSnackbar(
        withMessage: String.snackbarNoteDeleted,
        category: trialNoteDeleteUndoSnackbarCategory,
        undoBlock: {
          didUndo = true
          undoBlock()
    },
        completion: { (_) in
          if !didUndo, let pictureNote = note as? PictureNote {
            self.delegate?.trialDetailViewControllerDeletePictureNoteCompleted(
                pictureNote, forExperiment: experiment)
          }
    })
  }

  func experimentUpdateNoteUpdated(_ note: Note, trial: Trial?, experiment: Experiment) {
    guard trial?.ID == trialDetailDataSource.trial.ID else {
      return
    }
    trialDetailDataSource.updateNote(note)
  }

  func experimentUpdateTrialUpdated(_ trial: Trial, experiment: Experiment, updatedStats: Bool) {
    guard trial.ID == trialDetailDataSource.trial.ID else {
      return
    }

    updateDisplayTrial()
    if updatedStats {
      sensorsView?.sensors = trialDetailDataSource.displayTrial.sensors
    }
    collectionView.reloadData()
  }

  func experimentUpdateTrialArchiveStateChanged(_ trial: Trial,
                                                experiment: Experiment,
                                                undoBlock: @escaping () -> Void) {
    guard trial.ID == trialDetailDataSource.trial.ID else {
      return
    }

    collectionView.performBatchUpdates({
      let isDisplayTrialArchived = trialDetailDataSource.displayTrial.isArchived
      isEditable = !isDisplayTrialArchived
      // If the containing experiment allows additions, only then do we need to insert/delete the
      // "Add Notes" cell. This check is needed because it is possible to enter an archived
      // experiment with an archived trial, that could potentialy be unarchived. Or vice versa.
      let experimentAllowsAdditions = trialDetailDataSource.experimentAllowsAdditions
      let addNoteIndexPath = trialDetailDataSource.chartAndNotesFirstIndexPath

      if isDisplayTrialArchived && !trial.isArchived {
        collectionView.deleteItems(at: [trialDetailDataSource.archivedFlagIndexPath])
        if experimentAllowsAdditions {
          collectionView.insertItems(at: [addNoteIndexPath])
        }
      } else if !isDisplayTrialArchived && trial.isArchived {
        if experimentAllowsAdditions {
          collectionView.deleteItems(at: [addNoteIndexPath])
        }
        collectionView.insertItems(at: [trialDetailDataSource.archivedFlagIndexPath])
      }
    }, completion: nil)

    updateDisplayTrial()
  }

  // Unused.
  func trialDetailViewControllerDidRequestDeleteTrial(withID trialID: String) {}
  func detailViewControllerDidAddNote(_ note: Note, forTrialID trialID: String?) {}
  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateChanged trial: Trial) {}
  func trialDetailViewControllerDidUpdateTrial(cropRange: ChartAxis<Int64>?,
                                               name trialName: String?,
                                               caption: String?,
                                               withID trialID: String) {}
  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateToggledForTrialID trialID: String) {}

  // MARK: - TrialDetailDataSourceDelegate

  func trialDetailDataSource(_ trialDetailDataSource: TrialDetailDataSource,
                             didChange changes: [CollectionViewChange],
                             scrollTo scrollIndexPath: IndexPath?) {
    guard isViewVisible else {
      collectionView.reloadData()
      return
    }

    // Perform changes.
    collectionView.performChanges(changes) { (_) in
      // Scroll to index path if necessary.
      guard let scrollIndexPath = scrollIndexPath else { return }
      self.collectionView.scrollToItem(at: scrollIndexPath, at: .bottom, animated: true)
    }
  }

  // MARK: - UIGestureRecognizerDelegate

  override func interactivePopGestureShouldBegin() -> Bool {
    stopPlayback()
    return true
  }

  // MARK: - TrialDetailAddNoteCellDelegate

  func trialDetailAddNoteCellButtonPressed() {
    createPendingNote()
    view.endEditing(true)
    showAddNoteDialog()
  }

  // MARK: - PlaybackViewControllerDelegate

  func playbackViewControllerDidChangePlayheadTimestamp(forSensorID sensorID: String) {
    guard let playbackController = playbackViewControllers[sensorID] else { return }
    timestampString = timeFormat.string(
      fromTimestamp: playbackController.playheadRelativeTimestamp)
  }

  // MARK: - ImageSelectorDelegate

  func imageSelectorDidCreateImageData(_ imageDatas: [ImageData]) {
    guard imageDatas.count == 1, let imageDataTuple = imageDatas.first else {
        fatalError("Only one image can be selected for the trial detail vc.")
    }

    let imageData = imageDataTuple.imageData
    let metadata = imageDataTuple.metadata

    if FeatureFlags.isActionAreaEnabled {
      createPendingNote(imageData: imageData, imageMetaData: metadata)
      processPendingNote()

      // TODO: Consider AA-specific API.
      photoLibraryViewController.navigationController?.popViewController(animated: true)
    } else {
      pendingNote?.imageData = imageData
      pendingNote?.imageMetaData = metadata

      dismiss(animated: true) {
        self.showAddNoteDialog()
      }
    }
  }

  func imageSelectorDidCancel() {
    if FeatureFlags.isActionAreaEnabled {
      // TODO: Do we need to do anything? Seems like action area will take care of it.
    } else {
      dismiss(animated: true) {
        self.showAddNoteDialog()
      }
    }
  }

  // MARK: - CropRangeViewControllerDelegate

  func cropRangeViewControllerDidUpdateTimestamp(_ timestamp: Int64,
                                                 markerType: CropOverlayView.MarkerType) {
    guard let (_, playbackViewController) = currentPlaybackViewController else {
      return
    }
    playbackViewController.showMarker(withType: markerType, atTimestamp: timestamp)
  }

  // MARK: - TrialDetailSensorsViewDelegate

  func trialDetailSensorsViewWillShowSensor(_ sensor: DisplaySensor) {
    stopPlayback()
    configurePlaybackViewController(forSensor: sensor)
  }

  func trialDetailSensorsViewDidTapStats() {
    guard let sensor = sensorsView?.currentSensor else {
      return
    }
    toggleStats(forSensorID: sensor.ID)
  }

  // MARK: - CameraImageProviderDelegate

  func cameraImageProviderDidComplete() {
    dismiss(animated: true, completion: nil)
  }

  func cameraImageProviderDidPick(imageData: Data, metadata: NSDictionary?) {
    createPendingNote(imageData: imageData, imageMetaData: metadata)
    processPendingNote()
    dismiss(animated: true, completion: nil)
  }

  // MARK: - Private

  /// Stops playback on all charts.
  func stopPlayback() {
    for (_, playbackVC) in playbackViewControllers {
      playbackVC.stopPlayback()
    }
  }

  /// Toggles the display of stats for a chart.
  ///
  /// - Parameter sensorID: The ID of the sensor whose chart stats should be toggled.
  func toggleStats(forSensorID sensorID: String) {
    if let playbackController = playbackViewControllers[sensorID] {
      playbackController.shouldShowStats = !playbackController.shouldShowStats
    }
  }

  /// Dims the view below the chart and prevents scrolling.
  private func lockChartView() {
    // Disabling scrolling and changing the content offset simultaneously created an unexplained
    // layout bug in the stats view. Delaying scroll disabling solves the problem.
    DispatchQueue.main.async {
      self.collectionView.isScrollEnabled = false
    }

    collectionView.contentOffset = timeSelectionContentOffset(forViewSize: view.frame.size)

    // Add a dimming view to cover everything below the chart view. It uses a fixed height to
    // avoid an unsatisfiable constraint error when rotating.
    view.addSubview(dimmingView)
    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    dimmingView.heightAnchor.constraint(
      equalToConstant: Metrics.dimmingViewHeight).isActive = true
    let topMargin = dimmingViewTopMargin(forViewSize: view.frame.size)
    dimmingViewTopAnchor = dimmingView.topAnchor.constraint(equalTo: view.topAnchor,
                                                            constant: topMargin)
    dimmingViewTopAnchor?.isActive = true
  }

  /// Updates the view for the current view state.
  private func updateForState() {
    switch state {
    case .playback:
      // The default state where the user can scroll the view and observe the trial elements.
      title = String.runReviewActivityLabel
      if experimentInteractionOptions.shouldAllowEdits {
        navigationItem.rightBarButtonItems = [menuBarButton, editBarButton]
      } else {
        navigationItem.rightBarButtonItems = [menuBarButton]
      }
      navigationItem.leftBarButtonItem = backMenuItem
      collectionView.isScrollEnabled = true
      dimmingView.removeFromSuperview()
      timeSelectionView.removeFromSuperview()
      playbackViewControllers.values.forEach { $0.interactionState = .playback }
    case .timeSelect:
      // The state where the user is picking a time for a note. Scroll is locked to show the chart
      // and a time selection view. Other content is behind a dimming view.

      // If the view is small (due to a phone with a small screen), a save bar button will be shown
      // instead of using the time selection view's confirm button.
      let isViewSmall = min(view.bounds.width, view.bounds.height) <= 320

      title = String.editNoteTime
      navigationItem.rightBarButtonItems = isViewSmall ? [saveBarButton] : nil
      navigationItem.leftBarButtonItem = cancelBarButton

      lockChartView()

      // Add a time selection view to see and confirm the selected time.
      timeSelectionView.shouldShowConfirmButton = !isViewSmall
      view.addSubview(timeSelectionView)
      let margin = Metrics.timeSelectionMargin
      timeSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: margin).isActive = true
      timeSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -margin).isActive = true
      timeSelectionView.topAnchor.constraint(equalTo: dimmingView.topAnchor,
                                             constant: margin).isActive = true
      playbackViewControllers.values.forEach { $0.interactionState = .playback }
    case .crop:
      stopPlayback()
      title = String.cropRun
      navigationItem.rightBarButtonItems = [menuBarButton, saveBarButton]
      navigationItem.leftBarButtonItem = cancelBarButton

      playbackViewControllers.values.forEach { $0.interactionState = .crop }

      lockChartView()
    }
  }

  /// Returns the top margin for the dimming view used in the time select state.
  ///
  /// - Parameter viewSize: The view's size.
  /// - Returns: The dimming view top margin.
  func dimmingViewTopMargin(forViewSize viewSize: CGSize) -> CGFloat {
    let contentOffset = timeSelectionContentOffset(forViewSize: viewSize)
    let headerAndSensorHeight = TrialDetailSensorsView.height + TrialDetailHeaderCell.height
    return headerAndSensorHeight - contentOffset.y
  }

  /// Returns the content offset when in the time select state.
  ///
  /// - Parameter viewSize: The view's size.
  /// - Returns: The content offset.
  func timeSelectionContentOffset(forViewSize viewSize: CGSize) -> CGPoint {
    var yOffset = TrialDetailHeaderCell.height - view.safeAreaInsetsOrZero.top -
        collectionView.contentInset.top
    if viewSize.isWiderThanTall {
      yOffset += Metrics.timeSelectionLandscapeOffsetPadding
    }
    return CGPoint(x: 0, y: yOffset)
  }

  private func startCropping() {
    state = .crop

    // TODO: Don't disable sensor paging once it is supported. http://b/70326480
    sensorsView?.previousSensorButton.isEnabled = false
    sensorsView?.nextSensorButton.isEnabled = false

    let trial = trialDetailDataSource.trial
    let editingCropRange: ChartAxis<Int64>
    if let cropRange = trial.cropRange {
      editingCropRange = cropRange
    } else {
      let startingCropAmount = Int64(trial.durationInterval * 0.05 * 1000)
      let cropStartTime = trial.recordingRange.min + startingCropAmount
      let cropEndTime = trial.recordingRange.max - startingCropAmount
      editingCropRange = ChartAxis(min: cropStartTime, max: cropEndTime)
    }

    if let (_, currentPlaybackVC) = currentPlaybackViewController {
      currentPlaybackVC.resetAndloadData(cropRange: trial.recordingRange) {
        currentPlaybackVC.startCropping(withCropRange: editingCropRange,
                                        recordingRange: trial.recordingRange)
      }
    }
  }

  private func endCropping() {
    state = .playback

    let displayTrial = trialDetailDataSource.displayTrial
    for (_, playbackViewController) in playbackViewControllers {
      playbackViewController.resetAndloadData(cropRange: displayTrial.cropRange) {
        playbackViewController.endCropping()
        // TODO: Remove once sensor paging is supported during a crop. http://b/70326480
        self.sensorsView?.updatePaginationButtons()
      }
    }
  }

  private func saveCrop() {
    guard let (_, playbackViewController) = currentPlaybackViewController,
        let cropRange = playbackViewController.cropRange else {
      return
    }

    let trial = trialDetailDataSource.trial

    guard cropRange != trial.cropRange else {
      // Crop range hasn't changed.
      return
    }

    guard cropValidator.isCropRangeValid(cropRange) else {
      // Crop range isn't valid.
      return
    }

    itemDelegate?.trialDetailViewControllerDidUpdateTrial(cropRange: cropRange,
                                                          name: nil,
                                                          caption: nil,
                                                          withID: trial.ID)
  }

  /// Updates the display trial based on the current trial and populates the chart
  /// presentation views.
  private func updateDisplayTrial() {
    trialDetailDataSource.updateDisplayTrial()
    for sensor in trialDetailDataSource.displayTrial.sensors {
      guard let playbackViewController = playbackViewControllers[sensor.ID] else {
        continue
      }
      trialDetailDataSource.setChartPresentationView(playbackViewController.view,
                                                     forSensorID: sensor.ID)

      // Update stat overlays.
      if let min = sensor.stats.minValue,
          let max = sensor.stats.maxValue,
          let average = sensor.stats.averageValue {
        playbackViewController.setStats(min: min, max: max, average: average)
      }
    }
  }

  private func playbackMenuActions() -> [PopUpMenuAction] {
    var actions = [PopUpMenuAction]()

    // Crop
    func addCropAction() {
      let isCropEnabled = cropValidator.isRecordingRangeValidForCropping
          && !trialDetailDataSource.trial.isArchived
      actions.append(PopUpMenuAction(title: String.cropRun,
                                     icon: UIImage(named: "ic_crop"),
                                     isEnabled: isCropEnabled) { _ in
        self.startCropping()
      })
    }

    if experimentInteractionOptions.shouldAllowEdits {
      addCropAction()
    }

    // Export
    let exportTitle: String
    let exportIconName: String
    let exportAccessibilityLabel: String?
    let exportAction: Selector
    switch exportType {
    case .saveToFiles:
      exportTitle = String.saveToFilesTitle
      exportIconName = "ic_save_alt"
      exportAccessibilityLabel = String.saveToFilesContentDescription
      exportAction = #selector(self.saveToFilesButtonPressed)
    case .share:
      exportTitle = String.exportAction
      exportIconName = "ic_share"
      exportAccessibilityLabel = nil
      exportAction = #selector(self.shareButtonPressed)
    }
    actions.append(PopUpMenuAction(title: exportTitle,
                                   icon: UIImage(named: exportIconName),
                                   accessibilityLabel: exportAccessibilityLabel) { _ in
      // Show the trial share settings as a bottom sheet. It has an option for whether to export as
      // relative time, a cancel button and the export button.
      let trialShareVC =
          TrialShareSettingsViewController(analyticsReporter: self.analyticsReporter,
                                           exportType: self.exportType)
      trialShareVC.shareButton.addTarget(self, action: exportAction, for: .touchUpInside)
      let bottomSheetController = MDCBottomSheetController(contentViewController: trialShareVC)
      self.present(bottomSheetController, animated: true)
      self.trialShareViewController = trialShareVC
    })

    // Archive.
    func addArchiveAction() {
      let archiveTitle =
          trialDetailDataSource.trial.isArchived ? String.actionUnarchive : String.actionArchive
      let archiveAccessibilityLabel = trialDetailDataSource.trial.isArchived ?
          String.actionUnarchiveRecordingContentDescription :
          String.actionArchiveRecordingContentDescription
      let archiveImageName = trialDetailDataSource.trial.isArchived ? "ic_unarchive" : "ic_archive"
      actions.append(PopUpMenuAction(title: archiveTitle,
                                     icon: UIImage(named: archiveImageName),
                                     accessibilityLabel: archiveAccessibilityLabel,
                                     handler: { (_) in
        self.itemDelegate?.trialDetailViewController(self,
            trialArchiveStateToggledForTrialID: self.trialDetailDataSource.trial.ID)
      }))
    }

    if experimentInteractionOptions.shouldAllowEdits {
      addArchiveAction()
    }

    // Delete.
    func addDeleteAction() {
      actions.append(PopUpMenuAction(
          title: String.actionDelete,
          icon: UIImage(named: "ic_delete"),
          accessibilityLabel: String.actionDeleteRecordingContentDescription) { _ -> Void in
        // Prompt the user to confirm deletion.
        let alertController = MDCAlertController(title: String.deleteRunDialogTitle,
                                                 message: String.runReviewDeleteConfirm)
        let cancelAction = MDCAlertAction(title: String.btnDeleteObjectCancel)
        let deleteAction = MDCAlertAction(title: String.btnDeleteObjectConfirm) { (_) in
          let trialID = self.trialDetailDataSource.trial.ID
          self.itemDelegate?.trialDetailViewControllerDidRequestDeleteTrial(withID: trialID)
          self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        alertController.accessibilityViewIsModal = true
        self.present(alertController, animated: true)
      })
    }

    if experimentInteractionOptions.shouldAllowDeletes {
      addDeleteAction()
    }

    return actions
  }

  private func cropMenuActions() -> [PopUpMenuAction] {
    var actions = [PopUpMenuAction]()

    // Edit start time.
    actions.append(PopUpMenuAction(title: String.editCropStartTime, isEnabled: true) { _ in
      self.showTimestampEditAlert(for: .start)
    })

    // Edit end time.
    actions.append(PopUpMenuAction(title: String.editCropEndTime, isEnabled: true) { _ in
      self.showTimestampEditAlert(for: .end)
    })

    return actions
  }

  private func showTimestampEditAlert(for cropMarkerType: CropOverlayView.MarkerType) {
    guard let trialCropRange = currentPlaybackViewController?.1.cropRange else {
      return
    }
    cropRangeController.showTimestampEditAlert(for: cropMarkerType,
                                               trialCropRange: trialCropRange)
  }

  /// Creates trial data for export.
  ///
  /// - Parameter completion: Called when complete with a Bool indicating success, and the trial
  ///                         data file URL.
  private func createTrialExport(completion: @escaping (Bool, URL?) -> Void) {
    guard let trialShareViewController = trialShareViewController else { return }

    let trial = trialDetailDataSource.trial
    let filename = exportFilename
    let isRelativeTime = trialShareViewController.relativeSwitch.isOn
    let sensorIDs = trial.sensorLayouts.map { $0.sensorID }
    let range = trial.cropRange ?? trial.recordingRange
    guard let trialDataWriter = TrialDataWriter(trialID: trial.ID,
                                                filename: filename,
                                                isRelativeTime: isRelativeTime,
                                                sensorIDs: sensorIDs,
                                                range: range,
                                                sensorDataManager: sensorDataManager) else {
      print("[TrialDetailViewController] Error creating trial data writer.")
      dismiss(animated: true, completion: {
        completion(false, nil)
      })
      analyticsReporter.track(.trialExportError)
      return
    }

    trialDataWriter.write(progress: { (progress) in
      let clampedProgress = (0.0...1.0).clamp(progress)
      trialShareViewController.setProgress(clampedProgress)
    }) { (didSucceed) in
      guard didSucceed else {
        self.dismiss(animated: true, completion: {
          completion(false, nil)
        })
        return
      }

      self.dismiss(animated: true, completion: {
        completion(true, trialDataWriter.fileURL)
      })
      self.analyticsReporter.track(.trialExported)
    }
  }

  private func createPendingNote(text: String? = nil,
                                 imageData: Data? = nil,
                                 imageMetaData: NSDictionary? = nil) {
    guard let sensor = sensorsView?.currentSensor,
      let playbackController = playbackViewControllers[sensor.ID] else { return }
    pendingNote = PendingNote(text: text,
                              imageData: imageData,
                              imageMetaData: imageMetaData,
                              timestamp: playbackController.playheadTimestamp,
                              relativeTimestamp: playbackController.playheadRelativeTimestamp)
  }

  /// The passed in `noteText` will override any text that was previously set on the `pendingNote`.
  private func processPendingNote(noteText: String? = nil) {
    guard let pendingNote = pendingNote else { return }

    var newNote: Note
    if let imageData = pendingNote.imageData {
      // Save image
      let pictureNote = PictureNote()
      let pictureFilePath = metadataManager.relativePicturePath(for: pictureNote.ID)
      var savingError = false
      var errorMessage: String?
      do {
        try metadataManager.saveImageData(imageData,
                                          atPicturePath: pictureFilePath,
                                          experimentID: experiment.ID,
                                          withMetadata: pendingNote.imageMetaData)
      } catch MetadataManagerError.photoDiskSpaceError {
        errorMessage = String.photoDiskSpaceErrorMessage
        savingError = true
      } catch {
        sjlog_error("Unknown error saving picture note image: \(error)", category: .general)
        savingError = true
      }

      if savingError {
        finishAddingNote(errorMessage: errorMessage)
        return
      }

      pictureNote.filePath = pictureFilePath
      if let noteText = noteText {
        pictureNote.caption = Caption(text: noteText)
      }
      newNote = pictureNote
    } else if let noteText = noteText {
      newNote = TextNote(text: noteText)
    } else {
      // Notes need either text or an image.
      return
    }

    newNote.timestamp = {
      if let pendingNoteTimestamp = pendingNote.timestamp {
        return pendingNoteTimestamp
      } else {
        // If the pending note timestamp is nil, default to the recording start.
        return trialDetailDataSource.trial.recordingRange.min
      }
    }()

    itemDelegate?.detailViewControllerDidAddNote(newNote,
                                                 forTrialID: trialDetailDataSource.trial.ID)

    // Accessibility announcement string.
    var announcement: String
    switch newNote {
    case is TextNote: announcement = String.textNoteAddedContentDescription
    case is PictureNote: announcement = String.pictureNoteAddedContentDescription
    default: announcement = String.noteAddedContentDescription
    }
    announcement += " \(String.toRunContentDescription)"

    finishAddingNote(announcement: announcement)
  }

  // MARK: - Add Note

  private func showAddNoteDialog() {
    guard let pendingNote = pendingNote else { return }

    let dialogController = MDCDialogTransitionController()
    let dialog = AddTrialNoteViewController(analyticsReporter: analyticsReporter)
    dialog.saveButton.addTarget(self,
                                action: #selector(addNoteSaveButtonPressed),
                                for: .touchUpInside)
    dialog.cancelButton.addTarget(self,
                                  action: #selector(addNoteCancelButtonPressed),
                                  for: .touchUpInside)
    dialog.timestampButton.addTarget(self,
                                     action: #selector(addNoteTimestampButtonPressed),
                                     for: .touchUpInside)
    dialog.photoButton.addTarget(self,
                                 action: #selector(addNotePhotoButtonPressed),
                                 for: .touchUpInside)
    dialog.textField.addTarget(self,
                               action: #selector(addNoteTextFieldDidChange),
                               for: .editingChanged)
    dialog.modalPresentationStyle = .custom
    dialog.transitioningDelegate = dialogController
    dialog.mdc_dialogPresentationController?.dismissOnBackgroundTap = false

    let timestampString = timeFormat.string(fromTimestamp: pendingNote.relativeTimestamp)
    dialog.timestampButton.setTitle(timestampString, for: .normal)
    dialog.textField.text = pendingNote.text

    if let imageData = pendingNote.imageData, let image = UIImage(data: imageData) {
      dialog.showImage(image)
    } else {
      dialog.hideImage()
    }

    if pendingNote.imageData == nil && pendingNote.text == nil {
      dialog.saveButton.isEnabled = false
    }

    present(dialog, animated: true)
    dialogTransitionController = dialogController
    dialog.saveButton.isEnabled = pendingNoteDataIsValid()
    addNoteDialog = dialog
  }

  /// Closes the add note alert and resets all relevant data.
  ///
  /// - Parameter announcement: Optional string to announce with VoiceOver when complete.
  private func finishAddingNote(announcement: String? = nil, errorMessage: String? = nil) {
    pendingNote = nil
    if addNoteDialog != nil {
      dismiss(animated: true, completion: {
        if let errorMessage = errorMessage {
          showSnackbar(withMessage: errorMessage)
        }
        // Need to delay this announcement a bit or the VO engine eats it after the modal
        // disappears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          guard let announcement = announcement else { return }
          UIAccessibility.post(notification: .announcement, argument: announcement)
        }
      })
    }
    addNoteDialog = nil
    state = .playback
  }

  private func pendingNoteDataIsValid() -> Bool {
    guard let pendingNote = pendingNote else { return false }
    return pendingNote.text?.trimmedOrNil != nil || pendingNote.imageData != nil
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    stopPlayback()
    navigationController?.popViewController(animated: true)
  }

  @objc private func menuButtonPressed() {
    let popUpMenu = PopUpMenuViewController()

    // Actions change depending on state.
    var actions: [PopUpMenuAction]
    switch state {
    case .playback:
      actions = playbackMenuActions()
    case .timeSelect:
      // No menu button in time select mode.
      return
    case .crop:
      actions = cropMenuActions()
    }

    popUpMenu.addActions(actions)
    popUpMenu.present(from: self, position: .sourceView(menuBarButton.button))
  }

  @objc private func shareButtonPressed() {
    createTrialExport(completion: { (success, fileURL) in
      guard success, let fileURL = fileURL else {
        showSnackbar(withMessage: String.exportError)
        return
      }

      let activityController = UIActivityViewController(activityItems: [fileURL],
                                                        applicationActivities: nil)
      if let presentationController = activityController.popoverPresentationController {
        presentationController.sourceView = self.menuBarButton.button
        presentationController.sourceRect = self.menuBarButton.button.bounds
      }
      self.present(activityController, animated: true)
    })
  }

  @objc private func saveToFilesButtonPressed() {
    createTrialExport(completion: { (success, fileURL) in
      guard success, let fileURL = fileURL else {
        showSnackbar(withMessage: String.saveToFilesSingleErrorMessage)
        return
      }

      self.saveToFilesHandler.presentSaveToFiles(for: fileURL,
                                                 from: self) { result in
        switch result {
        case .saved:
          showSnackbar(withMessage: String.saveToFilesSingleSuccessMessage)
        case .cancelled:
          break
        }
      }
    })
  }

  @objc private func editButtonPressed() {
    let dialogController = MDCDialogTransitionController()
    let dialog = RenameTrialViewController(analyticsReporter: analyticsReporter)
    dialog.textField.text = trialDetailDataSource.trialTitle
    dialog.textField.placeholder = String.editTrialTitleHint
    dialog.okayButton.addTarget(self,
                                action: #selector(renameTrialOkayButtonPressed),
                                for: .touchUpInside)
    dialog.modalPresentationStyle = .custom
    dialog.transitioningDelegate = dialogController
    dialog.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
    present(dialog, animated: true)
    renameDialog = dialog
    dialogTransitionController = dialogController
  }

  @objc private func renameTrialOkayButtonPressed() {
    guard let dialog = renameDialog else { return }

    // Only update the trial title if the new title has a non-zero trimmed length.
    if let newTitle = dialog.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
        newTitle.count > 0 {
      itemDelegate?.trialDetailViewControllerDidUpdateTrial(cropRange: nil,
                                                            name: newTitle,
                                                            caption: nil,
                                                            withID: trialDetailDataSource.trial.ID)
    }
    dialog.dismiss(animated: true)
    renameDialog = nil
    dialogTransitionController = nil
  }

  @objc private func previousNextSensorTapped() {
    stopPlayback()
  }

  @objc private func addNoteCancelButtonPressed() {
    finishAddingNote()
  }

  @objc private func addNoteSaveButtonPressed() {
    guard let addNoteDialog = addNoteDialog else { return }
    processPendingNote(noteText: addNoteDialog.textField.text?.trimmedOrNil)
  }

  @objc private func addNoteTimestampButtonPressed() {
    guard let pendingNote = pendingNote else { return }

    self.pendingNote?.text = addNoteDialog?.textField.text
    let timeText = timeFormat.string(fromTimestamp: pendingNote.relativeTimestamp)
    timeSelectionView.timestampLabel.text = timeText
    timeSelectionView.accessibilityLabel =
        "\(String.editNoteTimeMenuItem), \(String.currentValueContentDescription) \(timeText))"
    collectionView.isScrollEnabled = false
    state = .timeSelect
    dismiss(animated: true)
    addNoteDialog = nil
  }

  @objc private func addNotePhotoButtonPressed() {
    let cameraController = StandaloneCameraViewController(analyticsReporter: analyticsReporter)
    cameraController.delegate = self
    cameraViewController = cameraController

    dismiss(animated: true, completion: {
      self.present(cameraController, animated: true)
    })
  }

  @objc private func cancelButtonPressed() {
    // In time select mode, bottom inset wasn't set properly when keyboard was dismissed.
    collectionView.contentInset.bottom = 0
    switch state {
    case .timeSelect:
      state = .playback
      showAddNoteDialog()
    case .crop: endCropping()
    case .playback: break
    }
  }

  @objc private func saveButtonPressed() {
    switch state {
    case .timeSelect:
      timeSelectionConfirmPressed()
    case .crop:
      saveCrop()
      endCropping()
    case .playback:
      break
    }
  }

  @objc private func timeSelectionConfirmPressed() {
    guard let sensor = sensorsView?.currentSensor,
        let playbackController = playbackViewControllers[sensor.ID] else {
      return
    }

    pendingNote?.timestamp = playbackController.playheadTimestamp
    let relativeTimestamp = playbackController.playheadRelativeTimestamp
    pendingNote?.relativeTimestamp = relativeTimestamp

    state = .playback
    showAddNoteDialog()
  }

  @objc private func addNoteTextFieldDidChange() {
    pendingNote?.text = addNoteDialog?.textField.text?.trimmedOrNil
    addNoteDialog?.saveButton.isEnabled = pendingNoteDataIsValid()
  }

  func cameraButtonPressed() {
    switch CaptureSessionInterruptionObserver.shared.cameraAvailability {
    case .permissionsDenied:
      showCameraPermissionsDeniedAlert()
    case .blockedByBrightnessSensor:
      showSnackbar(withMessage: String.inputCameraBlockedByBrightnessSensor,
                   category: nil,
                   actionTitle: String.actionOk,
                   actionHandler: nil
      )
    default: // Handles .available and .captureInterrupted
      present(cameraImageProvider.cameraViewController, animated: true)
    }
  }

  func showCameraPermissionsDeniedAlert() {
    let ac = UIAlertController(title: String.inputCameraPermissionDeniedTitle,
                               message: String.inputCameraPermissionDeniedSettings,
                               preferredStyle: .alert)

    let settingsAction = UIAlertAction(title: String.actionSettings,
                                       style: .default) { _ in
      if let settingsURL = URL(string: "App-prefs:root=Privacy&path=CAMERA") {
        UIApplication.shared.open(settingsURL)
      }
    }
    ac.addAction(settingsAction)

    let cancelAction = UIAlertAction(title: String.actionCancel,
                                     style: .cancel,
                                     handler: nil)
    ac.addAction(cancelAction)

    present(ac, animated: true)
  }
}

// MARK: - NotesViewControllerDelegate

extension TrialDetailViewController: NotesViewControllerDelegate {

  func notesViewController(_ notesViewController: NotesViewController,
                           didCreateTextForNote text: String) {
    createPendingNote()
    processPendingNote(noteText: text)

    // TODO: Consider AA-specific API.
    if FeatureFlags.isActionAreaEnabled {
      notesViewController.navigationController?.popViewController(animated: true)
    }
  }

}

// swiftlint:enable file_length type_body_length
