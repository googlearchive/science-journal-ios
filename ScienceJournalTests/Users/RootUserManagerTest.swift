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

class RootUserManagerTest: XCTestCase {

  var rootUserManager: RootUserManager!

  override func setUp() {
    // Remove the root user during setup so we can test initialization from a clean state.
    let rootURL = URL.documentsDirectoryURL.appendingPathComponent("Science Journal")
    do {
      try FileManager.default.removeItem(at: rootURL)
    } catch {
      print("[RootUserManagerTest] Error deleting root user: \(error)")
    }

    rootUserManager = RootUserManager(sensorController: MockSensorController())
    rootUserManager.preferenceManager.resetAll()
  }

  func testDeleteAllUserData() {
    let prefManager = rootUserManager.preferenceManager
    let metadataManager = rootUserManager.metadataManager
    let dataManager = rootUserManager.sensorDataManager
    let dataDeleter = rootUserManager.experimentDataDeleter

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

    XCTAssertNoThrow(try rootUserManager.deleteAllUserData())

    XCTAssertTrue(prefManager.defaultExperimentWasCreated, "Root user preferences are not reset.")
    XCTAssertNil(metadataManager.experiment(withID: experiment1.ID))
    XCTAssertNil(metadataManager.experiment(withID: experiment2.ID))
    XCTAssertNil(metadataManager.experiment(withID: experiment3.ID))
    XCTAssertFalse(FileManager.default.fileExists(atPath: deletedDataPath))
    XCTAssertFalse(FileManager.default.fileExists(atPath: dataManager.storeURL.path))
  }

  func testIsSharingAllowed() {
    rootUserManager.preferenceManager.isUser13OrOlder = false
    XCTAssertFalse(rootUserManager.isSharingAllowed,
                   "If the user is not age 13 or older, sharing is not allowed.")

    rootUserManager.preferenceManager.isUser13OrOlder = true
    XCTAssertTrue(rootUserManager.isSharingAllowed,
                  "If the user is age 13 or older, sharing is allowed.")
  }

  func testShouldVerifyAge() {
    // `setup` reset all preferences, so `preferenceManager.hasUserVerifiedAge` is currently false.
    XCTAssertTrue(rootUserManager.shouldVerifyAge,
                  "Age verification should occur if a non-account user has not verified age.")

    // Setting `isUser13OrOlder` will set `preferenceManager.hasUserVerifiedAge` to true.
    rootUserManager.preferenceManager.isUser13OrOlder = true
    XCTAssertFalse(rootUserManager.shouldVerifyAge,
                   "Age verification should not occur if a non-account user has verified age.")
  }

  func testIsDriveSyncEnabled() {
    XCTAssertFalse(rootUserManager.isDriveSyncEnabled,
                   "Drive sync should never be enabled for the root user.")
  }

  func testHasExperimentsDirectoryAfterInitialization() {
    XCTAssertFalse(rootUserManager.hasExperimentsDirectory,
                   "After initialization there shouldn't yet be a root experiments directory.")
  }

}
