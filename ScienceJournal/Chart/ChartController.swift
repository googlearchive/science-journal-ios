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

extension UIScrollView {
  /// Returns true if user is touching scroll view, dragging or has released but the view is still
  /// decelerating, otherwise false. Encompasses the entire state from the beginning of a user
  /// initiated movement until that movement is complete.
  var isUserScrolling: Bool {
    return isTracking || isDragging || isDecelerating
  }
}

/// A protocol used by ChartAxis to allow different numeric types to be associated with an axis.
protocol AxisNumber: Equatable {
  init(_ v: Int)
  static func -(lhs: Self, rhs: Self) -> Self
  static func <(lhs: Self, rhs: Self) -> Bool
  static func >(lhs: Self, rhs: Self) -> Bool
  static func <=(lhs: Self, rhs: Self) -> Bool
  static func >=(lhs: Self, rhs: Self) -> Bool
}

// Conform the types that are allowed for use by ChartAxis.
extension Int64: AxisNumber {}
extension Double: AxisNumber {}
extension CGFloat: AxisNumber {}

/// Defines the minimum and maximum values of an axis.
struct ChartAxis<T: AxisNumber> : Equatable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// - Parameters:
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  public static func ==(lhs: ChartAxis<T>, rhs: ChartAxis<T>) -> Bool {
    return lhs.min == rhs.min && lhs.max == rhs.max
  }

  var min: T
  var max: T

  var length: T {
    return max - min
  }

  static var zero: ChartAxis {
    return ChartAxis<T>(min: T(0), max: T(0))
  }

  var isEmpty: Bool {
    return min == T(0) && max == T(0)
  }

  /// Tests whether a value is within the axis range.
  ///
  /// - Parameter value: A numeric value.
  /// - Returns: True if the value is within the range of the axis (inclusive), otherwise false.
  func contains(_ value: T) -> Bool {
    return value >= min && value <= max
  }
}

/// A protocol for notifying a delegate of changes to the chart. Used to keep multiple charts
/// in sync.
protocol ChartControllerDelegate: class {
  /// Tells the delegate when the chart controller is changing the visible axis, either because of
  /// scrolling or zooming.
  ///
  /// - Parameters:
  ///   - chartController: The chart controller that changed the visible x-axis.
  ///   - visibleAxis: A chart axis.
  func chartController(_ chartController: ChartController,
                       didUpdateVisibleXAxis visibleAxis: ChartAxis<Int64>)

  /// Tells the delegate when the user starts or stops dragging a chart controller.
  ///
  /// - Parameters:
  ///   - chartController: The chart controller being dragged.
  ///   - isUserScrolling: True if the chart is being scrolled by the user, otherwise false.
  func chartController(_ chartController: ChartController, scrollStateChanged isUserScrolling: Bool)

  /// Tells the delegate the chart data finished loading. This is only called if the chart
  /// controller was initialized with a sensor ID and trial ID.
  ///
  /// - Parameter chartController: The chart controller that finished loading data.
  func chartControllerDidFinishLoadingData(_ chartController: ChartController)

  /// Tells the delegate the chart controller is requesting a change to the pinned to now state.
  ///
  /// - Parameters:
  ///   - chartController: A chart controller.
  ///   - shouldPinToNow: Whether the chart should be pinned to now.
  func chartController(_ chartController: ChartController, shouldPinToNow: Bool)
}

/// Manages a ChartView and the data it will display. Use a ChartController instead of directly
/// using a ChartView.
class ChartController: NSObject, ChartViewDelegate, UIScrollViewDelegate {

  // MARK: - Nested types

  /// Represents the direction of a zoom.
  ///
  /// - none: Unknown zoom direction.
  /// - x: A zoom of the x-axis.
  /// - y: A zoom of the y-axis.
  enum ChartZoomDirection {
    case none
    case x(CGFloat)
    case y(CGFloat)
  }

  /// Represents the direction of an x-axis pan.
  ///
  /// - left: A left pan.
  /// - right: A right pan.
  enum PanXDirection {
    case left
    case right
  }

  /// Represents the type of zoom.
  ///
  /// - `in`: Zooming in.
  /// - out: Zooming out.
  /// - toFit: Zooming chart to fit all data.
  enum ZoomType {
    case `in`
    case out
    case toFit
  }

  // MARK: - Properties

  /// When creating y-axis labels for a given range of values, this is the number of labels to
  /// attempt to create.
  let preferredYLabelsCount = 5

  /// The range of y-axis labels that will not trigger a recreation of new y-axis labels.
  let idealYLabelsCount = 3...6

  var chartOptions: ChartOptions {
    didSet {
      chartView.chartOptions = chartOptions
    }
  }

  /// The range of x values visible in the scroll view. If a value is set that is beyond the data
  /// axis bounds, the data axis will be expanded.
  fileprivate(set) var visibleXAxis = ChartAxis<Int64>.zero
  fileprivate(set) var visibleYAxis = ChartAxis<Double>.zero
  fileprivate(set) var dataXAxis = ChartAxis<Int64>.zero
  fileprivate(set) var dataYAxis = ChartAxis<Double>.zero

  private var statsMinValue: Double?
  private var statsMaxValue: Double?
  private var statsAverageValue: Double?

  /// When determining the initial layout of the graph based on displayMinY and displayMaxY, the
  /// view padding to apply top and bottom.
  let displayVerticalPadding: CGFloat = 20.0

  let chartView: ChartView
  let chartData = ChartData()
  var viewDataPoints = [CGPoint]()

  /// The overall first data point, if the chart is not in observe mode. Not necessarily the first
  /// point in chartData.
  var startDataPoint: DataPoint?
  var endDataPoint: DataPoint?

  /// Whether the view should scale to display added points outside the current visible area.
  var autoScaleYAxis = true

  /// True if the chart is displaying a stream of live data, otherwise false.
  var isLive = false

  var renderStartX: CGFloat = 0
  var renderEndX: CGFloat = 0

  /// The Y values that display a line and label on the graph. Defaults to [0.0].
  var yAxisLabelPoints = [Double]() {
    didSet {
      chartView.chartContentView.addYAxisLines(count: yAxisLabelPoints.count)
      chartView.addYAxisLabels(yAxisValues: yAxisLabelPoints)
    }
  }

  var startingZoom = ChartZoomDirection.none

  var startingZoomXAxis = ChartAxis<Int64>(min: 0, max: 0)
  var startingZoomYAxis = ChartAxis(min: 0.0, max: 0.0)

  var isZooming = false

  /// The minimum visible length, used to cap zooming.
  private var minVisibleLength: Int64 {
    return Int64(Float(dataXAxis.length) * 0.1)
  }

  var recordingStartTime: Int64?

  // Constants.
  let currentPointDiameter: CGFloat = 10.0
  let startEndPointDiameter: CGFloat = 10.0

  /// The percent of the chart's vertical spread added to the visible area as padding.
  let verticalPaddingPercent = 0.1  // 10%

  /// The percent of the chart's horizontal (time) spread added to the visible area as padding.
  let horizontalPaddingPercent = 0.05  // 5%

  /// The minimum vertical chart padding, used when the spread of Y values is zero. (For example
  /// when every data point has the same Y value).
  let minimumVerticalPadding = 0.5

  /// The minimum horizontal chart padding, used for very short recordings or when a recording only
  /// has 1 data point.
  let minimumHorizontalPadding: Int64 = 500

  /// The number of data points to keep when observing or recording. 900 points is about one minute
  /// of data since most sensors record 15 points per second.
  let observedPointsToKeep = 900

  weak var delegate: ChartControllerDelegate?

  /// Whether or not the stats overlay is showing. Stats must be set with
  /// `setStats(min:max:average)` before the stats will show.
  var shouldShowStats = false {
    didSet {
      if shouldShowStats {
        showStats()
      } else {
        hideStats()
      }
    }
  }

  /// The zoom presenter determines which zoom tier to display for a given chart range.
  private var zoomPresenter: ZoomPresenter?

  /// The trial ID, if displaying a recorded trial.
  private let trialID: String?

  /// The sensor ID, if displaying a recorded trial.
  private let sensorID: String?

  /// The sensor stats, if displaying a recorded trial.
  private let sensorStats: DisplaySensorStats?

  /// The crop range, if displaying a cropped recorded trial.
  private var cropRange: ChartAxis<Int64>?

  /// When in observe placement, whether the chart is visible or not. Set externally (probably by
  /// a table view). In non-observe placement this property is always false and should not be used.
  var isObserveVisible = false

  private let sensorDataManager: SensorDataManager?

  // MARK: - ChartController

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - placementType: The type of chart depending on which view it is in.
  ///   - colorPalette: The color palette for drawing some aspects of the chart.
  ///   - trialID: A trial ID if the chart is loading recorded data.
  ///   - sensorID: A sensor ID if the chart is loading recorded data.
  ///   - sensorStats: The sensor stats.
  ///   - cropRange: A crop range.
  ///   - notes: An array of notes to display on the chart.
  ///   - sensorDataManager: The sensor data manager.
  init(placementType: ChartPlacementType,
       colorPalette: MDCPalette?,
       trialID: String? = nil,
       sensorID: String? = nil,
       sensorStats: DisplaySensorStats? = nil,
       cropRange: ChartAxis<Int64>? = nil,
       notes: [DisplayNote]? = nil,
       sensorDataManager: SensorDataManager? = nil) {
    let lineColor = colorPalette?.tint600 ?? MDCPalette.blue.tint600
    chartOptions = ChartOptions(placementType: placementType, lineColor: lineColor)
    chartView = ChartView(chartOptions: chartOptions)
    chartView.clipsToBounds = true
    self.trialID = trialID
    self.sensorID = sensorID
    self.sensorStats = sensorStats
    isLive = placementType == .observe
    self.sensorDataManager = sensorDataManager

    if let trialStats = sensorStats, placementType != .observe {
      zoomPresenter = ZoomPresenter(sensorStats: trialStats)
    }

    super.init()
    chartView.pinchGestureRecognizer.addTarget(self,
                                               action: #selector(chartDidPinch(gestureRecognizer:)))
    chartView.scrollView.delegate = self
    chartView.scrollView.addGestureRecognizer(chartView.pinchGestureRecognizer)
    chartView.delegate = self
    configureChartViewAccessibility()

    if let notes = notes {
      chartData.addNotes(notes)
    }

    if trialID != nil && sensorID != nil && sensorStats != nil && sensorDataManager != nil {
      resetAndloadData(cropRange: cropRange)
    }

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(downloadedSensorData),
                                           name: .driveSyncManagerDownloadedSensorData,
                                           object: nil)
  }

  /// Loads data and resets the view to show the entire dataset.
  ///
  /// - Parameters:
  ///   - cropRange: The crop range to load, if applicable.
  ///   - completion: A closure called when the load is complete.
  func resetAndloadData(cropRange: ChartAxis<Int64>?, completion: (() -> Void)? = nil) {
    dataXAxis = .zero
    dataYAxis = .zero
    visibleXAxis = .zero
    visibleYAxis = .zero
    self.cropRange = cropRange
    let tier = zoomPresenter?.updateTier(forVisibleDuration: cropRange?.length) ?? 0
    loadData(range: cropRange, resolutionTier: tier, completion: completion)
  }

  /// Loads data for the chart to display. Replaces any existing data.
  ///
  /// - Parameters:
  ///   - range: The time range to load, optional. If no range is set the entire recorded range
  ///            will be loaded.
  ///   - resolutionTier: The resolution tier to load.
  ///   - completion: A block called when the loading is finished.
  func loadData(range: ChartAxis<Int64>?,
                resolutionTier: Int,
                completion: (() -> Void)? = nil) {
    guard let sensorID = sensorID, let trialID = trialID,
        let sensorDataManager = sensorDataManager else {
      completion?()
      return
    }

    chartView.showSpinner()
    chartData.removeAllDataPoints()

    sensorDataManager.fetchSensorData(
        forSensorID: sensorID,
        trialID: trialID,
        resolutionTier: resolutionTier,
        startTimestamp: range?.min,
        endTimestamp: range?.max,
        completion: { (dataPoints) in
          DispatchQueue.main.async {
            self.chartView.hideSpinner()
            if let dataPoints = dataPoints {
              self.chartData.addDataPoints(dataPoints)
              self.startDataPoint = self.chartData.dataPoints.first
              self.endDataPoint = self.chartData.dataPoints.last
              self.updateAxesForChartData()
              self.updateView()
            }
            self.delegate?.chartControllerDidFinishLoadingData(self)
            completion?()
          }
    })
  }

  /// Uses the visible axes and data axes to set the scroll view's content size and content offset.
  func updateViewForAxes() {
    // Make sure chartView subviews such as the scroll view have the proper layout first.
    chartView.layoutIfNeeded()

    // Use the data axis to determine content size.
    guard let contentWidth = viewPointX(fromDataPointX: dataXAxis.max),
        let contentHeight = viewPointY(fromDataPointY: dataYAxis.max),
        let contentOffset = viewPoint(fromDataPoint: DataPoint(x: visibleXAxis.min,
                                                               y: visibleYAxis.max)) else { return }

    chartView.scrollView.contentSize = CGSize(width: contentWidth,
                                              height: contentHeight)
    chartView.scrollView.contentOffset = contentOffset
  }

  /// Uses the existing labels and the current visible y-axis range to determine which y-axis labels
  /// to display.
  func updateYAxisLabels() {
    // With zoom scale clamping this should never happen, but protect against it just in case.
    // TODO: clamp zoom scale.
    let displayMinY = visibleYAxis.min
    let displayMaxY = visibleYAxis.max
    guard displayMaxY > displayMinY else {
      return
    }

    // Extrapolate the current label interval to see how many labels would display. This value
    // determines if all labels should be recreated, or added at the current increment.
    let potentialLabelCount = potentialLabelCountWithIntervalFrom(yAxisLabelPoints,
                                                                  minShown: displayMinY,
                                                                  maxShown: displayMaxY)
    if !idealYLabelsCount.contains(potentialLabelCount) {
      // If the potential points for the current increment is not within the ideal count, recreate
      // new y-axis labels.
      yAxisLabelPoints.removeAll()

      let range = displayMaxY - displayMinY

      // If there is no visible range, return.
      guard range > 0 else {
        return
      }

      // Given the preferred number of labels, determine the increment between labels. Ceil the
      // increment so y-axis labels fall on integers.
      let increment = ceil(range / Double(preferredYLabelsCount))
      // Get the first integer that's greater than or equal to yMin as the bottom most axis label.
      var label = ceil(displayMinY)

      // Starting at the integer value of yMin, add labels at the increment value.
      repeat {
        yAxisLabelPoints.append(label)
        label += increment
      } while label < displayMaxY
    } else {
      // If the potential labels are within the ideal number of labels, add any labels that may
      // not currently be visible.

      let increment = yAxisLabelPoints[1] - yAxisLabelPoints[0]

      var nextSmallerLabel = yAxisLabelPoints[0] - increment
      while (nextSmallerLabel > displayMinY) {
        yAxisLabelPoints.insert(nextSmallerLabel, at: 0)
        nextSmallerLabel -= increment
      }
      var nextLargerLabel = yAxisLabelPoints[yAxisLabelPoints.count - 1] + increment
      while (nextLargerLabel < displayMaxY) {
        yAxisLabelPoints.append(nextLargerLabel)
        nextLargerLabel += increment
      }
    }
  }

  /// Given a set of label points, find the interval and determine the max number of labels that
  /// would be visible in the given range. This value is helpful in determining whether the axis
  /// labels should be recreated or not.
  ///
  /// - Parameters:
  ///   - yAxisPoints: An array of axis label points.
  ///   - yMinShown: The minimum displayed axis value.
  ///   - yMaxShown: The maximum displayed axis value.
  /// - Returns: The total number of labels that could be displayed.
  func potentialLabelCountWithIntervalFrom(_ axisLabels: [Double],
                                           minShown: Double,
                                           maxShown: Double) -> Int {
    // If there are 1 or 0 labels, we need to re-show anyway, so just return 0.
    guard let lastAxisLabel = axisLabels.last, axisLabels.count > 1 else {
      return 0
    }

    let increment = axisLabels[1] - axisLabels[0]
    guard increment > 0 else { return 0 }


    let startIndex = Int(exactly: floor((minShown - axisLabels[0]) / Double(increment + 1)))
    let endIndexCeil = ceil((maxShown - lastAxisLabel) / increment)
    let endIndex = Int(exactly: endIndexCeil + Double(axisLabels.count - 1))

    if let startIndex = startIndex, let endIndex = endIndex {
      // If percentage is 1.0 index can be beyond count so clamp it.
      return endIndex - startIndex
    } else {
      return 0
    }
  }

  /// Returns the closest data point to a given timestamp.
  ///
  /// - Parameter timestamp: The timestamp to search for.
  /// - Returns: A data point that is closest to this timestamp.
  func closestDataPointToTimestamp(_ timestamp: Int64) -> DataPoint? {
    return chartData.closestDataPointToTimestamp(timestamp)
  }

  /// Sets the stats overlay values. To show them set `shouldShowStats` to true.
  ///
  /// - Parameters:
  ///   - min: The min value.
  ///   - max: The max value.
  ///   - average: The average value.
  func setStats(min: Double, max: Double, average: Double) {
    statsMinValue = min
    statsMaxValue = max
    statsAverageValue = average
    if shouldShowStats {
      showStats()
    }
  }

  // MARK: - Point conversion

  /// Returns an x-axis point in the view's coordinate system for a data point. If the view is not
  /// fully configured or correctly sized this can result in a NaN value due to dividing by zero.
  /// Therefore the result is an optional.
  ///
  /// - Parameter dataPoint: A data point.
  /// - Returns: An optional view point.
  func viewPoint(fromDataPoint dataPoint: DataPoint) -> CGPoint? {
    guard let x = viewPointX(fromDataPointX: dataPoint.x),
        let y = viewPointY(fromDataPointY: dataPoint.y) else { return nil }

    return CGPoint(x: x, y: y)
  }

  /// Returns an x-axis point in the view's coordinate system for a data point. If the view is not
  /// fully configured or correctly sized this can result in a NaN value due to dividing by zero.
  /// Therefore the result is an optional.
  ///
  /// - Parameter dataPointX: A data point x value.
  /// - Returns: An optional float.
  func viewPointX(fromDataPointX dataPointX: Int64) -> CGFloat? {
    let point = chartView.scrollView.bounds.size.width /
        CGFloat(visibleXAxis.length) *
        CGFloat(dataPointX - dataXAxis.min)
    return point.isNaN || point.isInfinite ? nil : point
  }

  /// Returns a y-axis point in the view's coordinate system for a data point. If the view is not
  /// fully configured or correctly sized this can result in a NaN value due to dividing by zero.
  /// Therefore the result is an optional.
  ///
  /// - Parameter dataPointX: A data point y value.
  /// - Returns: An optional float.
  func viewPointY(fromDataPointY dataPointY: Double) -> CGFloat? {
    let point = chartView.scrollView.bounds.size.height /
        CGFloat(visibleYAxis.length) *
        CGFloat(dataYAxis.max - dataPointY)
    return point.isNaN || point.isInfinite ? nil : point
  }

  func dataPointX(fromViewPointX viewPointX: CGFloat) -> Int64 {
    return Int64(viewPointX) * (visibleXAxis.length) /
        Int64(chartView.scrollView.bounds.size.width) + dataXAxis.min
  }

  func dataPointY(fromViewPointY viewPointY: CGFloat) -> Double {
    return dataYAxis.max - Double(viewPointY) * (visibleYAxis.max - visibleYAxis.min) /
        Double(chartView.scrollView.bounds.size.height)
  }

  func viewPoints(fromDataPoints dataPoints: [DataPoint]) -> [CGPoint]? {
    var viewPoints = [CGPoint]()
    for dataPoint in dataPoints {
      // Abort and return nil if any view points are invalid.
      guard let viewPoint = viewPoint(fromDataPoint: dataPoint) else { return nil }
      viewPoints.append(viewPoint)
    }
    return viewPoints
  }

  /// Returns an array of view points for the array of data points. Only creates the minimum number
  /// of view points necessary for display based on the display size of the chart.
  ///
  /// - Parameter dataPoints: An array of data points.
  /// - Returns: An array of view points. Returns nil if the view isn't ready for display.
  private func viewPointsForMinimumResolution(
      fromDataPoints dataPoints: [DataPoint]) -> [CGPoint]? {
    guard chartView.bounds.width > 0 else { return nil }

    // The number of data points that exist for each display point. The resulting number of view
    // points will be double this number since we record a min and a max.
    let points = Int(exactly: ceil(CGFloat(dataPoints.count) / chartView.bounds.width))
    guard let pointsPerDisplayPoint = points else {
      return nil
    }

    var nextMax: DataPoint?
    var nextMin: DataPoint?

    var viewPoints = [CGPoint]()
    for (index, dataPoint) in dataPoints.enumerated() {
      // Establish a max
      if let max = nextMax {
        if dataPoint.y > max.y {
          nextMax = dataPoint
        }
      } else {
        nextMax = dataPoint
      }

      // Establish a min
      if let min = nextMin {
        if dataPoint.y < min.y {
          nextMin = dataPoint
        }
      } else {
        nextMin = dataPoint
      }

      // Record view points per the calculated display interval.
      if index % pointsPerDisplayPoint == 0 {
        // Abort and return nil if any view points are invalid.
        guard let viewPointMax = viewPoint(fromDataPoint: nextMax!) else { return nil }
        guard let viewPointMin = viewPoint(fromDataPoint: nextMin!) else { return nil }

        // Add them in the correct order.
        if viewPointMax.x < viewPointMin.x {
          viewPoints.append(viewPointMax)
          viewPoints.append(viewPointMin)
        } else {
          viewPoints.append(viewPointMin)
          viewPoints.append(viewPointMax)
        }

        nextMax = nil
        nextMin = nil
      }
    }
    return viewPoints
  }

  func updateAxesForChartData() {
    guard let firstX = chartData.firstX,
        let lastX = chartData.lastX,
        let lengthX = chartData.lengthX,
        let minY = chartData.minY,
        let maxY = chartData.maxY,
        let lengthY = chartData.lengthY else {
      dataXAxis = .zero
      dataYAxis = .zero
      return
    }

    let horizontalPadding = max(Int64(Double(lengthX) * horizontalPaddingPercent),
                                minimumHorizontalPadding)
    let verticalPadding = max(lengthY * verticalPaddingPercent, minimumVerticalPadding)

    // Always set the data x axis to the limits of the data.
    dataXAxis = ChartAxis(min: firstX - horizontalPadding, max: lastX + horizontalPadding)

    // Only set the other axes if they are not set, in order to preserve any existing zoom scale.
    if dataYAxis.isEmpty {
      dataYAxis = ChartAxis(min: minY - verticalPadding, max: maxY + verticalPadding)
    }
    if visibleXAxis.isEmpty {
      visibleXAxis = dataXAxis
    }
    if visibleYAxis.isEmpty {
      visibleYAxis = dataYAxis
    }
  }

  /// Adds a single data point to the existing chart data.
  ///
  /// - Parameter dataPoint: A data point.
  func addDataPointToEnd(_ dataPoint: DataPoint) {
    guard chartOptions.placementType == .observe else { return }

    // Add the data point.
    chartData.addDataPoint(dataPoint)

    // If visible Y axis is not set, establish a reasonable visible range based on this data point.
    // A visible Y axis is required for view coordinate math.
    if visibleYAxis.isEmpty {
      var yMin = floor(dataPoint.y) - 1
      var yMax = ceil(dataPoint.y) + 1
      let verticalPadding = (yMax - yMin) * verticalPaddingPercent
      yMax += verticalPadding
      yMin -= verticalPadding
      visibleYAxis = ChartAxis(min: yMin, max: yMax)
      dataYAxis = visibleYAxis
      updateYAxisLabels()
    }

    guard let point = viewPoint(fromDataPoint: dataPoint) else {
      return
    }

    viewDataPoints.append(point)

    // Purge old data if necessary. Improves performance when observing or recording.
    if chartOptions.isPinnedToNow && chartData.dataPoints.count > observedPointsToKeep {
      let trimAmount = chartData.dataPoints.count - observedPointsToKeep
      let removeRange = 0...trimAmount
      chartData.dataPoints.removeSubrange(removeRange)
      viewDataPoints.removeSubrange(removeRange)
    }

    if chartView.scrollView.isTracking || isZooming {
      return
    }

    // If the newly added point is out of range of the visible Y range, scale the y-axis so it fits.
    // Only do this if the chart has a non-zero height to avoid bad scale calculations.

    let verticalThreshold = visibleYAxis.length * verticalPaddingPercent
    let maxThreshold = visibleYAxis.max - verticalThreshold
    let minThreshold = visibleYAxis.min + verticalThreshold

    if autoScaleYAxis && (dataPoint.y < minThreshold || dataPoint.y > maxThreshold) {
      if dataPoint.y < minThreshold {
        visibleYAxis.min = dataPoint.y - verticalThreshold
      } else {
        visibleYAxis.max = dataPoint.y + verticalThreshold
      }
      dataYAxis = visibleYAxis

      updateYAxisLabels()
      recreateViewPoints()
      chartView.setNeedsLayout()
    }

    if (!chartView.scrollView.isUserScrolling) {
      updateViewForAxes()
    }
    buildPath()
  }

  func resetData() {
    chartData.removeAll()
    viewDataPoints.removeAll()
    yAxisLabelPoints.removeAll()
    dataXAxis = .zero
    dataYAxis = .zero
    visibleXAxis = .zero
    visibleYAxis = .zero
    renderStartX = 0
    renderEndX = 0
    chartView.chartSize = CGSize(width: 0, height: chartView.chartSize.height)
  }

  func buildPath() {
    // Only draw the path in observe when the view is visible, to reduce CPU load.
    guard chartOptions.placementType != .observe || isObserveVisible else { return }

    // A chart with non-zero size is needed for proper paging calculations.
    guard chartView.frame.size.width > 0 && chartView.frame.size.height > 0 else { return }

    let pageBuffer: CGFloat = 2.0
    let pageSize = chartView.frame.size
    let currentPage = floor(chartView.scrollView.contentOffset.x / pageSize.width)
    let totalPages = ceil(chartView.scrollView.contentSize.width / pageSize.width)
    let firstPage = currentPage - pageBuffer
    let lastPage = currentPage + pageBuffer
    let startX = floor(firstPage > 0 ? firstPage * pageSize.width : 0)
    let chartViewContentWidth = chartView.scrollView.contentSize.width
    let endX = ceil(lastPage < totalPages ? lastPage * pageSize.width : chartViewContentWidth)

    // TODO: Handle Y-axis paging/zooming, similar to how we handle the X-axis.
    // If render start and end haven't changed, no need to build a new line
    let renderRangeChanged = startX != renderStartX || endX != renderEndX

    var lastPointWithinRenderRange = true
    if isLive, let lastPoint = viewDataPoints.last {
      lastPointWithinRenderRange = lastPoint.x > renderStartX && lastPoint.x < renderEndX
    }

    // If render range hasn't changed and the last data point is not within the render range,
    // don't build a new line.
    if !renderRangeChanged && !lastPointWithinRenderRange {
      return
    }

    renderStartX = startX
    renderEndX = endX

    // TODO: could also try reusing same bezier path?
    let newLine = UIBezierPath()

    for point in viewDataPoints {
      // Stop when end is reached
      if point.x > renderEndX {
        break
      }

      // Add points that fall after start x
      if point.x >= renderStartX {
        if newLine.isEmpty {
          newLine.move(to: point)
        } else {
          newLine.addLine(to: point)
        }
      }
    }

    chartView.chartContentView.dataLine = newLine

    buildDots()
    if chartOptions.isYAxisVisible {
      buildYAxisLines()
    }
    buildRecordingFeatures()
    buildNoteDots()
  }

  // Draws the start, end, and current point dots.
  func buildDots() {
    // Draws a dot shape at the given data point for the given layer.
    func setPathForDataPoint(_ dataPoint: DataPoint,
                             shapeLayer: CAShapeLayer) {
      guard let viewPoint = viewPoint(fromDataPoint: dataPoint) else { return }
      setPathForViewPoint(viewPoint, shapeLayer: shapeLayer)
    }

    func setPathForViewPoint(_ viewPoint: CGPoint, shapeLayer: CAShapeLayer) {
      if viewPoint.x >= renderStartX && viewPoint.x <= renderEndX {
        shapeLayer.path =
            dotPath(forDiameter: startEndPointDiameter, at: viewPoint).cgPath
        shapeLayer.isHidden = false
      } else {
        shapeLayer.isHidden = true
      }
    }

    switch chartOptions.placementType {
    case .observe:
      // Draws the current data point in observe mode.
      if let lastPoint = viewDataPoints.last {
        // Not flooring the dot points to avoid a step-like animation when the dot moves live.
        setPathForViewPoint(lastPoint,
                            shapeLayer: chartView.chartContentView.currentPointLayer)
      }
    case .runReview:
      // Draws the first data point for review mode.
      if let startDataPoint = startDataPoint {
        setPathForDataPoint(startDataPoint, shapeLayer: chartView.chartContentView.startPointLayer)
      }

      // Draws the last data point for review mode.
      if let endDataPoint = endDataPoint {
        setPathForDataPoint(endDataPoint, shapeLayer: chartView.chartContentView.endPointLayer)
      }
    case .previewReview: break // No dots in preview review.
    }
  }

  func buildNoteDots() {
    chartView.clearNoteDots()
    for notePoint in chartData.noteDataPoints {
      guard let point = viewPoint(fromDataPoint: notePoint),
          point.x >= renderStartX && point.x <= renderEndX else { continue }
      chartView.addNoteDot(at: point)
    }
  }

  // Draws red background behind recording region and a red line at the recording start time.
  func buildRecordingFeatures() {
    guard let recordingStartTime = recordingStartTime else {
      chartView.chartContentView.recordingBackgroundLayer.isHidden = true
      chartView.chartContentView.recordingStartLine.isHidden = true
      return
    }

    // Only draw if recording start is before the end of the render region.
    guard let recordingStartViewPosition = viewPointX(fromDataPointX: recordingStartTime),
        recordingStartViewPosition < renderEndX else { return }

    let recordingX = max(recordingStartViewPosition, renderStartX)
    let recordingWidth = renderEndX - recordingX
    let recordingRect = CGRect(x: recordingX,
                               y: 0,
                               width: recordingWidth,
                               height: chartView.bounds.size.height)
    chartView.chartContentView.recordingBackgroundLayer.path =
        UIBezierPath(rect: recordingRect).cgPath

    let recordingLinePath = UIBezierPath()
    recordingLinePath.move(to: CGPoint(x: recordingStartViewPosition, y: 0))
    recordingLinePath.addLine(to: CGPoint(x: recordingStartViewPosition,
                                          y: chartView.bounds.size.height))
    chartView.chartContentView.recordingStartLine.path = recordingLinePath.cgPath

    chartView.chartContentView.recordingBackgroundLayer.isHidden = false
    chartView.chartContentView.recordingStartLine.isHidden = false
  }

  func dotPath(forDiameter diameter: CGFloat,
               at viewPoint: CGPoint) -> UIBezierPath {
    let origin = CGPoint(x: viewPoint.x - diameter / 2,
                         y: viewPoint.y - diameter / 2)
    let size = CGSize(width: startEndPointDiameter,
                      height: startEndPointDiameter)
    return UIBezierPath(ovalIn: CGRect(origin: origin, size: size))
  }

  func buildYAxisLines() {
    var index = 0
    for yPoint in yAxisLabelPoints {
      let dataPoint = DataPoint(x: 0, y: yPoint)
      guard let viewPoint = self.viewPoint(fromDataPoint: dataPoint) else { continue }

      let yLine = UIBezierPath()
      let yLayer = chartView.chartContentView.yAxisLineLayers[index]

      yLine.move(to: CGPoint(x: renderStartX, y: viewPoint.y))
      yLine.addLine(to: CGPoint(x: renderEndX, y: viewPoint.y))
      yLayer.path = yLine.cgPath

      index += 1
    }
  }

  func recreateViewPoints() {
    let viewPoints: [CGPoint]?
    if chartOptions.placementType == .previewReview {
      viewPoints = viewPointsForMinimumResolution(fromDataPoints: chartData.dataPoints)
    } else {
      viewPoints = self.viewPoints(fromDataPoints: chartData.dataPoints)
    }

    guard let points = viewPoints else {
      return
    }

    viewDataPoints = points
    if let lastViewPoint = viewDataPoints.last {
      chartView.chartSize = CGSize(width: lastViewPoint.x, height: chartView.chartSize.height)
    }
  }

  func addNote(_ note: DisplayNote) {
    chartData.addNote(note)
    renderStartX = 0
    renderEndX = 0
    buildPath()
  }

  func removeNote(withID noteID: String, atTimestamp timestamp: Int64) {
    chartData.removeNote(withID: noteID, atTimestamp: timestamp)
    renderStartX = 0
    renderEndX = 0
    buildPath()
  }

  /// Removes all notes from the chart.
  func removeAllNotes() {
    chartData.removeAllNotes()
    renderStartX = 0
    renderEndX = 0
    buildPath()
  }

  // MARK: - UIGestureRecognizer

  @objc func chartDidPinch(gestureRecognizer: UIPinchGestureRecognizer) {
    guard chartOptions.canZoom else {
      return
    }

    // Gesture ended, reset zooming vars and return.
    if gestureRecognizer.state == .ended || gestureRecognizer.numberOfTouches < 2 {
      startingZoom = .none
      startingZoomXAxis = .zero
      startingZoomYAxis = .zero
      isZooming = false
      return
    }

    let firstTouch = gestureRecognizer.location(ofTouch: 0, in: chartView)
    let secondTouch = gestureRecognizer.location(ofTouch: 1, in: chartView)
    let xDiff = abs(firstTouch.x - secondTouch.x)
    let yDiff = abs(firstTouch.y - secondTouch.y)

    // Gesture began, establish initial zoom values to calculate changes.
    if gestureRecognizer.state == .began {
      isZooming = true
      startingZoomXAxis = visibleXAxis
      startingZoomYAxis = visibleYAxis

      if xDiff > yDiff {
        startingZoom = .x(xDiff)
      } else {
        startingZoom = .y(yDiff)
      }
    }

    switch startingZoom {
    case .none:
      return
    case .x(let xStartDiff):
      guard chartOptions.canZoomX else { return }

      let xChange = Int64(xStartDiff - xDiff) * visibleXAxis.length /
          Int64(chartView.scrollView.bounds.size.width)
      var newVisibleXMin = startingZoomXAxis.min - xChange / 2
      var newVisibleXMax = startingZoomXAxis.max + xChange / 2

      let newRange = newVisibleXMax - newVisibleXMin
      let availableRange = dataXAxis.length

      // If the new range falls outside the data bounds, adjust the values.
      if newVisibleXMin < dataXAxis.min && newRange <= availableRange {
        // new visible range goes beyond total data minimum range but has room.
        newVisibleXMin = dataXAxis.min
        newVisibleXMax = dataXAxis.min + newRange
      } else if newVisibleXMax > dataXAxis.max && newRange <= availableRange {
        newVisibleXMin = dataXAxis.max - newRange
        newVisibleXMax = dataXAxis.max
      } else if newVisibleXMin < dataXAxis.min && newVisibleXMax > dataXAxis.max {
        newVisibleXMin = dataXAxis.min
        newVisibleXMax = dataXAxis.max
      }

      // Check to see if a new resolution tier of data needs to be loaded.
      if let zoomPresenter = zoomPresenter {
        let currentTier = zoomPresenter.currentTier
        let newTier = zoomPresenter.updateTier(forVisibleDuration: newVisibleXMax - newVisibleXMin)
        if newTier != currentTier {
          // Toggling the enabled state of a gesture effectively aborts the gesture.
          gestureRecognizer.isEnabled = false
          gestureRecognizer.isEnabled = true
          loadData(range: cropRange, resolutionTier: newTier)
          return
        }
      }

      visibleXAxis = ChartAxis(min: newVisibleXMin, max: newVisibleXMax)
    case .y(let yStartDiff):
      // Turn off auto scalling if the user manually zooms the y-axis.
      autoScaleYAxis = false
      guard chartOptions.canZoomY else { return }
      let yChange = Double(yStartDiff - yDiff) * (visibleYAxis.max - visibleYAxis.min) /
          Double(chartView.scrollView.bounds.size.height)
      let visibleYMin = startingZoomYAxis.min - yChange / 2
      let visibleYMax = startingZoomYAxis.max + yChange / 2
      let visibleSize = visibleYMax - visibleYMin
      if visibleSize >= 1.0 {
        visibleYAxis = ChartAxis(min: visibleYMin, max: visibleYMax)
        dataYAxis = visibleYAxis
      }
    }

    updateView()
    delegate?.chartController(self, didUpdateVisibleXAxis: visibleXAxis)
  }

  func updateView() {
    updateViewForAxes()
    updateYAxisLabels()
    if chartOptions.isYAxisVisible {
      buildYAxisLines()
    }
    recreateViewPoints()
    buildPath()
    if shouldShowStats {
      showStats()
    }
    chartView.setNeedsLayout()
  }

  // MARK: - UIScrollViewDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard !isZooming else { return }

    // Don't calculate visible axes or update delegate unless user is scrolling. If contentOffset
    // was set externally there is no need to do any of this.
    guard scrollView.isUserScrolling else {
      return
    }

    // TODO: Update Y axis once Y scrolling is supported.
    let contentOffsetX = chartView.scrollView.contentOffset.x
    let xMin = dataPointX(fromViewPointX: contentOffsetX)

    // Use existing length to calculate max. If contentOffsetX + scroll width is used, integer
    // conversion during the round trip calculation can slowly erode the length value.
    let xMax = xMin + visibleXAxis.length
    visibleXAxis = ChartAxis(min: xMin, max: xMax)
    buildPath()

    delegate?.chartController(self, didUpdateVisibleXAxis: visibleXAxis)
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    delegate?.chartController(self, scrollStateChanged: true)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    // If decelerating, wait until decelerating has ended to consider the drag movement changed.
    if (!decelerate) {
      delegate?.chartController(self, scrollStateChanged: false)
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    delegate?.chartController(self, scrollStateChanged: false)
  }

  // MARK: - ChartViewDelegate

  func yPositionForLabel(atIndex labelIndex: Int) -> CGFloat? {
    let dataPointY = yAxisLabelPoints[labelIndex]
    return viewPointY(fromDataPointY: dataPointY)
  }

  func chartViewFrameSizeDidChange() {
    updateViewForAxes()
    recreateViewPoints()
    updateYAxisLabels()
    buildPath()
    if shouldShowStats {
      showStats()
    }
  }

  /// Called when the visible axis was changed externally. Visible axis should align to the
  /// new value.
  func setXAxis(visibleXAxis: ChartAxis<Int64>, dataXAxis: ChartAxis<Int64>) {
    guard visibleXAxis.max > visibleXAxis.min, dataXAxis.max > dataXAxis.min else { return }

    self.visibleXAxis = visibleXAxis
    self.dataXAxis = dataXAxis

    updateViewForAxes()
  }

  /// Updates the visible Y axis.
  ///
  /// - Parameter visibleYAxis: The visible Y axis to update to.
  func setVisibleYAxis(_ visibleYAxis: ChartAxis<Double>) {
    self.visibleYAxis = visibleYAxis
    self.dataYAxis = visibleYAxis
    updateViewForAxes()
  }

  // MARK: - Programmatic zoom and pan

  /// Pans the chart's x-axis in the given direction by a percent of the current visible area.
  /// Returns the number of milliseconds that the chart was panned.
  ///
  /// - Parameters:
  ///   - direction: The direction to pan.
  ///   - percent: A percentage of the current visible area to pan.
  /// - Returns: The number of milliseconds panned. Returns zero if the chart could not be panned.
  func panXAxis(_ direction: PanXDirection, byPercent percent: Float) -> Int64 {
    guard chartOptions.canScrollX else { return 0 }

    let visibleLength = visibleXAxis.length
    let panAmount = Int64(Float(visibleLength) * percent)

    var pannedXAxis: ChartAxis<Int64>
    switch direction {
    case .left:
      let newMin = max(visibleXAxis.min - panAmount, dataXAxis.min)
      pannedXAxis = ChartAxis(min: newMin, max: newMin + visibleLength)
    case .right:
      let newMax = min(visibleXAxis.max + panAmount, dataXAxis.max)
      pannedXAxis = ChartAxis(min: newMax - visibleLength, max: newMax)
    }

    let currentVisibleXAxisMin = visibleXAxis.min
    visibleXAxis = pannedXAxis
    updateView()
    delegate?.chartController(self, didUpdateVisibleXAxis: visibleXAxis)

    return pannedXAxis.min - currentVisibleXAxisMin
  }

  /// Zooms the chart's x-axis in the given direction by a percent of the current visible area.
  /// Returns the resulting zoom percentage.
  ///
  /// - Parameters:
  ///   - zoomType: The type of zoom.
  ///   - percent: The percent of the current visible area to zoom. Ignored if zooming to fit.
  /// - Returns: The resulting zoom percentage.
  @discardableResult func zoomXAxis(_ zoomType: ZoomType, byPercent percent: Float) -> Float {
    let dataLength = Float(dataXAxis.length)
    var percentZoomed: Float {
      return Float(visibleXAxis.length) / dataLength
    }

    guard chartOptions.canZoomX else {
      return percentZoomed
    }

    // If zooming to fit, set visible axis to total data axis.
    if zoomType == .toFit {
      visibleXAxis = dataXAxis
      updateView()
      delegate?.chartController(self, didUpdateVisibleXAxis: visibleXAxis)
      return 1.0
    }

    // Zoom by a percentage of the total data length.
    let zoomAmount = Int64(dataLength * percent)  * (zoomType == .in ? 1 : -1)

    let currentVisibleXAxis = visibleXAxis
    // TODO: If playhead is visible, zoom to be relative to it. http://b/67907819
    var newMin = max(currentVisibleXAxis.min + (zoomAmount / 2), dataXAxis.min)
    var newMax = min(currentVisibleXAxis.max - (zoomAmount / 2), dataXAxis.max)

    // New zoom is less than allowed max zoom.
    if newMax - newMin <= minVisibleLength {
      let diff = (currentVisibleXAxis.length - minVisibleLength) / 2
      newMin = currentVisibleXAxis.min - diff
      newMax = newMin + minVisibleLength
    }

    visibleXAxis = ChartAxis(min: newMin,
                             max: newMax)
    updateView()
    delegate?.chartController(self, didUpdateVisibleXAxis: visibleXAxis)

    return percentZoomed
  }

  // MARK: - Private

  private func showStats() {
    guard let statsMinValue = statsMinValue,
      let viewMin = viewPointY(fromDataPointY: statsMinValue),
      let statsMaxValue = statsMaxValue,
      let viewMax = viewPointY(fromDataPointY: statsMaxValue),
      let statsAverageValue = statsAverageValue,
      let viewAverage = viewPointY(fromDataPointY: statsAverageValue) else {
        return
    }
    chartView.statsOverlayView.showStats(min: viewMin, max: viewMax, average: viewAverage)
  }

  private func hideStats() {
    chartView.statsOverlayView.hideStats()
  }

  // MARK: ChartView Accessibility Actions

  private func configureChartViewAccessibility() {
    guard chartOptions.placementType != .previewReview else { return }

    chartView.isAccessibilityElement = true
    chartView.accessibilityTraits = .allowsDirectInteraction
    chartView.accessibilityLabel = chartOptions.placementType == .observe ?
        String.chartLiveContentDescription : String.chartRecordedContentDescription

    let panLeftAction = UIAccessibilityCustomAction(name: String.chartPanLeftContentDescription,
                                                    target: self,
                                                    selector: #selector(accessibilityPanLeft))
    let panRightAction = UIAccessibilityCustomAction(name: String.chartPanRightContentDescription,
                                                     target: self,
                                                     selector: #selector(accessibilityPanRight))
    let zoomInAction = UIAccessibilityCustomAction(name: String.chartZoomInContentDescription,
                                                   target: self,
                                                   selector: #selector(accessibilityZoomIn))
    let zoomOutAction = UIAccessibilityCustomAction(name: String.chartZoomOutContentDescription,
                                                    target: self,
                                                    selector: #selector(accessibilityZoomOut))
    let zoomToFitAction =
        UIAccessibilityCustomAction(name: String.chartZoomToFitContentDescription,
                                    target: self,
                                    selector: #selector(accessibilityZoomToFit))
    let pinToNowAction =
        UIAccessibilityCustomAction(name: String.btnResetDescription,
                                    target: self,
                                    selector: #selector(accessibilityPinToNow))
    if chartOptions.placementType == .observe {
      chartView.accessibilityCustomActions =
          [panLeftAction, panRightAction, pinToNowAction]
    } else {
      chartView.accessibilityCustomActions =
          [zoomInAction, zoomOutAction, panRightAction, panLeftAction, zoomToFitAction]
    }
  }

  private func accessibilityPanX(_ direction: PanXDirection) {
    delegate?.chartController(self, shouldPinToNow: false)
    let millisecondsPanned = panXAxis(direction, byPercent: 0.1)
    let timeInterval = TimeInterval(millisecondsPanned / 1000)
    let announcementString =
        "\(String.chartPannedContentDescription) \(timeInterval.accessibleDurationString)"
    UIAccessibility.post(notification: .announcement, argument: announcementString)
  }

  @objc private func accessibilityPanLeft() {
    accessibilityPanX(.left)
  }

  @objc private func accessibilityPanRight() {
    accessibilityPanX(.right)
  }

  @objc private func accessibilityZoomIn() {
    let zoomPercent = zoomXAxis(.in, byPercent: 0.1)
    if let viewPercent =
        NumberFormatter.percentFormatter.string(from: NSNumber(value: zoomPercent)) {
      let announcementString = "\(String.chartZoomLevelContentDescription) \(viewPercent)"
      UIAccessibility.post(notification: .announcement, argument: announcementString)
    }
  }

  @objc private func accessibilityZoomOut() {
    let zoomPercent = zoomXAxis(.out, byPercent: 0.1)
    if let viewPercent =
        NumberFormatter.percentFormatter.string(from: NSNumber(value: zoomPercent)) {
      let announcementString = "\(String.chartZoomLevelContentDescription) \(viewPercent)"
      UIAccessibility.post(notification: .announcement, argument: announcementString)
    }
  }

  @objc private func accessibilityZoomToFit() {
    zoomXAxis(.toFit, byPercent: 0)
    if let hundredPercent = NumberFormatter.percentFormatter.string(from: 1) {
      let announcementString = "\(String.chartZoomLevelContentDescription) \(hundredPercent)"
      UIAccessibility.post(notification: .announcement, argument: announcementString)
    }
  }

  @objc private func accessibilityPinToNow() {
    delegate?.chartController(self, shouldPinToNow: true)
  }

  // MARK: -  Notifications

  @objc private func downloadedSensorData(notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.downloadedSensorData(notification: notification)
      }
      return
    }

    guard let trialIDs =
        notification.userInfo?[DriveSyncUserInfoConstants.downloadedSensorDataTrialIDsKey] as?
            [String] else {
      return
    }

    if let trialID = trialID, trialIDs.contains(trialID) {
      resetAndloadData(cropRange: cropRange)
    }
  }

}
