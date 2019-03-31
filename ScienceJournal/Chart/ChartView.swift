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

import QuartzCore
import UIKit

import MaterialComponents

protocol ChartViewDelegate: class {
  func yPositionForLabel(atIndex labelIndex: Int) -> CGFloat?
  func chartViewFrameSizeDidChange()
}

/// Renders data as a line on an x and y axis. Use ChartController to create and manage ChartView
/// instances.
class ChartView: UIView {

  // - MARK: ChartContentView

  /// A content view that manages all the drawing of data and metadata.
  class ChartContentView: UIView {

    // Lines
    var dataLine = UIBezierPath() {
      didSet {
        dataLineLayer.path = dataLine.cgPath
      }
    }

    // Note Dots
    fileprivate var noteDots = [CALayer]()

    // Note Lines (only in obvserve placement)
    fileprivate var noteLines = [CALayer]()

    // Layers
    let dataLineLayer = CAShapeLayer()
    var yAxisLineLayers = [CAShapeLayer]()
    let currentPointLayer = CAShapeLayer()
    let startPointLayer = CAShapeLayer()
    let endPointLayer = CAShapeLayer()
    let recordingBackgroundLayer = CAShapeLayer()
    let recordingStartLine = CAShapeLayer()

    // Cached Colors
    var yAxisLineColor = UIColor.black

    override init(frame: CGRect) {
      super.init(frame: frame)
      configureView()
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      configureView()
    }

    private func configureView() {
      let recordFill = UIColor(red: 1, green: 0.85, blue: 0.85, alpha: 1)
      recordingBackgroundLayer.fillColor = recordFill.cgColor
      layer.addSublayer(recordingBackgroundLayer)

      dataLineLayer.lineWidth = 2
      dataLineLayer.fillColor = nil
      dataLineLayer.lineCap = .round
      dataLineLayer.lineJoin = .round
      dataLineLayer.disableImplicitAnimations()
      layer.addSublayer(dataLineLayer)

      layer.addSublayer(currentPointLayer)

      startPointLayer.fillColor = UIColor.white.cgColor
      startPointLayer.lineWidth = 3
      startPointLayer.isHidden = true
      startPointLayer.disableImplicitAnimations()
      endPointLayer.fillColor = UIColor.white.cgColor
      endPointLayer.lineWidth = 3
      endPointLayer.isHidden = true
      endPointLayer.disableImplicitAnimations()
      layer.addSublayer(startPointLayer)
      layer.addSublayer(endPointLayer)

      recordingStartLine.strokeColor = UIColor.red.cgColor
      recordingStartLine.disableImplicitAnimations()
      layer.addSublayer(recordingStartLine)

      contentMode = .left
    }

    func addYAxisLines(count: Int) {
      guard count > 0 else { return }

      for layer in yAxisLineLayers {
        layer.removeFromSuperlayer()
      }
      yAxisLineLayers.removeAll()
      for _ in 1...count {
        let lineLayer = CAShapeLayer()
        lineLayer.strokeColor = yAxisLineColor.cgColor
        lineLayer.fillColor = nil
        self.layer.insertSublayer(lineLayer, below: dataLineLayer)
        yAxisLineLayers.append(lineLayer)
      }
    }

  }

  // - MARK: ChartView

  weak var delegate: ChartViewDelegate?

  /// An array of labels to display values for each Y-axis line.
  var yAxisLabels = [UILabel]()

  let chartContentView = ChartContentView()

  let statsOverlayView = ChartStatsOverlayView()

  let scrollView = UIScrollView()

  private let spinner = MDCActivityIndicator()

  let pinchGestureRecognizer = UIPinchGestureRecognizer()

  /// A convenience property for getting and setting the content size of the chart inside the
  /// scroll view.
  var chartSize: CGSize {
    get {
      return scrollView.contentSize
    }
    set {
      chartContentView.frame = CGRect(x: 0, y: 0, width: newValue.width, height: newValue.height)
      scrollView.contentSize = CGSize(width: max(newValue.width, scrollView.bounds.size.width),
                                      height: scrollView.bounds.size.height)
    }
  }

  override var bounds: CGRect {
    didSet {
      chartSize = CGSize(width: bounds.size.width - leftMargin, height: bounds.size.height)
      if bounds.size.width != oldValue.size.width || bounds.size.height != oldValue.size.height {
        delegate?.chartViewFrameSizeDidChange()
      }
    }
  }

  override var frame: CGRect {
    didSet {
      chartSize = CGSize(width: frame.size.width - leftMargin, height: frame.size.height)
      if frame.size.width != oldValue.size.width || frame.size.height != oldValue.size.height {
        delegate?.chartViewFrameSizeDidChange()
      }
    }
  }

  var chartOptions: ChartOptions {
    didSet {
      updateChartOptions()
    }
  }

  /// The width of the y-axis label. Note that it is not visible in observe mode.
  static let yLabelWidth: CGFloat = 50.0

  var leftMargin: CGFloat {
    return chartOptions.isYAxisVisible ? ChartView.yLabelWidth : 0
  }

  /// The insets for the display of the visible chart area not including axes or margins. Used to
  /// calculate the time axis insets.
  var chartInsets: UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
  }

  // MARK: - UIView

  init(chartOptions: ChartOptions) {
    self.chartOptions = chartOptions

    super.init(frame: CGRect.zero)

    scrollView.alwaysBounceHorizontal = true
    scrollView.isExclusiveTouch = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    addSubview(scrollView)

    statsOverlayView.isUserInteractionEnabled = false
    addSubview(statsOverlayView)

    spinner.alpha = 0
    addSubview(spinner)

    chartSize = scrollView.bounds.size
    scrollView.addSubview(chartContentView)
    chartContentView.dataLine.lineWidth = 2

    updateChartOptions()
  }

  convenience required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func showSpinner() {
    spinner.alpha = 1
    spinner.startAnimating()
  }

  func hideSpinner() {
    spinner.alpha = 0
    spinner.stopAnimating()
  }

  // MARK: - Setup and drawing

  private func updateChartOptions() {
    scrollView.isScrollEnabled = chartOptions.canScroll
    chartContentView.dataLineLayer.strokeColor = chartOptions.lineColor.cgColor
    chartContentView.currentPointLayer.fillColor = chartOptions.lineColor.cgColor
    chartContentView.startPointLayer.strokeColor = chartOptions.lineColor.cgColor
    chartContentView.endPointLayer.strokeColor = chartOptions.lineColor.cgColor
    chartContentView.yAxisLineColor = chartOptions.yAxisLineColor

    if chartOptions.placementType == .previewReview {
      // In the experiment view, charts can be tapped to show a trial detail view, so they should
      // not intercept touches.
      isUserInteractionEnabled = false

      // Rasterize preview review charts for smoother scrolling.
      chartContentView.layer.rasterizationScale = UIScreen.main.scale
      chartContentView.layer.shouldRasterize = true
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    scrollView.frame = CGRect(x: leftMargin,
                              y: 0,
                              width: bounds.size.width - leftMargin,
                              height: bounds.size.height)

    statsOverlayView.frame = scrollView.frame

    spinner.sizeToFit()
    spinner.frame = CGRect(x: (bounds.size.width - spinner.frame.width) / 2,
                           y: (bounds.size.height - spinner.frame.height) / 2,
                           width: spinner.frame.width,
                           height: spinner.frame.height).integral

    guard chartOptions.isYAxisVisible else { return }

    var labelIndex = 0
    for label in yAxisLabels {
      guard let updatedYPosition = delegate?.yPositionForLabel(atIndex: labelIndex) else {
        continue
      }

      label.sizeToFit()
      label.frame = CGRect(x: floor((leftMargin - label.frame.size.width) / 2),
                           y: floor(updatedYPosition - label.frame.size.height / 2),
                           width: label.frame.size.width,
                           height: label.frame.size.height)
      labelIndex += 1
    }
  }

  /// Adds a note dot to the chart view.
  ///
  /// - Parameter viewPoint: The view location of the note dot.
  func addNoteDot(at viewPoint: CGPoint) {
    let dotLayer = CAShapeLayer()
    dotLayer.lineWidth = 2
    let dotRadius: CGFloat = 4.0

    // Set the color based on the placement. Preview review does not display notes.
    switch chartOptions.placementType {
    case .observe:
      dotLayer.fillColor = UIColor.yellow.cgColor
      dotLayer.strokeColor = chartOptions.lineColor.cgColor

      // In observe, notes also display a vertical dotted line.
      let linePath = UIBezierPath()
      linePath.move(to: CGPoint(x: viewPoint.x, y: 0))
      linePath.addLine(to: CGPoint(x: viewPoint.x, y: bounds.size.height))
      let lineLayer = CAShapeLayer()
      lineLayer.path = linePath.cgPath
      lineLayer.strokeColor = UIColor.gray.cgColor
      lineLayer.lineDashPattern = [4,4]
      lineLayer.lineWidth = 1
      chartContentView.layer.addSublayer(lineLayer)
      chartContentView.noteLines.append(lineLayer)
    case .runReview, .previewReview:
      dotLayer.fillColor = UIColor.gray.cgColor
      dotLayer.strokeColor = UIColor.white.cgColor
    }

    let dotRect = CGRect(x: viewPoint.x - dotRadius,
                         y: viewPoint.y - dotRadius,
                         width: dotRadius * 2,
                         height: dotRadius * 2)
    let dotPath = UIBezierPath(ovalIn: dotRect)
    dotLayer.path = dotPath.cgPath
    chartContentView.layer.addSublayer(dotLayer)
    chartContentView.noteDots.append(dotLayer)
  }

  func clearNoteDots() {
    chartContentView.noteDots.forEach { $0.removeFromSuperlayer() }
    chartContentView.noteDots.removeAll()
    chartContentView.noteLines.forEach { $0.removeFromSuperlayer() }
    chartContentView.noteLines.removeAll()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric,
                  height: chartOptions.placementType.height)
  }

  // MARK: - Y Labels

  func addYAxisLabels(yAxisValues: [Double]) {
    removeAllLabels()
    for yAxisValue in yAxisValues {
      let label = UILabel()
      label.font = UIFont.systemFont(ofSize: 12.0)
      label.text = String(yAxisValue)
      yAxisLabels.append(label)
      addSubview(label)
    }
  }

  func removeAllLabels() {
    for label in yAxisLabels {
      label.removeFromSuperview()
    }
    yAxisLabels.removeAll()
  }

}
