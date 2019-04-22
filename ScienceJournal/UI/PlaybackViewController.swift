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

protocol PlaybackViewControllerDelegate: class {
  /// Informs the delegate when playhead timestamp changes.
  ///
  /// - Parameter sensorID: A sensor ID.
  func playbackViewControllerDidChangePlayheadTimestamp(forSensorID sensorID: String)
}

// swiftlint:disable type_body_length
/// Responsible for presentation of a chart in review mode. Overlays a playback view onto a chart
/// view. User can tap a play button to play data over time or scrub the timeline to view specific
/// points in time.
class PlaybackViewController: UIViewController, ChartControllerDelegate, AccessibilityDelegate {

  // MARK: - Properties

  private let chartController: ChartController
  private var cropOverlayViewController: CropOverlayViewController?
  private let elapsedTimeFormatter = ElapsedTimeFormatter()
  private let pauseIconName = "ic_pause"
  private let playbackInterval: Int64 = 1000 / 30 // Playback interval in milliseconds at 30fps.
  private let playbackOverlay: PlaybackOverlayView
  private let playButton = UIButton()
  private let playIconName = "ic_play_arrow"
  private let sensorID: String
  private let timeAxisController: TimeAxisController
  private let toneGenerator = ToneGenerator()
  private let trialID: String
  private let percentToMoveWithAccessibility = 0.05
  private var isPlaying = false
  private var maxPlayheadPosition: CGFloat?
  private var minPlayheadPosition: CGFloat?
  private var playbackTimer: Timer?
  private(set) var playheadTimestamp: Int64?

  /// The current interaction state.
  var interactionState = InteractionState.playback

  /// The playback view controller delegate.
  weak var delegate: PlaybackViewControllerDelegate?

  private static let topPadding: CGFloat = 30

  /// The height of the playback view.
  static var viewHeight: CGFloat {
    return TimeAxisView.Style.review.height + ChartPlacementType.runReview.height +
        PlaybackViewController.topPadding
  }

  /// Whether or not the stats overlay is showing. Stats must be set with
  /// `setStats(min:max:average)` before the stats will show.
  var shouldShowStats: Bool {
    set {
      chartController.shouldShowStats = newValue
    }
    get {
      return chartController.shouldShowStats
    }
  }

  /// The playhead timestamp relative to the beginning of the trial.
  var playheadRelativeTimestamp: Int64 {
    guard let playheadTimestamp = playheadTimestamp else {
      return 0
    }
    return playheadTimestamp - timeAxisController.timeAxisView.zeroTime
  }

  /// The crop range, only available when cropping.
  var cropRange: ChartAxis<Int64>? {
    return cropOverlayViewController?.cropRange
  }

  let colorPalette: MDCPalette?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - sensorID: A sensor ID.
  ///   - sensorStats: The sensor stats.
  ///   - cropRange: A crop range.
  ///   - notes: An array of notes to display on the chart.
  ///   - colorPalette: The color palette for drawing some aspects of the chart.
  ///   - sensorDataManager: The sensor data manager.
  init(trialID: String,
       sensorID: String,
       sensorStats: DisplaySensorStats,
       cropRange: ChartAxis<Int64>? = nil,
       notes: [DisplayNote],
       colorPalette: MDCPalette?,
       sensorDataManager: SensorDataManager) {
    self.sensorID = sensorID
    self.trialID = trialID
    self.colorPalette = colorPalette
    playbackOverlay = PlaybackOverlayView(colorPalette: colorPalette)
    chartController = ChartController(placementType: .runReview,
                                      colorPalette: colorPalette,
                                      trialID: trialID,
                                      sensorID: sensorID,
                                      sensorStats: sensorStats,
                                      cropRange: cropRange,
                                      notes: notes,
                                      sensorDataManager: sensorDataManager)
    timeAxisController = TimeAxisController(style: .review, xAxis: chartController.visibleXAxis)

    super.init(nibName: nil, bundle: nil)

    // Pan gesture.
    let panGesture = UIPanGestureRecognizer(target: self,
                                            action: #selector(handleTimeAxisPanGesture(_:)))
    timeAxisController.timeAxisView.addGestureRecognizer(panGesture)

    // Tap gesture.
    let tapGesture = UITapGestureRecognizer(target: self,
                                            action: #selector(handleTimeAxisTapGesture(_:)))
    timeAxisController.timeAxisView.addGestureRecognizer(tapGesture)

    timeAxisController.timeAxisView.isAccessibilityElement = true
    timeAxisController.timeAxisView.accessibilityTraits = .adjustable
    timeAxisController.timeAxisView.accessibilityDelegate = self
    timeAxisController.timeAxisView.accessibilityLabel = String.chartContentDescription
    timeAxisController.timeAxisView.accessibilityHint = String.chartContentDetails

    chartController.delegate = self
    elapsedTimeFormatter.shouldDisplayTenths = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)

    chartController.chartView.translatesAutoresizingMaskIntoConstraints = false
    timeAxisController.timeAxisView.translatesAutoresizingMaskIntoConstraints = false

    let bottomWrapper = UIView()
    bottomWrapper.translatesAutoresizingMaskIntoConstraints = false
    bottomWrapper.addSubview(playButton)
    bottomWrapper.addSubview(timeAxisController.timeAxisView)
    playButton.leftAnchor.constraint(equalTo: bottomWrapper.leftAnchor).isActive = true
    playButton.topAnchor.constraint(equalTo: bottomWrapper.topAnchor).isActive = true
    playButton.bottomAnchor.constraint(equalTo: bottomWrapper.bottomAnchor).isActive = true
    timeAxisController.timeAxisView.leftAnchor.constraint(
        equalTo: playButton.rightAnchor).isActive = true
    timeAxisController.timeAxisView.topAnchor.constraint(
        equalTo: bottomWrapper.topAnchor).isActive = true
    timeAxisController.timeAxisView.bottomAnchor.constraint(
        equalTo: bottomWrapper.bottomAnchor).isActive = true
    timeAxisController.timeAxisView.rightAnchor.constraint(
        equalTo: bottomWrapper.rightAnchor).isActive = true

    let verticalStack = UIStackView(arrangedSubviews: [chartController.chartView, bottomWrapper])
    verticalStack.translatesAutoresizingMaskIntoConstraints = false
    verticalStack.axis = .vertical

    playButton.setImage(UIImage(named: playIconName), for: .normal)
    playButton.translatesAutoresizingMaskIntoConstraints = false
    playButton.accessibilityLabel = String.playContentDescription

    playbackOverlay.isHidden = true
    playbackOverlay.isUserInteractionEnabled = false
    playbackOverlay.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(verticalStack)
    view.addSubview(playbackOverlay)

    verticalStack.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    verticalStack.topAnchor.constraint(equalTo: view.topAnchor,
                                       constant: PlaybackViewController.topPadding).isActive = true
    verticalStack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
    verticalStack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    // Playback and crop overlays cover the entire view
    playbackOverlay.pinToEdgesOfView(view)

    // Play button should be the same width as the chart's y-axis labels.
    playButton.widthAnchor.constraint(
        equalToConstant: chartController.chartView.leftMargin).isActive = true
  }

  /// Sets the stats overlay values. To show them set `shouldShowStats` to true.
  ///
  /// - Parameters:
  ///   - min: The min value.
  ///   - max: The max value.
  ///   - average: The average value.
  func setStats(min: Double, max: Double, average: Double) {
    chartController.setStats(min: min, max: max, average: average)
  }

  func addNote(_ note: DisplayNote) {
    chartController.addNote(note)
  }

  func removeNote(withID noteID: String, atTimestamp timestamp: Int64) {
    chartController.removeNote(withID: noteID, atTimestamp: timestamp)
  }

  /// Updates the positions of the current state's overlays.
  func updateOverlays() {
    switch interactionState {
    case .playback: updatePlayheadPosition()
    case .crop: cropOverlayViewController?.updateCropMarkerPositions()
    }
  }

  /// Redraw the playhead at the current position. Used to update the playhead after a rotation.
  func updatePlayheadPosition() {
    guard let playheadTimestamp = playheadTimestamp else {
      return
    }
    showPlaybackOverlay(atTimestamp: playheadTimestamp, isDragging: false)
  }

  /// Enters the cropping state which shows crop start/end markers instead of a playhead.
  ///
  /// - Parameters:
  ///   - cropRange: The starting crop range to display.
  ///   - recordingRange: The trial's overall recording range.
  func startCropping(withCropRange cropRange: ChartAxis<Int64>,
                     recordingRange: ChartAxis<Int64>) {
    interactionState = .crop
    addCropOverlay(recordingRange: recordingRange, cropRange: cropRange)
    cropOverlayViewController?.updateCropMarkerPositions()
    playbackOverlay.isHidden = true
    playButton.isHidden = true
  }

  func endCropping() {
    interactionState = .playback
    updatePlayheadPosition()
    playbackOverlay.isHidden = false
    playButton.isHidden = false
    removeCropOverlay()
  }

  /// Loads data for the chart to display. Replaces any existing data.
  ///
  /// - Parameters:
  ///   - cropRange: The crop range to load, optional. If no range is set the entire recorded range
  ///                will be loaded.
  ///   - completion: A block called when the loading is finished.
  func resetAndloadData(cropRange: ChartAxis<Int64>?,
                        completion: (() -> Void)? = nil) {
    chartController.resetAndloadData(cropRange: cropRange, completion: completion)
  }

  /// Shows a crop marker at a given timestamp.
  ///
  /// - Parameters:
  ///   - marker: A crop marker type.
  ///   - timestamp: A timestamp.
  func showMarker(withType markerType: CropOverlayView.MarkerType, atTimestamp timestamp: Int64) {
    cropOverlayViewController?.showMarker(markerType, atTimestamp: timestamp)
  }

  // MARK: - AccessibilityDelegate

  func accessibilityAdjustableViewDidDecrement() {
    adjustableViewIncrement(forward: false)
  }

  func accessibilityAdjustableViewDidIncrement() {
    adjustableViewIncrement(forward: true)
  }

  // Move the playhead backward or forward based on accessibility actions.
  private func adjustableViewIncrement(forward: Bool) {
    guard let playheadTimestamp = playheadTimestamp,
        let lastDataPointX = chartController.chartData.lastX,
        let firstDataPointX = chartController.chartData.firstX else { return }
    let totalDuration = Double(lastDataPointX - firstDataPointX)
    let distanceToMove = Int64(totalDuration * percentToMoveWithAccessibility) * (forward ? 1 : -1)
    var newTimestamp = playheadTimestamp + distanceToMove
    if forward {
      newTimestamp = min(newTimestamp, lastDataPointX)
    } else {
      newTimestamp = max(newTimestamp, firstDataPointX)
    }
    movePlayheadToTimestamp(newTimestamp)

    // Make sure we can get a valid data point.
    guard let playheadDataPoint = chartController.closestDataPointToTimestamp(newTimestamp) else {
      return
    }

    // Prepare the VoiceOver announcement with the new position and corresponding value.
    let currentValue = Sensor.string(for: playheadDataPoint.y, units: nil, pointsAfterDecimal: 2)
    let percentage = String(format: "%.0f",
                            (Double(playheadTimestamp - firstDataPointX) / totalDuration) * 100.0)
    let announcementString = "\(percentage) \(String.percentContentDescription), \(currentValue)"
    UIAccessibility.post(notification: .announcement, argument: announcementString)
  }

  // MARK: - ChartControllerDelegate

  func chartController(_ chartController: ChartController,
                       didUpdateVisibleXAxis visibleAxis: ChartAxis<Int64>) {
    timeAxisController.visibleAxisChanged(visibleAxis, by: chartController)

    // Update overlays for scroll change.
    updateOverlays()
  }

  func chartController(_ chartController: ChartController,
                       scrollStateChanged isUserScrolling: Bool) {
    timeAxisController.isUserScrolling = isUserScrolling
  }

  func chartControllerDidFinishLoadingData(_ chartController: ChartController) {
    // Set time axis zero time first so labels are correct after setting visible axis.
    if let firstX = chartController.chartData.firstX {
      timeAxisController.timeAxisView.zeroTime = firstX
    }
    timeAxisController.dataXAxis = chartController.dataXAxis
    timeAxisController.visibleAxisChanged(chartController.visibleXAxis)

    // If playhead hasn't been set, move it to the beginning.
    if playheadTimestamp == nil {
      playheadTimestamp = timeAxisController.timeAxisView.zeroTime
    }
  }

  func chartController(_ chartController: ChartController, shouldPinToNow: Bool) {}

  /// Stops playback and tone generator.
  func stopPlayback() {
    playButton.setImage(UIImage(named: playIconName), for: .normal)
    playButton.accessibilityLabel = String.playContentDescription
    isPlaying = false
    playbackTimer?.invalidate()
    playbackTimer = nil
    toneGenerator.stop()
  }

  /// Moves the playhead to a timestamp. If timestamp is not within the chart's bounds the playhead
  /// will be hidden.
  ///
  /// - Parameter timestamp: A timestamp.
  func movePlayheadToTimestamp(_ timestamp: Int64) {
    showPlaybackOverlay(atTimestamp: timestamp, isDragging: false)
  }

  // MARK: - Private

  private func startPlayback() {
    guard let playheadTimestamp = playheadTimestamp else {
      return
    }

    isPlaying = true

    playButton.setImage(UIImage(named: pauseIconName), for: .normal)
    playButton.accessibilityLabel = String.pauseContentDescription

    // If next playback interval would be beyond the last timestamp, reset to the beginning.
    if let lastX = chartController.chartData.lastX,
        playheadTimestamp + playbackInterval >= lastX,
        let firstX = chartController.chartData.firstX {
      self.playheadTimestamp = firstX
    }

    let timer = Timer.scheduledTimer(timeInterval: Double(playbackInterval) / 1000,
                                     target: self,
                                     selector: #selector(playbackTimerFired),
                                     userInfo: nil,
                                     repeats: true)
    timer.fire()
    playbackTimer = timer
    toneGenerator.start()
  }

  @objc private func playbackTimerFired() {
    guard let playheadTimestamp = playheadTimestamp else {
      return
    }

    guard let lastX = chartController.chartData.lastX else { return }

    let dataPoint = showPlaybackOverlay(atTimestamp: playheadTimestamp, isDragging: false)

    // Play tone.
    if let dataPoint = dataPoint {
      toneGenerator.setToneFrequency(for: dataPoint.y,
                                     valueMin: chartController.visibleYAxis.min,
                                     valueMax: chartController.visibleYAxis.max,
                                     atTimestamp: playheadTimestamp)
    }

    // Check next timestamp.
    let nextTimestamp = playheadTimestamp + playbackInterval

    // If next timestamp is beyond end of the chart data, stop playback.
    guard nextTimestamp <= lastX else {
      stopPlayback()
      return
    }

    self.playheadTimestamp = nextTimestamp
  }

  private func showOverlay(atTimelinePosition timelinePosition: CGFloat,
                           isDragging: Bool,
                           hasDragEnded: Bool) {
    switch interactionState {
    case .playback:
      showPlaybackOverlay(atTimelinePosition: timelinePosition,
                          isDragging: isDragging,
                          hasDragEnded: hasDragEnded)
    case .crop:
      cropOverlayViewController?.showCropOverlay(atTimelinePosition: timelinePosition,
                                                 isDragging: isDragging,
                                                 hasDragEnded: hasDragEnded)
    }
  }

  private func showPlaybackOverlay(atTimelinePosition timelinePosition: CGFloat,
                                   isDragging: Bool,
                                   hasDragEnded: Bool) {
    guard let firstDataPointX = chartController.chartData.firstX,
        let lastDataPointX = chartController.chartData.lastX,
        let minPlayheadPosition = chartController.viewPointX(fromDataPointX: firstDataPointX),
        let maxPlayheadPosition = chartController.viewPointX(fromDataPointX: lastDataPointX) else {
          return
    }

    let clampedPosition =  max(min(timelinePosition, maxPlayheadPosition), minPlayheadPosition)

    // If a pan gesture ends at the beginning, hide the overlay. Use a 2 pt buffer to avoid
    // comparing exact float values.
    let minPositionTolerance = minPlayheadPosition + 2
    if hasDragEnded && clampedPosition < minPositionTolerance {
      playbackOverlay.isHidden = true
      return
    }

    guard let playheadTime =
        timeAxisController.timeAxisView.timestampForViewPosition(clampedPosition) else { return }
    showPlaybackOverlay(atTimestamp: playheadTime, isDragging: isDragging)
  }

  @discardableResult private func showPlaybackOverlay(atTimestamp timestamp: Int64,
                                                      isDragging: Bool) -> DataPoint? {
    guard let firstDataPointX = chartController.chartData.firstX,
        let lastDataPointX = chartController.chartData.lastX else {
      return nil
    }

    // Save the current playhead time, clamped to the available data range.
    let newPlayheadTimestamp = (firstDataPointX...lastDataPointX).clamp(timestamp)
    playheadTimestamp = newPlayheadTimestamp
    delegate?.playbackViewControllerDidChangePlayheadTimestamp(forSensorID: sensorID)

    // Make sure we can get a valid data point and chart view point.
    guard let playheadDataPoint = chartController.closestDataPointToTimestamp(newPlayheadTimestamp),
        let chartViewPoint = chartController.viewPoint(fromDataPoint: playheadDataPoint) else {
      return nil
    }

    // If the chart view point is not in bounds, hide the overlay.
    guard chartViewPoint.x >= chartController.chartView.scrollView.bounds.origin.x,
        chartViewPoint.x <= chartController.chartView.scrollView.bounds.maxX else {
      playbackOverlay.isHidden = true
      return nil
    }

    // Convert the chart view point to the playback view.
    let playbackOverlayPoint = self.view.convert(chartViewPoint,
                                                 from: chartController.chartView.scrollView)

    // Format the value and timestamp.
    let timestampString =
        elapsedTimeFormatter.string(fromTimestamp: playheadDataPoint.x - firstDataPointX)

    // Unlike other sensor values, the overlay always shows 2 points after decimal.
    let valueString = Sensor.string(for: playheadDataPoint.y, units: nil, pointsAfterDecimal: 2)
    let timeAxisLineYPosition = view.bounds.size.height - timeAxisController.timeAxisView.height +
        timeAxisController.timeAxisView.topBackgroundMargin
    playbackOverlay.setCurrentPoint(playbackOverlayPoint,
                                    timestamp: timestampString,
                                    value: valueString,
                                    isDragging: isDragging,
                                    timeAxisLineYPosition: timeAxisLineYPosition)
    playbackOverlay.isHidden = false

    return playheadDataPoint
  }

  @objc private func handleTimeAxisPanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    let newPlayheadPosition = panGestureRecognizer.location(in: timeAxisController.timeAxisView).x
    switch panGestureRecognizer.state {
    case .changed, .began:
      showOverlay(atTimelinePosition: newPlayheadPosition, isDragging: true, hasDragEnded: false)
    case .ended:
      showOverlay(atTimelinePosition: newPlayheadPosition, isDragging: false, hasDragEnded: true)
    default: break
    }
  }

  @objc private func handleTimeAxisTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {
    // The tap gesture is responding when Voice Over is enabled, so protecting against that case.
    guard !UIAccessibility.isVoiceOverRunning else { return }
    let newPlayheadPosition = tapGestureRecognizer.location(in: timeAxisController.timeAxisView).x
    showOverlay(atTimelinePosition: newPlayheadPosition, isDragging: false, hasDragEnded: true)
  }

  /// Adds a crop overlay view and controller to the view.
  ///
  /// - Parameters:
  ///   - recordingRange: The trial's recording range.
  ///   - cropRange: The starting crop range.
  private func addCropOverlay(recordingRange: ChartAxis<Int64>, cropRange: ChartAxis<Int64>) {
    let cropOverlay = CropOverlayViewController(recordingRange: recordingRange,
                                                cropRange: cropRange,
                                                chartController: chartController,
                                                timeAxisController: timeAxisController,
                                                colorPalette: colorPalette)
    addChild(cropOverlay)
    cropOverlay.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(cropOverlay.view)
    cropOverlay.view.pinToEdgesOfView(view)
    cropOverlayViewController = cropOverlay
    view.layoutIfNeeded()
  }

  /// Removes the crop overlay view and controller.
  private func removeCropOverlay() {
    cropOverlayViewController?.view.removeFromSuperview()
    cropOverlayViewController?.removeFromParent()
    cropOverlayViewController = nil
  }

  // MARK: - User actions

  @objc private func playButtonTapped() {
    if isPlaying {
      stopPlayback()
    } else {
      startPlayback()
    }
  }

  // MARK: - State

  /// The interaction state of the playback view.
  ///
  /// - playback: A single playhead marker can be moved through time.
  /// - crop: Two markers can be moved through time to determine crop range.
  enum InteractionState {
    case playback
    case crop
  }

}

// swiftlint:enable type_body_length
