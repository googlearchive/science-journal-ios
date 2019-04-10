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

class AccountUserManagerTest: XCTestCase {

  let accountUserManager = AccountUserManager(account: MockAuthAccount(),
                                              driveConstructor: DriveConstructorDisabled(),
                                              networkAvailability: SettableNetworkAvailability(),
                                              sensorController: MockSensorController(),
                                              analyticsReporter: AnalyticsReporterOpen())

  override func setUp() {
    super.setUp()
    accountUserManager.preferenceManager.resetAll()
  }

  func testDeleteAllUserData() {
    let prefManager = accountUserManager.preferenceManager
    let metadataManager = accountUserManager.metadataManager
    let dataManager = accountUserManager.sensorDataManager
    let dataDeleter = accountUserManager.experimentDataDeleter

    XCTAssertFalse(prefManager.defaultExperimentWasCreated)
    prefManager.defaultExperimentWasCreated = true
    XCTAssertTrue(prefManager.defaultExperimentWasCreated)

    let (experiment1, _) = metadataManager.createExperiment()
    let (experiment2, _) = metadataManager.createExperiment()
    let (experiment3, _) = metadataManager.createExperiment()
    XCTAssertNotNil(metadataManager.experiment(withID: experiment1.ID))
    XCTAssertNotNil(metadataManager.experiment(withID: experiment2.ID))
    XCTAssertNotNil(metadataManager.experiment(withID: experiment3.ID))

    // Move one experiment to the deleted data directory.
    _ = dataDeleter.performUndoableDeleteForExperiment(withID: experiment3.ID)
    XCTAssertNil(metadataManager.experiment(withID: experiment3.ID))
    let deletedDataPath = dataDeleter.deletedDataDirectoryURL.path
    XCTAssertTrue(FileManager.default.fileExists(atPath: deletedDataPath))

    XCTAssertTrue(FileManager.default.fileExists(atPath: dataManager.storeURL.path))

    XCTAssertNoThrow(try accountUserManager.deleteAllUserData())

    XCTAssertFalse(prefManager.defaultExperimentWasCreated)
    XCTAssertNil(metadataManager.experiment(withID: experiment1.ID))
    XCTAssertNil(metadataManager.experiment(withID: experiment2.ID))
    XCTAssertNil(metadataManager.experiment(withID: experiment3.ID))
    XCTAssertFalse(FileManager.default.fileExists(atPath: deletedDataPath))
    XCTAssertFalse(FileManager.default.fileExists(atPath: dataManager.storeURL.path))
  }

  func testIsSharingAllowed() {
    XCTAssertTrue(accountUserManager.isSharingAllowed, "Sharing is allowed for accounts.")
  }

  func testIsDriveSyncEnabled() {
    let disabledDriveConstructor = DriveConstructorDisabled()
    let accountUserManagerDriveDisabled =
        AccountUserManager(account: MockAuthAccount(),
                           driveConstructor: disabledDriveConstructor,
                           networkAvailability: SettableNetworkAvailability(),
                           sensorController: MockSensorController(),
                           analyticsReporter: AnalyticsReporterOpen())
    XCTAssertFalse(accountUserManagerDriveDisabled.isDriveSyncEnabled,
                   "Drive sync should be disabled when there is no drive sync manager.")

    let enabledDriveConstructor = MockDriveConstructor()
    let accountUserManagerDriveEnabled =
        AccountUserManager(account: MockAuthAccount(),
                           driveConstructor: enabledDriveConstructor,
                           networkAvailability: SettableNetworkAvailability(),
                           sensorController: MockSensorController(),
                           analyticsReporter: AnalyticsReporterOpen())
    XCTAssertTrue(accountUserManagerDriveEnabled.isDriveSyncEnabled,
                   "Drive sync should be enabled with a non-nil drive sync manager.")
  }

}
