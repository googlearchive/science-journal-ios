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

/// An operation that gets all sensor data for a trial, creates a GSJScalarSensorData proto for it,
/// and saves it to disk.
public class WriteTrialSensorDataToDiskOperation: GroupOperation {

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - saveFileURL: A file URL in which to save sensor data protos.
  ///   - sensorDataManager: The sensor data manager.
  ///   - trial: A trial.
  public init(saveFileURL: URL, sensorDataManager: SensorDataManager, trial: Trial) {
    var operations = [Operation]()
    var sensorCount = 0
    for sensorLayout in trial.sensorLayouts {
      let trialSensorOp = GetTrialSensorDumpOperation(sensorDataManager: sensorDataManager,
                                                      trialID: trial.ID,
                                                      sensorID: sensorLayout.sensorID)
      operations.append(trialSensorOp)
      sensorCount += 1
    }

    let sensorDataOp = GetSensorDataAsProtoOperation(saveFileURL: saveFileURL,
                                                     expectedSensorsCount: sensorCount)

    operations.forEach { sensorDataOp.addDependency($0) }
    operations.append(sensorDataOp)

    super.init(operations: operations)
  }

}
