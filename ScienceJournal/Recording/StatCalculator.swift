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

/// Calcualtes the stats for a sensor during recording.
class StatCalculator {

  // MARK: - Properties

  /// The maximum value added.
  var maximum: Double?

  /// The minimum value added.
  var minimum: Double?

  /// The average (mean) of the values recorded.
  var average: Double? {
    guard numberOfValues > 0 else { return nil }
    return totalValue / Double(numberOfValues)
  }

  /// The duration in milliseconds between the first and last timestamps.
  var duration: Int64? {
    guard let firstTimestamp = firstTimestamp, let lastTimestamp = lastTimestamp else {
      return nil
    }
    return lastTimestamp - firstTimestamp
  }

  /// The first timestamp added, in milliseconds.
  private var firstTimestamp: Int64?

  /// The last timestamp added, in milliseconds.
  private var lastTimestamp: Int64?

  /// The number of values added.
  private(set) var numberOfValues = 0

  /// The total of all values added.
  private var totalValue = 0.0

  // MARK: - Public

  /// Adds a data point to the caluclations for each stat.
  ///
  /// - Parameter dataPoint: A data point.
  func addDataPoint(_ dataPoint: DataPoint) {
    // First timestamp.
    if firstTimestamp == nil {
      firstTimestamp = dataPoint.x
    }

    // Last timestamp.
    lastTimestamp = dataPoint.x

    // Maximum
    if let maximum = maximum {
      self.maximum = max(maximum, dataPoint.y)
    } else {
      maximum = dataPoint.y
    }

    // Minimum
    if let minimum = minimum {
      self.minimum = min(minimum, dataPoint.y)
    } else {
      minimum = dataPoint.y
    }

    // Values for average calculation.
    numberOfValues += 1
    totalValue += dataPoint.y
  }

  /// Resets the calculator by removing all stats and values.
  func reset() {
    firstTimestamp = nil
    lastTimestamp = nil
    maximum = nil
    minimum = nil
    numberOfValues = 0
    totalValue = 0
  }

}
