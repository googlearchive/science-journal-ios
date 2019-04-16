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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class UserAssetManagerTest: XCTestCase {

  let sensorDataManager = SensorDataManager.testStore
  let trialID = "test_trial"

  override func setUp() {
    super.setUp()

    // Clean up any old data.
    sensorDataManager.performChanges(andWait: true, save: true) {
      self.sensorDataManager.removeData(forTrialID: self.trialID)
    }
  }

  func testStoreAndDeleteSensorData() {
    let metadataManager = MetadataManager.testingInstance
    let userAssetManager = UserAssetManager(driveSyncManager: nil,
                                            metadataManager: metadataManager,
                                            sensorDataManager: sensorDataManager)

    let sensorID = "test_sensor"
    let sensorLayout = SensorLayout(sensorID: sensorID, colorPalette: .blue)
    let trial = Trial()
    trial.proto.trialId = trialID
    trial.sensorLayouts = [sensorLayout]
    let experiment = Experiment(ID: "test_experiment")
    experiment.addTrial(trial, isUndo: false)
    metadataManager.saveExperiment(experiment)

    sensorDataManager.privateContext.performAndWait {
      SensorData.insert(dataPoint: DataPoint(x: 1, y: 2),
                        forSensorID: sensorID,
                        trialID: trial.ID,
                        resolutionTier: 0,
                        context: sensorDataManager.privateContext)
      SensorData.insert(dataPoint: DataPoint(x: 3, y: 4),
                        forSensorID: sensorID,
                        trialID: trial.ID,
                        resolutionTier: 0,
                        context: sensorDataManager.privateContext)
      try! sensorDataManager.privateContext.save()
    }

    let recordingURL = metadataManager.recordingURL(forTrialID: trial.ID,
                                                    experimentID: experiment.ID)

    let storeExpectation =
        expectation(description: "Completion should be called when finished storing sensor data.")
    userAssetManager.storeSensorData(forTrial: trial,
                                     experiment: experiment) {
      XCTAssertTrue(FileManager.default.fileExists(atPath: recordingURL.path))
      storeExpectation.fulfill()
    }
    waitForExpectations(timeout: 2)

    userAssetManager.deleteSensorData(forTrialID: trial.ID, experimentID: experiment.ID)
    XCTAssertFalse(FileManager.default.fileExists(atPath: recordingURL.path))
  }

}
