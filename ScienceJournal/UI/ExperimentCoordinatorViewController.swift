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

import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Snackbar_Snackbar
// swiftlint:disable line_length
import third_party_objective_c_material_components_ios_components_private_KeyboardWatcher_KeyboardWatcher
// swiftlint:enable line_length

protocol ExperimentCoordinatorViewControllerDelegate: class {

  /// Informs the delegate an experiment's archive state should be toggled.
  ///
  /// - Parameter experimentID: An experiment ID.
  func experimentViewControllerToggleArchiveStateForExperiment(withID experimentID: String)

  /// Informs the delegate the experiment should be deleted.
  ///
  /// - Parameter experiment: The experiment to delete.
  func experimentViewControllerDidRequestDeleteExperiment(_ experiment: Experiment)

  /// Informs the delegate the archive state of a trial should be toggled.
  ///
  /// - Parameter trialID: A trial ID.
  func experimentViewControllerToggleArchiveStateForTrial(withID trialID: String)

  /// Informs the delegate a trial should be shown.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - jumpToCaption: Whether to jump to the caption input when showing the trial.
  func experimentViewControllerShowTrial(withID trialID: String, jumpToCaption: Bool)

  /// Informs the delegate a note should be shown.
  ///
  /// - Parameters:
  ///   - displayNote: The display note to show.
  ///   - jumpToCaption: Whether to jump to the caption input when showing the trial.
  func experimentViewControllerShowNote(_ displayNote: DisplayNote, jumpToCaption: Bool)

  /// Informs the delegate a trial should be added to the current experiment.
  ///
  /// - Parameters:
  ///   - trial: The trial to add.
  ///   - isRecording: Whether the trial is recording.
  func experimentViewControllerAddTrial(_ trial: Trial, recording isRecording: Bool)

  /// Informs the delegate the deletion of a trial is complete, meaning it can no longer be undone.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - experiment: The experiment the trial belonged to.
  func experimentViewControllerDeleteTrialCompleted(_ trial: Trial,
                                                    fromExperiment experiment: Experiment)

  /// Informs the delegate a trial should be permanently deleted.
  ///
  /// - Parameters:
  ///   - trial: The trial to be deleted.
  ///   - experiment: The experiment the trial belongs to.
  func experimentViewControllerShouldPermanentlyDeleteTrial(_ trial: Trial,
                                                            fromExperiment experiment: Experiment)

  /// Informs the delegate that a trial finished recording.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - experiment: The experiment the trial belongs to.
  func experimentViewControllerDidFinishRecordingTrial(_ trial: Trial,
                                                       forExperiment experiment: Experiment)

  /// Informs the delegate the cover image for this experiment should be removed.
  ///
  /// - Parameter experiment: The experiment.
  /// - Returns: True if successful, otherwise false.
  func experimentViewControllerRemoveCoverImageForExperiment(_ experiment: Experiment) -> Bool

  /// Informs the delegate the experiment title changed.
  ///
  /// - Parameters:
  ///   - title: The experiment title.
  ///   - experiment: The experiment that changed.
  func experimentViewControllerDidSetTitle(_ title: String?, forExperiment experiment: Experiment)

  /// Informs the delegate the experiment cover image changed.
  ///
  /// - Parameters:
  ///   - imageData: The cover image data.
  ///   - metadata: The metadata associated with the image.
  ///   - experiment: The experiment whose cover image was set.
  func experimentViewControllerDidSetCoverImageData(_ imageData: Data?,
                                                    metadata: NSDictionary?,
                                                    forExperiment experiment: Experiment)

  /// Informs the delegate the experiment's recording trial changed.
  ///
  /// - Parameters:
  ///   - recordingTrial: The recoring trial that changed.
  ///   - experiment: The experiment that was changed.
  func experimentViewControllerDidChangeRecordingTrial(_ recordingTrial: Trial,
                                                       experiment: Experiment)

  /// Informs the delegate an experiment picture note delete has completed.
  ///
  /// - Parameters:
  ///   - pictureNote: The picture note.
  ///   - experiment: The experiment the picture note belonged to.
  func experimentViewControllerDeletePictureNoteCompleted(_ pictureNote: PictureNote,
                                                          forExperiment experiment: Experiment)

  /// Informs the delegate the experiment should be exported as a PDF.
  ///
  /// - Parameter experiment: The experiment to export.
  func experimentViewControllerExportExperimentPDF(
    _ experiment: Experiment,
    completionHandler: @escaping PDFExportController.CompletionHandler)

  /// Asks the delegate for a pop up menu action to initiate export flow.
  ///
  /// - Parameters:
  ///   - experiment: The experiment to be exported.
  ///   - presentingViewController: The presenting view controller.
  ///   - sourceView: View to anchor a popover to display.
  func experimentViewControllerExportFlowAction(for experiment: Experiment,
                                                from presentingViewController: UIViewController,
                                                sourceView: UIView) -> PopUpMenuAction?

}

// swiftlint:disable type_body_length
// TODO: Consider breaking this class into multiple files for each delegate.
/// A coordinator view controller responsible for displaying the items in an experiment.
class ExperimentCoordinatorViewController: MaterialHeaderViewController, DrawerPositionListener,
    EditExperimentViewControllerDelegate, ImageSelectorDelegate, NotesViewControllerDelegate,
    ObserveViewControllerDelegate, SensorSettingsDelegate, TriggerListDelegate,
    ExperimentItemsViewControllerDelegate, ExperimentUpdateListener, ExperimentStateListener,
    CameraImageProviderDelegate {

  typealias ReadyForPDFExportBlock = () -> Void

  // MARK: - Properties

  /// The edit bar button. Exposed for testing.
  let editBarButton = MaterialBarButtonItem()

  /// The menu bar button. Exposed for testing.
  let menuBarButton = MaterialMenuBarButtonItem()

  /// A fixed space bar item. Exposed for testing.
  lazy var fixedSpaceBarItem: UIBarButtonItem = {
    let fixedSpace = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    fixedSpace.width = ViewConstants.iPadDrawerSidebarWidth + 16
    fixedSpace.isEnabled = false
    return fixedSpace
  }()

  /// Interaction options for this experiment.
  var experimentInteractionOptions: ExperimentInteractionOptions {
    didSet {
      shouldAllowAdditions = experimentInteractionOptions.shouldAllowAdditions
    }
  }

  /// Whether this experiment allows additions.
  // Depends on experimentInteractionOptions and needs to be updated when it changes.
  @objc dynamic var shouldAllowAdditions: Bool

  /// The experiment. Exposed for testing.
  var experiment: Experiment

  weak var delegate: ExperimentCoordinatorViewControllerDelegate?
  weak var itemDelegate: ExperimentItemDelegate?
  private var dialogTransitionController: MDCDialogTransitionController?
  private let drawerVC: DrawerViewController?

  private let experimentDataParser: ExperimentDataParser
  private let experimentItemsViewController: ExperimentItemsViewController

  private let documentManager: DocumentManager
  private let metadataManager: MetadataManager
  private var renameDialog: RenameExperimentViewController?
  private var emptyViewTrailingConstraint: NSLayoutConstraint?
  private var drawerViewWidthConstraintSideBySide: NSLayoutConstraint?
  private var drawerViewLeadingConstraint: NSLayoutConstraint?
  private let emptyView =
      EmptyView(title: String.emptyExperiment, imageName: "empty_experiment_view")
  private var backMenuItem: MaterialBackBarButtonItem?
  private var drawerViewTopConstraint: NSLayoutConstraint?
  private let preferenceManager: PreferenceManager
  private let sensorController: SensorController
  private let sensorDataManager: SensorDataManager
  private let snackbarCategoryTriggersDisabled = "snackbarCategoryTriggersDisabled"
  private let snackbarCategoryDeletedRecording = "snackbarCategoryDeletedRecording"
  private let snackbarCategoryNoteDeleted = "snackbarCategoryNoteDeleted"
  private let snackbarCategoryExperimentArchivedState = "snackbarCategoryExperimentArchivedState"
  private let snackbarCategoryTrialArchivedState = "snackbarCategoryTrialArchivedState"
  private let snackbarCategoryCouldNotUpdateSensorSettings =
      "snackbarCategoryCouldNotUpdateSensorSettings"
  private let exportType: UserExportType
  private let saveToFilesHandler = SaveToFilesHandler()

  // A dictionary of chart controllers, keyed by sensor ID.
  private var chartControllers = [String: ChartController]()

  // A dictionary of chart export view controllers, keyed by sensor ID.
  private var chartExportViewControllers = [String: ChartExportViewController]()
  private var chartExportViewControllersLoaded = 0

  private var statusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.size.height
  }

  override var trackedScrollView: UIScrollView? {
    return experimentItemsViewController.collectionView
  }

  /// Should the experiment require a name? Default is true. If false, user will not be asked to
  /// rename the experiment when leaving the VC if the title is not set.
  var requireExperimentTitle: Bool = true

  /// Defines the current state of the views in this controller's tree.
  /// Setting this causes a full reload of the collection view and will cause a visual blink, but
  /// it is expected that this will happen behind an overlaid view for now.
  var experimentDisplay = ExperimentDisplay.normal {
    didSet {
      experimentItemsViewController.experimentDisplay = experimentDisplay
      switch experimentDisplay {
      case .normal, .pdfExport:
        reloadExperimentItems()
      case .recording:
        break
      }
    }
  }

  /// A block that will be called when this controller's view hierarchy is ready for PDF Export.
  var readyForPDFExport: ReadyForPDFExportBlock?

  // This VC is currently the delegate for these controllers, so we'll create them here
  // as needed until we remove the `DrawerViewController`.
  private lazy var _observeViewController: ObserveViewController =
    ObserveViewController(analyticsReporter: analyticsReporter,
                          preferenceManager: preferenceManager,
                          sensorController: sensorController,
                          sensorDataManager: sensorDataManager)
  var observeViewController: ObserveViewController {
    return drawerVC?.observeViewController ?? _observeViewController
  }

  private lazy var _notesViewController: NotesViewController =
    NotesViewController(analyticsReporter: analyticsReporter)
  var notesViewController: NotesViewController {
    return drawerVC?.notesViewController ?? _notesViewController
  }

  private lazy var cameraImageProvider: CameraImageProvider = {
    let cameraImageProvider = CameraImageProvider()
    cameraImageProvider.delegate = self
    return cameraImageProvider
  }()

  private lazy var _cameraViewController: CameraViewController =
    CameraViewController(analyticsReporter: analyticsReporter)
  var cameraViewController: CameraViewController {
    return drawerVC?.cameraViewController ?? _cameraViewController
  }

  private lazy var _photoLibraryViewController = PhotoLibraryViewController(
    actionBarButtonType: .send,
    selectionMode: .multiple,
    analyticsReporter: analyticsReporter)
  var photoLibraryViewController: PhotoLibraryViewController {
    return drawerVC?.photoLibraryViewController ?? _photoLibraryViewController
  }

  // MARK: - Public

  /// Designated initializer that takes an experiment.
  ///
  /// - Parameters:
  ///   - experiment: The experiment.
  ///   - experimentInteractionOptions: Experiment interaction options.
  ///   - exportType: The export option type to show.
  ///   - drawerViewController: A drawer view controller.
  ///   - analyticsReporter: An AnalyticsReporter.
  ///   - metadataManager: The metadata manager.
  ///   - preferenceManager: The preference manager.
  ///   - sensorController: The sensor controller.
  ///   - sensorDataManager: The sensor data manager.
  ///   - documentManager: The document manager.
  init(experiment: Experiment,
       experimentInteractionOptions: ExperimentInteractionOptions,
       exportType: UserExportType,
       drawerViewController: DrawerViewController?,
       analyticsReporter: AnalyticsReporter,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager,
       sensorController: SensorController,
       sensorDataManager: SensorDataManager,
       documentManager: DocumentManager) {
    self.experiment = experiment
    self.experimentInteractionOptions = experimentInteractionOptions
    self.shouldAllowAdditions = experimentInteractionOptions.shouldAllowAdditions
    self.exportType = exportType
    self.drawerVC = drawerViewController
    self.metadataManager = metadataManager
    self.preferenceManager = preferenceManager
    self.sensorController = sensorController
    self.sensorDataManager = sensorDataManager
    self.documentManager = documentManager

    experimentDataParser = ExperimentDataParser(experimentID: experiment.ID,
                                                metadataManager: metadataManager,
                                                sensorController: sensorController)

    let isExperimentArchived = metadataManager.isExperimentArchived(withID: experiment.ID)
    experimentItemsViewController =
        ExperimentItemsViewController(experimentInteractionOptions: experimentInteractionOptions,
                                      metadataManager: metadataManager,
                                      shouldShowArchivedFlag: isExperimentArchived)

    super.init(analyticsReporter: analyticsReporter)

    experimentItemsViewController.delegate = self
    experimentItemsViewController.scrollDelegate = self

    // Set delegate for all drawer items.
    observeViewController.delegate = self
    cameraViewController.delegate = self
    photoLibraryViewController.delegate = self
    notesViewController.delegate = self

    // Configure observe.
    updateObserveWithExperimentTriggers()
    observeViewController.setSensorLayouts(experiment.sensorLayouts,
        andAddListeners: experimentInteractionOptions.shouldShowDrawer)
    updateObserveWithAvailableSensors()

    // Register for trial stats update notifications.
    NotificationCenter.default.addObserver(self,
        selector: #selector(handleTrialStatsDidCompleteNotification(notification:)),
        name: SensorDataManager.TrialStatsCalculationDidComplete,
        object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  deinit {
    drawerVC?.removeDrawerPositionListener(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.preservesSuperviewLayoutMargins = true
    view.backgroundColor = MDCPalette.grey.tint200
    updateExperimentTitle()

    // Experiment items view controller. This must be configured before the drawer or empty view,
    // because both rely on the experiment items count.
    experimentItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
    addChild(experimentItemsViewController)
    view.addSubview(experimentItemsViewController.view)
    experimentItemsViewController.view.pinToEdgesOfView(view)
    experimentItemsViewController.didMove(toParent: self)

    setCollectionViewInset()
    reloadExperimentItems()

    // Drawer.
    if let drawerVC = drawerVC {
      addChild(drawerVC)
      view.addSubview(drawerVC.drawerView)
      drawerVC.drawerView.translatesAutoresizingMaskIntoConstraints = false
      // TODO: This needs to be smart about in-call status bar changes. http://b/62135678
      drawerViewTopConstraint =
          drawerVC.drawerView.topAnchor.constraint(equalTo: view.topAnchor,
                                                   constant: statusBarHeight)
      drawerViewTopConstraint?.isActive = true
      drawerVC.drawerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      drawerVC.drawerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
      drawerViewWidthConstraintSideBySide = drawerVC.drawerView.widthAnchor.constraint(
          equalToConstant: ViewConstants.iPadDrawerSidebarWidth)
      drawerViewLeadingConstraint =
          drawerVC.drawerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
      drawerVC.addDrawerPositionListener(self)
      updateDrawerForExperimentInteractionOptions(animated: false)
    }

    // Configure the empty view.
    emptyView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyView)
    emptyView.topAnchor.constraint(equalTo: appBar.navigationBar.bottomAnchor).isActive = true
    emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    emptyViewTrailingConstraint = emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    emptyViewTrailingConstraint?.isActive = true
    emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    updateEmptyViewArchivedFlagInsets()
    updateEmptyView(animated: false)

    updateConstraints(forDisplayType: displayType, withSize: view.bounds.size)

    // Bar buttons.
    backMenuItem = MaterialBackBarButtonItem(target: self,
                                             action: #selector(backButtonPressed))
    navigationItem.hidesBackButton = true
    navigationItem.leftBarButtonItem = backMenuItem

    editBarButton.button.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
    editBarButton.button.setImage(UIImage(named: "ic_edit"), for: .normal)
    editBarButton.button.accessibilityLabel = String.editExperimentBtnContentDescription
    editBarButton.button.accessibilityHint = String.editExperimentBtnContentDetails

    menuBarButton.button.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuBarButton.button.setImage(UIImage(named: "ic_more_horiz"), for: .normal)

    updateRightBarButtonItems(for: displayType)

    // Reset the drawer since it is reused between experiments.
    drawerVC?.reset()

    if let drawerVC = drawerVC, drawerVC.isDisplayedAsSidebar {
      drawerVC.setPositionToFull(animated: false)
    } else if experimentItemsViewController.isEmpty {
      // If there is no content, display drawer at half height to encourage input.
      drawerVC?.setPositionToHalfOrPeeking(animated: false)
    } else {
      // Hide the drawer by default.
      drawerVC?.setPositionToPeeking(animated: false)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Bring the drawer to the front of the app bar view, which is brought to the front in
    // MaterialHeaderViewController.
    if let drawerVC = drawerVC {
      view.bringSubviewToFront(drawerVC.drawerView)
    }

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .MDCKeyboardWatcherKeyboardWillChangeFrame,
                                           object: nil)

    setCollectionViewInset()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    NotificationCenter.default.removeObserver(self,
                                              name: .MDCKeyboardWatcherKeyboardWillChangeFrame,
                                              object: nil)

    // Dismiss snackbars presented by this view controller, but don't dismiss the delete experiment
    // undo snackbar.
    [snackbarCategoryTriggersDisabled, snackbarCategoryDeletedRecording,
        snackbarCategoryNoteDeleted, snackbarCategoryExperimentArchivedState,
        snackbarCategoryTrialArchivedState, snackbarCategoryCouldNotUpdateSensorSettings].forEach {
          MDCSnackbarManager.dismissAndCallCompletionBlocks(withCategory: $0)
    }
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { (_) in
      let displayType = self.traitCollection.displayType(with: size)

      self.updateConstraints(forDisplayType: displayType, withSize: size)
      self.updateRightBarButtonItems(for: displayType)
      self.updateDrawerPosition(for: displayType, size: size)
      if FeatureFlags.isActionAreaEnabled == false {
        // This would set the header to the wrong color while recording.
        self.updateHeaderColor()
      }
      self.updateEmptyViewArchivedFlagInsets()
    })
  }

  /// Reloads the view with a new experiment.
  ///
  /// - Parameter experiment: An experiment.
  func reloadWithNewExperiment(_ experiment: Experiment) {
    self.experiment = experiment
    updateExperimentTitle()
    reloadExperimentItems()
    updateEmptyView(animated: true)
  }

  // Displays a detail view controller for the the display item, optionally jumping to the caption
  // field when it loads.
  private func displayDetailViewController(for displayItem: DisplayItem,
                                           jumpToCaption: Bool = false) {
    switch displayItem {
    case let displayTrial as DisplayTrial:
      delegate?.experimentViewControllerShowTrial(withID: displayTrial.ID,
                                                  jumpToCaption: jumpToCaption)
    case let displayNote as DisplayNote:
      delegate?.experimentViewControllerShowNote(displayNote, jumpToCaption: jumpToCaption)
    default: return
    }
  }

  /// Cancels a recording if there was one in progress.
  func cancelRecordingIfNeeded() {
    guard RecordingState.isRecording else { return }
    observeViewController.endRecording(isCancelled: true)
  }

  // MARK: - DrawerPositionListener

  func drawerViewController(_ drawerViewController: DrawerViewController,
                            isPanningDrawerView drawerView: DrawerView) {}
  func drawerViewController(_ drawerViewController: DrawerViewController,
                            willChangeDrawerPosition position: DrawerPosition) {}
  func drawerViewController(_ drawerViewController: DrawerViewController,
                            didPanBeyondBounds panDistance: CGFloat) {}

  func drawerViewController(_ drawerViewController: DrawerViewController,
                            didChangeDrawerPosition position: DrawerPosition) {
    setCollectionViewInset(onlyIfViewIsVisible: true)
    updateHeaderColor()
  }

  // MARK: - ExperimentItemsViewControllerDelegate

  func experimentItemsViewControllerDidSelectItem(_ displayItem: DisplayItem) {
    if RecordingState.isRecording {
      // Trial is recording, disable cell taps for detail views and taps on the recording indicator
      // cell should take you to a halfway-open drawer on the observe tab in portrait, open full
      // drawer in landscape.
      guard let displayTrial = displayItem as? DisplayTrial,
          displayTrial.status != .final else { return }
      if FeatureFlags.isActionAreaEnabled {
        actionAreaController?.reshowDetail()
      } else {
        drawerVC?.showContent()
        guard drawerVC?.currentViewController is ObserveViewController else {
          drawerVC?.selectObserve()
          return
        }
      }
    } else {
      // No trial recording currently, cells tapped lead to detail views.
      displayDetailViewController(for: displayItem)
    }
  }

  func experimentItemsViewControllerMenuPressedForItem(_ displayItem: DisplayItem,
                                                       button: MenuButton) {
    let popUpMenu = PopUpMenuViewController()

    // If the user is recording, we don't want them to enter any other VC like details, so remove
    // these menu items.
    if !RecordingState.isRecording {
      // View.
      func addViewAction() {
        popUpMenu.addAction(PopUpMenuAction(
          title: String.actionViewDetails,
          icon: UIImage(named: "ic_visibility")) { _ -> Void in
            self.displayDetailViewController(for: displayItem)
        })
      }

      // Comment.
      func addCommentAction() {
        popUpMenu.addAction(PopUpMenuAction(
          title: String.actionAddCaption,
          icon: UIImage(named: "ic_comment")) { _ -> Void in
            self.displayDetailViewController(for: displayItem, jumpToCaption: true)
        })
      }

      switch displayItem.itemType {
      case .textNote:
        // Edit.
        func showEditAction() {
          popUpMenu.addAction(PopUpMenuAction(title: String.actionEdit,
                                              icon: UIImage(named: "ic_edit")) { _ -> Void in
            self.displayDetailViewController(for: displayItem)
          })
        }

        if experimentInteractionOptions.shouldAllowEdits {
          showEditAction()
        } else {
          addViewAction()
        }
      case .trial:
        addViewAction()
      case .snapshotNote, .pictureNote, .triggerNote:
        addViewAction()
        if experimentInteractionOptions.shouldAllowEdits {
          addCommentAction()
        }
      }
    }

    // Archive.
    func showArchiveAction(forTrial displayTrial: DisplayTrial) {
      let archiveTitle = displayTrial.isArchived ? String.actionUnarchive : String.actionArchive
      let archiveAccessibilityLabel = displayTrial.isArchived ?
          String.actionUnarchiveRecordingContentDescription :
          String.actionArchiveRecordingContentDescription
      let archiveImageName = displayTrial.isArchived ? "ic_unarchive" : "ic_archive"
      popUpMenu.addAction(PopUpMenuAction(title: archiveTitle,
                                          icon: UIImage(named: archiveImageName),
                                          accessibilityLabel: archiveAccessibilityLabel,
                                          handler: { (_) in
        self.delegate?.experimentViewControllerToggleArchiveStateForTrial(withID: displayTrial.ID)
      }))
    }

    if experimentInteractionOptions.shouldAllowEdits {
      switch displayItem.itemType {
      case .trial(let displayTrial):
        showArchiveAction(forTrial: displayTrial)
      default:
        break
      }
    }

    // Export
    if !RecordingState.isRecording,
        let displayPictureNote = displayItem as? DisplayPictureNote,
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
    func showDeleteAction() {
      popUpMenu.addAction(PopUpMenuAction(
          title: String.actionDelete,
          icon: UIImage(named: "ic_delete"),
          accessibilityLabel: displayItem.itemType.deleteActionAccessibilityLabel) { _ -> Void in
        switch displayItem.itemType {
        case .trial(let trial):
          // Prompt the user to confirm deletion.
          let alertController = MDCAlertController(title: String.deleteRunDialogTitle,
                                                   message: String.runReviewDeleteConfirm)
          let cancelAction = MDCAlertAction(title: String.btnDeleteObjectCancel)
          let deleteAction = MDCAlertAction(title: String.btnDeleteObjectConfirm) { (_) in
            // Delete the trial.
            self.itemDelegate?.trialDetailViewControllerDidRequestDeleteTrial(withID: trial.ID)
          }
          alertController.addAction(cancelAction)
          alertController.addAction(deleteAction)
          self.present(alertController, animated: true)
        default:
          if let displayNote = displayItem as? DisplayNote {
            self.itemDelegate?.detailViewControllerDidDeleteNote(displayNote)
          }
        }
      })
    }

    if experimentInteractionOptions.shouldAllowDeletes {
      showDeleteAction()
    }

    popUpMenu.present(from: self, position: .sourceView(button))
  }

  func experimentItemsViewControllerCommentPressedForItem(_ displayItem: DisplayItem) {
    displayDetailViewController(for: displayItem, jumpToCaption: true)
  }

  // MARK: - EditExperimentViewControllerDelegate

  func editExperimentViewControllerDidSetTitle(_ title: String?,
                                               forExperimentID experimentID: String) {
    delegate?.experimentViewControllerDidSetTitle(title, forExperiment: experiment)
    updateExperimentTitle()
  }

  func editExperimentViewControllerDidSetCoverImageData(_ imageData: Data?,
                                                        metadata: NSDictionary?,
                                                        forExperimentID experimentID: String) {
    delegate?.experimentViewControllerDidSetCoverImageData(imageData,
                                                           metadata: metadata,
                                                           forExperiment: experiment)
  }

  // MARK: - ObserveViewControllerDelegate

  func observeViewControllerDidStartRecording(_ observeViewController: ObserveViewController) {
    experimentItemsViewController.collectionViewChangeScrollPosition = .bottom
    updateForRecording()
  }

  func observeViewControllerDidEndRecording(_ observeViewController: ObserveViewController) {
    experimentItemsViewController.collectionViewChangeScrollPosition = .top
    updateForRecording()
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didCreateSensorSnapshots sensorSnapshots: [SensorSnapshot]) {
    let snapshotNote = SnapshotNote(snapshots: sensorSnapshots)
    addNoteToExperimentOrTrial(snapshotNote)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didReceiveNoteTrigger trigger: SensorTrigger,
                             forSensor sensor: Sensor,
                             atTimestamp timestamp: Int64) {
    let sensorSpec = SensorSpec(sensor: sensor)
    let triggerNote = TriggerNote(sensorSpec: sensorSpec,
                                  triggerInformation: trigger.triggerInformation,
                                  timestamp: timestamp)
    addNoteToExperimentOrTrial(triggerNote)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didBeginTrial trial: Trial) {
    delegate?.experimentViewControllerAddTrial(trial, recording: true)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didUpdateTrial trial: Trial,
                             isFinishedRecording: Bool) {
    if isFinishedRecording {
      updateTrial(trial, didFinishRecording: isFinishedRecording)
      delegate?.experimentViewControllerDidFinishRecordingTrial(trial,
                                                                forExperiment: experiment)
      UIAccessibility.post(
          notification: .announcement,
          argument: "\(String.runAddedContentDescription) \(String.toExperimentContentDescription)")
    }
    delegate?.experimentViewControllerDidChangeRecordingTrial(trial, experiment: experiment)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didCancelTrial trial: Trial) {
    delegate?.experimentViewControllerShouldPermanentlyDeleteTrial(trial,
                                                                   fromExperiment: experiment)
    removeRecordingTrial()
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didPressSetTriggersForSensor sensor: Sensor) {
    showTriggerListViewController(for: sensor)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             isSensorTriggerActive sensorTrigger: SensorTrigger) -> Bool {
    guard let sensorLayout =
        experiment.sensorLayouts.first(where: { $0.sensorID == sensorTrigger.sensorID }) else {
      return false
    }
    return sensorLayout.isTriggerActive(sensorTrigger.triggerID)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didUpdateSensorLayouts sensorLayouts: [SensorLayout]) {
    // Only save the experiment if anything changed.
    if sensorLayouts != experiment.sensorLayouts {
      experiment.sensorLayouts = sensorLayouts
      metadataManager.saveExperimentWithoutDateOrDirtyChange(experiment)
    }
  }

  func observeViewControllerDidPressSensorSettings(_ observeViewController: ObserveViewController) {
    let vc = SensorSettingsViewController(enabledSensorIDs: experiment.availableSensorIDs,
                                          analyticsReporter: analyticsReporter,
                                          metadataManager: metadataManager,
                                          sensorController: sensorController)
    vc.delegate = self
    if UIDevice.current.userInterfaceIdiom == .pad {
      vc.modalPresentationStyle = .formSheet
    }
    present(vc, animated: true)
  }

  func observeViewController(_ observeViewController: ObserveViewController,
                             didExceedTriggerFireLimitForSensor sensor: Sensor) {
    guard let sensorLayout = experiment.sensorLayoutForSensorID(sensor.sensorId) else { return }
    sensorLayout.activeSensorTriggerIDs.removeAll()
    metadataManager.saveExperimentWithoutDateOrDirtyChange(experiment)
    updateObserveWithExperimentTriggers()

    showSnackbar(withMessage: String.triggersDisabledMessage,
                 category: snackbarCategoryTriggersDisabled,
                 actionTitle: String.triggersDisabledActionTitle,
                 actionHandler: {
      self.showTriggerListViewController(for: sensor)
    })
  }

  // MARK: - ImageSelectorDelegate

  func imageSelectorDidCreateImageData(_ imageDatas: [ImageData]) {
    createPictureNotes(from: imageDatas)
  }

  func imageSelectorDidCancel() {}

  // MARK: - ExperimentUpdateListener

  func experimentUpdateTrialNoteAdded(_ note: Note, toTrial trial: Trial) {
    if let displayNote = experimentDataParser.parseNote(note) {
      observeViewController.addNoteToCharts(displayNote)
    }
    updateTrial(trial)
  }

  func experimentUpdateExperimentNoteAdded(_ note: Note,
                                           toExperiment experiment: Experiment) {
    addExperimentNote(note)
  }

  func experimentUpdateExperimentNoteDeleted(_ note: Note,
                                             experiment: Experiment,
                                             undoBlock: @escaping () -> Void) {
    removeNote(note)
    updateEmptyView(animated: true)

    var didUndo = false
    showUndoSnackbar(
        withMessage: String.snackbarNoteDeleted,
        category: snackbarCategoryNoteDeleted,
        undoBlock: {
          didUndo = true
          undoBlock()
    },
        completion: { (_) in
          if !didUndo, let pictureNote = note as? PictureNote {
            self.delegate?.experimentViewControllerDeletePictureNoteCompleted(
                pictureNote, forExperiment: experiment)
          }
    })
  }

  func experimentUpdateTrialNoteDeleted(_ note: Note,
                                        trial: Trial,
                                        experiment: Experiment,
                                        undoBlock: @escaping () -> Void) {
    updateTrial(trial)
  }

  func experimentUpdateNoteUpdated(_ note: Note, trial: Trial?, experiment: Experiment) {
    if let trial = trial {
      updateTrial(trial)
    } else {
      updateNote(note)
    }
  }

  func experimentUpdateTrialUpdated(_ trial: Trial, experiment: Experiment, updatedStats: Bool) {
    updateTrial(trial)
  }

  func experimentUpdateTrialAdded(_ trial: Trial,
                                  toExperiment experiment: Experiment,
                                  recording isRecording: Bool) {
    if isRecording {
      addRecordingTrial(trial)
    } else if !trial.isArchived || preferenceManager.shouldShowArchivedRecordings {
      addTrial(trial, sorted: true)
    }
    updateEmptyView(animated: true)
  }

  func experimentUpdateTrialDeleted(_ trial: Trial,
                                    fromExperiment experiment: Experiment,
                                    undoBlock: (() -> Void)?) {
    removeTrial(trial)
    updateEmptyView(animated: true)

    guard let undoBlock = undoBlock else {
      // If the snackbar is not showing, delete the associated sensor data.
      self.delegate?.experimentViewControllerDeleteTrialCompleted(trial, fromExperiment: experiment)
      return
    }

    var didUndo = false
    showUndoSnackbar(withMessage: String.deletedRecordingMessage,
                     category: snackbarCategoryDeletedRecording,
                     undoBlock: {
      didUndo = true
      undoBlock()
    }, completion: { (_) in
      // When the snackbar is finished showing, if undo was not performed, delete the associated
      // sensor data.
      if !didUndo {
        self.delegate?.experimentViewControllerDeleteTrialCompleted(trial,
                                                                    fromExperiment: experiment)
      }
    })
  }

  func experimentUpdateTrialArchiveStateChanged(_ trial: Trial,
                                                experiment: Experiment,
                                                undoBlock: @escaping () -> Void) {
    updateTrial(trial)
    if trial.isArchived {
      // Only offer undo if the trial was archived.
      showUndoSnackbar(withMessage: String.archivedRunMessage,
                       category: snackbarCategoryTrialArchivedState,
                       undoBlock: undoBlock)
    } else {
      // If the user is unarchiving, hide any archived state undo snackbars.
      MDCSnackbarManager.dismissAndCallCompletionBlocks(
          withCategory: snackbarCategoryTrialArchivedState)
    }
  }

  // MARK: - ExperimentStateListener

  func experimentStateArchiveStateChanged(forExperiment experiment: Experiment,
                                          overview: ExperimentOverview,
                                          undoBlock: @escaping () -> Void) {
    if metadataManager.isExperimentArchived(withID: experiment.ID) {
      observeViewController.removeAllSensorListeners()

      experimentInteractionOptions = .archived
      experimentItemsViewController.experimentInteractionOptions = experimentInteractionOptions
      experimentItemsViewController.shouldShowArchivedFlag = true

      // If the user just archived, show an undo snackbar.
      showUndoSnackbar(withMessage: String.archivedExperimentMessage,
                       category: self.snackbarCategoryExperimentArchivedState,
                       undoBlock: undoBlock)
    } else {
      // If the user is unarchiving, hide any archived state undo snackbars.
      MDCSnackbarManager.dismissAndCallCompletionBlocks(
        withCategory: self.snackbarCategoryExperimentArchivedState)

      observeViewController.addListenersForAllSensorCards()

      experimentInteractionOptions = .normal
      experimentItemsViewController.experimentInteractionOptions = experimentInteractionOptions
      experimentItemsViewController.shouldShowArchivedFlag = false
    }

    updateDrawerForExperimentInteractionOptions()
    updateEmptyViewArchivedFlag()
  }

  func experimentStateDeleted(_ deletedExperiment: DeletedExperiment, undoBlock: (() -> Void)?) {}
  func experimentStateRestored(_ experiment: Experiment, overview: ExperimentOverview) {}

  // MARK: - NotesViewControllerDelegate

  func notesViewController(_ notesViewController: NotesViewController,
                           didCreateTextForNote text: String) {
    let textNote = TextNote(text: text)
    addNoteToExperimentOrTrial(textNote)

    // TODO: Consider AA-specific API.
    if FeatureFlags.isActionAreaEnabled {
      notesViewController.navigationController?.popViewController(animated: true)
    }
  }

  // MARK: - TriggerListDelegate

  func triggerListViewController(_ triggerListViewController: TriggerListViewController,
                                 didUpdateTriggers sensorTriggers: [SensorTrigger],
                                 withActiveTriggerIDs activeTriggerIDs: [String],
                                 forSensor sensor: Sensor) {
    guard let sensorLayout = experiment.sensorLayoutForSensorID(sensor.sensorId) else { return }

    // Update sensor triggers.
    let updatedTriggerIds = sensorTriggers.map { $0.triggerID }
    let triggersForSensor = experiment.sensorTriggers.filter { $0.sensorID == sensor.sensorId }
    // If the updated trigger IDs do not contain the trigger's ID, remove it from the experiment.
    for trigger in triggersForSensor {
      if !updatedTriggerIds.contains(trigger.triggerID) {
        guard let index = experiment.sensorTriggers.firstIndex(where: {
          $0.triggerID == trigger.triggerID
        }) else { continue }
        experiment.sensorTriggers.remove(at: index)
      }
    }

    let experimentTriggerIDs = triggersForSensor.map { $0.triggerID }
    for trigger in sensorTriggers {
      if !experimentTriggerIDs.contains(trigger.triggerID) {
        // If the updated trigger contains a trigger ID not in the experiment's triggers, add it to
        // the experiment.
        experiment.sensorTriggers.append(trigger)
      } else {
        // If the experiment triggers contains the updated trigger, replace it.
        guard let index = experiment.sensorTriggers.firstIndex(where: {
            $0.triggerID == trigger.triggerID
        }) else { continue }
        experiment.sensorTriggers[index] = trigger
      }
    }

    // Update active sensor trigger IDs in the layout.
    sensorLayout.activeSensorTriggerIDs = activeTriggerIDs

    // Save the experiment.
    metadataManager.saveExperimentWithoutDateOrDirtyChange(experiment)

    // Update observe.
    updateObserveWithExperimentTriggers()
  }

  // MARK: - SensorSettingsDelegate

  func sensorSettingsViewController(_ sensorSettingsViewController: SensorSettingsViewController,
                                    didRequestCloseWithEnabledSensors enabledSensorIDs: [String]) {
    dismiss(animated: true) {
      guard !RecordingState.isRecording else {
        // Sensors should not be enabled or disabled during a recording.
        showSnackbar(withMessage: String.sensorSettingsCouldNotUpdateWhileRecording,
                     category: self.snackbarCategoryCouldNotUpdateSensorSettings)
        return
      }

      var availableSensors = [SensorEntry]()
      for sensorID in enabledSensorIDs {
        if let sensor = self.sensorController.sensor(for: sensorID) {
          availableSensors.append(SensorEntry(sensor: sensor))
        }
      }
      self.experiment.availableSensors = availableSensors
      self.metadataManager.saveExperimentWithoutDateOrDirtyChange(self.experiment)
      self.updateObserveWithAvailableSensors()
    }
  }

  // MARK: - UIGestureRecognizerDelegate

  override func interactivePopGestureShouldBegin() -> Bool {
    guard !RecordingState.isRecording else { return false }

    guard experiment.title == nil else {
      prepareToCloseObserve()
      return true
    }

    promptForTitleIfNecessary()
    return false
  }

  // MARK: - CameraImageProviderDelegate

  func cameraImageProviderDidComplete() {
    dismiss(animated: true, completion: nil)
  }

  func cameraImageProviderDidPick(imageData: Data, metadata: NSDictionary?) {
    createPictureNotes(from: [ImageData(imageData: imageData, metadata: metadata)])
    dismiss(animated: true, completion: nil)
  }

  // MARK: - Private

  private func updateEmptyView(animated: Bool) {
    updateEmptyViewArchivedFlag()
    UIView.animate(withDuration: animated ? 0.5 : 0) {
      self.emptyView.alpha = self.experimentItemsViewController.isEmpty ? 1 : 0
    }
  }

  private func updateEmptyViewArchivedFlag() {
    let isExperimentArchived = metadataManager.isExperimentArchived(withID: experiment.ID)
    emptyView.archivedFlag.isHidden = !isExperimentArchived
  }

  private func updateForRecording() {
    if let presentedViewController = presentedViewController as? PopUpMenuViewController {
      // If there's a popup menu presented, dismiss it first.
      presentedViewController.dismiss(animated: true)
    }

    let isRecording = RecordingState.isRecording
    navigationItem.leftBarButtonItem = isRecording ? nil : backMenuItem
    editBarButton.isEnabled = !isRecording
    menuBarButton.isEnabled = !isRecording

    func updateAppBarBackgroundColor() {
      if isRecording {
        appBar.headerViewController.headerView.backgroundColor =
          .trialHeaderRecordingBackgroundColor
      } else {
        appBar.headerViewController.headerView.backgroundColor = .appBarDefaultBackgroundColor
      }
    }

    if let transitionCoordinator = transitionCoordinator {
      transitionCoordinator.animateAlongsideTransition(in: view, animation: { _ in
        updateAppBarBackgroundColor()
      })
    } else {
      updateAppBarBackgroundColor()
    }

    let isCameraAllowed = CaptureSessionInterruptionObserver.shared.isCameraUseAllowed
    // Update the camera tab icon.
    drawerVC?.isCameraItemEnabled = isCameraAllowed
    if drawerVC?.currentViewController is CameraViewController {
      // Update the camera disabled view and start the capture session if the camera is currently
      // visible.
      drawerVC?.cameraViewController.photoCapturer.startCaptureSessionIfNecessary()
      drawerVC?.cameraViewController.updateDisabledView(forCameraUseAllowed: isCameraAllowed)
    }
    // Update the recording progress bar.
    if isRecording {
      drawerVC?.drawerView.recordingBar.startAnimating()
    } else {
      drawerVC?.drawerView.recordingBar.stopAnimating()
    }
  }

  /// Sets the collection view content inset for the drawer height.
  ///
  /// - Parameter onlyIfViewIsVisible: Whether or not to only set the collection view inset if the
  ///             view is visible.
  private func setCollectionViewInset(onlyIfViewIsVisible: Bool = false) {
    guard !onlyIfViewIsVisible || experimentItemsViewController.isViewVisible else {
      // Calling this method while the experiment items collecion view is not visible can cause an
      // incorrect layout. It will be called again in viewWillAppear if the view is not currently
      // visible.
      return
    }

    var bottomInset = MDCKeyboardWatcher.shared().visibleKeyboardHeight
    var rightInset: CGFloat = 0
    if experimentInteractionOptions.shouldShowDrawer, let drawerVC = drawerVC {
      if drawerVC.isDisplayedAsSidebar {
        rightInset = ViewConstants.iPadDrawerSidebarWidth
      } else {
        bottomInset = drawerVC.drawerView.visibleHeight
      }
    }
    experimentItemsViewController.setCollectionViewInsets(bottom: bottomInset,
                                                          right: rightInset)
  }

  // If a trial is recording, adds the note to the trial, otherwise adds it to the experiment.
  func addNoteToExperimentOrTrial(_ note: Note) {
    itemDelegate?.detailViewControllerDidAddNote(note,
        forTrialID: observeViewController.recordingTrial?.ID)
    var destination: String
    if observeViewController.recordingTrial != nil {
      destination = String.toRunContentDescription
    } else {
      destination = String.toExperimentContentDescription
    }

    var announcementMessage: String
    switch note {
    case is TextNote: announcementMessage = String.textNoteAddedContentDescription
    case is PictureNote: announcementMessage = String.pictureNoteAddedContentDescription
    case is SnapshotNote: announcementMessage = String.snapshotNoteAddedContentDescription
    case is TriggerNote: announcementMessage = String.triggerNoteAddedContentDescription
    default: announcementMessage = String.noteAddedContentDescription
    }
    UIAccessibility.post(notification: .announcement,
                         argument: "\(announcementMessage) \(destination)")
  }

  private func promptForTitleIfNecessary() {
    // If we aren't requiring an experiment to have a title, we're done.
    guard requireExperimentTitle == true else {
      dismissViewController()
      return
    }

    // If a user has set a title before, we're done.
    guard experiment.title == nil else {
      dismissViewController()
      return
    }

    // If the experiment is empty, delete it without prompting instead of forcing the user to rename
    // it and keeping it around.
    if experiment.isEmpty {
      prepareToCloseObserve()
      delegate?.experimentViewControllerDidRequestDeleteExperiment(experiment)
      return
    }

    let dialogController = MDCDialogTransitionController()
    let dialog = RenameExperimentViewController(analyticsReporter: analyticsReporter)
    dialog.textField.text = String.localizedUntitledExperiment
    dialog.textField.placeholder = String.experimentTitleHint
    dialog.okayButton.addTarget(self,
                                action: #selector(renameExperimentOkayButtonPressed),
                                for: .touchUpInside)
    dialog.modalPresentationStyle = .custom
    dialog.transitioningDelegate = dialogController
    dialog.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
    present(dialog, animated: true)
    renameDialog = dialog
    dialogTransitionController = dialogController
  }

  private func dismissViewController() {
    prepareToCloseObserve()
    navigationController?.popViewController(animated: true)
  }

  // Sets observe's triggers from the experiment.
  private func updateObserveWithExperimentTriggers() {
    observeViewController.sensorTriggers = experiment.sensorTriggers
  }

  // Sets observe's available sensors from the experiment.
  private func updateObserveWithAvailableSensors() {
    guard !experiment.availableSensors.isEmpty else {
      // Reset the available sensors to empty, since the drawer is re-used across experiments.
      observeViewController.setAvailableSensorIDs([],
          andAddListeners: experimentInteractionOptions.shouldShowDrawer)
      return
    }

    // If no internal supported sensors are in the available sensors, make all sensors available by
    // setting the available sensors array to empty.
    let supportedInternalSensorIDs =
        sensorController.supportedInternalSensors.map { $0.sensorId }
    let supportedAvailableInternalSensorIDs =
        supportedInternalSensorIDs.filter { experiment.availableSensorIDs.contains($0) }
    if supportedAvailableInternalSensorIDs.isEmpty {
      experiment.availableSensors = []
    }
    observeViewController.setAvailableSensorIDs(experiment.availableSensorIDs,
        andAddListeners: experimentInteractionOptions.shouldShowDrawer)
  }

  private func prepareToCloseObserve() {
    observeViewController.updateSensorLayouts()
  }

  private func updateHeaderColor(animated: Bool = true) {
    let isDark = drawerVC?.isOpenFull ?? false
    UIView.animate(withDuration: animated ? 0.2 : 0) {
      if let drawerVC = self.drawerVC, drawerVC.isDisplayedAsSidebar ||
          !self.experimentInteractionOptions.shouldShowDrawer {
        self.appBar.headerViewController.headerView.backgroundColor = .appBarDefaultBackgroundColor
      } else {
        self.appBar.headerViewController.headerView.backgroundColor = isDark ?
            DrawerView.barBackgroundColor : .appBarDefaultBackgroundColor
      }
    }
  }

  private func updateConstraints(forDisplayType displayType: DisplayType,
                                 withSize size: CGSize) {
    drawerVC?.drawerView.setAvailableHeight(size.height - statusBarHeight)
    drawerViewTopConstraint?.constant = statusBarHeight
    drawerViewLeadingConstraint?.isActive = false
    drawerViewWidthConstraintSideBySide?.isActive = false

    let showAsSidebar = drawerVC != nil && experimentInteractionOptions.shouldShowDrawer &&
        displayType == .regularWide
    drawerViewLeadingConstraint?.isActive = !showAsSidebar
    drawerViewWidthConstraintSideBySide?.isActive = showAsSidebar
    emptyViewTrailingConstraint?.constant =
        showAsSidebar ? -ViewConstants.iPadDrawerSidebarWidth : 0
    drawerVC?.isDisplayedAsSidebar = showAsSidebar
    drawerVC?.cameraViewController.fullscreenButton.isHidden = showAsSidebar

    setCollectionViewInset(onlyIfViewIsVisible: true)
  }

  /// Updates the right bar button items for the display type. Exposed for testing.
  ///
  /// Parameter displayType: The display type of the view.
  func updateRightBarButtonItems(for displayType: DisplayType) {
    let showAsSidebar = drawerVC != nil && experimentInteractionOptions.shouldShowDrawer &&
        displayType == .regularWide

    var buttons = [UIBarButtonItem]()
    if showAsSidebar {
      buttons.append(fixedSpaceBarItem)
    }
    buttons.append(menuBarButton)
    if experimentInteractionOptions.shouldAllowEdits {
      buttons.append(editBarButton)
    }
    navigationItem.rightBarButtonItems = buttons
  }

  private func updateDrawerPosition(for displayType: DisplayType, size: CGSize) {
    // Don't change drawer positions if it is not visible. Doing so can cause the keyboard to show
    // on iPad when the drawer is in landscape and notes is the selected item.
    guard let drawerVC = drawerVC,
        !drawerVC.drawerView.isHidden && drawerVC.drawerView.alpha == 1 else { return }

    switch displayType {
    case .compact, .compactWide:
      if size.isWiderThanTall && !drawerVC.isPeeking {
        // Open the drawer to full, as long as it wasn't peeking. Otherwise, pan to the current
        // position to retain the correct layout.
        drawerVC.setPositionToFull(animated: false)
      } else {
        drawerVC.drawerView.panToCurrentPosition(animated: false)
      }
    case .regular:
      drawerVC.setPositionToHalf(animated: false)
    case .regularWide:
      drawerVC.setPositionToFull(animated: false)
    }
  }

  /// Updates the drawer for the experiment interaction options. Exposed for testing.
  ///
  /// Parameter animated: Whether to animate the change.
  func updateDrawerForExperimentInteractionOptions(animated: Bool = true) {
    if experimentInteractionOptions.shouldShowDrawer {
      let showAsSidebar = displayType == .regularWide
      if showAsSidebar {
        drawerVC?.setPositionToFull(animated: false)
      } else if experimentItemsViewController.isEmpty {
        // If there is no content, display drawer at half height.
        drawerVC?.setPositionToHalf(animated: false)
      } else {
        // Hide the drawer by default.
        drawerVC?.setPositionToPeeking(animated: false)
      }
    } else {
      drawerVC?.drawerView.endEditing(true)
    }

    let duration = animated ? 0.3 : 0
    UIView.animate(withDuration: duration, animations: {
      self.drawerVC?.drawerView.alpha = !self.experimentInteractionOptions.shouldShowDrawer ? 0 : 1
      self.setCollectionViewInset(onlyIfViewIsVisible: true)
      self.updateConstraints(forDisplayType: self.displayType, withSize: self.view.bounds.size)
      self.view.layoutIfNeeded()
    }) { (_) in
      if !self.experimentInteractionOptions.shouldShowDrawer {
        self.drawerVC?.setPositionToPeeking(animated: false)
      }
    }

    updateRightBarButtonItems(for: displayType)
  }

  private func showTriggerListViewController(for sensor: Sensor) {
    guard let sensorLayout = experiment.sensorLayoutForSensorID(sensor.sensorId) else { return }
    let triggerListViewController =
        TriggerListViewController(sensorTriggers: experiment.triggersForSensor(sensor),
                                  activeTriggerIDs: sensorLayout.activeSensorTriggerIDs,
                                  sensor: sensor,
                                  delegate: self,
                                  analyticsReporter: analyticsReporter)
    let navigationController = UINavigationController(rootViewController: triggerListViewController)
    if UIDevice.current.userInterfaceIdiom == .pad {
      navigationController.modalPresentationStyle = .formSheet
    }
    present(navigationController, animated: true)
  }

  private func updateEmptyViewArchivedFlagInsets() {
    emptyView.archivedFlagInsets = experimentItemsViewController.cellInsets
  }

  private func reloadExperimentItems() {
    if let recordingTrial = observeViewController.recordingTrial {
      addRecordingTrial(recordingTrial)
    }
    experimentItemsViewController.setExperimentItems(parseExperimentItems())
  }

  /// Parses the experiment into a sorted array of display items.
  ///
  /// - Returns: A sorted array of display items (trials and notes).
  private func parseExperimentItems() -> [DisplayItem] {
    let includeArchivedRecordings = preferenceManager.shouldShowArchivedRecordings
    let trialsToInclude = experiment.trials.filter { !$0.isArchived || includeArchivedRecordings }
    var displayTrials = experimentDataParser.parsedTrials(
      trialsToInclude,
      maxNotes: experimentDisplay.maxDisplayNotes)

    // The recording trial will be handled separately, so remove it if there is one.
    let recordingTrial = observeViewController.recordingTrial
    if let recordingIndex = displayTrials.firstIndex(where: { $0.ID == recordingTrial?.ID }) {
      displayTrials.remove(at: recordingIndex)
    }

    for (trialIndex, displayTrial) in displayTrials.enumerated() {
      for (sensorIndex, var displaySensor) in displayTrial.sensors.enumerated() {
        displaySensor.chartPresentationView = chartViewForSensor(displaySensor, trial: displayTrial)
        displayTrials[trialIndex].sensors[sensorIndex] = displaySensor
      }
    }
    var items: [DisplayItem] = displayTrials as [DisplayItem]

    items += experimentDataParser.parseNotes(experiment.notes) as [DisplayItem]
    items.sort { (data1, data2) -> Bool in
      // Sort oldest to newest.
      return data1.timestamp.milliseconds < data2.timestamp.milliseconds
    }

    // If there are no trials (and thus charts), we're ready for export, otherwise this ready block
    // will be called when the charts load asynchronously.
    if displayTrials.isEmpty {
      readyForPDFExport?()
    }

    return items
  }

  // Returns a chart view and adds its controller to the chart controllers array.
  private func chartViewForSensor(_ sensor: DisplaySensor,
                                  trial: DisplayTrial) -> UIView {
    let chartController: ChartController
    let wrapperView: UIView
    let trialSensorKey = trial.ID + sensor.ID

    switch experimentDisplay {
    case .normal, .recording:
      chartController = ChartController(placementType: .previewReview,
                                        colorPalette: sensor.colorPalette,
                                        trialID: trial.ID,
                                        sensorID: sensor.ID,
                                        sensorStats: sensor.stats,
                                        cropRange: trial.cropRange,
                                        notes: trial.notes,
                                        sensorDataManager: sensorDataManager)
      wrapperView = chartController.chartView
    case .pdfExport:
      let chartLoaded: ChartExportViewController.ChartLoadedBlock = {
        self.chartExportViewControllersLoaded += 1

        if self.chartExportViewControllersLoaded == self.chartExportViewControllers.count {
          self.readyForPDFExport?()
        }
      }
      let chartExportVC = ChartExportViewController(trialID: trial.ID,
                                                    sensorID: sensor.ID,
                                                    sensorStats: sensor.stats,
                                                    cropRange: trial.cropRange,
                                                    notes: trial.notes,
                                                    colorPalette: sensor.colorPalette,
                                                    sensorDataManager: sensorDataManager,
                                                    chartLoaded: chartLoaded)
      chartController = chartExportVC.chartController
      wrapperView = chartExportVC.view
      chartExportViewControllers[trialSensorKey] = chartExportVC
    }
    chartControllers[trialSensorKey] = chartController
    return wrapperView
  }

  /// Updates the title in the nav bar based on the current experiment.
  private func updateExperimentTitle() {
    title = experiment.title ?? String.localizedUntitledExperiment
  }

  private func createPictureNotes(from imageSet: [(imageData: Data, metadata: NSDictionary?)]) {
    do {
      // If any of the images fail to save, we'll throw an error
      // instead of adding the note to the experiment or trial.
      let pictureNotes: [PictureNote] = try imageSet.map { imageData, metadata in
        let pictureNote = PictureNote()
        let pictureFilePath = metadataManager.relativePicturePath(for: pictureNote.ID)
        try metadataManager.saveImageData(imageData,
                                          atPicturePath: pictureFilePath,
                                          experimentID: experiment.ID,
                                          withMetadata: metadata)
        pictureNote.filePath = pictureFilePath
        return pictureNote
      }
      pictureNotes.forEach { addNoteToExperimentOrTrial($0) }

      // TODO: Consider AA-specific API.
      if FeatureFlags.isActionAreaEnabled {
        photoLibraryViewController.navigationController?.popViewController(animated: true)
      }
    } catch MetadataManagerError.photoDiskSpaceError {
      showSnackbar(withMessage: String.photoDiskSpaceErrorMessage)
    } catch {
      sjlog_error("Unknown error saving picture note image: \(error)", category: .general)
    }
  }

  // MARK: - Experiment Updates

  private func createDisplayTrial(fromTrial trial: Trial, isRecording: Bool) -> DisplayTrial {
    let maxNotes: Int? = isRecording ? ExperimentDisplay.recording.maxDisplayNotes :
        ExperimentDisplay.normal.maxDisplayNotes
    var displayTrial =
        experimentDataParser.parseTrial(trial,
                                        maxNotes: maxNotes,
                                        isRecording: isRecording)

    // Update the chart controller.
    for (index, var displaySensor) in displayTrial.sensors.enumerated() {
      displaySensor.chartPresentationView = chartViewForSensor(displaySensor, trial: displayTrial)
      displayTrial.sensors[index] = displaySensor
    }
    return displayTrial
  }

  private func addRecordingTrial(_ trial: Trial) {
    let displayTrial = createDisplayTrial(fromTrial: trial, isRecording: true)
    experimentItemsViewController.addOrUpdateRecordingTrial(displayTrial)
  }

  /// Updates a trial.
  ///
  /// - Parameters:
  ///   - trial: The trial to update.
  ///   - didFinishRecording: True if the trial finished recording, and should be updated from a
  ///                         recording trial to a recorded trial.
  private func updateTrial(_ trial: Trial, didFinishRecording: Bool = false) {
    // If trial is archived, remove it if necessary.
    if trial.isArchived && !preferenceManager.shouldShowArchivedRecordings {
      experimentItemsViewController.removeTrial(withID: trial.ID)
    } else {
      // If trial is not archived, add or update it.
      let isRecording = observeViewController.recordingTrial?.ID == trial.ID
      let displayTrial = self.createDisplayTrial(fromTrial: trial, isRecording: isRecording)
      if isRecording {
        experimentItemsViewController.addOrUpdateRecordingTrial(displayTrial)
      } else {
        experimentItemsViewController.addOrUpdateTrial(displayTrial,
                                                       didFinishRecording: didFinishRecording)
      }
    }
    updateEmptyView(animated: true)
  }

  private func addTrial(_ trial: Trial, sorted isSorted: Bool) {
    let displayTrial = self.createDisplayTrial(fromTrial: trial, isRecording: false)
    experimentItemsViewController.addItem(displayTrial, sorted: isSorted)
  }

  @discardableResult private func removeTrial(_ trial: Trial) -> Int? {
    return experimentItemsViewController.removeTrial(withID: trial.ID)
  }

  private func removeRecordingTrial() {
    return experimentItemsViewController.removeRecordingTrial()
  }

  private func updateNote(_ note: Note) {
    guard let displayNote = experimentDataParser.parseNote(note) else {
      return
    }
    experimentItemsViewController.updateNote(displayNote)
  }

  private func addExperimentNote(_ note: Note) {
    guard let displayNote = experimentDataParser.parseNote(note) else {
      return
    }
    experimentItemsViewController.addItem(displayNote, sorted: true)
    updateEmptyView(animated: true)
  }

  private func removeNote(_ note: Note) {
    experimentItemsViewController.removeNote(withNoteID: note.ID)
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    promptForTitleIfNecessary()
  }

  @objc private func menuButtonPressed() {
    view.endEditing(true)

    let popUpMenu = PopUpMenuViewController()

    // Remove the cover image if one exists, and this is allowed.
    if experimentInteractionOptions.shouldAllowCoverRemoval &&
        metadataManager.imagePathForExperiment(experiment) != nil {
      popUpMenu.addAction(PopUpMenuAction(
          title: String.removeCoverImage,
          accessibilityLabel: String.removeCoverImageContentDescription) { _ -> Void in
        let alertController = MDCAlertController(title: nil,
                                                 message: String.removeCoverImageMessage)
        let cancelAction = MDCAlertAction(title: String.btnDeleteObjectCancel)
        let deleteAction = MDCAlertAction(title: String.btnDeleteObjectConfirm) { (_) in
          var snackbarMessage = String.removeCoverImageFailed
          if (self.delegate?.experimentViewControllerRemoveCoverImageForExperiment(
              self.experiment))! {
            snackbarMessage = String.removeCoverImageSuccessful
          }
          showSnackbar(withMessage: snackbarMessage)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true)
      })
    }

    // Show archived recordings?
    let archivedRecordingsIconName = preferenceManager.shouldShowArchivedRecordings ?
        "ic_check_box" : "ic_check_box_outline_blank"
    popUpMenu.addAction(PopUpMenuAction(
        title: String.includeArchivedTrials,
        icon: UIImage(named: archivedRecordingsIconName)) { _ -> Void in
      self.preferenceManager.shouldShowArchivedRecordings =
          !self.preferenceManager.shouldShowArchivedRecordings
      self.reloadExperimentItems()
      self.updateEmptyView(animated: true)
    })

    // Archive experiment.
    func showArchiveAction() {
      let isExperimentArchived = metadataManager.isExperimentArchived(withID: experiment.ID)
      let archiveTitle = isExperimentArchived ? String.actionUnarchive : String.actionArchive
      let archiveAccessibilityLabel = isExperimentArchived ?
          String.actionUnarchiveExperimentContentDescription :
          String.actionArchiveExperimentContentDescription
      let iconName = isExperimentArchived ? "ic_unarchive" : "ic_archive"
      popUpMenu.addAction(PopUpMenuAction(
          title: archiveTitle,
          icon: UIImage(named: iconName),
          accessibilityLabel: archiveAccessibilityLabel) { _ -> Void in
        if RecordingState.isRecording {
          self.observeViewController.endRecording(isCancelled: true)
        }
        self.observeViewController.removeAllSensorListeners()
        self.delegate?.experimentViewControllerToggleArchiveStateForExperiment(
            withID: self.experiment.ID)
      })
    }

    if experimentInteractionOptions.shouldAllowEdits {
      showArchiveAction()
    }

    // Export
    if !RecordingState.isRecording && !experiment.isEmpty {
      if let action = delegate?.experimentViewControllerExportFlowAction(
        for: experiment,
        from: self,
        sourceView: menuBarButton.button) {
        popUpMenu.addAction(action)
      }
    }

    // Delete.
    popUpMenu.addAction(PopUpMenuAction(
        title: String.actionDelete,
        icon: UIImage(named: "ic_delete"),
        accessibilityLabel: String.actionDeleteExperimentContentDescription) { _ -> Void in
      // Prompt the user to confirm deletion.
      let alertController = MDCAlertController(title: String.deleteExperimentDialogTitle,
                                               message: String.deleteExperimentDialogMessage)
      let cancelAction = MDCAlertAction(title: String.btnDeleteObjectCancel)
      let deleteAction = MDCAlertAction(title: String.btnDeleteObjectConfirm) { (_) in
        if RecordingState.isRecording {
          self.observeViewController.endRecording()
        }
        self.observeViewController.removeAllSensorListeners()
        self.delegate?.experimentViewControllerDidRequestDeleteExperiment(self.experiment)
      }
      alertController.addAction(cancelAction)
      alertController.addAction(deleteAction)
      alertController.accessibilityViewIsModal = true
      self.present(alertController, animated: true)
    })

    popUpMenu.present(from: self, position: .sourceView(menuBarButton.button))
  }

  @objc private func editButtonPressed() {
    view.endEditing(true)

    let vc = EditExperimentViewController(experiment: experiment,
                                          analyticsReporter: analyticsReporter,
                                          metadataManager: metadataManager)
    vc.delegate = self
    if UIDevice.current.userInterfaceIdiom == .pad {
      vc.modalPresentationStyle = .formSheet
    }
    present(vc, animated: true)
  }

  @objc private func renameExperimentOkayButtonPressed() {
    guard let dialog = renameDialog else { return }
    var newTitle = dialog.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    newTitle = newTitle == nil || newTitle == "" ? String.localizedUntitledExperiment : newTitle
    delegate?.experimentViewControllerDidSetTitle(newTitle, forExperiment: experiment)
    dialog.dismiss(animated: true) {
      self.dismissViewController()
    }
    renameDialog = nil
    dialogTransitionController = nil
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

  // MARK: - Notifications

  @objc func handleKeyboardNotification(_ notification: Notification) {
    setCollectionViewInset(onlyIfViewIsVisible: true)
  }

  @objc private func handleTrialStatsDidCompleteNotification(notification: Notification) {
    guard let trialID =
        notification.userInfo?[SensorDataManager.TrialStatsDidCompleteTrialIDKey] as? String,
        let trial = experiment.trial(withID: trialID) else {
      return
    }
    updateTrial(trial)
  }

}

extension ExperimentCoordinatorViewController: PDFExportable {

  var scrollView: UIScrollView {
    return experimentItemsViewController.collectionView
  }

}

// swiftlint:enable file_length, type_body_length
