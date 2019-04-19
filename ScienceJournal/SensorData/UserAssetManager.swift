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

/// Manages assets for a user's experiments, including generating trial sensor data protos, and
/// syncing image assets with Drive.
open class UserAssetManager {

  // MARK: - Properties

  private let driveSyncManager: DriveSyncManager?
  private let metadataManager: MetadataManager
  private let sensorDataManager: SensorDataManager
  private let operationQueue = GSJOperationQueue()

  // MARK: - Public

  /// Designated initialzier.
  ///
  /// Parameters:
  ///   - driveSyncManager: A drive sync manager.
  ///   - metadataManager: A metadata manager.
  ///   - sensorDataManager: A sensor data manager.
  public init(driveSyncManager: DriveSyncManager?,
       metadataManager: MetadataManager,
       sensorDataManager: SensorDataManager) {
    self.driveSyncManager = driveSyncManager
    self.metadataManager = metadataManager
    self.sensorDataManager = sensorDataManager
  }

  /// Stores the sensor data proto for a trial to disk.
  ///
  /// Parameters:
  ///   - trial: A trial
  ///   - experiment: The experiment the trial belongs to.
  ///   - completion: Called when finished.
  func storeSensorData(forTrial trial: Trial,
                       experiment: Experiment,
                       completion: (() -> Void)? = nil) {
    let saveURL = metadataManager.recordingURL(forTrialID: trial.ID, experimentID: experiment.ID)

    let writeTrialSensorDataToDiskOperation =
        WriteTrialSensorDataToDiskOperation(saveFileURL: saveURL,
                                            sensorDataManager: sensorDataManager,
                                            trial: trial)
    writeTrialSensorDataToDiskOperation.addObserver(BlockObserver {
        [unowned self] (operation, _) in
      if operation.didFinishSuccessfully {
        self.driveSyncManager?.syncTrialSensorData(atURL: saveURL, experimentID: experiment.ID)
      }
      completion?()
    })

    operationQueue.addOperation(writeTrialSensorDataToDiskOperation)
  }

  /// Deletes the sensor data proto for a trial from disk.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - experimentID: The ID of the experiment the trial belongs to.
  public func deleteSensorData(forTrialID trialID: String, experimentID: String) {
    let recordingURL = metadataManager.recordingURL(forTrialID: trialID,
                                                    experimentID: experimentID)
    do {
      try FileManager.default.removeItem(at: recordingURL)
    } catch {
      sjlog_error("Cannot remove sensor data proto: \(error.localizedDescription)",
                  category: .general)
    }
  }

  /// Checks an experiment's trials for corresponding sensor data protos on disk and writes any that
  /// are missing.
  func writeMissingSensorDataProtos(forExperiment experiment: Experiment) {
    let writeMissingProtosOp =
        WriteMissingSensorDataProtosOperation(experiment: experiment,
                                              metadataManager: metadataManager,
                                              sensorDataManager: sensorDataManager)
    operationQueue.addOperation(writeMissingProtosOp)
  }

  /// Do any needed work in preparation of the user session ending.
  func tearDown() {
    operationQueue.terminate()
  }

}
