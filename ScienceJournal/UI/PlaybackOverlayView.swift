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

/// An overlay view for ChartView that displays a flag and arrow that points to a point on a chart.
class PlaybackOverlayView: UIView {

  // MARK: - DottedLineView

  private class DottedLineView: ShapeView {
    override init(color: UIColor, frame: CGRect, coder aDecoder: NSCoder?) {
      super.init(color: color, frame: frame, coder: aDecoder)
      shapeLayer.lineDashPattern = [2,2]
      shapeLayer.strokeColor = UIColor.lightGray.cgColor
      shapeLayer.lineWidth = 1
    }

    override var intrinsicContentSize: CGSize {
      return CGSize(width: 1, height: UIView.noIntrinsicMetric)
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 0, y: 0))
      path.addLine(to: CGPoint(x: 0, y: bounds.size.height))
      shapeLayer.path = path.cgPath
    }
  }

  // MARK: - ChartDotView

  private class ChartDotView: ShapeView {
    override init(color: UIColor, frame: CGRect, coder aDecoder: NSCoder?) {
      super.init(color: color, frame: frame, coder: aDecoder)
      shapeLayer.fillColor = color.cgColor
      shapeLayer.strokeColor = UIColor.white.cgColor
      shapeLayer.lineWidth = 2
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      shapeLayer.path = UIBezierPath(ovalIn: bounds).cgPath
    }
  }

  // MARK: - TimelineDotView

  private class TimelineDotView: UIView {

    let strokeWidth: CGFloat = 40
    let strokeSelectedWidth: CGFloat = 20
    let innerDotRadius: CGFloat = 3.5
    let maxRadius: CGFloat = 25
    var outerDotRadius: CGFloat {
      return isSelected ? maxRadius : 10
    }

    let innerDotLayer = CAShapeLayer()
    let outerDotLayer = CAShapeLayer()

    var isSelected = false {
      didSet {
        setNeedsLayout()
      }
    }

    init(frame: CGRect = .zero, coder aDecoder: NSCoder? = nil) {
      if let aDecoder = aDecoder {
        super.init(coder: aDecoder)!
      } else {
        super.init(frame: frame)
      }
    }

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
      let innerDotFrame = CGRect(x: (bounds.size.width / 2) - innerDotRadius,
                                 y: (bounds.size.height / 2) - innerDotRadius,
                                 width: innerDotRadius * 2,
                                 height: innerDotRadius * 2)
      innerDotLayer.path = UIBezierPath(ovalIn: innerDotFrame).cgPath
      let outerDotFrame = CGRect(x: (bounds.size.width / 2) - outerDotRadius,
                                 y: (bounds.size.height / 2) - outerDotRadius,
                                 width: outerDotRadius * 2,
                                 height: outerDotRadius * 2)
      outerDotLayer.path = UIBezierPath(ovalIn: outerDotFrame).cgPath
    }

    private func configureView() {
      innerDotLayer.fillColor = MDCPalette.blue.tint600.cgColor
      outerDotLayer.fillColor = UIColor(red: 0.259, green: 0.522, blue: 0.957, alpha: 0.33).cgColor

      layer.addSublayer(innerDotLayer)
      layer.addSublayer(outerDotLayer)
    }

  }

  // MARK: - Properties

  private let flagView = DataPointFlagView()
  private let dottedLine = DottedLineView()
  private let chartDot = ChartDotView()
  private let timelineDot = TimelineDotView()
  private let colorPalette: MDCPalette?

  init(colorPalette: MDCPalette?, frame: CGRect = .zero, coder aDecoder: NSCoder? = nil) {
    self.colorPalette = colorPalette
    if let aDecoder = aDecoder {
      super.init(coder: aDecoder)!
    } else {
      super.init(frame: frame)
    }
    configureView()
  }

  override convenience init(frame: CGRect) {
    self.init(colorPalette: MDCPalette.blue, frame: frame)
  }

  required convenience init?(coder aDecoder: NSCoder) {
    self.init(colorPalette: MDCPalette.blue, coder: aDecoder)
  }

  private func configureView() {
    flagView.color = colorPalette?.tint600
    chartDot.color = colorPalette?.tint600

    // flagView is not added as a sub view until its frame has been calculated the first time to
    // avoid a constraint error.
    addSubview(dottedLine)
    addSubview(chartDot)
    addSubview(timelineDot)
  }

  /// Adjusts the flag view and dotted line to align with the given point.
  ///
  /// - Parameters:
  ///   - point: A CGPoint relative to this view.
  ///   - timestamp: A string representing a timestamp.
  ///   - value: A string representing a value.
  ///   - isDragging: True if the current point is being dragged, otherwise false.
  ///   - timeAxisLineYPosition: The y-position of the time axis line, which is where the timeline
  ///                            dot should be positioned.
  func setCurrentPoint(_ point: CGPoint,
                       timestamp: String,
                       value: String,
                       isDragging: Bool,
                       timeAxisLineYPosition: CGFloat) {
    // Hide flag and line if point is out of bounds.
    guard point.x >= 0, point.x <= bounds.size.width else {
      flagView.isHidden = true
      dottedLine.isHidden = true
      chartDot.isHidden = true
      timelineDot.isHidden = true
      return
    }

    flagView.isHidden = false
    dottedLine.isHidden = false
    chartDot.isHidden = false
    timelineDot.isHidden = false

    flagView.timestampLabel.text = timestamp
    flagView.valueLabel.text = value

    // Don't let the flag view beyond the view bounds.
    let flagSize = flagView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    let flagX = min(max(0, point.x - flagSize.width / 2), bounds.size.width - flagSize.width)
    flagView.frame = CGRect(x: flagX, y: 0, width: flagSize.width, height: flagSize.height)

    // Add flag view the first time only after setting its frame to avoid a constraint error.
    if !subviews.contains(flagView) {
      addSubview(flagView)
    }

    // Adjust flag arrow if point is near the view edges.
    let halfFlagWidth = flagSize.width / 2
    let maxCenteredArrow = bounds.size.width - halfFlagWidth
    let minCenteredArrow = halfFlagWidth
    if point.x - maxCenteredArrow > 0 {
      flagView.arrowOffset = point.x - maxCenteredArrow
    } else if point.x < minCenteredArrow {
      flagView.arrowOffset = point.x - minCenteredArrow
    } else {
      flagView.arrowOffset = 0
    }

    let dottedLineHeight = point.y - flagView.frame.maxY
    dottedLine.frame = CGRect(x: point.x,
                              y: flagView.frame.maxY,
                              width: 1,
                              height: dottedLineHeight)

    let chartDotRadius: CGFloat = 4
    chartDot.frame = CGRect(x: point.x - chartDotRadius,
                            y: point.y - chartDotRadius,
                            width: chartDotRadius * 2,
                            height: chartDotRadius * 2)

    timelineDot.frame = CGRect(x: point.x - timelineDot.maxRadius,
                               y: timeAxisLineYPosition - timelineDot.maxRadius,
                               width: timelineDot.maxRadius * 2,
                               height: timelineDot.maxRadius * 2)
    timelineDot.isSelected = isDragging
  }

}
