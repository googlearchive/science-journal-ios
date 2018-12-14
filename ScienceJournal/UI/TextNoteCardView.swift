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
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A subclass of UITextView that overrides point(inside:with:) to ensure taps do one of two things,
/// depending on where in the view they occur:
///
/// 1. If they occur on a link, they are allowed (return true) and the data detector system will
///    correctly open the URL as expected.
/// 2. If they occur anywhere else, they are not allowed (return false) and the cell in which this
///    view is contained will properly receive the didSelectItemAt delegate call.
///
/// Without this change, and with UITextView's requirement of isSelectable being true for links to
/// work, text in our TextNote cells would be selectable and tapping cells would not take you to
/// the detail view as expected.
class GSJNoteTextView: UITextView {

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    let leftDirection = UITextDirection(rawValue: UITextLayoutDirection.left.rawValue)
    guard let position = closestPosition(to: point),
        let range = tokenizer.rangeEnclosingPosition(position,
                                                     with: .character,
                                                     inDirection: leftDirection) else {
      return false
    }

    let startIndex = offset(from: beginningOfDocument, to: range.start)
    return attributedText.attribute(NSAttributedString.Key.link,
                                    at: startIndex,
                                    effectiveRange: nil) != nil
  }

}

/// A view composed of a text note's data, which includes the text of the note and the values of the
/// sensors when this note was taken. This view can be used inside a trial card or inside a
/// snapshot card, both in Experiment detail views. Timestamp is optional.
class TextNoteCardView: ExperimentCardView {

  // MARK: - Constants

  /// Font size for the text view. Used in view height calculation.
  static let textFontSize: CGFloat = 16.0
  /// Font size for the value snapshots label. Used in view height calculation.
  static let valueSnapshotsFontSize: CGFloat = 12.0

  // MARK: - Properties

  /// The text note to display.
  var textNote: DisplayTextNote? {
    didSet {
      updateViewForTextNote()
    }
  }

  private let preferredMaxLayoutWidth: CGFloat
  private let showTimestamp: Bool
  private let snapshotsLabel = UILabel()
  private let textView = GSJNoteTextView()

  // Accessibility wrapping view allowing the text to be read as well as the timestamp, without
  // breaking the outer view.
  private let accessibilityWrappingView = UIView()

  // MARK: - Public

  /// Initialize a Text Note card view with a display text note object and give it a preferred max
  /// layout width that informs the view's intrinsic content size.
  ///
  /// - Parameters:
  ///   - textNote: The display text note to use in this view.
  ///   - preferredMaxLayoutWidth: The layout width to use in this view's intrinsic content size.
  ///   - showTimestamp: Should the relative timestamp be shown?
  init(textNote: DisplayTextNote, preferredMaxLayoutWidth: CGFloat, showTimestamp: Bool = false) {
    self.textNote = textNote
    self.showTimestamp = showTimestamp
    self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    super.init(frame: .zero)
    configureView()
  }

  override required init(frame: CGRect) {
    fatalError("init(frame:) is not supported")
  }

  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  /// Calculates the height required to display this view, given the data provided.
  ///
  /// - Parameters:
  ///   - textNote: The data with which to calculate view height.
  ///   - showingTimestamp: Should the relative timestamp be measured?
  ///   - width: Maximum width for this view, used to constrain measurements.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func heightForTextNote(_ textNote: DisplayTextNote,
                                showingTimestamp: Bool,
                                inWidth width: CGFloat) -> CGFloat {
    // Constrained width, including padding.
    let constrainedWidth = width - ExperimentCardView.horizontalPaddingTotal

    // If necessary, measure the width of the timestamp to further constrain the width of the labels
    // measured here. Add the spacing between the timestamp and the text as well.
    var timestampMeasure: CGFloat = 0
    if showingTimestamp {
      timestampMeasure = ceil(textNote.timestamp.string.labelWidth(
          font: MDCTypography.fontLoader().regularFont(
              ofSize: TextNoteCardView.timestampFontSize))) +
          ExperimentCardView.innerHorizontalPadding
    }

    // Measure the height of the text, constraining it to `width`.
    var totalHeight =
        textNote.text.labelHeight(withConstrainedWidth: constrainedWidth - timestampMeasure,
                                                  font: MDCTypography.fontLoader().regularFont(
                                                      ofSize: TextNoteCardView.textFontSize))

    if let valueSnapshots = textNote.valueSnapshots {
      // Add the vertical spacing between the labels.
      totalHeight += ExperimentCardView.innerLabelsSpacing
      // Measure the height of the snapshots.
      totalHeight += valueSnapshots.labelHeight(
          withConstrainedWidth: constrainedWidth - timestampMeasure,
          font: MDCTypography.fontLoader().regularFont(
              ofSize: TextNoteCardView.valueSnapshotsFontSize))
    }

    // Add the vertical padding on top and bottom of the cell.
    totalHeight += (ExperimentCardView.innerVerticalPadding * 2)

    return totalHeight
  }

  override var intrinsicContentSize: CGSize {
    guard let textNote = textNote else { return .zero }
    return CGSize(width: UIView.noIntrinsicMetric,
                  height: TextNoteCardView.heightForTextNote(textNote,
                                                             showingTimestamp: showTimestamp,
                                                             inWidth: preferredMaxLayoutWidth))
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let textNote = textNote else { return .zero }
    return CGSize(width: size.width,
                  height: TextNoteCardView.heightForTextNote(textNote,
                                                             showingTimestamp: showTimestamp,
                                                             inWidth: size.width))
  }

  // Performance on older devices is too poor with auto layout, so use frames to lay out this
  // view.
  override func layoutSubviews() {
    super.layoutSubviews()

    var timestampLabelFrame: CGRect = .zero
    if showTimestamp {
      timestampLabel.sizeToFit()
      timestampLabelFrame = timestampLabel.frame
    }

    // Calculate the offset the timestamp creates in widths for the text and value snapshots.
    let timestampWidthOffset = timestampLabelFrame.size.width +
        (ExperimentCardView.innerHorizontalPadding * (timestampLabelFrame.size.width > 0 ? 3 : 2))

    // Lay out the text view.
    var textHeight: CGFloat = 0
    if let textNote = textNote {
      textHeight = textNote.text.labelHeight(
          withConstrainedWidth: bounds.size.width - timestampWidthOffset,
          font: MDCTypography.fontLoader().regularFont(
              ofSize: TextNoteCardView.textFontSize))
    }
    textView.frame = CGRect(x: bounds.minX + ExperimentCardView.innerHorizontalPadding,
                            y: bounds.minY + ExperimentCardView.innerVerticalPadding,
                            width: bounds.size.width - timestampWidthOffset,
                            height: textHeight)

    // Lay out the value snapshots, if necessary.
    if let textNote = textNote, let valueSnapshots = textNote.valueSnapshots {
      let valueHeight = valueSnapshots.labelHeight(
          withConstrainedWidth: bounds.size.width - timestampWidthOffset,
          font: MDCTypography.fontLoader().regularFont(
              ofSize: TextNoteCardView.valueSnapshotsFontSize))
      snapshotsLabel.frame = CGRect(x: bounds.minX + ExperimentCardView.innerHorizontalPadding,
                                    y: textView.frame.maxY + ExperimentCardView.innerLabelsSpacing,
                                    width: bounds.size.width - timestampWidthOffset,
                                    height: valueHeight)
    }

    // Lay out the timestamp, if necessary.
    if showTimestamp {
      timestampLabel.frame = CGRect(x: bounds.maxX - ExperimentCardView.innerHorizontalPadding -
                                        timestampLabelFrame.size.width,
                                    y: textView.frame.minY,
                                    width: timestampLabelFrame.size.width,
                                    height: timestampLabelFrame.size.height)
    }
  }

  override func reset() {
    textNote = nil
    textView.text = nil
    snapshotsLabel.text = nil
    timestampLabel.text = nil
    accessibilityWrappingView.accessibilityLabel = nil
  }

  // MARK: - Private

  private func configureView() {
    // Text view.
    addSubview(textView)
    textView.textColor = .black
    textView.font = MDCTypography.fontLoader().regularFont(ofSize: TextNoteCardView.textFontSize)
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.isScrollEnabled = false
    textView.isEditable = false
    textView.dataDetectorTypes = .link
    textView.isAccessibilityElement = false
    let linkTextAttributes: [NSAttributedString.Key : Any] = [
      NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue):
          MDCPalette.blue.tint500,
      NSAttributedString.Key(rawValue: NSAttributedString.Key.underlineStyle.rawValue):
          NSUnderlineStyle.single.rawValue,
      NSAttributedString.Key(rawValue: NSAttributedString.Key.underlineColor.rawValue):
          MDCPalette.blue.tint200
    ]
    textView.linkTextAttributes = linkTextAttributes

    // Value snapshots label.
    snapshotsLabel.textColor = MDCPalette.grey.tint500
    snapshotsLabel.font = MDCTypography.fontLoader().regularFont(
        ofSize: TextNoteCardView.valueSnapshotsFontSize)

    // Timestamp, if necessary.
    if showTimestamp {
      addSubview(timestampLabel)
      timestampLabel.isAccessibilityElement = true
      timestampLabel.accessibilityTraits = .staticText
    }

    // Accessibility wrapping view.
    configureAccessibilityWrappingView(accessibilityWrappingView, traits: .staticText)

    updateViewForTextNote()
  }

  private func updateViewForTextNote() {
    guard let textNote = textNote else { return }

    // Text view.
    textView.text = textNote.text

    // Value snapshots label.
    if let valueSnapshots = textNote.valueSnapshots {
      addSubview(snapshotsLabel)
      snapshotsLabel.text = valueSnapshots
    } else {
      snapshotsLabel.removeFromSuperview()
    }

    // Timestamp, if necessary.
    if showTimestamp {
      timestampLabel.text = textNote.timestamp.string
    }

    // Accessibility wrapping view.
    accessibilityWrappingView.accessibilityLabel = textNote.text

    setNeedsLayout()
  }


}
