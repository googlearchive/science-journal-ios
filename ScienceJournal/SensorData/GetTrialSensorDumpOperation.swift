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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// An operation that fetches data for a single trial sensor and converts it into a sensor data
/// dump proto.
class GetTrialSensorDumpOperation: GSJOperation {

  private let sensorDataManager: SensorDataManager
  private let trialID: String
  private let sensorID: String

  /// When the operation completes successfully this will contain the sensor data dump.
  var dump: GSJScalarSensorDataDump?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorDataManager: A sensor data manager.
  ///   - trialID: A trial ID.
  ///   - sensorID: A sensor ID.
  init(sensorDataManager: SensorDataManager, trialID: String, sensorID: String) {
    self.sensorDataManager = sensorDataManager
    self.trialID = trialID
    self.sensorID = sensorID
  }

  override func execute() {
    sensorDataManager.fetchSensorData(
        forSensorID: sensorID,
        trialID: trialID,
        completion: { (dataPoints) in
          guard let dataPoints = dataPoints, dataPoints.count > 0 else {
            self.finish(withErrors:
                [SensorDataExportError.failedToFetchDatabaseSensorData(self.trialID,
                                                                       self.sensorID)])
            return
          }

          var rows = [GSJScalarSensorDataRow]()

          for dataPoint in dataPoints {
            let row = GSJScalarSensorDataRow()
            row.timestampMillis = dataPoint.x
            row.value = dataPoint.y
            rows.append(row)
          }

          let sensorDump = GSJScalarSensorDataDump()
          sensorDump.tag = self.sensorID
          sensorDump.trialId = self.trialID
          sensorDump.rowsArray = NSMutableArray(array: rows)
          self.dump = sensorDump

          self.finish()
    })
  }

}
