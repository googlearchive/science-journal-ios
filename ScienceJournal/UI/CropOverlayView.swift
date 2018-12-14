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

/// A view that displays start and end crop positions for interactive chart cropping.
class CropOverlayView: UIView {

  // MARK: - Properties

  /// The y-position of the top of the time axis top line.
  var timeAxisLineYPosition: CGFloat = 0
  /// The chart view minimum x position.
  var chartMinXPosition: CGFloat = 0
  /// The chart view maximum x position.
  var chartMaxXPosition: CGFloat = 0
  /// A hidden view that represents the start crop marker for accessibility.
  let startA11yMarker = UIView()
  /// A hidden view that represents the end crop marker for accessibility.
  let endA11yMarker = UIView()

  private let startMarker = CropMarkerView(position: .start)
  private let endMarker = CropMarkerView(position: .end)
  private let startLine = VerticalLineView()
  private let endLine = VerticalLineView()
  private let startFlagView = DataPointFlagView()
  private let endFlagView = DataPointFlagView()
  private let leadingDimmingView = UIView()
  private let trailingDimmingView = UIView()
  private let colorPalette: MDCPalette?

  private enum Metrics {
    static let flagArrowBuffer: CGFloat = 8
    static let flagYNormal: CGFloat = 0
    static let flagYAvoiding: CGFloat = -33
    static let flagMinGap: CGFloat = 15
    static let lineLengthPadding: CGFloat = 1
  }

  // MARK: - Public

  /// Designated initializer
  ///
  /// - Parameters:
  ///   - colorPalette: A color palette.
  ///   - frame: A frame.
  ///   - aDecoder: A decoder.
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
    self.init(colorPalette: nil, frame: frame)
  }

  required convenience init?(coder aDecoder: NSCoder) {
    self.init(colorPalette: nil, coder: aDecoder)
  }

  /// Sets the color of the flag views and crop lines.
  ///
  /// - Parameter color: A color.
  func setColor(_ color: UIColor) {
    [startFlagView, endFlagView].forEach { $0.color = color }
    [startLine, endLine].forEach { $0.color = color }
  }

  /// Sets the crop marker start position.
  ///
  /// - Parameters:
  ///   - position: The horizontal position.
  ///   - timestamp: The timestamp string.
  ///   - value: The value string.
  func setStartPosition(_ position: CGFloat,
                        timestamp: String,
                        value: String) {
    setPosition(position,
                forMarker: .start,
                timestamp: timestamp,
                value: value)
  }

  /// Sets the crop marker end position.
  ///
  /// - Parameters:
  ///   - position: The horizontal position.
  ///   - timestamp: The timestamp string.
  ///   - value: The value string.
  func setEndPosition(_ position: CGFloat,
                      timestamp: String,
                      value: String) {
    setPosition(position,
                forMarker: .end,
                timestamp: timestamp,
                value: value)
  }

  func showStartPoint() {
    [startLine, startMarker, startFlagView].forEach { $0.isHidden = false }
  }

  func showEndPoint() {
    [endLine, endMarker, endFlagView].forEach { $0.isHidden = false }
  }

  /// Hides the start crop marker.
  func hideStartPoint() {
    [startLine, startMarker, startFlagView].forEach { $0.isHidden = true }
  }

  /// Hides the end crop marker.
  func hideEndPoint() {
    [endLine, endMarker, endFlagView].forEach { $0.isHidden = true }
  }

  // MARK: - Private

  /// Sets the position for a marker.
  ///
  /// - Parameters:
  ///   - position: The horizontal position.
  ///   - marker: A marker type.
  ///   - timestamp: The timestamp string.
  ///   - value: The value string.
  private func setPosition(_ position: CGFloat,
                           forMarker marker: MarkerType,
                           timestamp: String,
                           value: String) {
    var lineView: VerticalLineView
    var markerView: CropMarkerView
    var markerA11yView: UIView
    var flagView: DataPointFlagView

    // The marker view is before or after the position depending on the type.
    var markerXOffset: CGFloat

    // The line needs to be offset to align with the marker view.
    var lineXOffset: CGFloat

    switch marker {
    case .start:
      lineView = startLine
      markerView = startMarker
      markerA11yView = startA11yMarker
      flagView = startFlagView
      markerXOffset = CropMarkerView.Metrics.size.width
      lineXOffset = -(VerticalLineView.lineWidth / 2)
    case .end:
      lineView = endLine
      markerView = endMarker
      markerA11yView = endA11yMarker
      flagView = endFlagView
      markerXOffset = 0
      lineXOffset = VerticalLineView.lineWidth / 2
    }

    flagView.timestampLabel.text = timestamp
    flagView.valueLabel.text = value

    // Flag view. Set the ideal frame based on the crop position without considering flag overlap.
    let flagSize = flagView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    flagView.frame = CGRect(x: position - flagSize.width / 2,
                            y: Metrics.flagYNormal,
                            width: flagSize.width,
                            height: flagSize.height)
    flagView.arrowOffset = 0

    // Adjust end flag and its arrow if it is too close to right margin.
    if endFlagView.frame.maxX > bounds.size.width {
      let arrowOffset = endFlagView.frame.maxX - bounds.size.width
      endFlagView.frame.origin.x = bounds.size.width - endFlagView.frame.width
      endFlagView.arrowOffset = arrowOffset
    }

    // Now determine if the flags overlap and adjust the end flag appropriately.
    let flagHorizontalOverlap = endFlagView.frame.minX - startFlagView.frame.maxX
    if flagHorizontalOverlap < Metrics.flagMinGap {
      let arrowOffset = flagHorizontalOverlap - Metrics.flagMinGap
      let maxArrowOffset = endFlagView.frame.width / 2 - Metrics.flagArrowBuffer
      if abs(arrowOffset) <= maxArrowOffset {
        let newEndFlagX = startFlagView.frame.maxX + Metrics.flagMinGap
        // If the end flag would go beyond the bounds with the new x-origin, instead change the
        // y-position. Otherwise use the new x-origin.
        if newEndFlagX + endFlagView.frame.width > bounds.size.width {
          endFlagView.frame.origin.y = Metrics.flagYAvoiding
        } else {
          endFlagView.frame.origin.x = newEndFlagX
          endFlagView.arrowOffset = arrowOffset
        }
      } else {
        endFlagView.frame.origin.y = Metrics.flagYAvoiding
      }
    }

    // Add flag views the first time only after setting its frame to avoid a constraint error.
    if !subviews.contains(flagView) {
      addSubview(flagView)
    }

    // Vertical line.
    let lineHeight = timeAxisLineYPosition - flagView.frame.maxY + Metrics.lineLengthPadding
    lineView.frame = CGRect(x: position + lineXOffset,
                            y: flagView.frame.maxY,
                            width: 1,
                            height: lineHeight)

    // Marker view.
    markerView.frame = CGRect(x: position - markerXOffset,
                              y: lineView.frame.maxY,
                              width: CropMarkerView.Metrics.size.width,
                              height: CropMarkerView.Metrics.size.height)

    // Marker accessibility view.
    markerA11yView.frame = markerView.frame.insetBy(dx: -10, dy: -10)

    // Dimming views.
    switch marker {
    case .start:
      if position > chartMinXPosition {
        let maxWidth = chartMaxXPosition - chartMinXPosition
        leadingDimmingView.frame = CGRect(x: chartMinXPosition,
                                          y: 0,
                                          width: min(position - chartMinXPosition, maxWidth),
                                          height: timeAxisLineYPosition)
        leadingDimmingView.isHidden = false
      } else {
        leadingDimmingView.isHidden = true
      }
    case .end:
      if position < chartMaxXPosition {
        let trailingX = max(position, chartMinXPosition)
        trailingDimmingView.frame = CGRect(x: trailingX,
                                           y: 0,
                                           width: chartMaxXPosition - trailingX,
                                           height: timeAxisLineYPosition)
        trailingDimmingView.isHidden = false
      } else {
        trailingDimmingView.isHidden = true
      }
    }
  }

  private func configureView() {
    // Dimming views.
    [leadingDimmingView, trailingDimmingView].forEach {
      $0.backgroundColor = UIColor(white: 0, alpha: 0.2)
    }

    [startFlagView, endFlagView].forEach { $0.color = colorPalette?.tint600 }
    [startLine, endLine].forEach { $0.strokeColor = colorPalette?.tint600 }

    // Markers.
    [startMarker, endMarker].forEach { $0.color = .appBarReviewBackgroundColor }

    [leadingDimmingView,
     trailingDimmingView,
     startMarker,
     endMarker,
     startA11yMarker,
     endA11yMarker,
     startLine,
     endLine].forEach { addSubview($0) }
  }

  // MARK: - MarkerType

  /// The potential positions of a crop marker.
  ///
  /// - start: The starting marker.
  /// - end: The ending marker.
  enum MarkerType {
    case start
    case end
  }

  // MARK: - Crop Marker View

  class CropMarkerView: ShapeView {

    enum Metrics {
      static let size = CGSize(width: 22, height: 22)
    }

    /// The position of the marker.
    var position = MarkerType.start {
      didSet {
        setNeedsLayout()
      }
    }

    convenience init(position: MarkerType, color: UIColor = .black) {
      self.init(color: color, frame: .zero, coder: nil)
      self.position = position
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      let path = UIBezierPath()
      path.move(to: CGPoint(x: bounds.midX, y: 0))
      let center = CGPoint(x: bounds.midX, y: bounds.midY)

      switch position {
      case .start:
        path.addLine(to: CGPoint(x: bounds.maxX, y: 0))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
        path.addArc(withCenter: center,
                    radius: bounds.width / 2,
                    startAngle: 0,
                    endAngle: .pi * 3 / 2,
                    clockwise: true)
      case .end:
        path.addArc(withCenter: center,
                    radius: bounds.width / 2,
                    startAngle: .pi * 3 / 2,
                    endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: bounds.midX, y: 0))
      }

      path.close()
      shapeLayer.path = path.cgPath
    }

    override var intrinsicContentSize: CGSize {
      return Metrics.size
    }

  }

  // MARK: - VerticalLineView

  private class VerticalLineView: ShapeView {

    static let lineWidth: CGFloat = 1

    override init(color: UIColor, frame: CGRect, coder aDecoder: NSCoder?) {
      super.init(color: color, frame: frame, coder: aDecoder)
      shapeLayer.strokeColor = color.cgColor
      shapeLayer.lineWidth = VerticalLineView.lineWidth
    }

    override var intrinsicContentSize: CGSize {
      return CGSize(width: VerticalLineView.lineWidth, height: UIView.noIntrinsicMetric)
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 0, y: 0))
      path.addLine(to: CGPoint(x: 0, y: bounds.size.height))
      shapeLayer.path = path.cgPath
    }
  }

}
