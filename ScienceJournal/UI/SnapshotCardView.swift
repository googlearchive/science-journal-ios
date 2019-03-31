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
import MaterialComponents

/// A view composed of a snapshot's data, which includes a value, value description and an icon for
/// the type of sensor used. This view can be used inside a trial card or inside a snapshot card,
/// both in Experiment detail views. Timestamp is optional.
class SnapshotCardView: ExperimentCardView {

  // MARK: - Constants

  /// Font size for the main value label. Used in view height calculation.
  static let valueFontSize: CGFloat = 24.0
  /// Font size for the secondary description label. Used in view height calculation.
  static let descriptionFontSize: CGFloat = 16.0
  /// Icon dimension.
  static let iconDimension: CGFloat = 50.0
    /// The size of the sensor icon.
  static let sensorIconSize = CGSize(width: iconDimension, height: iconDimension)

  // MARK: - Properties

  /// The snapshot value to display.
  var snapshot: DisplaySnapshotValue? {
    didSet {
      updateForSnapshot()
    }
  }

  /// Whether or not to show the relative timestamp.
  var showTimestamp: Bool {
    didSet {
      guard showTimestamp != oldValue else { return }
      setNeedsLayout()
    }
  }

  private let preferredMaxLayoutWidth: CGFloat
  private let descriptionLabel = UILabel()
  private let icon = UIImageView()
  private let valueLabel = UILabel()
  private let accessibilityWrappingView = UIView()

  // MARK: - Public

  /// Initialize a Snapshot card view with a display snapshot value object and give it a preferred
  /// max layout width that informs the view's intrinsic content size.
  ///
  /// - Parameters:
  ///   - snapshot: The display snapshot value use in this view.
  ///   - preferredMaxLayoutWidth: The layout width to use in this view's intrinsic content size.
  ///   - showTimestamp: Should the relative timestamp be shown?
  init(snapshot: DisplaySnapshotValue? = nil,
       preferredMaxLayoutWidth: CGFloat,
       showTimestamp: Bool = false) {
    self.snapshot = snapshot
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

  override var intrinsicContentSize: CGSize {
    guard let snapshot = snapshot else { return .zero }
    return CGSize(width: UIView.noIntrinsicMetric,
                  height: SnapshotCardView.heightForSnapshot(snapshot,
                                                             inWidth: preferredMaxLayoutWidth))
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let snapshot = snapshot else { return .zero }
    return CGSize(width: size.width,
                  height: SnapshotCardView.heightForSnapshot(snapshot,
                                                             inWidth: size.width))
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Timestamp label.
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
    icon.frame = CGRect(x: ExperimentCardView.innerHorizontalPadding,
                        y: floor((bounds.maxY - SnapshotCardView.iconDimension) / 2),
                        width: SnapshotCardView.iconDimension,
                        height: SnapshotCardView.iconDimension)

    // Description label.
    let descriptionLabelMinX = icon.frame.maxX + ExperimentCardView.innerHorizontalPadding
    let descriptionLabelMaxX = showTimestamp ? timestampLabel.frame.minX : bounds.maxX
    descriptionLabel.sizeToFit()
    descriptionLabel.frame =
        CGRect(x: descriptionLabelMinX,
               y: ExperimentCardView.innerVerticalPadding,
               width: descriptionLabelMaxX - ExperimentCardView.innerHorizontalPadding -
                          descriptionLabelMinX,
               height: descriptionLabel.frame.height)

    // Value label.
    valueLabel.sizeToFit()
    valueLabel.frame = CGRect(x: descriptionLabel.frame.minX,
                              y: descriptionLabel.frame.maxY,
                              width: descriptionLabel.frame.width,
                              height: valueLabel.frame.height)

    [timestampLabel, icon, descriptionLabel, valueLabel].forEach {
      $0.adjustFrameForLayoutDirection()
    }
  }

  /// Calculates the height required to display this view, given the data provided in `snapshot`.
  ///
  /// - Parameters:
  ///   - snapshot: The data with which to calculate view height.
  ///   - width: Maximum width for this view, used to constrain measurements.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func heightForSnapshot(_ snapshot: DisplaySnapshotValue,
                                inWidth width: CGFloat) -> CGFloat {
    // Constrained width, including padding.
    let constrainedWidth = width - ExperimentCardView.horizontalPaddingTotal

    var totalHeight: CGFloat = 0
    // Measure the height of the value type, constraining it to the max view width.
    let labelsHeight =
        snapshot.valueType.labelHeight(withConstrainedWidth: constrainedWidth,
                                       font: MDCTypography.fontLoader().regularFont(
                                           ofSize: SnapshotCardView.descriptionFontSize)) +
        snapshot.value.labelHeight(withConstrainedWidth: constrainedWidth,
                                   font: MDCTypography.fontLoader().boldFont!(
                                       ofSize: SnapshotCardView.valueFontSize))
    // If the icon is taller, use that instead.
    totalHeight += max(SnapshotCardView.iconDimension, labelsHeight)

    // Add the vertical padding on top and bottom of the cell.
    totalHeight += (ExperimentCardView.innerVerticalPadding * 2)

    return totalHeight
  }

  override func reset() {
    snapshot = nil
    icon.image = nil
    descriptionLabel.text = nil
    valueLabel.text = nil
    timestampLabel.text = nil
    accessibilityWrappingView.accessibilityLabel = nil
  }

  // MARK: - Private

  private func configureView() {
    // Description label.
    descriptionLabel.isAccessibilityElement = false
    descriptionLabel.textColor = MDCPalette.grey.tint500
    descriptionLabel.font = MDCTypography.fontLoader().regularFont(
        ofSize: SnapshotCardView.descriptionFontSize)
    addSubview(descriptionLabel)

    // Value label.
    valueLabel.isAccessibilityElement = false
    valueLabel.textColor = .black
    valueLabel.font = MDCTypography.fontLoader().boldFont?(
        ofSize: SnapshotCardView.valueFontSize)
    addSubview(valueLabel)

    // Icon.
    addSubview(icon)

    // Timestamp label.
    addSubview(timestampLabel)

    configureAccessibilityWrappingView(accessibilityWrappingView, traits: .staticText)

    updateForSnapshot()
  }

  private func updateForSnapshot() {
    icon.image = snapshot?.sensorIcon
    descriptionLabel.text = snapshot?.valueType
    valueLabel.text = snapshot?.value
    if showTimestamp {
      timestampLabel.text = snapshot?.timestamp.string
    }

    if let snapshot = snapshot {
      var additionalValue = ", "
      if let sensorIconAccessibilityLabel = snapshot.sensorIconAccessibilityLabel {
        additionalValue += "\(sensorIconAccessibilityLabel), "
      }
      accessibilityWrappingView.accessibilityLabel =
          "\(snapshot.valueType)\(additionalValue)\(snapshot.value)"
    }
  }

}
