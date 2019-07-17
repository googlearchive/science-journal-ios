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

/// A cell displaying the results of trigger note in an Experiment. The cell contains a sensor
/// value, a description, a header and an optional caption.
class TriggerCardCell: FrameLayoutMaterialCardCell {

  // MARK: - Properties

  weak var delegate: ExperimentCardCellDelegate?
  private var captionView = ExperimentCardCaptionView()
  private let headerView = ExperimentCardHeaderView()
  private let separator = SeparatorView(direction: .horizontal, style: .dark)
  private var triggerCardView: TriggerCardView?
  private var triggerNote: DisplayTriggerNote?

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
      // Header view.
      headerView.frame = CGRect(x: 0,
                                y: nextOriginY,
                                width: cellContentView.bounds.width,
                                height: ExperimentCardHeaderView.height)
      nextOriginY = headerView.frame.maxY
    }

    // Separator.
    separator.frame = CGRect(x: 0,
                             y: nextOriginY,
                             width: cellContentView.bounds.width,
                             height: SeparatorView.Metrics.dimension)

    // Trigger card view.
    if let triggerNote = triggerNote {
      let triggerCardViewHeight =
          TriggerCardView.heightForTriggerNote(triggerNote,
                                               showingTimestamp: false,
                                               inWidth: cellContentView.bounds.width)
      triggerCardView?.frame = CGRect(x: 0,
                                      y: separator.frame.maxY,
                                      width: cellContentView.bounds.width,
                                      height: triggerCardViewHeight)
    }

    // Caption view.
    if let caption = triggerNote?.caption {
      let captionViewHeight =
          ceil(ExperimentCardCaptionView.heightWithCaption(caption, inWidth: bounds.width))
      captionView.frame = CGRect(x: 0,
                                 y: cellContentView.bounds.maxY - captionViewHeight,
                                 width: cellContentView.bounds.width,
                                 height: captionViewHeight)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    triggerNote = nil
  }

  /// Calculates the height required to display this view, given the trigger note.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - triggerNote: The trigger note to measure.
  ///   - showingHeader: Whether or not the cell will be showing the header.
  ///   - showingInlineTimestamp: Whether or not the cell will be showing the inline timestamp.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat,
                     triggerNote: DisplayTriggerNote,
                     showingHeader: Bool,
                     showingInlineTimestamp: Bool) -> CGFloat {
    // Measure the height trigger view.
    var totalHeight = TriggerCardView.heightForTriggerNote(triggerNote,
                                                           showingTimestamp: showingInlineTimestamp,
                                                           inWidth: width)
    // Add the separator height.
    totalHeight += SeparatorView.Metrics.dimension
    if showingHeader {
      // Add the header stackView's height.
      totalHeight += ExperimentCardHeaderView.height
    }
    // The caption, if necessary.
    if let caption = triggerNote.caption {
      totalHeight += ExperimentCardCaptionView.heightWithCaption(caption, inWidth: width)
    }
    return totalHeight
  }

  /// Sets the trigger note to display in the cell, and whether or not to show the header and
  /// inline timestamp.
  ///
  /// - Parameters:
  ///   - triggerNote: The trigger note to display in the cell.
  ///   - shouldShowHeader: Whether or not to show the header.
  ///   - shouldShowInlineTimestamp: Whether or not to show the inline timestamp.
  ///   - shouldShowCaptionButton: Whether or not to show the caption button.
  func setTriggerNote(_ triggerNote: DisplayTriggerNote,
                      showHeader shouldShowHeader: Bool,
                      showInlineTimestamp shouldShowInlineTimestamp: Bool,
                      showCaptionButton shouldShowCaptionButton: Bool,
                      experimentDisplay: ExperimentDisplay = .normal) {
    self.triggerNote = triggerNote

    // Trigger view.
    triggerCardView?.showTimestamp = shouldShowInlineTimestamp
    triggerCardView?.triggerNote = triggerNote

    // Header.
    headerView.isHidden = !shouldShowHeader

    // Timestamp.
    headerView.headerTimestampLabel.text = triggerNote.timestamp.string
    headerView.accessibilityLabel = headerView.headerTimestampLabel.text
    headerView.isTimestampRelative = triggerNote.timestamp.isRelative

    // Caption and add caption button.
    if let caption = triggerNote.caption {
      headerView.showCaptionButton = false
      captionView.isHidden = false
      captionView.captionLabel.text = caption
    } else {
      headerView.showCaptionButton = shouldShowCaptionButton
      captionView.isHidden = true
    }

    headerView.showMenuButton = experimentDisplay.showMenuButton

    setNeedsLayout()
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

    // Separator.
    cellContentView.addSubview(separator)

    // Trigger card view.
    let triggerCardView = TriggerCardView(preferredMaxLayoutWidth: bounds.width)
    self.triggerCardView = triggerCardView
    cellContentView.addSubview(triggerCardView)

    // Caption view.
    cellContentView.addSubview(captionView)

    // Accessibility wrapping view, which sits behind all other elements to allow a user to "grab"
    // a cell by tapping anywhere in the empty space of a cell.
    let accessibilityWrappingView = UIView()
    cellContentView.configureAccessibilityWrappingView(
        accessibilityWrappingView,
        withLabel: String.noteContentDescriptionTrigger,
        hint: String.doubleTapToViewDetails)

    // Set the order of elements to be the wrapping view first, then the rest.
    accessibilityElements = [accessibilityWrappingView, headerView, triggerCardView, captionView]
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
