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

import third_party_objective_c_material_components_ios_components_Collections_Collections

/// The detail view controller of a trigger which shows a trigger note, metadata, and allows for
/// caption editing.
class TriggerDetailViewController: MaterialHeaderCollectionViewController,
                                   NoteDetailEditCaptionCellDelegate,
                                   CaptionableNoteDetailController {

  // MARK: - Nested types

  /// A data structure for trigger metadata.
  struct TriggerMetadata {
    /// The icon.
    var icon: UIImage?

    /// The title.
    var title: String

    /// The description.
    var description: String
  }

  /// The data source for the trigger.
  class TriggerDataSource {

    /// The trigger data sections.
    enum Section: Int {
      /// The trigger section.
      case trigger

      /// The caption section.
      case caption

      /// The metadata section.
      case metadata
    }

    /// The trigger's metadata.
    var metadata = [TriggerMetadata]()

    private let trigger: DisplayTriggerNote

    // One section for the trigger cell, one section for the caption, one section for the detail
    // cells (with a header).
    let numberOfSections = 3

    private let experimentInteractionOptions: ExperimentInteractionOptions

    /// Designated initializer.
    ///
    /// Parameters:
    ///  - trigger: The trigger note to display.
    ///  - experimentInteractionOptions: THe experiment interaction options.
    init(trigger: DisplayTriggerNote, experimentInteractionOptions: ExperimentInteractionOptions) {
      self.trigger = trigger
      self.experimentInteractionOptions = experimentInteractionOptions

      // Create the date metadata item for trigger.
      let date = Date(milliseconds: trigger.timestamp.milliseconds)
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MMMM d, yyyy"
      let datestamp = dateFormatter.string(from: date)
      dateFormatter.dateFormat = "EEEE h:mm a"
      let timestamp = dateFormatter.string(from: date)
      metadata.append(TriggerMetadata(icon: UIImage(named: "ic_today"),
                                      title: datestamp,
                                      description: timestamp))
    }

    /// The number of items in a section.
    ///
    /// Parameter section: The section index.
    /// Returns: The number of items in the section.
    func numberOfItemsInSection(_ section: Int) -> Int {
      guard let sectionEnum = Section(rawValue: section) else { return 0 }
      switch sectionEnum {
      case .trigger: return 1
      case .caption:
        if experimentInteractionOptions.shouldAllowEdits {
          return 1
        } else {
          return trigger.caption != nil ? 1 : 0
        }
      case .metadata: return metadata.count
      }
    }

  }

  // MARK: - Constants

  private static let innerHorizontalPadding: CGFloat = 16.0
  private static let innerVerticalPadding: CGFloat = 16.0
  private let triggerDetailCellIdentifier = "TriggerDetailCell"
  private let noteDetailEditCaptionCellIdentifier = "NoteDetailEditCaptionCell"
  private let noteMetadataDetailCellIdentifier = "NoteMetadataDetailCell"
  private let noteMetadataDetailHeaderViewIdentifier = "NoteMetadataDetailHeaderView"

  // MARK: - Properties

  private var isEditingCaption: Bool = false
  private var dataSource: TriggerDataSource
  private weak var delegate: ExperimentItemDelegate?
  private var displayTrigger: DisplayTriggerNote
  private let experimentInteractionOptions: ExperimentInteractionOptions

  private var cellHorizontalInset: CGFloat {
    var inset: CGFloat {
      switch displayType {
      case .compact, .compactWide:
        return TriggerDetailViewController.innerHorizontalPadding * 2
      case .regular:
        return ViewConstants.cellHorizontalInsetRegularDisplayType
      case .regularWide:
        return ViewConstants.cellHorizontalInsetRegularWideDisplayType
      }
    }
    return inset + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  // Should the view controller make the caption field first responder the first time it appears?
  private var shouldJumpToCaptionOnLoad: Bool

  private var captionEdgeInsets: UIEdgeInsets {
    return UIEdgeInsets(top: 0,
                        left: cellHorizontalInset / 2,
                        bottom: (TriggerDetailViewController.innerVerticalPadding * 2),
                        right: cellHorizontalInset / 2)
  }
  private var metadataEdgeInsets: UIEdgeInsets {
    return UIEdgeInsets(top: TriggerDetailViewController.innerVerticalPadding,
                        left: cellHorizontalInset / 2,
                        bottom: TriggerDetailViewController.innerVerticalPadding,
                        right: cellHorizontalInset / 2)
  }
  private var triggerEdgeInsets: UIEdgeInsets {
    return UIEdgeInsets(top: TriggerDetailViewController.innerVerticalPadding,
                        left: cellHorizontalInset / 2,
                        bottom: 0,
                        right: cellHorizontalInset / 2)
  }

  // MARK: - NoteDetailController

  var displayNote: DisplayNote {
    get {
      return displayTrigger
    }
    set {
      if let triggerNote = newValue as? DisplayTriggerNote {
        displayTrigger = triggerNote
        updateViewForDisplayNote()
      }
    }
  }

  var currentCaption: String?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// Parameters:
  ///  - displayTrigger: The trigger note to display.
  ///  - experimentInteractionOptions: THe experiment interaction options.
  ///  - delegate: The experiment item delegate.
  ///  - jumpToCaption: Whether to jump to the caption field when the view controller shows.
  ///  - analyticsReporter: The analytics reporter.
  init(displayTrigger: DisplayTriggerNote,
       experimentInteractionOptions: ExperimentInteractionOptions,
       delegate: ExperimentItemDelegate?,
       jumpToCaption: Bool,
       analyticsReporter: AnalyticsReporter) {
    self.displayTrigger = displayTrigger
    self.experimentInteractionOptions = experimentInteractionOptions
    self.delegate = delegate
    self.dataSource = TriggerDataSource(trigger: displayTrigger,
                                        experimentInteractionOptions: experimentInteractionOptions)
    self.shouldJumpToCaptionOnLoad = jumpToCaption
    currentCaption = displayTrigger.caption
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(TriggerDetailCell.self,
                             forCellWithReuseIdentifier: triggerDetailCellIdentifier)
    collectionView?.register(NoteDetailEditCaptionCell.self,
                             forCellWithReuseIdentifier: noteDetailEditCaptionCellIdentifier)
    collectionView?.register(NoteMetadataDetailCell.self,
                             forCellWithReuseIdentifier: noteMetadataDetailCellIdentifier)
    collectionView?.register(NoteMetadataDetailHeaderView.self,
                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                             withReuseIdentifier: noteMetadataDetailHeaderViewIdentifier)

    appBar.headerViewController.headerView.backgroundColor = .appBarReviewBackgroundColor
    collectionView?.backgroundColor = .white

    title = String.triggerDetailsTitle

    let backMenuItem = MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    navigationItem.leftBarButtonItem = backMenuItem

    func addDeleteButton() {
      let deleteBarButton = MaterialBarButtonItem()
      deleteBarButton.button.addTarget(self,
                                       action: #selector(deleteButtonPressed),
                                       for: .touchUpInside)
      deleteBarButton.button.setImage(UIImage(named: "ic_delete"), for: .normal)
      deleteBarButton.accessibilityLabel = String.deleteNoteMenuItem
      navigationItem.rightBarButtonItem = deleteBarButton
    }

    if experimentInteractionOptions.shouldAllowDeletes {
      addDeleteButton()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if shouldJumpToCaptionOnLoad {
      guard let captionCell = collectionView?.cellForItem(at:
          IndexPath(item: 0, section: TriggerDataSource.Section.caption.rawValue))
          as? NoteDetailEditCaptionCell else { return }
      captionCell.textField.becomeFirstResponder()
      shouldJumpToCaptionOnLoad = false
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Save the note's caption if necessary.
    view.endEditing(true)
    let newCaptionText = currentCaption?.trimmedOrNil
    if newCaptionText != displayTrigger.caption {
      displayTrigger.caption = newCaptionText
      delegate?.detailViewControllerDidUpdateCaptionForNote(displayTrigger)
    }
  }

  // MARK: - UICollectionViewDataSource

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return dataSource.numberOfSections
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return dataSource.numberOfItemsInSection(section)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: noteMetadataDetailHeaderViewIdentifier,
        for: indexPath)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    guard let section = TriggerDataSource.Section(rawValue: indexPath.section) else {
      return .zero
    }

    let width = collectionView.bounds.size.width - cellHorizontalInset
    var calculatedHeight: CGFloat = 0
    switch section {
    case .trigger:
      calculatedHeight = TriggerDetailCell.height(inWidth: width, triggerNote: displayTrigger)
    case .caption:
      calculatedHeight = NoteDetailEditCaptionCell.height
    case .metadata:
      let metadata = dataSource.metadata[indexPath.item]
      calculatedHeight = NoteMetadataDetailCell.heightWithText(metadata.title,
                                                               description: metadata.description,
                                                               inWidth: width)
    }
    return CGSize(width: width, height: ceil(calculatedHeight))
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let section = TriggerDataSource.Section(rawValue: indexPath.section)!
    switch section {
    case .trigger:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: triggerDetailCellIdentifier,
        for: indexPath)
      if let cell = cell as? TriggerDetailCell {
        cell.triggerNote = displayTrigger
      }
      return cell
    case .caption:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: noteDetailEditCaptionCellIdentifier,
        for: indexPath)
      if let cell = cell as? NoteDetailEditCaptionCell {
        cell.textField.text = currentCaption
        cell.delegate = self
        cell.shouldAllowEditing = experimentInteractionOptions.shouldAllowEdits
      }
      return cell
    case .metadata:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: noteMetadataDetailCellIdentifier,
        for: indexPath)
      if let cell = cell as? NoteMetadataDetailCell {
        let metadata = dataSource.metadata[indexPath.item]
        cell.iconView.image = metadata.icon
        cell.textLabel.text = metadata.title
        cell.descriptionLabel.text = metadata.description
      }
      return cell
    }
  }

  // MARK: - UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
    guard let sectionEnum = TriggerDataSource.Section(rawValue: section) else { return .zero }
    switch sectionEnum {
    case .trigger: return triggerEdgeInsets
    case .caption: return captionEdgeInsets
    case .metadata: return metadataEdgeInsets
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    guard section == TriggerDataSource.Section.metadata.rawValue else { return .zero }
    return CGSize(width: collectionView.bounds.size.width -  cellHorizontalInset,
                  height: NoteMetadataDetailHeaderView.height)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    // If the user is in edit mode on a caption and they tap any other cell, end editing.
    guard isEditingCaption, indexPath.section != TriggerDataSource.Section.caption.rawValue else {
      return
    }
    self.view.endEditing(true)
    isEditingCaption = false
  }

  // MARK: - NoteDetailEditCaptionCellDelegate

  func didBeginEditingCaption() {
    isEditingCaption = true
    let captionIndexPath = IndexPath(item: 0, section: TriggerDataSource.Section.caption.rawValue)
    collectionView?.scrollToItem(at: captionIndexPath, at: .top, animated: true)
  }

  func captionEditingChanged(_ caption: String?) {
    currentCaption = caption
  }

  // MARK: - Private

  private func updateViewForDisplayNote() {
    updateCaptionFromDisplayNote()
    collectionView?.reloadData()
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func deleteButtonPressed() {
    delegate?.detailViewControllerDidDeleteNote(displayTrigger)
    navigationController?.popViewController(animated: true)
  }

}
