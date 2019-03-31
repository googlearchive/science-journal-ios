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

/// A view that displays dotted lines representing the minimum, maximum and average points
/// relative to a chart view.
class ChartStatsOverlayView: UIView {

  enum Metrics {
    static let iconWidth: CGFloat = 15.0
    static let iconPadding: CGFloat = 3.0
  }

  // MARK: - Properties

  private let maxLineLayer = CAShapeLayer()
  private let minLineLayer = CAShapeLayer()
  private let averageLineLayer = CAShapeLayer()
  private let maxIcon = UIImageView()
  private let minIcon = UIImageView()
  private let averageIcon = UIImageView()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Shows the min, max, and average lines with the given y-axis view positions.
  ///
  /// - Parameters:
  ///   - min: The min y-axis view position.
  ///   - max: The max y-axis view position.
  ///   - average: The average y-axis view position.
  func showStats(min: CGFloat, max: CGFloat, average: CGFloat) {
    let lineStartX = Metrics.iconWidth + Metrics.iconPadding

    let minPath = UIBezierPath()
    minPath.move(to: CGPoint(x: lineStartX, y: min))
    minPath.addLine(to: CGPoint(x: bounds.size.width, y: min))
    minLineLayer.path = minPath.cgPath
    minLineLayer.isHidden = false
    minIcon.center = CGPoint(x: 0, y: min + minLineLayer.lineWidth)
    minIcon.isHidden = false

    let maxPath = UIBezierPath()
    maxPath.move(to: CGPoint(x: lineStartX, y: max))
    maxPath.addLine(to: CGPoint(x: bounds.size.width, y: max))
    maxLineLayer.path = maxPath.cgPath
    maxLineLayer.isHidden = false
    maxIcon.center = CGPoint(x: 0, y: max - maxLineLayer.lineWidth)
    maxIcon.isHidden = false

    let averagePath = UIBezierPath()
    averagePath.move(to: CGPoint(x: lineStartX, y: average))
    averagePath.addLine(to: CGPoint(x: bounds.size.width, y: average))
    averageLineLayer.path = averagePath.cgPath
    averageLineLayer.isHidden = false
    averageIcon.center = CGPoint(x: 0, y: average)
    averageIcon.isHidden = false
  }

  /// Hides the stats lines.
  func hideStats() {
    maxLineLayer.isHidden = true
    minLineLayer.isHidden = true
    averageLineLayer.isHidden = true
    maxIcon.isHidden = true
    minIcon.isHidden = true
    averageIcon.isHidden = true
  }

  // MARK: - Private

  private func configureView() {
    let minMaxColor = MDCPalette.green.tint600
    let averageColor = MDCPalette.grey.tint600
    [maxLineLayer, minLineLayer].forEach { $0.strokeColor = minMaxColor.cgColor }
    averageLineLayer.strokeColor = averageColor.cgColor

    let dashPattern: [NSNumber] = [4, 4]
    [maxLineLayer, minLineLayer, averageLineLayer].forEach {
      $0.lineDashPattern = dashPattern
      layer.addSublayer($0)
    }

    maxIcon.image = UIImage(named: "chart_overlay_max")
    maxIcon.contentMode = .topLeft
    maxIcon.tintColor = minMaxColor
    minIcon.image = UIImage(named: "chart_overlay_min")
    minIcon.contentMode = .bottomLeft
    minIcon.tintColor = minMaxColor
    averageIcon.image = UIImage(named: "chart_overlay_avg")
    averageIcon.contentMode = .left
    averageIcon.tintColor = averageColor

    [maxIcon, minIcon, averageIcon].forEach { addSubview($0) }

    hideStats()
  }

}
