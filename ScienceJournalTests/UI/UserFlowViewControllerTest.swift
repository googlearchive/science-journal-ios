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

/// A partial mock metadata manager that has an expectation that is fulfilled when
/// `createDefaultExperimentIfNecessary()` is called.
class PartialMockMetadataManager: MetadataManager {

  var createDefaultExperimentCalledExpectation: XCTestExpectation?

  convenience init() {
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    let rootURL = tempDirectory.appendingPathComponent("TESTING-" + UUID().uuidString)
    self.init(rootURL: rootURL,
              deletedRootURL: rootURL,
              preferenceManager: PreferenceManager(),
              sensorController: MockSensorController(),
              sensorDataManager: SensorDataManager.testStore)
  }

  override func createDefaultExperimentIfNecessary() {
    super.createDefaultExperimentIfNecessary()
    createDefaultExperimentCalledExpectation?.fulfill()
  }

}

class UserFlowViewControllerTest: XCTestCase {

  let mockDriveSyncManager = MockDriveSyncManager()
  let mockUserAssetManager = MockUserAssetManager()
  let partialMockMetadataManager = PartialMockMetadataManager()
  let preferenceManager = PreferenceManager()
  var userFlowViewController: UserFlowViewController!

  override func setUp() {
    super.setUp()

    let authAccount = MockAuthAccount(ID: "testID")
    let mockAccountsManager = MockAccountsManager(mockAuthAccount: authAccount)
    let mockUserManager = MockUserManager(driveSyncManager: mockDriveSyncManager,
                                          metadataManager: partialMockMetadataManager,
                                          preferenceManager: preferenceManager,
                                          sensorDataManager: SensorDataManager.testStore)
    userFlowViewController =
        UserFlowViewController(accountsManager: mockAccountsManager,
                               analyticsReporter: AnalyticsReporterOpen(),
                               commonUIComponents: CommonUIComponentsOpen(),
                               devicePreferenceManager: DevicePreferenceManager(),
                               drawerConfig: DrawerConfigOpen(),
                               existingDataMigrationManager: nil,
                               feedbackReporter: FeedbackReporterOpen(),
                               networkAvailability: SettableNetworkAvailability(),
                               sensorController: MockSensorController(),
                               shouldShowPreferenceMigrationMessage: false,
                               userAssetManager: mockUserAssetManager,
                               userManager: mockUserManager)
  }

  func testShowExperimentWithCurrentVersion() {
    let experiment = Experiment(ID: "test experiment")
    experiment.fileVersion.version = Experiment.Version.major
    experiment.fileVersion.minorVersion = Experiment.Version.minor

    userFlowViewController.showExperiment(experiment)

    XCTAssertEqual(userFlowViewController.experimentCoordinatorVC!.experiment.ID,
                   experiment.ID)
    XCTAssertEqual(
        userFlowViewController.experimentCoordinatorVC!.experimentInteractionOptions,
        ExperimentInteractionOptions.normal)
  }

  func testShowExperimentWithNewerMinorVersion() {
    let experiment = Experiment(ID: "test experiment")
    experiment.fileVersion.version = Experiment.Version.major
    experiment.fileVersion.minorVersion = Experiment.Version.minor + 1

    userFlowViewController.showExperiment(experiment)

    XCTAssertEqual(userFlowViewController.experimentCoordinatorVC!.experiment.ID,
                   experiment.ID)
    XCTAssertEqual(
        userFlowViewController.experimentCoordinatorVC!.experimentInteractionOptions,
        ExperimentInteractionOptions.readOnly)
  }

  func testSensorDataDeleted() {
    let experiment = Experiment(ID: "test experiment")
    let trial = Trial()
    experiment.addTrial(trial, isUndo: false)

    XCTAssertNil(mockUserAssetManager.deleteSensorDataCallParameters)

    userFlowViewController.experimentViewControllerDeleteTrialCompleted(trial,
                                                                        fromExperiment: experiment)

    XCTAssertNotNil(mockUserAssetManager.deleteSensorDataCallParameters)
    let (trialIDParam, experimentIDParam) = mockUserAssetManager.deleteSensorDataCallParameters!
    XCTAssertEqual(trial.ID, trialIDParam)
    XCTAssertEqual(experiment.ID, experimentIDParam)
  }

  func testCreateDefaultExperimentWithDriveSyncNotCreatedAgain() {
    partialMockMetadataManager.createDefaultExperimentCalledExpectation =
        expectation(description: "The default experiment should not be created.")
    partialMockMetadataManager.createDefaultExperimentCalledExpectation?.isInverted = true
    preferenceManager.defaultExperimentWasCreated = true
    userFlowViewController.viewDidAppear(false)
    waitForExpectations(timeout: 3)

    XCTAssertEqual(partialMockMetadataManager.experimentOverviews.count,
                   0,
                   "An experiment should not have been created.")
  }

  func testCreateDefaultExperimentNoDriveSync() {
    partialMockMetadataManager.createDefaultExperimentCalledExpectation =
        expectation(description: "The default experiment should be created.")
    let authAccount = MockAuthAccount(ID: "testID")
    let mockAccountsManager = MockAccountsManager(mockAuthAccount: authAccount)
    let mockUserManager = MockUserManager(driveSyncManager: nil,
                                          metadataManager: partialMockMetadataManager,
                                          preferenceManager: preferenceManager,
                                          sensorDataManager: SensorDataManager.testStore)
    userFlowViewController =
        UserFlowViewController(accountsManager: mockAccountsManager,
                               analyticsReporter: AnalyticsReporterOpen(),
                               commonUIComponents: CommonUIComponentsOpen(),
                               devicePreferenceManager: DevicePreferenceManager(),
                               drawerConfig: DrawerConfigOpen(),
                               existingDataMigrationManager: nil,
                               feedbackReporter: FeedbackReporterOpen(),
                               networkAvailability: SettableNetworkAvailability(),
                               sensorController: MockSensorController(),
                               shouldShowPreferenceMigrationMessage: false,
                               userAssetManager: mockUserAssetManager,
                               userManager: mockUserManager)
    preferenceManager.defaultExperimentWasCreated = false
    userFlowViewController.viewDidAppear(false)
    waitForExpectations(timeout: 3)

    XCTAssertEqual(partialMockMetadataManager.experimentOverviews.count,
                   1,
                   "An experiment should have been created.")
    XCTAssertEqual(partialMockMetadataManager.experimentOverviews[0].title,
                   "Welcome to Science Journal",
                   "The experiment's title should be 'Welcome to Science Journal'")
  }

  func testCreateDefaultExperimentWithDriveSyncUnknownExistence() {
    partialMockMetadataManager.createDefaultExperimentCalledExpectation =
        expectation(description: "The default experiment should not be created.")
    partialMockMetadataManager.createDefaultExperimentCalledExpectation?.isInverted = true
    mockDriveSyncManager.mockExperimentLibraryExistsValue = nil
    preferenceManager.defaultExperimentWasCreated = false
    userFlowViewController.viewDidAppear(false)
    waitForExpectations(timeout: 3)

    XCTAssertTrue(preferenceManager.defaultExperimentWasCreated,
                  "`defaultExperimentWasCreated` should be set to true.")
    XCTAssertEqual(partialMockMetadataManager.experimentOverviews.count,
                   0,
                   "An experiment should not have been created.")
  }

  func testCreateDefaultExperimentWithDriveSyncLibraryExists() {
    partialMockMetadataManager.createDefaultExperimentCalledExpectation =
        expectation(description: "The default experiment should not be created.")
    partialMockMetadataManager.createDefaultExperimentCalledExpectation?.isInverted = true
    mockDriveSyncManager.mockExperimentLibraryExistsValue = true
    preferenceManager.defaultExperimentWasCreated = false
    userFlowViewController.viewDidAppear(false)
    waitForExpectations(timeout: 3)

    XCTAssertTrue(preferenceManager.defaultExperimentWasCreated,
                  "`defaultExperimentWasCreated` should be set to true.")
    XCTAssertEqual(partialMockMetadataManager.experimentOverviews.count,
                   0,
                   "An experiment should not have been created.")
  }

  func testCreateDefaultExperimentWithDriveSyncLibraryDoesNotExist() {
    partialMockMetadataManager.createDefaultExperimentCalledExpectation =
        expectation(description: "The default experiment should not be created.")
    mockDriveSyncManager.mockExperimentLibraryExistsValue = false
    preferenceManager.defaultExperimentWasCreated = false
    userFlowViewController.viewDidAppear(false)
    waitForExpectations(timeout: 3)

    XCTAssertEqual(partialMockMetadataManager.experimentOverviews.count,
                   1,
                   "An experiment should have been created.")
    XCTAssertEqual(partialMockMetadataManager.experimentOverviews[0].title,
                   "Welcome to Science Journal",
                   "The experiment's title should be 'Welcome to Science Journal'")

  }

}
