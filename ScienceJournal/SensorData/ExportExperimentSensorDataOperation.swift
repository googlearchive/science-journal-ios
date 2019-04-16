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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// An operation that gets all trial data for one experiment and creates a GSJScalarSensorData
/// proto. This is used when exporting experiments as a document file.
class ExportExperimentSensorDataOperation: GroupOperation {

  private let experimentSensorDataOp: GetSensorDataAsProtoOperation

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - saveDirectoryURL: A directory URL in which to save sensor data protos.
  ///   - sensorDataManager: A sensor data manager.
  ///   - experiment: An experiment.
  init(saveDirectoryURL: URL, sensorDataManager: SensorDataManager, experiment: Experiment) {
    var operations = [Operation]()
    var sensorCount = 0
    for trial in experiment.trials {
      for sensorLayout in trial.sensorLayouts {
        let trialSensorOp = GetTrialSensorDumpOperation(sensorDataManager: sensorDataManager,
                                                        trialID: trial.ID,
                                                        sensorID: sensorLayout.sensorID)
        operations.append(trialSensorOp)
        sensorCount += 1
      }
    }

    let saveURL = saveDirectoryURL.appendingPathComponent(MetadataManager.sensorDataProtoFilename)
    let sensorDataOp = GetSensorDataAsProtoOperation(saveFileURL: saveURL,
                                                     expectedSensorsCount: sensorCount)
    experimentSensorDataOp = sensorDataOp

    // ExperimentSensorDataOperation depends on data in the trial sensor operations.
    operations.forEach { sensorDataOp.addDependency($0) }
    operations.append(experimentSensorDataOp)

    super.init(operations: operations)
  }

}
