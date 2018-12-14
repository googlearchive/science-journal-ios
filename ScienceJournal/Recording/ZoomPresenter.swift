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

import Foundation

/// Determines which zoom tier to use to display a chart with a given visible range.
class ZoomPresenter {

  /// The ideal number of data points to display. Experimentally determined while developing the
  /// Android app.
  private let idealDisplayedDataPointCount: Int64 = 500

  /// The difference between the current and ideal tier before a new tier is used. Experimentally
  /// determined value to avoid unnecessary tier changes.
  private let zoomLevelChangeThreshold = 0.3

  /// Trial stats, which contain the trial's zoom tier information.
  private let sensorStats: DisplaySensorStats

  /// The current tier, defaults to tier zero.
  private(set) var currentTier = 0

  /// Designated initializer.
  ///
  /// - Parameter sensorStats: Stats for the chart's sensor.
  init(sensorStats: DisplaySensorStats) {
    self.sensorStats = sensorStats
  }

  /// Updates the tier based on a visible range.
  ///
  /// - Parameter visibleDuration: The visible duration.
  /// - Returns: The zoom tier that should be used.
  func updateTier(forVisibleDuration visibleDuration: Int64? = nil) -> Int {
    let computeDuration = visibleDuration ?? sensorStats.totalDuration
    guard let duration = computeDuration else {
      return 0
    }
    currentTier = computeTier(forVisibleDuration: duration)
    return currentTier
  }

  /// Computes a tier based on a visible range.
  ///
  /// - Parameter visibleDuration: The visible duration.
  /// - Returns: The zoom tier that should be used.
  private func computeTier(forVisibleDuration visibleDuration: Int64) -> Int {
    guard let zoomPresenterTierCount = sensorStats.zoomPresenterTierCount,
        let zoomLevelBetweenTiers = sensorStats.zoomLevelBetweenTiers,
        let numberOfValues = sensorStats.numberOfValues,
        let totalDuration = sensorStats.totalDuration else {
      // If information needed to calculate a zoom tier is missing, default to tier zero
      // (all data points).
      return 0
    }

    guard totalDuration > 0 && visibleDuration > 0 else {
      // Durations of zero cannot produce valid zoom tiers and also produce NaN values and crash.
      return 0
    }

    let idealTier = computeIdealTier(forVisibleDuration: visibleDuration,
                                     totalDuration: totalDuration,
                                     numberOfValues: numberOfValues,
                                     zoomLevelBetweenTiers: zoomLevelBetweenTiers)

    // Check if difference between current and ideal is great enough to calculate a new change.
    if abs(idealTier - Double(currentTier)) < zoomLevelChangeThreshold {
      return currentTier
    }

    // Note: On Android this code rounds instead of floors. Rounding up should always produce a tier
    // with insufficient data points. Have not figured out the descrepency with Android code.
    let actualTier = Int(floor(idealTier))
    let maxTier = Int(zoomPresenterTierCount) - 1
    return (0...maxTier).clamp(actualTier)
  }

  /// Returns an ideal tier as a fractional value.
  ///
  /// - Parameters:
  ///   - visibleDuration: The duration of the visible data points.
  ///   - totalDuration: The total duration of the entire recording.
  ///   - numberOfValues: The total number of all recorded values.
  ///   - zoomLevelBetweenTiers: The zoom level between tiers (or the number of data points in one
  ///                            tier per data point in the tier above).
  /// - Returns: The ideal tier.
  func computeIdealTier(forVisibleDuration visibleDuration: Int64,
                        totalDuration: Int64,
                        numberOfValues: Int,
                        zoomLevelBetweenTiers: Int) -> Double {
    let meanMillisPerDataPoint = Double(totalDuration) / Double(numberOfValues)
    let expectedTierZeroDataPointsInRange = Double(visibleDuration) / meanMillisPerDataPoint
    let idealTierZeroDataPointsPerDisplayedPoint =
        expectedTierZeroDataPointsInRange / Double(idealDisplayedDataPointCount)
    return log(idealTierZeroDataPointsPerDisplayedPoint) / log(Double(zoomLevelBetweenTiers))
  }

}
