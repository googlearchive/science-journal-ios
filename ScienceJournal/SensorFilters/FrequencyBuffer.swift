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

/// A filter that converts a series of values into a frequency based on a given window
/// and tolerance.
class FrequencyBuffer: ValueFilter {

  private var readings = [DataPoint]()
  private let window: Int64
  private let denominatorInMillis: Double
  private let filter: Double

  private var averageValue: Double {
    let total = readings.reduce(0, { total, value in total + value.y })
    // Adding `filter` means that variations of less than `filter` won't register as cycles.
    return total / Double(readings.count) + filter
  }

  private var latestFrequency: Double {
    guard readings.count > 1 else {
      return 0
    }

    let average = averageValue
    var crossings = 0
    var firstCrossingTime: Int64?
    var lastCrossingTime: Int64?
    var higherThanAverage = readings[0].y > average
    for reading in readings[1..<readings.endIndex] {
      let thisReadingHigher = reading.y > average
      if higherThanAverage != thisReadingHigher {
        higherThanAverage = thisReadingHigher
        crossings += 1
        if firstCrossingTime == nil {
          firstCrossingTime = reading.x
        } else {
          lastCrossingTime = reading.x
        }
      }
    }

    // Drop the leading cross because that's where time starts.
    crossings -= 1

    guard let firstCrossing = firstCrossingTime, let lastCrossing = lastCrossingTime else {
      return 0
    }

    let adjustedWindowMillis = Double(lastCrossing - firstCrossing)

    if adjustedWindowMillis < Double(window / 4) {
      // if the signal appears to have stopped 3/4 a window ago, then treat it as stopped.
      // Without this, we can read very or infinitely short single spikes as representing a
      // nonsensical, very high "frequency", leading to janky frequency "spikes" when
      // signals stop and start.
      return 0
    }

    let adjustedWindowUserUnits = adjustedWindowMillis / denominatorInMillis
    let cycles = Double(crossings) / 2.0
    let userUnitFrequency = cycles / adjustedWindowUserUnits
    return userUnitFrequency
  }

  /// Designated Initializer
  ///
  /// - Parameters:
  ///   - window: How many milliseconds of data to keep for frequency detection.
  ///   - denominatorInMillis: How many milliseconds are in the display unit (for Hz, this should
  ///                          be 1000. For RPM, it should be 60,000)
  ///   - filter: Only consider signals with an amplitude at least twice this number.
  init(window: Int64, denominatorInMillis: Double, filter: Double) {
    self.window = window
    self.denominatorInMillis = denominatorInMillis
    self.filter = filter
  }

  func filterValue(timestamp: Int64, value: Double) -> Double {
    readings.append(DataPoint(x: timestamp, y: value))
    prune(fromTimestamp: timestamp)
    return latestFrequency
  }

  // MARK: - Private

  private func prune(fromTimestamp timestamp: Int64) {
    let oldestRemaining = timestamp - window
    while readings[0].x < oldestRemaining {
      readings.remove(at: 0)
    }
  }

}
