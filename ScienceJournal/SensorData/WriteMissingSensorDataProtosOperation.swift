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

/// An operation that finds experiment trials with missing sensor data protos and writes them
/// to disk. Sensor data protos are how sensor data is synced to Drive.
class WriteMissingSensorDataProtosOperation: GroupOperation {

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - experiment: An experiment.
  ///   - metadataManager: The metadata manager.
  ///   - sensorDataManager: The sensor data manager.
  init(experiment: Experiment,
       metadataManager: MetadataManager,
       sensorDataManager: SensorDataManager) {
    var operations = [GSJOperation]()
    for trial in experiment.trials {
      let recordingURL =
          metadataManager.recordingURL(forTrialID: trial.ID, experimentID: experiment.ID)

      if !FileManager.default.fileExists(atPath: recordingURL.path) {
        // A recording proto doesn't exist for this trial so write one to disk. This will fail if
        // no sensor data exists for this trial. In which case this is probably a recording created
        // on another device and the recording proto has yet to be downloaded from Drive.
        let writeProtoToDisk =
            WriteTrialSensorDataToDiskOperation(saveFileURL: recordingURL,
                                                sensorDataManager: sensorDataManager,
                                                trial: trial)
        operations.append(writeProtoToDisk)
      }
    }

    super.init(operations: operations)
  }

}
