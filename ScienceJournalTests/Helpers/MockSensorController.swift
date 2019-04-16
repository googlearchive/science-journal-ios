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

import Foundation

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// A `SensorController` that can be mocked for testing.
class MockSensorController: SensorController {

  /// The `Sensor`s to return when calling `sensor(for:)`.
  var sensorsToReturn = [String: Sensor]()

  /// Adds a sensor to return for a sensor ID.
  ///
  /// - Parameters:
  ///   - sensor: The sensor to return.
  ///   - sensorId: The sensor ID to return it for.
  func addSensorToReturn(_ sensor: Sensor, forSensorId sensorId: String) {
    sensorsToReturn[sensorId] = sensor
  }

  /// Returns the specified `Sensor`, for the `sensorID`.
  ///
  /// - Parameter sensorID: The sensor ID.
  /// - Returns: The sensor.
  override func sensor(for sensorID: String) -> Sensor? {
    return sensorsToReturn[sensorID]
  }

  /// Returns all of the sensors in `sensorsToReturn`.
  override var availableSensors: [Sensor] {
    return sensorsToReturn.compactMap({ $0.value })
  }

}
