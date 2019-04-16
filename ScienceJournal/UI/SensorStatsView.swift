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

/// A view that displays the minimum, average and maximum values of a given sensor recording, in a
/// horizontally aligned stackView. This view is used in Trial cards (via TrialCardSensorView) but
/// can also be used in sensor cards when recording. Looks like:
///
///  Header  |  Header  |  Header
///  Value   |  Value   |  Value
///
class SensorStatsView: UIView {

  // MARK: - Properties

  /// The height of the sensor stats view.
  static let height = StatView.height

  /// The color of the min and max value labels.
  var textColor: UIColor? = SensorStatType.min.textColor {
    didSet {
      minView.valueTextColor = textColor
      maxView.valueTextColor = textColor
    }
  }

  private let minView = StatView(headerText: SensorStatType.min.title,
                                 valueTextColor: SensorStatType.min.textColor)
  private let averageView = StatView(headerText: SensorStatType.average.title,
                                     valueTextColor: SensorStatType.average.textColor)
  private let maxView = StatView(headerText: SensorStatType.max.title,
                                 valueTextColor: SensorStatType.max.textColor)

  private let firstPipeView = SeparatorView(direction: .vertical, style: .dark)
  private let secondPipeView = SeparatorView(direction: .vertical, style: .dark)

  private enum Metrics {
    static let statsSpacing: CGFloat = 26.0
  }

  private var size: CGSize {
    let width = minView.frame.width + averageView.frame.width + maxView.frame.width +
        Metrics.statsSpacing * 4 + firstPipeView.frame.width + secondPipeView.frame.width
    return CGSize(width: width, height: SensorStatsView.height)
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - min: The minimum value.
  ///   - average: The average value.
  ///   - max: The maximum value.
  init(min: String, average: String, max: String) {
    super.init(frame: .zero)
    configureView()
    setMin(min, average: average, max: max)
  }

  override init(frame: CGRect) {
    fatalError("init(frame:) is not supported")
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var intrinsicContentSize: CGSize {
    return size
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return self.size
  }

  /// Sets the stat values.
  ///
  /// - Parameters:
  ///   - min: The minimum value.
  ///   - average: The average value.
  ///   - max: The maximum value.
  func setMin(_ min: String, average: String, max: String) {
    minView.valueText = min
    minView.sizeToFit()
    averageView.valueText = average
    averageView.sizeToFit()
    maxView.valueText = max
    maxView.sizeToFit()
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    minView.frame = CGRect(x: 0,
                           y: 0,
                           width: minView.frame.width,
                           height: minView.frame.height)
    firstPipeView.frame = CGRect(x: minView.frame.maxX + Metrics.statsSpacing,
                                 y: 0,
                                 width: firstPipeView.frame.width,
                                 height: bounds.height)
    averageView.frame = CGRect(x: firstPipeView.frame.maxX + Metrics.statsSpacing,
                               y: 0,
                               width: averageView.frame.width,
                               height: averageView.frame.height)
    secondPipeView.frame = CGRect(x: averageView.frame.maxX + Metrics.statsSpacing,
                                  y: 0,
                                  width: secondPipeView.frame.width,
                                  height: bounds.height)
    maxView.frame = CGRect(x: secondPipeView.frame.maxX + Metrics.statsSpacing,
                           y: 0,
                           width: maxView.frame.width,
                           height: maxView.frame.height)
    [minView, firstPipeView, averageView, secondPipeView, maxView].forEach {
      $0.adjustFrameForLayoutDirection()
    }
  }

  // MARK: - Private

  private func configureView() {
    addSubview(minView)
    addSubview(firstPipeView)
    addSubview(averageView)
    addSubview(secondPipeView)
    addSubview(maxView)
  }

}
