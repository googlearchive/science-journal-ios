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

/// A view containing the value and header for a stat. Looks like:
///
///   Header
///   Value
///
class StatView: UIView {

  // MARK: - Properties

  /// The height of this view.
  static var height: CGFloat = {
    let headerHeight = ceil(SensorStatType.min.title.labelHeight(
        withConstrainedWidth: 0,
        font: MDCTypography.fontLoader().regularFont(ofSize: Metrics.headerFontSize)))
    let lightFont = MDCTypography.fontLoader().lightFont(ofSize: Metrics.valueFontSize) ??
        UIFont.systemFont(ofSize: Metrics.valueFontSize)
    return headerHeight + ceil("1".labelHeight(withConstrainedWidth: 0, font: lightFont))
  }()

  /// The value text color.
  var valueTextColor: UIColor? {
    get {
      return valueLabel.textColor
    }
    set {
      valueLabel.textColor = newValue
    }
  }

  /// The value text.
  var valueText: String? {
    get {
      return valueLabel.text
    }
    set {
      valueLabel.text = newValue
      valueLabel.sizeToFit()
      setNeedsLayout()
      updateAccessibilityLabel()
    }
  }

  private let headerLabel = UILabel()
  private let valueLabel = UILabel()

  private enum Metrics {
    static let headerFontSize: CGFloat = 12.0
    static let valueFontSize: CGFloat = 16.0
    static let maxWidth: CGFloat = 60.0
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - headerText: The header text.
  ///   - valueTextColor: The value text color.
  init(headerText: String, valueTextColor: UIColor) {
    headerLabel.text = headerText
    valueLabel.textColor = valueTextColor
    super.init(frame: .zero)
    configureView()
    updateAccessibilityLabel()
  }

  override init(frame: CGRect) {
    fatalError("init(frame:) is not supported")
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let headerLabelWidth = min(headerLabel.frame.width, Metrics.maxWidth)
    headerLabel.frame = CGRect(x: floor((bounds.width - headerLabelWidth) / 2),
                               y: 0,
                               width: headerLabelWidth,
                               height: headerLabel.frame.height)

    let valueLabelWidth = min(valueLabel.frame.width, Metrics.maxWidth)
    valueLabel.frame = CGRect(x: floor((bounds.width - valueLabelWidth) / 2),
                              y: headerLabel.frame.maxY,
                              width: valueLabelWidth,
                              height: valueLabel.frame.height)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let maxLabelWidth = max(headerLabel.frame.width, valueLabel.frame.width)
    return CGSize(width: min(maxLabelWidth, Metrics.maxWidth), height: StatView.height)
  }

  // MARK: - Private

  private func configureView() {
    isAccessibilityElement = true

    headerLabel.textColor = MDCPalette.grey.tint600
    headerLabel.font = MDCTypography.fontLoader().regularFont(ofSize: Metrics.headerFontSize)
    headerLabel.sizeToFit()
    addSubview(headerLabel)

    valueLabel.font = MDCTypography.fontLoader().lightFont(ofSize: Metrics.valueFontSize) ??
        UIFont.systemFont(ofSize: Metrics.valueFontSize)
    addSubview(valueLabel)
  }

  private func updateAccessibilityLabel() {
    accessibilityLabel = "\(headerLabel.text ?? ""), \(valueLabel.text ?? "")"
  }

}
