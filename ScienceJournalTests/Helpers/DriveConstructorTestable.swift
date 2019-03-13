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

import Foundation

import googlemac_iPhone_Shared_SSOAuth_SSOAuth

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// A mock drive constructor used for testing.
class MockDriveConstructor: DriveConstructor {
  let mockDriveSyncManager = MockDriveSyncManager()
  /// Returns a mock drive sync manager when called.
  func driveSyncManager(withAuthorization authorization: GTMFetcherAuthorizationProtocol,
                        metadataManager: MetadataManager,
                        networkAvailability: NetworkAvailability,
                        preferenceManager: PreferenceManager,
                        sensorDataManager: SensorDataManager,
                        analyticsReporter: AnalyticsReporter) -> DriveSyncManager? {
    return mockDriveSyncManager
  }
}

/// A Drive sync manager that calls completion with a mock value when `experimentLibraryExists()` is
/// called.
class MockDriveSyncManager: DriveSyncManager {
  var delegate: DriveSyncManagerDelegate?
  func syncExperimentLibrary(andReconcile shouldReconcile: Bool, userInitiated: Bool) {}
  func syncExperiment(withID experimentID: String,
                      condition: DriveExperimentSyncCondition) {}
  func syncTrialSensorData(atURL url: URL, experimentID: String) {}
  func deleteExperiment(withID experimentID: String) {}
  func deleteImageAssets(atURLs urls: [URL], experimentID: String) {}
  func deleteSensorDataAsset(atURL url: URL, experimentID: String) {}
  func debug_removeAllUserDriveData(completion: @escaping (Int, [Error]) -> Void) {}

  var mockExperimentLibraryExistsValue: Bool?
  var tearDownCalled = false

  func experimentLibraryExists(completion: @escaping (Bool?) -> Void) {
    completion(mockExperimentLibraryExistsValue)
  }

  func tearDown() {
    tearDownCalled = true
  }

}
