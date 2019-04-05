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

class ExperimentDataDeleterTest: XCTestCase {

  var experimentDataDeleter: ExperimentDataDeleter!
  let metadataManager = MetadataManager.testingInstance
  let sensorDataManager = SensorDataManager.testStore

  override func setUp() {
    experimentDataDeleter = ExperimentDataDeleter(accountID: "test_id",
                                                  metadataManager: metadataManager,
                                                  sensorDataManager: sensorDataManager)
  }

  func testPerformUndoableDeleteForExperiment() {
    let experiment = createExperimentAndAssert()
    let experimentID = experiment.ID

    let deletedExperiment =
        experimentDataDeleter.performUndoableDeleteForExperiment(withID: experimentID)
    XCTAssertNotNil(deletedExperiment)
    XCTAssertEqual(experimentID, deletedExperiment!.experimentID)
    assertExperimentIsDeleted(withID: experimentID)
    assertSensorDataExists(forTrialID: experiment.trials[0].ID)

    experimentDataDeleter.confirmDeletion(for: deletedExperiment!)
    assertExperimentIsDeleted(withID: experimentID)
    assertSensorDataDoesNotExist(forTrialID: experiment.trials[0].ID)
  }

  func testRestoreExperiment() {
    let experiment = createExperimentAndAssert()
    let experimentID = experiment.ID
    let deletedExperiment =
        experimentDataDeleter.performUndoableDeleteForExperiment(withID: experimentID)
    XCTAssertNotNil(deletedExperiment)
    assertExperimentIsDeleted(withID: experimentID)

    experimentDataDeleter.restoreExperiment(deletedExperiment!)
    assertExperimentExists(withID: experimentID)
    assertSensorDataExists(forTrialID: experiment.trials[0].ID)
  }

  func testPermanentlyDeleteExperiment() {
    let experiment = createExperimentAndAssert()
    let experimentID = experiment.ID

    assertSensorDataExists(forTrialID: experiment.trials[0].ID)

    let didDelete = experimentDataDeleter.permanentlyDeleteExperiment(withID: experimentID)
    XCTAssertTrue(didDelete)
    assertExperimentIsDeleted(withID: experimentID)
    assertSensorDataDoesNotExist(forTrialID: experiment.trials[0].ID)
  }

  func testImageDeleteAndRestore() {
    // Get an image.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    XCTAssertNotNil(image, "The test requires an image that exists.")

    // Get a path.
    let path = metadataManager.relativePicturePath(for: "ExperimentTestID")

    // Save the image.
    metadataManager.saveImage(image, atPicturePath: path, experimentID: "ExperimentTestID")
    XCTAssertNotNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                    "Image at path should not be nil.")

    // Delete the image.
    experimentDataDeleter.performUndoableDeleteForAsset(atPath: path,
                                                        experimentID: "ExperimentTestID")
    XCTAssertNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                 "Deleted image path should be nil.")

    // Restore the image.
    experimentDataDeleter.restoreAsset(atPath: path, experimentID: "ExperimentTestID")
    XCTAssertNotNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                    "Restored image should not be nil")
  }

  // MARK: - Helpers

  /// Creates an experiment that has one trial with sensor data, and asserts it and its data are on
  /// disk.
  ///
  /// - Returns: The experiment.
  func createExperimentAndAssert() -> Experiment {
    // Create the experiment.
    let (experiment, _) = metadataManager.createExperiment()

    // Create a trial with sensor data and add it to the experiment.
    let trial = Trial()
    let trialID = trial.ID
    experiment.trials.append(trial)
    metadataManager.saveExperiment(experiment)

    sensorDataManager.privateContext.performAndWait {
      for timestamp in 0...9 {
        let value = timestamp * 2
        SensorData.insert(dataPoint: DataPoint(x: Int64(timestamp), y: Double(value)),
                          forSensorID: "test sensor",
                          trialID: trialID,
                          resolutionTier: 0,
                          context: self.sensorDataManager.privateContext)
      }
      try! sensorDataManager.privateContext.save()
    }

    // Assert the experiment is on disk, along with its overview and trial sensor data.
    XCTAssertNotNil(metadataManager.experiment(withID: experiment.ID),
                    "The experiment should be on disk.")
    XCTAssertTrue(metadataManager.experimentOverviews.contains {
      $0.experimentID == experiment.ID }, "The experiment should have a corresponding overview.")

    assertSensorDataExists(forTrialID: trialID)

    return experiment
  }

  func assertSensorDataExists(forTrialID trialID: String) {
    let expectation = self.expectation(description: "Wait for sensor data fetch.")
    sensorDataManager.fetchSensorData(forSensorID: "test sensor",
                                      trialID: trialID) { (dataPoints) in
      XCTAssertEqual(10, dataPoints!.count)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func assertSensorDataDoesNotExist(forTrialID trialID: String) {
    let expectation = self.expectation(description: "Wait for sensor data fetch.")
    sensorDataManager.privateContext.perform {
      self.sensorDataManager.fetchSensorData(forSensorID: "test sensor",
                                             trialID: trialID) { (dataPoints) in
        XCTAssertEqual(0, dataPoints!.count)
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: 1)
  }

  /// Asserts the experiment with an ID and its overview are not on disk, as well as a trial's
  /// sensor data.
  ///
  /// - Parameters:
  ///   - experimentID: The experiment ID.
  ///   - trialID: The trial ID.
  func assertExperimentIsDeleted(withID experimentID: String) {
    XCTAssertNil(metadataManager.experiment(withID: experimentID),
                 "The experiment should be nil.")
    XCTAssertFalse(metadataManager.experimentOverviews.contains {
                       $0.experimentID == experimentID },
                   "The experiment should not have an overview.")
  }

  func assertExperimentExists(withID experimentID: String) {
    XCTAssertNotNil(metadataManager.experiment(withID: experimentID),
                    "The experiment should not be nil.")
    XCTAssertTrue(metadataManager.experimentOverviews.contains { $0.experimentID == experimentID },
                  "The experiment should have an overview.")
  }

}
