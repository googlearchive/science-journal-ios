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

protocol TimeAxisControllerDelegate: class {
  /// Tells the delegate the pinned-to-now state changed.
  ///
  /// - Parameters:
  ///   - timeAxisController: A time axis controller.
  ///   - isPinnedToNow: The current pinned-to-now state.
  func timeAxisController(_ timeAxisController: TimeAxisController,
                          didChangePinnedToNow isPinnedToNow: Bool)
}

/// Controls the display of a TimeAxisView.
class TimeAxisController: UIViewController {

  var timeAxisView: TimeAxisView {
    return view as! TimeAxisView
  }

  weak var delegate: TimeAxisControllerDelegate?

  // The visible axis of the chart views. The time axis view may show a different visible axis if
  // the time axis view is wider than the chart views.
  private(set) var visibleXAxis: ChartAxis<Int64> = .zero

  // The total range of values represented by a chart view's scroll view.
  var dataXAxis: ChartAxis<Int64> = .zero {
    didSet {
      timeAxisView.dataAxis = dataXAxis
    }
  }

  let defaultVisibleRange: Int64 = 20000  // 20 seconds in milliseconds

  var listener: ((ChartAxis<Int64>, ChartAxis<Int64>, ChartController?) -> Void)?

  /// The insets relative
  var chartTimeAxisInsets = UIEdgeInsets.zero

  let liveTimeInterval = 0.02  // 20 milliseconds

  /// A timer that updates the view when there is an incoming stream of data.
  var liveTimer: Timer?
  var isLive: Bool
  var isPinnedToNow: Bool {
    didSet {
      guard isPinnedToNow != oldValue else { return }
      delegate?.timeAxisController(self, didChangePinnedToNow: isPinnedToNow)
    }
  }

  /// The amount of time in milliseconds before the current time the view can be scrolled to enable
  /// pinning the scroll to the current time.
  let pinnedToNowThreshold: Int64 = 100

  /// The percent of the chart's visible time added after the now timestamp.
  let nowPaddingPercent = 0.05  // 5%

  /// True if the time axis is moving because of a user interaction, otherwise false.
  var isUserScrolling = false {
    didSet {
      guard oldValue != isUserScrolling else { return }

      if isUserScrolling {
        // Started dragging. Disabled pinned to now in case the user drags away from the
        // current point.
        isPinnedToNow = false
      } else {
        // Stopped dragging. If movement ended at the max data value or within a threshold, enable
        // pinned to now.
        if visibleXAxis.max >= (dataXAxis.max - pinnedToNowThreshold) {
          isPinnedToNow = true
        }
      }
    }
  }

  /// The starting time of a recording. When in observe mode the time axis will display a red dot
  /// and line to mark the time range that is being recorded. Setting this on a review style axis
  /// has no effect.
  var recordingStartTime: Int64? {
    get {
      return timeAxisView.recordingStartTime
    }
    set {
      timeAxisView.recordingStartTime = newValue
    }
  }

  private let style: TimeAxisView.Style

  init(style: TimeAxisView.Style, xAxis: ChartAxis<Int64>? = nil) {
    self.style = style
    isLive = style == .observe
    isPinnedToNow = style == .observe

    super.init(nibName: nil, bundle: nil)

    if let xAxis = xAxis {
      visibleXAxis = xAxis
      dataXAxis = xAxis
    } else {
      // If no axis was set use the default range.
      resetAxisToDefault()
    }
    updateForVisibleAxis()
  }

  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  // MARK: - UIViewController

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startLiveTimer()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopLiveTimer()
  }

  override func loadView() {
    view = TimeAxisView(style: style, visibleAxis: visibleXAxis, dataAxis: dataXAxis)
  }

  // MARK: - Public

  // Reset visible and data axes from the current time through the default visible range.
  func resetAxisToDefault() {
    let nowTimestamp = Date().millisecondsSince1970
    visibleXAxis = ChartAxis(min: nowTimestamp - defaultVisibleRange, max: nowTimestamp)
    dataXAxis = visibleXAxis
  }

  /// Adds a note dote at a timestamp.
  func addNoteDotAtTimestamp(_ timestamp: Int64) {
    guard style == .observe else { return }
    timeAxisView.noteTimestamps.append(timestamp)
  }

  /// Removes all note dots.
  func removeAllNoteDots() {
    guard style == .observe else { return }
    timeAxisView.noteTimestamps.removeAll()
  }

  // MARK: - Private

  // Starts the live timer which causes the time axis to scroll along with the current time.
  func startLiveTimer() {
    let timer = Timer.scheduledTimer(timeInterval: liveTimeInterval,
                                     target: self,
                                     selector: #selector(timerFired),
                                     userInfo: nil,
                                     repeats: true)
    // Allows the timer to fire while scroll views are tracking.
    RunLoop.main.add(timer, forMode: .common)
    liveTimer = timer
  }

  // Stops the live timer, removing it from the main run loop.
  func stopLiveTimer() {
    liveTimer?.invalidate()
  }

  @objc func timerFired() {
    // Only change axes if live and the user is not dragging.
    guard isLive, !isUserScrolling else { return }

    let nowTimestamp = Date().millisecondsSince1970

    // Expand the data axis if the current time is beyond the bounds, minus a padding threshold.
    let currentVisibleLength = visibleXAxis.length
    let horizontalPadding = Int64(Double(currentVisibleLength) * nowPaddingPercent)
    let maxTimeThreshold = dataXAxis.max - horizontalPadding
    if nowTimestamp > maxTimeThreshold {
      let visibleMax = nowTimestamp + horizontalPadding
      dataXAxis.max = visibleMax
      timeAxisView.dataAxis.max = visibleMax

      // Pin visible area to latest timestamp if pinned to now.
      if isPinnedToNow {
        visibleXAxis = ChartAxis(min: visibleMax - currentVisibleLength, max: visibleMax)
      }

      // When recording, label time is relative to the recording start time, otherwise it's
      // relative to the current time.
      if let recordingStartTime = recordingStartTime {
        timeAxisView.zeroTime = recordingStartTime
      } else {
        timeAxisView.zeroTime = nowTimestamp
      }
    }

    updateForVisibleAxis()
  }

  func visibleAxisChanged(_ visibleXAxis: ChartAxis<Int64>,
                          by chartController: ChartController? = nil) {
    guard visibleXAxis.max > visibleXAxis.min else { return }

    self.visibleXAxis = visibleXAxis
    updateForVisibleAxis(sourceChartController: chartController)
  }

  func updateForVisibleAxis(sourceChartController chartController: ChartController? = nil) {
    // Update listener.
    if let listener = listener {
      listener(visibleXAxis, dataXAxis, chartController)
    }

    // Update timeAxisView. The visible and data axis must be adjusted if the size of the chart is
    // different than the size of the time axis. Typically the charts have left and right margins,
    // but the time axis can sometimes be full screen width.
    var timeAxisVisibleAxis = visibleXAxis
    var timeAxisDataAxis = dataXAxis
    if chartTimeAxisInsets != .zero {
      let chartWidth =
          timeAxisView.bounds.size.width - chartTimeAxisInsets.left - chartTimeAxisInsets.right
      let xScale = CGFloat(visibleXAxis.length) / chartWidth
      let leftDiff = Int64(chartTimeAxisInsets.left * xScale)
      let rightDiff = Int64(chartTimeAxisInsets.right * xScale)
      timeAxisVisibleAxis = ChartAxis(min: timeAxisVisibleAxis.min - leftDiff,
                                      max: timeAxisVisibleAxis.max + rightDiff)
      timeAxisDataAxis = ChartAxis(min: timeAxisDataAxis.min - leftDiff,
                                   max: timeAxisDataAxis.max + rightDiff)
    }
    timeAxisView.dataAxis = timeAxisDataAxis
    timeAxisView.visibleAxis = timeAxisVisibleAxis
  }

}
