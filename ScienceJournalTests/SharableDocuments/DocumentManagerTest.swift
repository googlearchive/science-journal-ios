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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class DocumentManagerTest: XCTestCase {

  let metadataManager = MetadataManager.testingInstance
  let sensorDataManager = SensorDataManager.testStore
  var documentManager: DocumentManager!

  override func setUp() {
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "DocumentManagerTest",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                      metadataManager: metadataManager,
                                      sensorDataManager: sensorDataManager)
  }

  func testExperimentIsReadyForExport() {

    let (experiment, _) = metadataManager.createExperiment()

    assertExperiment(experiment,
                     isReady: true,
                     message: "Experiment with no assets is ready for export.")

    let pictureNote = PictureNote()
    pictureNote.filePath = "assets/asset.jpg"
    experiment.addNote(pictureNote)

    assertExperiment(experiment,
                     isReady: false,
                     message: "Experiment with a picture note but no asset on disk is not ready"
                                + " for export.")

    let asset = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    metadataManager.saveImage(asset,
                              atPicturePath: "assets/asset.jpg",
                              experimentID: experiment.ID)

    assertExperiment(experiment,
                     isReady: true,
                     message: "Experiment with a picture note and asset on disk is ready.")

    let trial = Trial()
    experiment.addTrial(trial, isUndo: false)

    assertExperiment(experiment,
                     isReady: false,
                     message: "Experiment with a trial but no sensor data isn't ready to export.")

    sensorDataManager.privateContext.performAndWait {
      SensorData.insert(dataPoint: DataPoint(x: 22, y: 222),
                        forSensorID: "sensor_id",
                        trialID: trial.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
    }

    assertExperiment(experiment,
                     isReady: true,
                     message: "Experiment with trial and at least 1 data point is ready to export.")
  }

  func assertExperiment(_ experiment: Experiment, isReady: Bool, message: String) {
    let expectation = self.expectation(description: "Ready check complete.")
    documentManager.experimentIsReadyForExport(experiment) { (ready) in
      XCTAssertTrue(ready == isReady, message)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
