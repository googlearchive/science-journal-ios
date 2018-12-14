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

/// A cell displaying the results of a text note snapshot in an Experiment. The cell contains the
/// text of the note and a header.
class TextNoteCardCell: AutoLayoutMaterialCardCell {

  // MARK: - Properties

  weak var delegate: ExperimentCardCellDelegate?
  private let headerView = ExperimentCardHeaderView()
  private var textNoteWrapperView = UIView()
  private let stackView = UIStackView()
  private let accessibilityWrappingView = UIView()
  private var separatorTopConstraint: NSLayoutConstraint?
  private let separator = SeparatorView(direction: .horizontal, style: .dark)

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func updateConstraints() {
    super.updateConstraints()

    separatorTopConstraint?.isActive = false
    let separatorTopAnchor =
        headerView.isHidden ? cellContentView.topAnchor : headerView.bottomAnchor
    separatorTopConstraint = separator.topAnchor.constraint(equalTo: separatorTopAnchor)
    separatorTopConstraint?.isActive = true
  }

  /// Sets the text note to show in the cell and whether or not to show the header and inline
  /// timestamp.
  ///
  /// - Parameters:
  ///   - textNote: The text note to show in the cell.
  ///   - shouldShowHeader: Whether or not to show the header.
  ///   - shouldShowInlineTimestamp: Whether or not to show the inline timestamp.
  func setTextNote(_ textNote: DisplayTextNote,
                   showHeader shouldShowHeader: Bool,
                   showInlineTimestamp shouldShowInlineTimestamp: Bool) {
    // Remove the previous text note view.
    let textSubviews = textNoteWrapperView.subviews
    for subview in textSubviews {
      subview.removeFromSuperview()
    }

    // Create a text note view for the text note.
    let textNoteView = TextNoteCardView(textNote: textNote,
                                        preferredMaxLayoutWidth: bounds.width,
                                        showTimestamp: shouldShowInlineTimestamp)
    textNoteWrapperView.addSubview(textNoteView)
    textNoteView.translatesAutoresizingMaskIntoConstraints = false
    textNoteView.pinToEdgesOfView(textNoteWrapperView)

    // Header.
    headerView.isHidden = !shouldShowHeader
    headerView.headerTimestampLabel.text = textNote.timestamp.string
    headerView.accessibilityLabel = headerView.headerTimestampLabel.text
    headerView.isTimestampRelative = textNote.timestamp.isRelative

    // Set the order of elements to be the wrapping view first, then the header.
    accessibilityElements = [accessibilityWrappingView, headerView, textNoteView]

    setNeedsUpdateConstraints()
  }

  /// Calculates the height required to display this view, given the data provided.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - textNote: The data with which to calculate view height.
  ///   - showingHeader: Whether or not the cell will be showing the header.
  ///   - showingInlineTimestamp: Whether or not the cell will be showing the inline timestamp.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat,
                     textNote: DisplayTextNote,
                     showingHeader: Bool,
                     showingInlineTimestamp: Bool) -> CGFloat {
    var totalHeight: CGFloat = 0
    // Measure the height of the note.
    totalHeight += TextNoteCardView.heightForTextNote(textNote,
                                                      showingTimestamp: showingInlineTimestamp,
                                                      inWidth: width)
    // Add the separator height.
    totalHeight += SeparatorView.Metrics.dimension
    if showingHeader {
      // Add the header stack view's height.
      totalHeight += ExperimentCardHeaderView.height
    }
    return ceil(totalHeight)
  }

  // MARK: - Private

  private func configureView() {
    // Header stack view.
    cellContentView.addSubview(headerView)
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.showCaptionButton = false  // Text notes can't have captions.
    headerView.timestampButton.addTarget(self,
                                         action: #selector(timestampButtonPressed),
                                         for: .touchUpInside)
    headerView.menuButton.addTarget(self,
                                    action: #selector(menuButtonPressed),
                                    for: .touchUpInside)
    headerView.topAnchor.constraint(equalTo: cellContentView.topAnchor).isActive = true
    headerView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor).isActive = true
    headerView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor).isActive = true

    // Separator.
    separator.translatesAutoresizingMaskIntoConstraints = false
    cellContentView.addSubview(separator)
    separatorTopConstraint = separator.topAnchor.constraint(equalTo: headerView.bottomAnchor)
    separatorTopConstraint?.isActive = true
    separator.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor).isActive = true
    separator.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor).isActive = true

    // Text note wrapper.
    cellContentView.addSubview(textNoteWrapperView)
    textNoteWrapperView.translatesAutoresizingMaskIntoConstraints = false
    textNoteWrapperView.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
    textNoteWrapperView.leadingAnchor.constraint(
        equalTo: cellContentView.leadingAnchor).isActive = true
    textNoteWrapperView.trailingAnchor.constraint(
        equalTo: cellContentView.trailingAnchor).isActive = true
    textNoteWrapperView.bottomAnchor.constraint(
        equalTo: cellContentView.bottomAnchor).isActive = true
    textNoteWrapperView.isAccessibilityElement = false

    // Accessibility wrapping view, which sits behind all other elements to allow a user to "grab"
    // a cell by tapping anywhere in the empty space of a cell.
    cellContentView.configureAccessibilityWrappingView(
        accessibilityWrappingView,
        withLabel: String.noteContentDescriptionText,
        hint: String.doubleTapToEdit)
  }

  // MARK: - User actions

  @objc private func menuButtonPressed(sender: MenuButton) {
    delegate?.experimentCardCellMenuButtonPressed(self, button: sender)
  }

  @objc private func timestampButtonPressed() {
    delegate?.experimentCardCellTimestampButtonPressed(self)
  }

}
