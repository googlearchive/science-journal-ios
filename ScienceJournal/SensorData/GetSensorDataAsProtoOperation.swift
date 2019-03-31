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

import ScienceJournalProtos

enum SensorDataExportError: Error {
  /// Error fetching sensor data from the database. Associated data are the trial ID and sensor ID.
  case failedToFetchDatabaseSensorData(String, String)
  /// The sensor dumps recieved by dependent operations doesn't match the expected count.
  case invalidSensorDumpCount
  /// Error converting the sensor data proto into data.
  case errorGettingDataFromProto
  /// Error saving the data to disk.
  case errorSavingDataToDisk
}

/// An operation that assembles sensor data dumps into a GSJScalarSensorData proto. This operation
/// requires one or more `GetTrialSensorDumpOperation`s as dependencies which provide the
/// GSJScalarSensorDataDump protos for GSJScalarSensorData.
class GetSensorDataAsProtoOperation: GSJOperation {

  private let expectedSensorsCount: Int
  private let saveFileURL: URL

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - saveFileURL: The file url where the proto should be saved.
  ///   - expectedSensorsCount: The expected number of sensor dumps created by dependencies.
  ///                           Used for error checking.
  init(saveFileURL: URL, expectedSensorsCount: Int) {
    self.saveFileURL = saveFileURL
    self.expectedSensorsCount = expectedSensorsCount
  }

  override func execute() {
    let sensors = dependencies.compactMap { ($0 as? GetTrialSensorDumpOperation)?.dump }

    // Verify the number of sensors equals the number we expected.
    guard sensors.count == expectedSensorsCount else {
      finish(withErrors: [SensorDataExportError.invalidSensorDumpCount])
      return
    }

    // Don't save a proto unless there is at least one recording.
    guard sensors.count > 0 else {
      finish()
      return
    }

    let sensorData = GSJScalarSensorData()
    sensorData.sensorsArray = NSMutableArray(array: sensors)

    guard let data = sensorData.data() else {
      finish(withErrors: [SensorDataExportError.errorGettingDataFromProto])
      return
    }

    do {
      try data.write(to: saveFileURL)
    } catch {
      finish(withErrors: [SensorDataExportError.errorSavingDataToDisk])
      return
    }

    finish()
  }

}
