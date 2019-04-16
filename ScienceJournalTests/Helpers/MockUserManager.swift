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

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// A mock user manager that allows for injecting dependencies.
class MockUserManager: UserManager {
  var driveSyncManager: DriveSyncManager?
  var metadataManager: MetadataManager
  var preferenceManager: PreferenceManager
  var sensorDataManager: SensorDataManager
  var assetManager: UserAssetManager
  let experimentDataDeleter: ExperimentDataDeleter
  let documentManager: DocumentManager

  var isSharingAllowed: Bool {
    return false
  }

  var isDriveSyncEnabled: Bool {
    return false
  }

  init(driveSyncManager: DriveSyncManager?,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager,
       sensorDataManager: SensorDataManager,
       assetManager: UserAssetManager) {
    self.driveSyncManager = driveSyncManager
    self.metadataManager = metadataManager
    self.preferenceManager = preferenceManager
    self.sensorDataManager = sensorDataManager
    self.assetManager = assetManager
    experimentDataDeleter = ExperimentDataDeleter(accountID: "MockUser",
                                                  metadataManager: metadataManager,
                                                  sensorDataManager: sensorDataManager)
    documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                      metadataManager: metadataManager,
                                      sensorDataManager: sensorDataManager)
  }

  func tearDown() {}
  func deleteAllUserData() throws {}

}
