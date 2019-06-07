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

import UIKit

/// A cell displaying the results of sensor(s) snapshot in an Experiment. The cell contains one or
/// more SnapshotCardViews, a header and an optional caption.
class SnapshotCardCell: FrameLayoutMaterialCardCell {

  // MARK: - Properties

  weak var delegate: ExperimentCardCellDelegate?
  private let captionView = ExperimentCardCaptionView()
  private let headerView = ExperimentCardHeaderView()
  private var snapshotViews = [SnapshotCardView]()
  private var snapshotViewsContainer = UIView()
  private let separator = SeparatorView(direction: .horizontal, style: .dark)
  private var snapshotNote: DisplaySnapshotNote?

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    var nextOriginY: CGFloat = 0
    if !headerView.isHidden {
      headerView.frame = CGRect(x: 0,
                                y: nextOriginY,
                                width: cellContentView.bounds.width,
                                height: ExperimentCardHeaderView.height)
      nextOriginY = headerView.frame.maxY
    }

    separator.frame = CGRect(x: 0,
                             y: nextOriginY,
                             width: cellContentView.bounds.width,
                             height: SeparatorView.Metrics.dimension)

    if let snapshots = snapshotNote?.snapshots {
      let snapshotViewsHeight = ceil(SnapshotCardCell.height(forSnapshots: snapshots,
                                                             inWidth: cellContentView.bounds.width))
      snapshotViewsContainer.frame = CGRect(x: 0,
                                            y: separator.frame.maxY,
                                            width: cellContentView.bounds.width,
                                            height: snapshotViewsHeight)

      for (index, snapshotView) in snapshotViews.enumerated() {
        let snapshotViewHeight = snapshotViewsHeight / CGFloat(snapshotViews.count)
        snapshotView.frame = CGRect(x: 0,
                                    y: snapshotViewHeight * CGFloat(index),
                                    width: cellContentView.bounds.width,
                                    height: snapshotViewHeight)
      }
    }

    if let caption = snapshotNote?.caption {
      let captionViewHeight =
          ceil(ExperimentCardCaptionView.heightWithCaption(caption,
                                                           inWidth: cellContentView.bounds.width))
      captionView.frame = CGRect(x: 0,
                                 y: snapshotViewsContainer.frame.maxY,
                                 width: cellContentView.bounds.width,
                                 height: captionViewHeight)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    snapshotNote = nil
  }

  /// Sets the snapshot note to show in the cell and whether or not to show the header and
  /// inline timestamp.
  ///
  /// - Parameters:
  ///   - snapshotNote: The snapshot note to show in the cell.
  ///   - shouldShowHeader: Whether or not to show the header.
  ///   - shouldShowInlineTimestamp: Whether or not to show the inline timestamp.
  ///   - shouldShowCaptionButton: Whether or not to show the caption button.
  func setSnapshotNote(_ snapshotNote: DisplaySnapshotNote,
                       showHeader shouldShowHeader: Bool,
                       showInlineTimestamp shouldShowInlineTimestamp: Bool,
                       showCaptionButton shouldShowCaptionButton: Bool,
                       showMenuButton shouldShowMenuButton: Bool = true) {
    self.snapshotNote = snapshotNote

    // Remove any snapshot views that are not needed.
    if snapshotViews.count > snapshotNote.snapshots.count {
      let rangeOfSnapshotViewsToRemove = snapshotNote.snapshots.count..<snapshotViews.count
      snapshotViews[rangeOfSnapshotViewsToRemove].forEach { $0.removeFromSuperview() }
      snapshotViews.removeSubrange(rangeOfSnapshotViewsToRemove)
    }

    // Add any snapshot views that are needed.
    for _ in snapshotViews.count..<snapshotNote.snapshots.count {
      let snapshotCardView = SnapshotCardView(preferredMaxLayoutWidth: bounds.width,
                                              showTimestamp: shouldShowInlineTimestamp)
      snapshotViews.append(snapshotCardView)
      snapshotViewsContainer.addSubview(snapshotCardView)
    }

    // Update snapshot views with snapshots.
    for (index, snapshot) in snapshotNote.snapshots.enumerated() {
      let snapshotView = snapshotViews[index]
      snapshotView.showTimestamp = shouldShowInlineTimestamp
      snapshotView.snapshot = snapshot
    }

    // Header.
    headerView.isHidden = !shouldShowHeader

    // Timestamp.
    headerView.headerTimestampLabel.text = snapshotNote.timestamp.string
    headerView.accessibilityLabel = snapshotNote.timestamp.string
    headerView.isTimestampRelative = snapshotNote.timestamp.isRelative

    // Caption and add caption button.
    if let caption = snapshotNote.caption {
      headerView.showCaptionButton = false
      captionView.isHidden = false
      captionView.captionLabel.text = caption
    } else {
      headerView.showCaptionButton = shouldShowCaptionButton
      captionView.isHidden = true
    }

    headerView.showMenuButton = shouldShowMenuButton

    setNeedsLayout()
  }

  /// Calculates the height required to display this view, given the data provided in `snapshots`.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - snapshotNote: The snapshot note to measure.
  ///   - showingHeader: Whether or not the cell will be showing the header.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat,
                     snapshotNote: DisplaySnapshotNote,
                     showingHeader: Bool) -> CGFloat {
    // Measure the height of the snapshots.
    var totalHeight = SnapshotCardCell.height(forSnapshots: snapshotNote.snapshots,
                                              inWidth: width)
    // Add the separator height.
    totalHeight += SeparatorView.Metrics.dimension
    if showingHeader {
      // Add the header stack view's height.
      totalHeight += ExperimentCardHeaderView.height
    }
    // The caption, if necessary.
    if let caption = snapshotNote.caption {
      totalHeight += ExperimentCardCaptionView.heightWithCaption(caption, inWidth: width)
    }
    return totalHeight
  }

  // MARK: - Private

  private func configureView() {
    // Header view.
    cellContentView.addSubview(headerView)
    headerView.timestampButton.addTarget(self,
                                         action: #selector(timestampButtonPressed),
                                         for: .touchUpInside)
    headerView.commentButton.addTarget(self,
                                       action: #selector(commentButtonPressed),
                                       for: .touchUpInside)
    headerView.menuButton.addTarget(self,
                                    action: #selector(menuButtonPressed(sender:)),
                                    for: .touchUpInside)

    // Separator view.
    cellContentView.addSubview(separator)

    // Snapshot views container.
    cellContentView.addSubview(snapshotViewsContainer)

    // Caption view.
    cellContentView.addSubview(captionView)

    // Accessibility wrapping view, which sits behind all other elements to allow a user to "grab"
    // a cell by tapping anywhere in the empty space of a cell.
    let accessibilityWrappingView = UIView()
    cellContentView.configureAccessibilityWrappingView(
        accessibilityWrappingView,
        withLabel: String.noteContentDescriptionSnapshot,
        hint: String.doubleTapToViewDetails)

    // Set the order of elements to be the wrapping view first, then the header.
    accessibilityElements = [accessibilityWrappingView, headerView, snapshotViewsContainer]
  }

  private static func height(forSnapshots snapshots: [DisplaySnapshotValue],
                             inWidth width: CGFloat) -> CGFloat {
    return snapshots.reduce(0) { (result, snapshot) in
      result + SnapshotCardView.heightForSnapshot(snapshot, inWidth: width)
    }
  }

  // MARK: - User actions

  @objc private func commentButtonPressed() {
    delegate?.experimentCardCellCommentButtonPressed(self)
  }

  @objc private func menuButtonPressed(sender: MenuButton) {
    delegate?.experimentCardCellMenuButtonPressed(self, button: sender)
  }

  @objc private func timestampButtonPressed() {
    delegate?.experimentCardCellTimestampButtonPressed(self)
  }

}
