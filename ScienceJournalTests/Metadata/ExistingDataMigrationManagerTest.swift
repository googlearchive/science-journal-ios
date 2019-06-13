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

class ExistingDataMigrationManagerTest: XCTestCase {

  var accountMetadataManager: MetadataManager!
  var accountSensorDataManager: SensorDataManager!
  var accountUserManager: UserManager!
  var rootMetadataManager: MetadataManager!
  var rootSensorDataManager: SensorDataManager!
  var rootUserManager: UserManager!
  var existingDataMigrationManager: ExistingDataMigrationManager!
  var sensorController = MockSensorController()

  override func setUp() {
    super.setUp()

    let rootURL = createUniqueTestDirectoryURL()
    accountMetadataManager = createMetadataManager(rootURL: rootURL)
    accountSensorDataManager = createSensorDataManager(rootURL: rootURL)
    let accountPreferenceManager = PreferenceManager(accountID: "ExistingDataMigrationManagerTest")
    let accountAssetManager = UserAssetManager(driveSyncManager: nil,
                                               metadataManager: accountMetadataManager,
                                               sensorDataManager: accountSensorDataManager)
    accountUserManager = MockUserManager(driveSyncManager: nil,
                                         metadataManager: accountMetadataManager,
                                         preferenceManager: accountPreferenceManager,
                                         sensorDataManager: accountSensorDataManager,
                                         assetManager: accountAssetManager)

    rootMetadataManager = createMetadataManager(sensorController: sensorController)
    rootSensorDataManager = createSensorDataManager()
    let rootPreferenceManager = PreferenceManager(accountID: "ExistingDataMigrationManagerTest")
    let rootAssetManager = UserAssetManager(driveSyncManager: nil,
                                            metadataManager: accountMetadataManager,
                                            sensorDataManager: accountSensorDataManager)
    rootUserManager = MockUserManager(driveSyncManager: nil,
                                      metadataManager: rootMetadataManager,
                                      preferenceManager: rootPreferenceManager,
                                      sensorDataManager: rootSensorDataManager,
                                      assetManager: rootAssetManager)

    existingDataMigrationManager =
        ExistingDataMigrationManager(accountUserManager: accountUserManager,
                                     rootUserManager: rootUserManager)
  }

  func testMigrateExperiment() {
    // Create two experiments with trials and sensor data.
    let (experiment1, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID1 = experiment1.ID
    let trial1 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial1.ID)
    experiment1.trials.append(trial1)
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    rootUserManager.metadataManager.saveImage(
        image,
        atPicturePath: rootUserManager.metadataManager.importExportCoverImagePath,
        experimentID: experimentID1)
    rootUserManager.metadataManager.saveExperiment(experiment1)

    let (experiment2, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID2 = experiment2.ID
    let trial2 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial2.ID)
    experiment2.trials.append(trial2)
    rootUserManager.metadataManager.saveExperiment(experiment2)

    // Assert the experiments and assets are there.
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootUserManager.metadataManager.assetsURL(
        for: experiment1).appendingPathComponent("ExperimentCoverImage").appendingPathExtension(
            "jpg").path))
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))

    // Assert the sensor data is there.
    let expectation1 = expectation(description: "Fetch trial 1 sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial1.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation1.fulfill()
    })

    let expectation2 = expectation(description: "Fetch trial 2 sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation2.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Migrate the first experiment.
    let expectation3 = expectation(description: "Migrate experiment 1.")
    existingDataMigrationManager.migrateExperiment(withID: experimentID1, completion: { (errors) in
      XCTAssertTrue(errors.isEmpty)
      expectation3.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Assert the first experiment is in the account metadata manager and deleted from the root
    // metadata manager. The assets should be moved from root user storage to account user storage.
    // The second experiment should still be in the root metadata manager, and should not be in the
    // account metadata manager.
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertFalse(FileManager.default.fileExists(atPath: rootUserManager.metadataManager.assetsURL(
        for: experiment1).appendingPathComponent("ExperimentCoverImage").appendingPathExtension(
            "jpg").path))
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertTrue(FileManager.default.fileExists(
        atPath: accountUserManager.metadataManager.assetsURL(
            for: experiment1).appendingPathComponent("ExperimentCoverImage").appendingPathExtension(
                "jpg").path))
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))
    XCTAssertNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    // Assert the sensor data for experiment 1 is in the account sensor data manager and deleted
    // from the root sensor data manager. The second experiment's sensor data should still be in the
    // root sensor data manager, and should not be in the account sensor data manager.
    let expectation4 =
        expectation(description: "Trial 1 sensor data should be deleted for the root user.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial1.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation4.fulfill()
    })

    let expectation5 =
        expectation(description: "Trial 1 sensor data should be stored for the account user.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial1.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation5.fulfill()
    })

    let expectation6 =
        expectation(description: "Trial 2 sensor data should still be stored for the root user.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation6.fulfill()
    })

    let expectation7 =
        expectation(description: "Trial 2 sensor data should not be stored for the account user.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation7.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Migrate the second experiment.
    let expectation8 = expectation(description: "Migrate experiment 2.")
    existingDataMigrationManager.migrateExperiment(withID: experimentID2, completion: { (errors) in
      XCTAssertTrue(errors.isEmpty)
      expectation8.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Assert it is in the account metadata manager and deleted from the root metadata manager.
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    // Assert its sensor data is in the account sensor data manager and deleted from the root sensor
    // data manager.
    let expectation9 =
        expectation(description: "Trial 2 sensor data should be deleted for the root user.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation9.fulfill()
    })

    let expectation10 =
        expectation(description: "Trial 2 sensor data should be stored for the account user.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation10.fulfill()
    })

    waitForExpectations(timeout: 1)
  }

  func testMigrateAllExperiments() {
    // Create two experiments with trials and sensor data.
    let (experiment1, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID1 = experiment1.ID
    let trial1 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial1.ID)
    experiment1.trials.append(trial1)
    rootUserManager.metadataManager.saveExperiment(experiment1)

    let (experiment2, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID2 = experiment2.ID
    let trial2 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial2.ID)
    experiment2.trials.append(trial2)
    rootUserManager.metadataManager.saveExperiment(experiment2)

    // Assert the experiments are in root, not account storage.
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))
    XCTAssertNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    // Migrate all experiments.
    let expectation1 = expectation(description: "Migrate experiments.")
    existingDataMigrationManager.migrateAllExperiments(completion: { (errors) in
      XCTAssertTrue(errors.isEmpty)
      expectation1.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Confirm the two experiments are in account storage, not root.
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    XCTAssertEqual(existingDataMigrationManager.numberOfExistingExperiments,
                   0,
                   "There should be no existing experiments.")
  }

  func testMigrateExperimentLoadError() {
    // Attempt to migrate an experiment with an ID that does not exist. Assert that the experiment
    // load error is passed back with the ID.
    let expectation1 = expectation(description: "Migrate experiment.")
    let experimentID = "does_not_exist"
    existingDataMigrationManager.migrateExperiment(withID: experimentID, completion: { (errors) in
      switch errors[0] {
      case .experimentLoadError(let errorExperimentID):
        XCTAssertEqual(errorExperimentID, experimentID)
        expectation1.fulfill()
      case .experimentSaveError(_), .sensorDataFetchError(_), .assetsSaveError(_),
          .notEnoughFreeDiskSpaceToMigrate(_):
        XCTFail()
      }
    })
    waitForExpectations(timeout: 1)
  }

  func testMigrateExperimentWithAccountSensorData() {
    // Create an experiment and a trial. Put the same sensor data in root and the account.
    let (experiment, _) = rootUserManager.metadataManager.createExperiment()
    let trial = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial.ID)
    populateAccountUserManagerWithSensorData(forTrialID: trial.ID, numberOfPoints: 3)
    experiment.trials.append(trial)
    rootUserManager.metadataManager.saveExperiment(experiment)

    // Assert the experiment is in root and not account.
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))
    XCTAssertNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))

    // Assert the sensor data is in root and account.
    var rootSensorData: [DataPoint]!
    let expectation1 = expectation(description: "Fetch root sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                         completion: { (sensorData, _) in
      // Copy sensor data as data points because the fetch context is reset after completion.
      rootSensorData = sensorData?.dataPoints
      XCTAssertEqual(3, sensorData!.count)
      expectation1.fulfill()
    })
    let expectation2 = expectation(description: "Fetch account sensor data.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation2.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Migrate the experiment.
    let expectation3 = expectation(description: "Migrate experiment.")
    existingDataMigrationManager.migrateExperiment(withID: experiment.ID, completion: { (errors) in
      XCTAssertTrue(errors.isEmpty)
      expectation3.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Assert the experiment is in account and not root.
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))

    // Assert the sensor data is in account and not root, and the account only has 3 data points,
    // matching the previous root sensor data.
    let expectation4 = expectation(description: "Fetch root sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation4.fulfill()
    })
    let expectation5 = expectation(description: "Fetch account sensor data.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      XCTAssertEqual(rootSensorData[0].x, sensorData![0].timestamp)
      XCTAssertEqual(rootSensorData[0].y, sensorData![0].value)
      XCTAssertEqual(rootSensorData[1].x, sensorData![1].timestamp)
      XCTAssertEqual(rootSensorData[1].y, sensorData![1].value)
      XCTAssertEqual(rootSensorData[2].x, sensorData![2].timestamp)
      XCTAssertEqual(rootSensorData[2].y, sensorData![2].value)
      expectation5.fulfill()
    })

    waitForExpectations(timeout: 1)
  }

  func testMigrateExperimentWithWrongAccountSensorDataCount() {
    // Create an experiment and a trial. Put the same sensor data in root and the account.
    let (experiment, _) = rootUserManager.metadataManager.createExperiment()
    let trial = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial.ID)
    populateAccountUserManagerWithSensorData(forTrialID: trial.ID, numberOfPoints: 2)
    experiment.trials.append(trial)
    rootUserManager.metadataManager.saveExperiment(experiment)

    // Assert the experiment is in root and not account.
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))
    XCTAssertNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))

    // Assert the sensor data is in root and account.
    var rootSensorData: [DataPoint]!
    let expectation1 = expectation(description: "Fetch root sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                         completion: { (sensorData, _) in
      // Copy sensor data as data points because the fetch context is reset after completion.
      rootSensorData = sensorData?.dataPoints
      XCTAssertEqual(3, sensorData!.count)
      expectation1.fulfill()
    })
    let expectation2 = expectation(description: "Fetch account sensor data.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(2, sensorData!.count)
      expectation2.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Migrate the experiment.
    let expectation3 = expectation(description: "Migrate experiment.")
    existingDataMigrationManager.migrateExperiment(withID: experiment.ID, completion: { (errors) in
      XCTAssertTrue(errors.isEmpty)
      expectation3.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Assert the experiment is in account and not root.
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))

    // Assert the sensor data is in account and not root, and the account only has 3 data points.
    let expectation4 = expectation(description: "Fetch root sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation4.fulfill()
    })
    let expectation5 = expectation(description: "Fetch account sensor data.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      XCTAssertEqual(rootSensorData[0].x, sensorData![0].timestamp)
      XCTAssertEqual(rootSensorData[0].y, sensorData![0].value)
      XCTAssertEqual(rootSensorData[1].x, sensorData![1].timestamp)
      XCTAssertEqual(rootSensorData[1].y, sensorData![1].value)
      XCTAssertEqual(rootSensorData[2].x, sensorData![2].timestamp)
      XCTAssertEqual(rootSensorData[2].y, sensorData![2].value)
      expectation5.fulfill()
    })

    waitForExpectations(timeout: 1)
  }

  func testMigrateExperimentWithNoAccountSensorData() {
    // Create an experiment and a trial. Put the same sensor data in root and the account.
    let (experiment, _) = rootUserManager.metadataManager.createExperiment()
    let trial = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial.ID)
    experiment.trials.append(trial)
    rootUserManager.metadataManager.saveExperiment(experiment)

    // Assert the experiment is in root and not account.
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))
    XCTAssertNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))

    // Assert the sensor data is in root and account.
    var rootSensorData: [DataPoint]!
    let expectation1 = expectation(description: "Fetch root sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                         completion: { (sensorData, _) in
      // Copy sensor data as data points because the fetch context is reset after completion.
      rootSensorData = sensorData?.dataPoints
      XCTAssertEqual(3, sensorData!.count)
      expectation1.fulfill()
    })
    let expectation2 = expectation(description: "Fetch account sensor data.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation2.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Migrate the experiment.
    let expectation3 = expectation(description: "Migrate experiment.")
    existingDataMigrationManager.migrateExperiment(withID: experiment.ID, completion: { (errors) in
      XCTAssertTrue(errors.isEmpty)
      expectation3.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Assert the experiment is in account and not root.
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))
    XCTAssertNotNil(
        accountUserManager.metadataManager.experimentAndOverview(forExperimentID: experiment.ID))

    // Assert the sensor data is in account and not root, and the account only has 3 data points.
    let expectation4 = expectation(description: "Fetch root sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation4.fulfill()
    })
    let expectation5 = expectation(description: "Fetch account sensor data.")
    accountUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                            completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      XCTAssertEqual(rootSensorData[0].x, sensorData![0].timestamp)
      XCTAssertEqual(rootSensorData[0].y, sensorData![0].value)
      XCTAssertEqual(rootSensorData[1].x, sensorData![1].timestamp)
      XCTAssertEqual(rootSensorData[1].y, sensorData![1].value)
      XCTAssertEqual(rootSensorData[2].x, sensorData![2].timestamp)
      XCTAssertEqual(rootSensorData[2].y, sensorData![2].value)
      expectation5.fulfill()
    })

    waitForExpectations(timeout: 1)
  }

  func testRemoveExperiment() {
    // Create two experiments with trials and sensor data.
    let (experiment1, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID1 = experiment1.ID
    let trial1 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial1.ID)
    experiment1.trials.append(trial1)
    rootUserManager.metadataManager.saveExperiment(experiment1)

    let (experiment2, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID2 = experiment2.ID
    let trial2 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial2.ID)
    experiment2.trials.append(trial2)
    rootUserManager.metadataManager.saveExperiment(experiment2)

    // Assert the experiments are there.
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    // Assert the sensor data is there.
    let expectation1 = expectation(description: "Fetch trial 1 sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial1.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation1.fulfill()
    })

    let expectation2 = expectation(description: "Fetch trial 2 sensor data.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation2.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Remove the first experiment.
    let expectation3 = expectation(description: "Remove experiment from root complete.")
    existingDataMigrationManager.removeExperimentFromRootUser(withID: experiment1.ID) {
      expectation3.fulfill()
    }

    waitForExpectations(timeout: 1)

    // Assert the first experiment is deleted, second is still there.
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1))
    XCTAssertNotNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    // Assert the sensor data for experiment 1 is deleted.
    let expectation4 = expectation(description: "Trial 1 sensor data should be deleted.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial1.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation4.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Assert the sensor data for experiment 2 is still there.
    let expectation5 = expectation(description: "Trial 2 sensor data should not be deleted.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertEqual(3, sensorData!.count)
      expectation5.fulfill()
    })

    waitForExpectations(timeout: 1)

    // Remove the second experiment.
    let expectation6 = expectation(description: "Remove experiment from root complete.")
    existingDataMigrationManager.removeExperimentFromRootUser(withID: experiment2.ID) {
      expectation6.fulfill()
    }
    waitForExpectations(timeout: 1)

    // Assert it is deleted.
    XCTAssertNil(
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2))

    // Assert its sensor data is deleted.
    let expectation7 = expectation(description: "Trial 2 sensor data should be deleted.")
    rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial2.ID,
                                                         completion: { (sensorData, _) in
      XCTAssertTrue(sensorData!.isEmpty)
      expectation7.fulfill()
    })

    waitForExpectations(timeout: 1)
  }

  func testRemoveAllExperimentsForRootUser() {
    // Create two experiments with trials and sensor data.
    let (experiment1, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID1 = experiment1.ID
    let trial1 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial1.ID)
    experiment1.trials.append(trial1)
    rootUserManager.metadataManager.saveExperiment(experiment1)

    let (experiment2, _) = rootUserManager.metadataManager.createExperiment()
    let experimentID2 = experiment2.ID
    let trial2 = Trial()
    populateRootUserManagerWithSensorData(forTrialID: trial2.ID)
    experiment2.trials.append(trial2)
    rootUserManager.metadataManager.saveExperiment(experiment2)

    // Assert the experiments are there.
    let experimentAndOverview1 =
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1)
    XCTAssertNotNil(experimentAndOverview1)
    let experimentAndOverview2 =
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2)
    XCTAssertNotNil(experimentAndOverview2)

    // Remove all experiments.
    existingDataMigrationManager.removeAllExperimentsFromRootUser()

    // Confirm the two experiments are gone.
    let experimentAndOverview1a =
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID1)
    XCTAssertNil(experimentAndOverview1a)
    let experimentAndOverview2a =
        rootUserManager.metadataManager.experimentAndOverview(forExperimentID: experimentID2)
    XCTAssertNil(experimentAndOverview2a)

    // Confirm there are no existing experiments.
    XCTAssertEqual(existingDataMigrationManager.numberOfExistingExperiments,
                   0,
                   "There should be no existing experiments.")
  }

  func testMigratePreferences() {
    // This test will use the preference for data tracking to confirm that preference migration is
    // occuring.

    accountUserManager.preferenceManager.resetAll()

    // Set the root user preference for data tracking to true.
    rootUserManager.preferenceManager.hasUserOptedOutOfUsageTracking = true

    // Migrate preferences.
    existingDataMigrationManager.migratePreferences()

    // Assert the account user's preference for data tracking is true.
    XCTAssertTrue(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)

    // Set the root user preference for data tracking to false.
    rootUserManager.preferenceManager.hasUserOptedOutOfUsageTracking = false

    // Migrate preferences.
    existingDataMigrationManager.migratePreferences()

    // Assert the account user's preference for data tracking is false.
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)
  }

  func testRemoveAllBluetoothDevices() {
    // Confirm there are no BLE sensors.
    XCTAssertEqual(0, sensorController.bluetoothSensorCount)

    // Create two test sensors.
    let interface1 = TestSensorInterface(identifier: "INTERFACE 1")
    let sensor1 = BluetoothSensor(sensorInterface: interface1, sensorTimer: UnifiedSensorTimer())
    sensorController.addOrUpdateBluetoothSensor(sensor1)
    XCTAssertEqual(1, sensorController.bluetoothSensorCount)

    let interface2 = TestSensorInterface(identifier: "INTERFACE 2")
    let sensor2 = BluetoothSensor(sensorInterface: interface2, sensorTimer: UnifiedSensorTimer())
    sensorController.addOrUpdateBluetoothSensor(sensor2)
    XCTAssertEqual(2, sensorController.bluetoothSensorCount)

    // Remove all BLE devices.
    existingDataMigrationManager.removeAllBluetoothDevices()

    // Confirm.
    XCTAssertEqual(0, sensorController.bluetoothSensorCount)
  }

  // MARK: - Helpers

  func populateRootUserManagerWithSensorData(forTrialID trialID: String) {
    rootUserManager.sensorDataManager.addSensorDataPoint(DataPoint(x: 1, y: 5),
                                                         sensorID: "test",
                                                         trialID: trialID,
                                                         resolutionTier: 0)
    rootUserManager.sensorDataManager.addSensorDataPoint(DataPoint(x: 2, y: 6),
                                                         sensorID: "test",
                                                         trialID: trialID,
                                                         resolutionTier: 1)
    rootUserManager.sensorDataManager.addSensorDataPoint(DataPoint(x: 3, y: 7),
                                                         sensorID: "test",
                                                         trialID: trialID,
                                                         resolutionTier: 2)
    rootUserManager.sensorDataManager.savePrivateContext(andWait: true)
  }

  // Maximum number of points is 3.
  func populateAccountUserManagerWithSensorData(forTrialID trialID: String,
                                                numberOfPoints: Int) {
    let maxPoints = min(3, numberOfPoints)
    for index in 0..<maxPoints {
      accountUserManager.sensorDataManager.addSensorDataPoint(
          DataPoint(x: Int64(index + 1), y: Double(index + 5)),
          sensorID: "test",
          trialID: trialID,
          resolutionTier: Int16(index))
    }
    accountUserManager.sensorDataManager.savePrivateContext(andWait: true)
  }

}
