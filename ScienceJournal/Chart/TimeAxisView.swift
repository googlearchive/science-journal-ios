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

protocol AccessibilityDelegate: class {
  /// Inform the delegate adjustable accessibility element did increment its value.
  func accessibilityAdjustableViewDidIncrement()
  /// Inform the delegate adjustable accessibility element did decrement its value.
  func accessibilityAdjustableViewDidDecrement()
}

/// A view that displays a horizontal axis with labels and tick marks corresponding to time values.
/// This corresponds to the Android class ExternalAxisView.
class TimeAxisView: UIScrollView {

  // MARK: - Style

  /// The style of a TimeAxisView.
  enum Style {
    /// Used when recording in the observe view.
    case observe
    /// Used during playback in a trial review.
    case review

    var height: CGFloat {
      switch self {
      case .observe: return 41.0
      case .review: return 40.0
      }
    }
  }

  // MARK: - Constants

  weak var accessibilityDelegate: AccessibilityDelegate?
  let numberOfTicks = 10
  let paddingTop: CGFloat = 8.0
  let longTickHeight: CGFloat = 6.0
  let shortTickHeight: CGFloat = 3.0
  let tickPaddingTop: CGFloat = 2.0
  let tickPaddingBottom: CGFloat = 4.0
  let tickWidth: CGFloat = 1.0
  let topLineWidth: CGFloat = 1.0
  let recordingLineWidth: CGFloat = 5.0
  let recordingDotRadius: CGFloat = 8.0
  let noteDotRadius: CGFloat = 7.0
  let noteDotLineWidth: CGFloat = 3.0
  // Label size is fixed to avoid the cost of calculating it frequently.
  let labelSize = CGSize(width: 50, height: 12)

  // MARK: - Properties

  var topBackgroundMargin: CGFloat {
    switch style {
    case .observe: return recordingDotRadius + recordingLineWidth
    case .review: return 10
    }
  }

  override var bounds: CGRect {
    didSet {
      // When the bounds size changes, recalculate the content size and offset based on the visible
      // range.
      if bounds.size != oldValue.size {
        updateContentSizeAndOffset()
      }
    }
  }

  /// The display format for time.
  let timeFormat = ElapsedTimeFormatter()

  /// Timestamps where notes should be displayed.
  var noteTimestamps: [Int64] = []

  /// The min/max of the entire range of data that can be displayed. This represents the beginning
  /// and end of the time axis scroll view.
  var dataAxis: ChartAxis<Int64>

  /// The currently rendered view axis, used to calculate when a new range should be drawn.
  private var renderAxis: ChartAxis<CGFloat> = .zero

  /// The min/max of the visible area. This corresponds to the visible bounds of the scroll view.
  var visibleAxis: ChartAxis<Int64> {
    didSet {
      // Need to redraw labels, so reset render axis.
      renderAxis = .zero
      updateContentSizeAndOffset()
    }
  }

  /// The time that will be labeled as 0:00. All other times are labeled relative to this time.
  var zeroTime: DataPoint.Millis = 0

  /// The height of the view based on the current style.
  var height: CGFloat {
    return style.height
  }

  private var shapeLayers = [CAShapeLayer]()
  private var inUseTextLayers = [CATextLayer]()
  private var availableTextLayers = [CATextLayer]()

  private let style: Style

  var recordingStartTime: Int64? {
    didSet {
      guard style == .observe else { return }

      // Hide line if not recording.
      if recordingStartTime == nil {
        recordingDotLayer.path = nil
        recordingLineLayer.path = nil
      }

      // Force the view to redraw.
      renderAxis = .zero
    }
  }

  /// The background, only used in observe style.
  private lazy var backgroundLayer: CAShapeLayer = {
    let shapeLayer = CAShapeLayer()
    shapeLayer.fillColor = UIColor(white: 1, alpha: 0.8).cgColor
    self.layer.addSublayer(shapeLayer)
    return shapeLayer
  }()

  /// A thin black line along the top of the axis view, only used in review.
  private lazy var topLineLayer: CAShapeLayer = {
    let shapeLayer = CAShapeLayer()
    shapeLayer.lineWidth = self.topLineWidth
    shapeLayer.strokeColor = UIColor.black.cgColor
    self.layer.addSublayer(shapeLayer)
    return shapeLayer
  }()

  /// A thic red line along the top of the axis view, used in observe style when recording.
  private lazy var recordingLineLayer: CAShapeLayer = {
    let shapeLayer = CAShapeLayer()
    shapeLayer.lineWidth = self.recordingLineWidth
    shapeLayer.strokeColor = UIColor.red.cgColor
    self.layer.addSublayer(shapeLayer)
    return shapeLayer
  }()

  /// A red dot with a white stroke used to show the recording start point.
  private lazy var recordingDotLayer: CAShapeLayer = {
    let shapeLayer = CAShapeLayer()
    shapeLayer.lineWidth = self.recordingLineWidth
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.fillColor = UIColor.red.cgColor
    self.layer.addSublayer(shapeLayer)
    return shapeLayer
  }()

  // MARK: - Public

  init(style: Style, visibleAxis: ChartAxis<Int64>, dataAxis: ChartAxis<Int64>) {
    self.style = style
    self.visibleAxis = visibleAxis
    self.dataAxis = dataAxis
    zeroTime = dataAxis.min

    super.init(frame: CGRect.zero)

    isScrollEnabled = false
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
  }

  override func accessibilityIncrement() {
    accessibilityDelegate?.accessibilityAdjustableViewDidIncrement()
  }

  override func accessibilityDecrement() {
    accessibilityDelegate?.accessibilityAdjustableViewDidDecrement()
  }

  private override convenience init(frame: CGRect) {
    fatalError("init(coder:) is not supported")
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: style.height)
  }

  /// Returns a timestamp corresponding to a horizontal view position
  ///
  /// - Parameter viewPosition: The horizontal view position.
  /// - Returns: A timestamp.
  func timestampForViewPosition(_ viewPosition: CGFloat) -> Int64? {
    guard bounds.size.width > 0 else { return nil }
    return Int64(viewPosition * CGFloat(visibleAxis.length) / bounds.size.width) + dataAxis.min
  }

  // MARK: - Private

  private func updateContentSizeAndOffset() {
    guard visibleAxis.length > 0 else { return }
    let contentWidth =
        CGFloat(dataAxis.length) * bounds.size.width / CGFloat(visibleAxis.length)
    contentSize = CGSize(width: contentWidth, height: bounds.size.height)

    guard let offsetX = viewPositionForTime(visibleAxis.min) else { return }
    contentOffset = CGPoint(x: offsetX, y: 0)
    drawView()
  }

  private func drawView() {
    // Don't do anything if the size of the view is zero. (This happens when the view is first
    // created and hasn't been sized yet).
    guard bounds.size != .zero else { return }

    // Given the current scroll position, determine the desired render range.
    let pageBuffer: CGFloat = 1
    let pageSize = frame.size
    let currentPage = floor(contentOffset.x / pageSize.width)
    let firstPage = max(-1, currentPage - pageBuffer)
    let lastPage = currentPage + pageBuffer
    let startX = firstPage * pageSize.width
    let endX = (lastPage + 1) * pageSize.width
    let desiredRenderAxis = ChartAxis(min: startX, max: endX)

    // Only draw if the desired render axis is different than the current one.
    guard desiredRenderAxis != renderAxis else { return }

    renderAxis = desiredRenderAxis

    // If observe style, draw a background.
    if style == .observe {
      let bgRect = CGRect(x: startX,
                          y: topBackgroundMargin,
                          width: endX - startX,
                          height: bounds.size.height - topBackgroundMargin)
      let backgroundPath = UIBezierPath(rect: bgRect)
      backgroundLayer.path = backgroundPath.cgPath
    }

    // Remove existing layers.
    shapeLayers.forEach { $0.removeFromSuperlayer() }
    shapeLayers.removeAll()

    // Move all existing text layers to available layers in order to reuse them.
    availableTextLayers.append(contentsOf: inUseTextLayers)
    inUseTextLayers.removeAll()

    guard let renderStartTime = timestampForViewPosition(renderAxis.min),
        let renderEndTime = timestampForViewPosition(renderAxis.max) else { return }

    // Default time between ticks, rounded down to nearest second.
    var timeBetweenTicks = visibleAxis.length / Int64(numberOfTicks) / 1000 * 1000
    if timeBetweenTicks < 1000 {
      // Make sure the minimum time between ticks is half a second.
      timeBetweenTicks = 500
    }

    var tickTime: Int64
    var isLabelTick: Bool

    // Establish the initial tick time and initial label state.
    // When there is no zero time (observing but not recording) tick placement is arbitrary.
    // If there is a zero time (recording or reviewing) make ticks relative to zero.
    if style == .observe && recordingStartTime == nil {
      isLabelTick = true
      tickTime = renderStartTime
    } else {
      // Set first tick relative to the zero time.
      let timeFromZero = zeroTime - renderStartTime
      let ticksFromZero = timeFromZero / timeBetweenTicks
      tickTime = zeroTime - ticksFromZero * timeBetweenTicks
      isLabelTick = ticksFromZero % 2 == 0
    }

    while tickTime < renderEndTime {
      guard let tickPosition = viewPositionForTime(tickTime) else { continue }
      if isLabelTick {
        addLabel(forTime: tickTime, atPosition: tickPosition)
        addLongTick(atPosition: tickPosition)
      } else {
        addShortTick(atPosition: tickPosition)
      }
      tickTime += timeBetweenTicks
      isLabelTick = !isLabelTick
    }

    // Remove unused layers.
    availableTextLayers.forEach { $0.removeFromSuperlayer() }

    switch style {
    case .review:
      let topLinePath = UIBezierPath()
      let yPosition = topLineWidth / 2 + topBackgroundMargin
      topLinePath.move(to: CGPoint(x: startX, y: yPosition))
      topLinePath.addLine(to: CGPoint(x: endX, y: yPosition))
      topLineLayer.path = topLinePath.cgPath
    case .observe:
      guard let recordingStartTime = recordingStartTime,
          let recordingStartViewPosition = viewPositionForTime(recordingStartTime) else {
        return
      }

      // Record line.
      if recordingStartViewPosition < endX {
        let lineStartPosition = max(recordingStartViewPosition, startX)
        let recordLinePath = UIBezierPath()
        let yPosition = topBackgroundMargin - recordingLineWidth / 2
        recordLinePath.move(to: CGPoint(x: lineStartPosition, y: yPosition))
        recordLinePath.addLine(to: CGPoint(x: endX, y: yPosition))
        recordingLineLayer.path = recordLinePath.cgPath
      }

      // Record dot.
      if startX...endX ~= recordingStartViewPosition {
        let recordDotFrame = CGRect(x: recordingStartViewPosition - recordingDotRadius,
                                    y: recordingLineWidth / 2,
                                    width: recordingDotRadius * 2,
                                    height: recordingDotRadius * 2)
        let recordDotPath = UIBezierPath(ovalIn: recordDotFrame)
        recordingDotLayer.path = recordDotPath.cgPath
      }

      // Note dots.
      for timestamp in noteTimestamps {
        guard renderStartTime...renderEndTime ~= timestamp,
            let notePosition = viewPositionForTime(timestamp) else { continue }
        addNoteDot(atPosition: notePosition)
      }
    }
  }

  private func addNoteDot(atPosition position: CGFloat) {
    let noteDotFrame = CGRect(x: position - noteDotRadius,
                              y: topBackgroundMargin - recordingLineWidth / 2 - noteDotRadius,
                              width: noteDotRadius * 2,
                              height: noteDotRadius * 2)
    let noteDotLayer = CAShapeLayer()
    noteDotLayer.lineWidth = noteDotLineWidth
    noteDotLayer.strokeColor = UIColor.red.cgColor
    noteDotLayer.fillColor = UIColor.yellow.cgColor
    noteDotLayer.path = UIBezierPath(ovalIn: noteDotFrame).cgPath
    shapeLayers.append(noteDotLayer)
    layer.addSublayer(noteDotLayer)
  }

  private func addLabel(forTime time: DataPoint.Millis, atPosition labelPosition: CGFloat) {
    var textLayer: CATextLayer

    // Existing text layers are reused as creating new layers is costly.
    if !availableTextLayers.isEmpty {
      textLayer = availableTextLayers.remove(at: 0)
    } else {
      textLayer = CATextLayer()
      // Disable implicit animations.
      textLayer.disableImplicitAnimations()
      textLayer.foregroundColor = UIColor.black.cgColor
      textLayer.contentsScale = UIScreen.main.scale
      textLayer.fontSize = 10
      textLayer.alignmentMode = .center
    }

    textLayer.string = timeFormat.string(fromTimestamp: time - zeroTime)
    let yPosition = topBackgroundMargin + tickPaddingTop + longTickHeight + tickPaddingBottom
    textLayer.frame = CGRect(x: floor(labelPosition - labelSize.width / 2),
                             y: yPosition,
                             width: labelSize.width,
                             height: labelSize.height)
    layer.addSublayer(textLayer)
    inUseTextLayers.append(textLayer)
  }

  private func addLongTick(atPosition position: CGFloat) {
    addTick(atPosition: position, height: longTickHeight)
  }

  private func addShortTick(atPosition position: CGFloat) {
    addTick(atPosition: position, height: shortTickHeight)
  }

  private func addTick(atPosition position: CGFloat, height: CGFloat) {
    let newTickLayer = tickLayer(withPath: tickPathForPosition(position, height: height))
    layer.addSublayer(newTickLayer)
    shapeLayers.append(newTickLayer)
  }

  private func tickPathForPosition(_ position: CGFloat, height: CGFloat) -> UIBezierPath {
    let path = UIBezierPath()
    let topPadding = tickPaddingTop + topBackgroundMargin
    path.move(to: CGPoint(x: position, y: topPadding))
    path.addLine(to: CGPoint(x: position, y: topPadding + height))
    return path
  }

  private func tickLayer(withPath path: UIBezierPath) -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.lineWidth = tickWidth
    layer.strokeColor = UIColor.black.cgColor
    layer.path = path.cgPath
    return layer
  }

  private func viewPositionForTime(_ time: DataPoint.Millis) -> CGFloat? {
    guard visibleAxis.length > 0 else { return nil }
    return bounds.size.width / CGFloat(visibleAxis.length) * CGFloat(time - dataAxis.min)
  }

}
