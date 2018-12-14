/*
 *  Copyright 2019 Google Inc. All Rights Reserved.
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

import UIKit

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

protocol ExperimentItemsViewControllerDelegate: class {
  func experimentItemsViewControllerDidSelectItem(_ displayItem: DisplayItem)
  func experimentItemsViewControllerCommentPressedForItem(_ displayItem: DisplayItem)
  func experimentItemsViewControllerMenuPressedForItem(_ displayItem: DisplayItem,
                                                       button: MenuButton)
}

/// A view controller that displays experiment items in a list.
class ExperimentItemsViewController: VisibilityTrackingViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    ExperimentItemsDataSourceDelegate,
    ExperimentCardCellDelegate {

  // MARK: - Properties

  let archivedFlagCellIdentifier = "ArchivedFlagCell"
  let textNoteCardCellIdentifier = "TextNoteCardCell"
  let pictureCardCellIdentifier = "PictureCardCell"
  let snapshotCardCellIdentifier = "SnapshotCardCell"
  let trialCardCellIdentifier = "TrialCardCell"
  let triggerCardCellIdentifier = "TriggerCardCell"
  let defaultCellIdentifier = "DefaultCell"

  private(set) var collectionView: UICollectionView
  private let experimentDataSource: ExperimentItemsDataSource!

  weak var delegate: ExperimentItemsViewControllerDelegate?

  /// The scroll delegate will recieve a subset of scroll delegate calls (didScroll,
  /// didEndDecelerating, didEndDragging, willEndDragging).
  weak var scrollDelegate: UIScrollViewDelegate?

  /// The experiment's interaction options.
  var experimentInteractionOptions: ExperimentInteractionOptions

  /// Whether to show the archived flag.
  var shouldShowArchivedFlag: Bool {
    set {
      experimentDataSource.shouldShowArchivedFlag = newValue
    }
    get {
      return experimentDataSource.shouldShowArchivedFlag
    }
  }

  /// The scroll position to use when adding items. This is changed when adding content to a trial
  /// while recording but should be replaced by logic that can scroll to a view within a trial cell.
  var collectionViewChangeScrollPosition = UICollectionView.ScrollPosition.top

  /// Returns the insets for experiment cells.
  var cellInsets: UIEdgeInsets {
    var insets: UIEdgeInsets {
      switch displayType {
      case .compact, .compactWide:
        return MaterialCardCell.cardInsets
      case .regular:
        return UIEdgeInsets(top: MaterialCardCell.cardInsets.top,
                            left: 150,
                            bottom: MaterialCardCell.cardInsets.bottom,
                            right: 150)
      case .regularWide:
        // The right side needs to compensate for the drawer sidebar when the experiment is not
        // archived.
        return UIEdgeInsets(top: MaterialCardCell.cardInsets.top,
                            left: 90,
                            bottom: MaterialCardCell.cardInsets.bottom,
                            right: 90)
      }
    }
    return UIEdgeInsets(top: insets.top,
                        left: insets.left + view.safeAreaInsetsOrZero.left,
                        bottom: insets.bottom,
                        right: insets.right + view.safeAreaInsetsOrZero.right)
  }

  /// Returns true if there are no trials or notes in the experiment, otherwise false.
  var isEmpty: Bool {
    return experimentDataSource.experimentItems.count +
        experimentDataSource.recordingTrialItemCount == 0
  }

  private let metadataManager: MetadataManager
  private let trialCardNoteViewPool = TrialCardNoteViewPool()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - experimentInteractionOptions: The experiment's interaction options.
  ///   - metadataManager: The metadata manager.
  ///   - shouldShowArchivedFlag: Whether to show the archived flag.
  init(experimentInteractionOptions: ExperimentInteractionOptions,
       metadataManager: MetadataManager,
       shouldShowArchivedFlag: Bool) {
    self.experimentInteractionOptions = experimentInteractionOptions
    experimentDataSource = ExperimentItemsDataSource(shouldShowArchivedFlag: shouldShowArchivedFlag)
    self.metadataManager = metadataManager

    let flowLayout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

    super.init(nibName: nil, bundle: nil)
    experimentDataSource.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView.register(ArchivedFlagCell.self,
                            forCellWithReuseIdentifier: archivedFlagCellIdentifier)
    collectionView.register(TextNoteCardCell.self,
                            forCellWithReuseIdentifier: textNoteCardCellIdentifier)
    collectionView.register(PictureCardCell.self,
                            forCellWithReuseIdentifier: pictureCardCellIdentifier)
    collectionView.register(SnapshotCardCell.self,
                            forCellWithReuseIdentifier: snapshotCardCellIdentifier)
    collectionView.register(TrialCardCell.self, forCellWithReuseIdentifier: trialCardCellIdentifier)
    collectionView.register(TriggerCardCell.self,
                            forCellWithReuseIdentifier: triggerCardCellIdentifier)
    collectionView.register(UICollectionViewCell.self,
                            forCellWithReuseIdentifier: defaultCellIdentifier)

    // Collection view.
    collectionView.alwaysBounceVertical = true
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = MDCPalette.grey.tint200
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    collectionView.pinToEdgesOfView(view)
  }

  /// Replaces the experiment items with new items.
  ///
  /// - Parameter items: An array of display items.
  func setExperimentItems(_ items: [DisplayItem]) {
    experimentDataSource.experimentItems = items
    collectionView.reloadData()
  }

  /// Sets the bottom and right collection view insets. Top insets are not set because they are
  /// updated automatically by the MDC app bar.
  ///
  /// - Parameters:
  ///   - bottom: The bottom inset.
  ///   - right: The right inset.
  func setCollectionViewInsets(bottom: CGFloat, right: CGFloat) {
    collectionView.contentInset.bottom = bottom
    collectionView.contentInset.right = right
    collectionView.scrollIndicatorInsets = collectionView.contentInset
    if isViewVisible {
      // Invalidating the collection view layout while the view is off screen causes the size for
      // item at method to be called too early when navigating back to this view. Being called too
      // early can result in a negative width to be calculated, which crashes the app.
      collectionView.collectionViewLayout.invalidateLayout()
    }
  }

  /// If a trial with a matching ID exists it will be updated with the given trial, otherwise the
  /// trial will be added in the proper sort order.
  ///
  /// - Parameters:
  ///   - displayTrial: A display trial.
  ///   - didFinishRecording: Whether or not this is a display trial that finished recording, and
  ///                         should be moved from the recording trial section, to a recorded trial.
  func addOrUpdateTrial(_ displayTrial: DisplayTrial, didFinishRecording: Bool) {
    if didFinishRecording {
      experimentDataSource.removeRecordingTrial()
    }
    experimentDataSource.addOrUpdateTrial(displayTrial)
  }

  /// Adds an experiment item to the end of the existing items.
  ///
  /// - Parameters:
  ///   - displayItem: A display item.
  ///   - isSorted: Whether the item should be inserted in the correct sort order or added
  ///               to the end.
  func addItem(_ displayItem: DisplayItem, sorted isSorted: Bool = false) {
    experimentDataSource.addItem(displayItem, sorted: isSorted)
  }

  /// Adds a recording trial to the data source.
  ///
  /// - Parameter recordingTrial: A recording trial.
  func addOrUpdateRecordingTrial(_ recordingTrial: DisplayTrial) {
    experimentDataSource.addOrUpdateRecordingTrial(recordingTrial)
  }

  /// Updates a matching trial with a new trial.
  ///
  /// - Parameter displayTrial: A display trial.
  func updateTrial(_ displayTrial: DisplayTrial) {
    experimentDataSource.updateTrial(displayTrial)
  }

  /// Removes the trial with a given ID.
  ///
  /// - Parameter trialID: A trial ID.
  /// - Returns: The index of the removed trial if the removal succeeded.
  @discardableResult func removeTrial(withID trialID: String) -> Int? {
    return experimentDataSource.removeTrial(withID: trialID)
  }

  /// Removes the recording trial.
  func removeRecordingTrial() {
    return experimentDataSource.removeRecordingTrial()
  }

  /// Updates a matching note with a new note.
  ///
  /// - Parameter displayNote: A display note.
  func updateNote(_ displayNote: DisplayNote) {
    experimentDataSource.updateNote(displayNote)
  }

  /// Removes the note with a given ID.
  ///
  /// - Parameter noteID: A note ID.
  func removeNote(withNoteID noteID: String) {
    experimentDataSource.removeNote(withNoteID: noteID)
  }

  // MARK: - UICollectionViewDataSource

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return experimentDataSource.numberOfSections
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return experimentDataSource.numberOfItemsInSection(section)
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.size.width - collectionView.contentInset.right -
      cellInsets.left - cellInsets.right
    var calculatedCellHeight: CGFloat

    let section = experimentDataSource.section(atIndex: indexPath.section)
    switch section {
    case .archivedFlag:
      calculatedCellHeight = ArchivedFlagCell.height
    case .experimentData, .recordingTrial:
      // The experiment's data.
      let showHeader = experimentDataSource.isExperimentDataSection(indexPath.section)
      let isRecordingTrial = experimentDataSource.isRecordingTrialSection(indexPath.section)
      guard let experimentItem =
          experimentDataSource.item(inSection: section,
                                    atIndex: indexPath.item) else { return .zero }
      switch experimentItem.itemType {
      case .textNote(let displayTextNote):
        calculatedCellHeight = TextNoteCardCell.height(inWidth: width,
                                                       textNote: displayTextNote,
                                                       showingHeader: showHeader,
                                                       showingInlineTimestamp: isRecordingTrial)
      case .snapshotNote(let displaySnapshotNote):
        calculatedCellHeight = SnapshotCardCell.height(inWidth: width,
                                                       snapshotNote: displaySnapshotNote,
                                                       showingHeader: showHeader)
      case .trial(let displayTrial):
        calculatedCellHeight = TrialCardCell.height(inWidth: width, trial: displayTrial)
      case .pictureNote(let displayPictureNote):
        let pictureStyle: PictureStyle = isRecordingTrial ? .small : .large
        calculatedCellHeight = PictureCardCell.height(inWidth: width,
                                                      pictureNote: displayPictureNote,
                                                      pictureStyle: pictureStyle,
                                                      showingHeader: showHeader)
      case .triggerNote(let displayTriggerNote):
        calculatedCellHeight = TriggerCardCell.height(inWidth: width,
                                                      triggerNote: displayTriggerNote,
                                                      showingHeader: showHeader,
                                                      showingInlineTimestamp: isRecordingTrial)
      }
      calculatedCellHeight = ceil(calculatedCellHeight)
    }

    return CGSize(width: width, height: calculatedCellHeight)
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let section = experimentDataSource.section(atIndex: indexPath.section)
    switch section {
    case .archivedFlag:
      return collectionView.dequeueReusableCell(withReuseIdentifier: archivedFlagCellIdentifier,
                                                for: indexPath)
    case .experimentData, .recordingTrial:
      let showHeader = experimentDataSource.isExperimentDataSection(indexPath.section)
      let isRecordingTrial = experimentDataSource.isRecordingTrialSection(indexPath.section)
      let displayItem = experimentDataSource.item(inSection: section, atIndex: indexPath.item)
      let showCaptionButton = experimentInteractionOptions.shouldAllowEdits

      let cell: UICollectionViewCell
      switch displayItem?.itemType {
      case .textNote(let textNote)?:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: textNoteCardCellIdentifier,
                                                  for: indexPath)
        if let cell = cell as? TextNoteCardCell {
          cell.setTextNote(textNote, showHeader: showHeader, showInlineTimestamp: isRecordingTrial)
          cell.delegate = self
        }
      case .snapshotNote(let snapshotNote)?:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: snapshotCardCellIdentifier,
                                                  for: indexPath)
        if let cell = cell as? SnapshotCardCell {
          cell.setSnapshotNote(snapshotNote,
                               showHeader: showHeader,
                               showInlineTimestamp: isRecordingTrial,
                               showCaptionButton: showCaptionButton)
          cell.delegate = self
        }
      case .trial(let trial)?:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: trialCardCellIdentifier,
                                                  for: indexPath)
        if let cell = cell as? TrialCardCell {
          // The trial card note view pool must be set before configuring the cell.
          cell.setTrialCardNoteViewPool(trialCardNoteViewPool)

          if trial.status == .recording {
            cell.configureRecordingCellWithTrial(trial, metadataManager: metadataManager)
          } else {
            cell.configureCellWithTrial(trial, metadataManager: metadataManager)
          }
          cell.delegate = self
        }
      case .pictureNote(let displayPictureNote)?:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: pictureCardCellIdentifier,
                                                  for: indexPath)
        if let cell = cell as? PictureCardCell {
          let pictureStyle: PictureStyle = isRecordingTrial ? .small : .large
          cell.setPictureNote(displayPictureNote,
                              withPictureStyle: pictureStyle,
                              metadataManager: metadataManager,
                              showHeader: showHeader,
                              showInlineTimestamp: isRecordingTrial,
                              showCaptionButton: showCaptionButton)
          cell.delegate = self
        }
      case .triggerNote(let displayTriggerNote)?:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: triggerCardCellIdentifier,
                                                  for: indexPath)
        if let cell = cell as? TriggerCardCell {
          cell.setTriggerNote(displayTriggerNote,
                              showHeader: showHeader,
                              showInlineTimestamp: isRecordingTrial,
                              showCaptionButton: showCaptionButton)
          cell.delegate = self
        }
      case .none:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: defaultCellIdentifier,
                                                  for: indexPath)
      }

      // Set the cell borders
      if isRecordingTrial, let cell = cell as? MaterialCardCell {
        let isFirstCellInRecordingSection = indexPath.item == 0
        let isLastCellInRecordingSection =
            indexPath.item == experimentDataSource.recordingTrialItemCount - 1
        if isFirstCellInRecordingSection && isLastCellInRecordingSection {
          cell.border = MaterialCardCell.Border(options: .all)
        } else if isFirstCellInRecordingSection {
          cell.border = MaterialCardCell.Border(options: .top)
        } else if isLastCellInRecordingSection {
          cell.border = MaterialCardCell.Border(options: .bottom)
        } else {
          cell.border = MaterialCardCell.Border(options: .none)
        }
      }

      return cell
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      willDisplay cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    if experimentDataSource.section(atIndex: indexPath.section) == .experimentData ||
        experimentDataSource.isRecordingTrialSection(indexPath.section) {
      // Loading picture note images on demand instead of all at once prevents crashes and reduces
      // the memory footprint.
      if let pictureNoteCell = cell as? PictureCardCell {
        pictureNoteCell.displayImage()
      } else if let trialNoteCell = cell as? TrialCardCell {
        trialNoteCell.displayImages()
      }
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      didEndDisplaying cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    if experimentDataSource.section(atIndex: indexPath.section) == .experimentData {
      if let pictureNoteCell = cell as? PictureCardCell {
        pictureNoteCell.removeImage()
      } else if let trialNoteCell = cell as? TrialCardCell {
        trialNoteCell.removeImages()
      }
    }
  }

  // MARK: - UICollectionViewDelegate

  // TODO: Investigate why this can't just be set on the flowLayout as `sectionInset`.
  // For some reason, it's not adding appropriate section insets to the top and bottom.
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    if experimentDataSource.isArchivedFlagSection(section) &&
        experimentDataSource.numberOfItemsInSection(
        experimentDataSource.archivedFlagSectionIndex) == 0 {
      return .zero
    }
    return cellInsets
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    if experimentDataSource.isRecordingTrialSection(section) {
      return 0
    }

    return MaterialCardCell.cardInsets.bottom
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let section = experimentDataSource.section(atIndex: indexPath.section)
    switch section {
    case .experimentData, .recordingTrial:
      guard let displayItem =
          experimentDataSource.item(inSection: section, atIndex: indexPath.item) else { return }
      delegate?.experimentItemsViewControllerDidSelectItem(displayItem)
    default:
      return
    }
  }

  // MARK: - ExperimentCardCellDelegate

  func experimentCardCellCommentButtonPressed(_ cell: MaterialCardCell) {
    guard let indexPath = collectionView.indexPath(for: cell) else { return }

    let section = experimentDataSource.section(atIndex: indexPath.section)
    switch section {
    case .experimentData:
      guard let displayItem = experimentDataSource.item(inSection: section,
                                                        atIndex: indexPath.item) else { return }
      delegate?.experimentItemsViewControllerCommentPressedForItem(displayItem)
    case .recordingTrial:
      return
    default:
      return
    }
  }

  func experimentCardCellMenuButtonPressed(_ cell: MaterialCardCell, button: MenuButton) {
    guard let indexPath = collectionView.indexPath(for: cell) else { return }

    let section = experimentDataSource.section(atIndex: indexPath.section)
    switch section {
    case .experimentData, .recordingTrial:
      guard let displayItem = experimentDataSource.item(inSection: section,
                                                        atIndex: indexPath.item) else { return }
      delegate?.experimentItemsViewControllerMenuPressedForItem(displayItem, button: button)
    default:
      return
    }
  }

  // Unsupported.
  func experimentCardCellTimestampButtonPressed(_ cell: MaterialCardCell) {}

    // MARK: - ExperimentItemsDataSourceDelegate

  func experimentDataSource(_ experimentDataSource: ExperimentItemsDataSource,
                            didChange changes: [CollectionViewChange],
                            scrollToIndexPath indexPath: IndexPath?) {
    guard isViewVisible else {
      collectionView.reloadData()
      return
    }

    // Perform changes.
    collectionView.performChanges(changes)

    // Scroll to index path if necessary.
    guard let indexPath = indexPath else { return }
    collectionView.scrollToItem(at: indexPath,
                                at: collectionViewChangeScrollPosition,
                                animated: true)
  }

  // MARK: - UIScrollViewDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollDelegate?.scrollViewDidScroll!(scrollView)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollDelegate?.scrollViewDidEndDecelerating!(scrollView)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                willDecelerate decelerate: Bool) {
    scrollDelegate?.scrollViewDidEndDragging!(scrollView, willDecelerate: decelerate)
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                 withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    scrollDelegate?.scrollViewWillEndDragging!(scrollView,
                                               withVelocity: velocity,
                                               targetContentOffset: targetContentOffset)
  }

}
