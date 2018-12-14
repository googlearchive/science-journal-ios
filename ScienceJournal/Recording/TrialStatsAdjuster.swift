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

/// Responsible for recalculating the stats of a trial. Typically this only happens after a trial
/// is cropped and the old stats are no longer valid for the new range. Must be used on the
/// Core Data context queue that owns the array of SensorData.
class TrialStatsAdjuster {

  private let trial: Trial
  private let sensorData: [SensorData]

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - trial: The trial for which to recalculate stats.
  ///   - sensorData: The trial's sensor data.
  init(trial: Trial, sensorData: [SensorData]) {
    self.trial = trial
    self.sensorData = sensorData
  }

  /// Begins the recalculation asynchronously. Must be called on the Core Data context queue that
  /// owns the array of SensorData.
  ///
  /// - Parameter completion: A completion called with the new trial stats array. Always called on
  ///                         the main thread.
  func recalculateStats(_ completion: @escaping ([TrialStats]) -> Void) {
    // Build a dictionary of stat calculators keyed by sensor ID.
    var statCalculators = [String: StatCalculator]()
    let sensorIDs = self.trial.sensorLayouts.map { $0.sensorID }
    for sensorID in sensorIDs {
      statCalculators[sensorID] = StatCalculator()
    }

    // Add the sensor data to the appropriate stat calculator.
    for sensorDataPoint in self.sensorData {
      guard let statCalculator = statCalculators[sensorDataPoint.sensor] else {
        continue
      }

      statCalculator.addDataPoint(DataPoint(x: sensorDataPoint.timestamp, y: sensorDataPoint.value))
    }

    // Build trial stats from the populated calculators.
    let trialStats: [TrialStats] = statCalculators.map { (sensorID, calculator) in
      // Use existing stats if they are available to preserve zoom tier data.
      let stats = trial.sensorTrialStats(for: sensorID) ?? TrialStats(sensorID: sensorID)
      stats.addStatsFromStatCalculator(calculator)
      return stats
    }

    DispatchQueue.main.async {
      completion(trialStats)
    }
  }

}
