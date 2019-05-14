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

class ClaimExperimentsFlowControllerTest: XCTestCase, TestDirectories {

  var claimExperimentsFlowController: ClaimExperimentsFlowController!
  var existingDataMigrationManager: ExistingDataMigrationManager!

  override func setUp() {
    super.setUp()

    let mockSensorController = MockSensorController()
    let accountUserManager = AccountUserManager(account: MockAuthAccount(),
                                                driveConstructor: DriveConstructorDisabled(),
                                                networkAvailability: SettableNetworkAvailability(),
                                                sensorController: mockSensorController,
                                                analyticsReporter: AnalyticsReporterOpen())
    let rootUserManager = RootUserManager(
      sensorController: mockSensorController,
      documentsDirectoryURL: createUniqueTestDirectoryURL()
    )
    existingDataMigrationManager =
        ExistingDataMigrationManager(accountUserManager: accountUserManager,
                                     rootUserManager: rootUserManager)
    claimExperimentsFlowController =
        ClaimExperimentsFlowController(authAccount: MockAuthAccount(),
                                       analyticsReporter: AnalyticsReporterOpen(),
                                       existingDataMigrationManager: existingDataMigrationManager,
                                       sensorController: mockSensorController)
  }

  func testShowExperiment() {
    // Show an experiment. Assert that the experiment shown is the correct one. The experiment
    // interaction options should be read-only. The open experiment should also be correct.
    let (experiment, _) =
        existingDataMigrationManager.rootUserManager.metadataManager.createExperiment()
    claimExperimentsFlowController.showExperiment(experiment)

    XCTAssertEqual(claimExperimentsFlowController.experimentCoordinatorVC!.experiment.ID,
                   experiment.ID)
    XCTAssertEqual(
        claimExperimentsFlowController.experimentCoordinatorVC!.experimentInteractionOptions,
        ExperimentInteractionOptions.readOnlyWithItemDelete)
    XCTAssertEqual(claimExperimentsFlowController.openExperimentUpdateManager!.experiment.ID,
                   experiment.ID)
  }

  func testShowTrial() {
    // Show an experiment and then one of its trials. The trial shown should be correct, and the
    // experiment interaction options should be read-only.
    let (experiment, _) =
        existingDataMigrationManager.rootUserManager.metadataManager.createExperiment()
    let trial = Trial()
    experiment.trials.append(trial)
    claimExperimentsFlowController.showExperiment(experiment)
    claimExperimentsFlowController.showTrial(withID: trial.ID)

    XCTAssertEqual(claimExperimentsFlowController.trialDetailVC!.trialDetailDataSource.trial.ID,
                   trial.ID)
    XCTAssertEqual(
        claimExperimentsFlowController.trialDetailVC!.experimentInteractionOptions,
        ExperimentInteractionOptions.readOnlyWithItemDelete)
  }

  func testCloseClaimVCIfComplete() {
    // Confirm there are no existing experiments.
    XCTAssertEqual(existingDataMigrationManager.numberOfExistingExperiments,
                   0,
                   "There should be no existing experiments.")
    let (experiment, _) =
        existingDataMigrationManager.rootUserManager.metadataManager.createExperiment()
    // Confirm there is one.
    XCTAssertEqual(existingDataMigrationManager.numberOfExistingExperiments,
                   1,
                   "There should be one existing experiment.")
    XCTAssertFalse(claimExperimentsFlowController.dismissClaimFlowIfComplete(),
                   "There are existing experiments to migrate.")
    // Delete the experiment.
    let deleter = existingDataMigrationManager.rootUserManager.experimentDataDeleter
    _ = deleter.performUndoableDeleteForExperiment(withID: experiment.ID)
    // Confirm there are no experiments.
    XCTAssertEqual(existingDataMigrationManager.numberOfExistingExperiments,
                   0,
                   "There should be no existing experiments.")
    // Confirm we should close the claim VC.
    XCTAssertTrue(claimExperimentsFlowController.dismissClaimFlowIfComplete(),
                   "There are no existing experiments to migrate.")
  }

}
