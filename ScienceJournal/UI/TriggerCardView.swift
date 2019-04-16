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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view composed of a trigger's data, which includes a value, value description and an icon for
/// the type of sensor used. This view can be used inside a trial card or inside a trigger card,
/// both in Experiment detail views. Caption is optional.
class TriggerCardView: ExperimentCardView {

  // MARK: - Constants

  /// The width and height of the breakpoint icon.
  static let breakpointIconDimension: CGFloat = 24.0
  /// The spacing between the breakpoint icon and the description.
  static let breakpointHorizontalSpacing: CGFloat = 6.0
  /// Font size for the secondary description label.
  static let descriptionFontSize: CGFloat = 16.0
  /// The width and height of the sensor icon.
  static let sensorIconDimension: CGFloat = 50.0
  /// The size of the sensor icon.
  static let sensorIconSize = CGSize(width: sensorIconDimension, height: sensorIconDimension)
  /// Font size for the main value label.
  static let valueFontSize: CGFloat = 24.0

  // MARK: - Properties

  /// The trigger note to display.
  var triggerNote: DisplayTriggerNote? {
    didSet {
      updateForTrigger()
    }
  }

  /// Whether or not to show the timestamp.
  var showTimestamp: Bool {
    didSet {
      guard showTimestamp != oldValue else { return }
      setNeedsLayout()
    }
  }

  private let preferredMaxLayoutWidth: CGFloat
  private let breakpointIcon = UIImageView(image: UIImage(named: "ic_trigger"))
  private let descriptionLabel = UILabel()
  private let sensorIcon = UIImageView()
  private let valueLabel = UILabel()
  private let accessibilityWrappingView = UIView()

  // MARK: - Public

  /// Initialize a Trigger Note card view with a display trigger note object and give it a preferred
  /// max layout width that informs the view's intrinsic content size.
  ///
  /// - Parameters:
  ///   - triggerNote: The display trigger note to use in this view.
  ///   - preferredMaxLayoutWidth: The layout width to use in this view's intrinsic content size.
  ///   - showTimestamp: Should the relative timestamp be shown?
  init(triggerNote: DisplayTriggerNote? = nil,
       preferredMaxLayoutWidth: CGFloat,
       showTimestamp: Bool = false) {
    self.triggerNote = triggerNote
    self.showTimestamp = showTimestamp
    self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    super.init(frame: .zero)
    configureView()
  }

  override required init(frame: CGRect) {
    fatalError("init(frame:) is not supported")
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  /// Calculates the height required to display this view, given the trigger note.
  ///
  /// - Parameters:
  ///   - triggerNote: The data with which to calculate view height.
  ///   - showingTimestamp: Should the relative timestamp be measured?
  ///   - width: Maximum width for this view, used to constrain measurements.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func heightForTriggerNote(_ triggerNote: DisplayTriggerNote,
                                   showingTimestamp: Bool,
                                   inWidth width: CGFloat) -> CGFloat {
    // Constrained width for measuring the value, including padding, sensor icon and spacing between
    // the two.
    let constrainedWidth = width - ExperimentCardView.horizontalPaddingTotal -
        TriggerCardView.sensorIconDimension - ExperimentCardView.innerHorizontalPadding

    // Constrained width for measuring the description, which needs to take into account padding,
    // the main sensor icon, the breakpoint icon, and the spacing between each.
    let descriptionWidth = constrainedWidth - TriggerCardView.breakpointIconDimension -
        TriggerCardView.breakpointHorizontalSpacing

    // If necessary, measure the width of the timestamp to further constrain the width of the labels
    // measured here. Add the spacing between the timestamp and the text as well.
    var timestampMeasure: CGFloat = 0
    if showingTimestamp {
      timestampMeasure = ceil(triggerNote.timestamp.string.labelWidth(
        font: MDCTypography.fontLoader().regularFont(ofSize: TriggerCardView.timestampFontSize))) +
        ExperimentCardView.innerHorizontalPadding
    }

    var totalHeight: CGFloat = 0
    // Measure the height of the labels, constraining them to the constrained width.
    let labelsHeight =
        triggerNote.descriptionText.labelHeight(
            withConstrainedWidth: descriptionWidth - timestampMeasure,
            font: MDCTypography.fontLoader().regularFont(
                ofSize: SnapshotCardView.descriptionFontSize)) +
        triggerNote.valueText.labelHeight(withConstrainedWidth: constrainedWidth,
                                          font: MDCTypography.fontLoader().boldFont!(
                                              ofSize: SnapshotCardView.valueFontSize))

    // Use either the icon size or the labels height, whichever is greater.
    totalHeight += max(TriggerCardView.sensorIconDimension, labelsHeight)

    // Add the vertical padding on top and bottom of the cell.
    totalHeight += (ExperimentCardView.innerVerticalPadding * 2)

    return totalHeight
  }

  override var intrinsicContentSize: CGSize {
    guard let triggerNote = triggerNote else { return .zero }
    return CGSize(width: UIView.noIntrinsicMetric,
                  height: TriggerCardView.heightForTriggerNote(triggerNote,
                                                               showingTimestamp: showTimestamp,
                                                               inWidth: preferredMaxLayoutWidth))
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let triggerNote = triggerNote else { return .zero }
    return CGSize(width: size.width,
                  height: TriggerCardView.heightForTriggerNote(triggerNote,
                                                               showingTimestamp: showTimestamp,
                                                               inWidth: size.width))
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    timestampLabel.isHidden = !showTimestamp
    if showTimestamp {
      timestampLabel.sizeToFit()
      timestampLabel.frame = CGRect(
          x: bounds.maxX - timestampLabel.frame.width - ExperimentCardView.innerHorizontalPadding,
          y: ExperimentCardView.innerVerticalPadding,
          width: timestampLabel.frame.width,
          height: timestampLabel.frame.height)
    }

    // Sensor icon.
    sensorIcon.frame =
        CGRect(x: ExperimentCardView.innerHorizontalPadding,
               y: floor((bounds.maxY - TriggerCardView.sensorIconDimension) / 2),
               width: TriggerCardView.sensorIconDimension,
               height: TriggerCardView.sensorIconDimension)


    // Breakpoint icon. Wait to set Y origin after the description label is set.
    breakpointIcon.frame =
        CGRect(x: sensorIcon.frame.maxX + ExperimentCardView.innerHorizontalPadding,
               y: 0,
               width: breakpointIcon.frame.width,
               height: breakpointIcon.frame.height)

    // Description label.
    let descriptionLabelWidth = (showTimestamp ? timestampLabel.frame.minX : bounds.maxX) -
        breakpointIcon.frame.maxX - ExperimentCardView.innerHorizontalPadding -
        TriggerCardView.breakpointHorizontalSpacing
    if let descriptionLabelHeight =
        descriptionLabel.text?.labelHeight(withConstrainedWidth: descriptionLabelWidth,
                                           font: descriptionLabel.font) {
      descriptionLabel.frame = CGRect(
          x: breakpointIcon.frame.maxX + TriggerCardView.breakpointHorizontalSpacing,
          y: ExperimentCardView.innerVerticalPadding,
          width: descriptionLabelWidth,
          height: descriptionLabelHeight)
    }

    // Now that the description label is set, set the breakpoint icon Y origin.
    breakpointIcon.frame.origin.y =
        floor(descriptionLabel.frame.midY - breakpointIcon.frame.height / 2)

    // Value label.
    valueLabel.sizeToFit()
    valueLabel.frame = CGRect(x: breakpointIcon.frame.minX,
                              y: descriptionLabel.frame.maxY,
                              width: valueLabel.frame.width,
                              height: valueLabel.frame.height)

    // Adjust subview frames for RTL.
    [timestampLabel, sensorIcon, breakpointIcon, descriptionLabel, valueLabel].forEach {
      $0.adjustFrameForLayoutDirection(inWidth: self.bounds.width)
    }
  }

  override func reset() {
    triggerNote = nil
    sensorIcon.image = nil
    descriptionLabel.text = nil
    valueLabel.text = nil
    timestampLabel.text = nil
    accessibilityWrappingView.accessibilityLabel = nil
  }

  // MARK: - Private

  private func configureView() {
    // Sensor icon.
    addSubview(sensorIcon)

    // Breakpoint icon.
    addSubview(breakpointIcon)
    breakpointIcon.tintColor = MDCPalette.blue.tint700

    // Description label.
    addSubview(descriptionLabel)
    descriptionLabel.isAccessibilityElement = false
    descriptionLabel.numberOfLines = 0
    descriptionLabel.textColor = MDCPalette.grey.tint500
    descriptionLabel.font =
        MDCTypography.fontLoader().regularFont(ofSize: SnapshotCardView.descriptionFontSize)
    descriptionLabel.textAlignment =
        UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right

    // Value label.
    addSubview(valueLabel)
    valueLabel.isAccessibilityElement = false
    valueLabel.textColor = .black
    valueLabel.font = MDCTypography.fontLoader().boldFont?(ofSize: SnapshotCardView.valueFontSize)

    // Timestamp label.
    addSubview(timestampLabel)

    configureAccessibilityWrappingView(accessibilityWrappingView, traits: .staticText)

    updateForTrigger()
  }

  private func updateForTrigger() {
    guard let triggerNote = triggerNote else { return }

    // Sensor icon.
    sensorIcon.image = triggerNote.icon

    // Description label.
    descriptionLabel.text = triggerNote.descriptionText

    // Value label.
    valueLabel.text = triggerNote.valueText

    // Timestamp label.
    timestampLabel.text = triggerNote.timestamp.string

    var additionalValue = ", "
    if let iconAccessibilityLabel = triggerNote.iconAccessibilityLabel {
      additionalValue += "\(iconAccessibilityLabel), "
    }
    accessibilityWrappingView.accessibilityLabel =
        "\(triggerNote.descriptionText)\(additionalValue)\(triggerNote.valueText)"
  }

}
