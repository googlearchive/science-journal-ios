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

/// View controller that displays crop markers over the playback view.
class CropOverlayViewController: UIViewController {

  // MARK: - Properties

  /// The crop range.
  var cropRange: ChartAxis<Int64>

  private let recordingRange: ChartAxis<Int64>
  private var draggingCropMarker: CropOverlayView.MarkerType?
  private let chartController: ChartController
  private let timeAxisController: TimeAxisController
  private let elapsedTimeFormatter = ElapsedTimeFormatter()
  private let colorPalette: MDCPalette?
  private let cropA11yMoveDuration: Int64 = 500  // Half a second.
  private let cropValidator: CropValidator

  private var cropOverlayView: CropOverlayView {
    return view as! CropOverlayView
  }

  /// The time interval from the first chart data value to the crop start timestamp.
  var cropStartRelativeInterval: TimeInterval? {
    guard let firstDataPointX = chartController.chartData.firstX else {
      return nil
    }
    let relativeTimestamp = cropRange.min - firstDataPointX
    return TimeInterval(relativeTimestamp / 1000)
  }

  /// The time interval from the first chart data value to the crop end timestamp.
  var cropEndRelativeInterval: TimeInterval? {
    guard let firstDataPointX = chartController.chartData.firstX else {
      return nil
    }
    let relativeTimestamp = cropRange.max - firstDataPointX
    return TimeInterval(relativeTimestamp / 1000)
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - recordingRange: The trial recording range.
  ///   - cropRange: The starting crop range.
  ///   - chartController: A chart controller.
  ///   - timeAxisController: A time axis controller.
  ///   - colorPalette: A color palette.
  init(recordingRange: ChartAxis<Int64>,
       cropRange: ChartAxis<Int64>,
       chartController: ChartController,
       timeAxisController: TimeAxisController,
       colorPalette: MDCPalette?) {
    self.recordingRange = recordingRange
    self.cropRange = cropRange
    self.chartController = chartController
    self.timeAxisController = timeAxisController
    self.colorPalette = colorPalette
    cropValidator = CropValidator(trialRecordingRange: recordingRange)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  override func loadView() {
    view = CropOverlayView(colorPalette: colorPalette)
    cropOverlayView.isUserInteractionEnabled = false
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureAccessibility()
  }

  /// Updates a crop marker based on the given timeline position. The marker closest to the timeline
  /// position when a drag event starts will be the marker that moves.
  ///
  /// - Parameters:
  ///   - timelinePosition: A view position on the timeline.
  ///   - isDragging: True if the user is dragging, otherwise false.
  ///   - hasDragEnded: True if the user has ended dragging, otherwise false.
  func showCropOverlay(atTimelinePosition timelinePosition: CGFloat,
                       isDragging: Bool,
                       hasDragEnded: Bool) {
    // Get crop positions.
    guard let cropStartPosition = chartController.viewPointX(fromDataPointX: cropRange.min),
        let cropEndPosition = chartController.viewPointX(fromDataPointX: cropRange.max) else {
      return
    }

    // If draggingCropMarker is nil the drag event has just started. Determine which marker to move.
    if draggingCropMarker == nil {
      let distanceToStart = abs(cropStartPosition - timelinePosition)
      let distanceToEnd = abs(cropEndPosition - timelinePosition)
      if distanceToStart < distanceToEnd {
        draggingCropMarker = .start
      } else {
        draggingCropMarker = .end
      }
    }

    // At this point the marker has been chosen, but unwrap just in case.
    guard let draggingCropMarker = draggingCropMarker else {
      return
    }

    showMarker(draggingCropMarker, atPosition: timelinePosition, hasDragEnded: hasDragEnded)
  }

  /// Shows a marker at a timestamp.
  ///
  /// - Parameters:
  ///   - marker: A crop marker type.
  ///   - timestamp: A timestamp.
  func showMarker(_ marker: CropOverlayView.MarkerType, atTimestamp timestamp: Int64) {
    guard let position = chartController.viewPointX(fromDataPointX: timestamp) else {
      return
    }
    showMarker(marker, atPosition: position, hasDragEnded: true)
  }

  /// Shows a marker at a position on the x-axis.
  ///
  /// - Parameters:
  ///   - marker: A crop marker type.
  ///   - position: A position on the x-axis.
  ///   - hasDragEnded: True if this represents the last point of a drag or a single update.
  func showMarker(_ marker: CropOverlayView.MarkerType,
                  atPosition position: CGFloat,
                  hasDragEnded: Bool) {
    guard let positionTimestamp =
        timeAxisController.timeAxisView.timestampForViewPosition(position) else {
      return
    }

    // Clamp the position based on the marker type and determine its timestamp.
    switch marker {
    case .start:
      guard let clampedTimestamp =
          cropValidator.startCropTimestampClampedToValidRange(positionTimestamp,
                                                              cropRange: cropRange) else {
        return
      }
      cropRange.min = clampedTimestamp
    case .end:
      guard let clampedTimestamp =
          cropValidator.endCropTimestampClampedToValidRange(positionTimestamp,
                                                            cropRange: cropRange) else {
        return
      }
      cropRange.max = clampedTimestamp
    }

    updateCropMarkerPositions()

    if hasDragEnded {
      self.draggingCropMarker = nil
    }
  }

  /// Updates the positions of the crop markers based on the currently set timestamps and view.
  func updateCropMarkerPositions() {
    // Get data points and their corresponding view points for the start and end markers.
    guard let cropStartDataPoint = chartController.closestDataPointToTimestamp(cropRange.min),
        let startViewPoint = chartController.viewPoint(fromDataPoint: cropStartDataPoint),
        let cropEndDataPoint = chartController.closestDataPointToTimestamp(cropRange.max),
        let endViewPoint = chartController.viewPoint(fromDataPoint: cropEndDataPoint),
        let firstDataPointX = chartController.chartData.firstX else {
      return
    }

    // The position of the top of the time axis.
    let timeAxisLineYPosition = view.bounds.size.height - timeAxisController.timeAxisView.height +
        timeAxisController.timeAxisView.topBackgroundMargin

    cropOverlayView.timeAxisLineYPosition = timeAxisLineYPosition
    cropOverlayView.chartMinXPosition = ChartView.yLabelWidth
    cropOverlayView.chartMaxXPosition = chartController.chartView.frame.maxX

    func updateStartMarker() {
      // If the start view point is not in bounds, hide the overlay.
      if startViewPoint.x < chartController.chartView.scrollView.bounds.origin.x ||
          startViewPoint.x > chartController.chartView.scrollView.bounds.maxX {
        cropOverlayView.hideStartPoint()
      } else {
        cropOverlayView.showStartPoint()
      }

      // Convert the start view point to the playback view's coordinates.
      let startViewPointConverted = self.view.convert(startViewPoint,
                                                      from: chartController.chartView.scrollView)
      let startTimestampString =
          elapsedTimeFormatter.string(fromTimestamp: cropStartDataPoint.x - firstDataPointX)

      // Data point flags always show 2 points after decimal.
      let startValueString = Sensor.string(for: cropStartDataPoint.y,
                                           units: nil,
                                           pointsAfterDecimal: 2)

      cropOverlayView.setStartPosition(startViewPointConverted.x,
                                       timestamp: startTimestampString,
                                       value: startValueString)

      if let relativeInterval = cropStartRelativeInterval {
        cropOverlayView.startA11yMarker.accessibilityLabel =
            "\(String.cropStartSeekbarContentDescription) " +
            "\(relativeInterval.accessibleDurationString)"
      }
    }

    func updateEndMarker() {
      // If the end view point is not in bounds, hide the overlay.
      if endViewPoint.x < chartController.chartView.scrollView.bounds.origin.x ||
        endViewPoint.x > chartController.chartView.scrollView.bounds.maxX {
        cropOverlayView.hideEndPoint()
      } else {
        cropOverlayView.showEndPoint()
      }

      // Convert the end view point to the playback view's coordinates.
      let endViewPointConverted = self.view.convert(endViewPoint,
                                                    from: chartController.chartView.scrollView)
      let endTimestampString =
          elapsedTimeFormatter.string(fromTimestamp: cropEndDataPoint.x - firstDataPointX)

      // Data point flags always show 2 points after decimal.
      let endValueString = Sensor.string(for: cropEndDataPoint.y, units: nil, pointsAfterDecimal: 2)

      cropOverlayView.setEndPosition(endViewPointConverted.x,
                                     timestamp: endTimestampString,
                                     value: endValueString)

      if let relativeInterval = cropEndRelativeInterval {
        cropOverlayView.endA11yMarker.accessibilityLabel =
            "\(String.cropEndSeekbarContentDescription) " +
            "\(relativeInterval.accessibleDurationString)"
      }
    }

    updateStartMarker()
    updateEndMarker()

    cropOverlayView.isHidden = false
  }

  // MARK: - Private

  /// Configures accessibility features for cropping.
  private func configureAccessibility() {
    [cropOverlayView.startA11yMarker, cropOverlayView.endA11yMarker].forEach { (view) in
      view.isUserInteractionEnabled = false
      view.isAccessibilityElement = true
      view.accessibilityTraits = .allowsDirectInteraction
    }

    let moveStartLeftAction =
        UIAccessibilityCustomAction(name: String.cropMoveStartLeftContentDescription,
                                    target: self,
                                    selector: #selector(accessibilityMoveStartLeft))
    let moveStartRightAction =
        UIAccessibilityCustomAction(name: String.cropMoveStartRightContentDescription,
                                    target: self,
                                    selector: #selector(accessibilityMoveStartRight))
    let moveEndLeftAction =
        UIAccessibilityCustomAction(name: String.cropMoveEndLeftContentDescription,
                                    target: self,
                                    selector: #selector(accessibilityMoveEndLeft))
    let moveEndRightAction =
        UIAccessibilityCustomAction(name: String.cropMoveEndRightContentDescription,
                                    target: self,
                                    selector: #selector(accessibilityMoveEndRight))

    cropOverlayView.startA11yMarker.accessibilityCustomActions =
        [moveStartLeftAction, moveStartRightAction]
    cropOverlayView.endA11yMarker.accessibilityCustomActions =
        [moveEndLeftAction, moveEndRightAction]
  }

  private func moveMarker(_ marker: CropOverlayView.MarkerType,
                          direction: AccessibilityMoveDirection,
                          announcementPrefix: String) {
    let moveAmount: Int64
    switch direction {
    case .left: moveAmount = -cropA11yMoveDuration
    case .right: moveAmount = cropA11yMoveDuration
    }

    let initialMarkerTimestamp: Int64
    switch marker {
    case .start:
      initialMarkerTimestamp = cropRange.min
    case .end:
      initialMarkerTimestamp = cropRange.max
    }

    let movedTimestamp = initialMarkerTimestamp + moveAmount

    showMarker(marker, atTimestamp: movedTimestamp)

    // Use the marker accessibility label as part of the announcement text.
    let markerA11yLabel: String?
    switch marker {
    case .start:
      markerA11yLabel = cropOverlayView.startA11yMarker.accessibilityLabel
    case .end:
      markerA11yLabel = cropOverlayView.endA11yMarker.accessibilityLabel
    }

    // TODO: Relative intervals less than 1 second read as "zero seconds" http://b/70277203
    if let markerA11yLabel = markerA11yLabel {
      let announcementString = "\(announcementPrefix),, \(markerA11yLabel)"
      UIAccessibility.post(notification: .announcement, argument: announcementString)
    }
  }

  @objc private func accessibilityMoveStartLeft() {
    moveMarker(.start,
               direction: .left,
               announcementPrefix: String.cropMoveStartLeftContentDescription)
  }

  @objc private func accessibilityMoveStartRight() {
    moveMarker(.start,
               direction: .right,
               announcementPrefix: String.cropMoveStartRightContentDescription)
  }

  @objc private func accessibilityMoveEndLeft() {
    moveMarker(.end,
               direction: .left,
               announcementPrefix: String.cropMoveEndLeftContentDescription)
  }

  @objc private func accessibilityMoveEndRight() {
    moveMarker(.end,
               direction: .right,
               announcementPrefix: String.cropMoveEndRightContentDescription)
  }

  // MARK: - Nested types

  private enum AccessibilityMoveDirection {
    case left, right
  }

}
