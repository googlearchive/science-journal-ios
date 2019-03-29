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

/// Manages data for the pre-accounts root user. This user is not associated with any auth account.
class RootUserManager: UserManager {

  var driveSyncManager: DriveSyncManager? {
    return nil
  }

  let metadataManager: MetadataManager
  let preferenceManager: PreferenceManager
  let sensorDataManager: SensorDataManager
  let assetManager: UserAssetManager
  let experimentDataDeleter: ExperimentDataDeleter
  let documentManager: DocumentManager

  var shouldVerifyAge: Bool {
    // Age verification is required for a non-account user, if they have not done so yet.
    return !preferenceManager.hasUserVerifiedAge
  }

  var isSharingAllowed: Bool {
    // Sharing is allowed for users age 13 or older.
    return preferenceManager.isUser13OrOlder
  }

  var isDriveSyncEnabled: Bool {
    return false
  }

  /// Whether there is a root user experiments directory on disk. This is a reliable indicator for
  /// whether the root user has been used before or not.
  var hasExperimentsDirectory: Bool {
    return FileManager.default.fileExists(atPath: metadataManager.experimentsDirectoryURL.path)
  }

  private let documentsDirectoryURL: URL
  private let metadataRootURL: URL

  /// Designated initializer.
  ///
  /// - Parameter sensorController: The sensor controler.
  init(sensorController: SensorController) {
    documentsDirectoryURL = URL.documentsDirectoryURL

    // Configure preference manager with no account ID.
    preferenceManager = PreferenceManager(clock: Clock(), accountID: nil)

    let storeURL = documentsDirectoryURL.appendingPathComponent(SensorDataManager.rootStoreName)
    sensorDataManager = SensorDataManager(storeURL: storeURL)

    metadataRootURL = documentsDirectoryURL.appendingPathComponent("Science Journal")
    metadataManager = MetadataManager(rootURL: metadataRootURL,
                                      deletedRootURL: documentsDirectoryURL,
                                      preferenceManager: preferenceManager,
                                      sensorController: sensorController,
                                      sensorDataManager: sensorDataManager)

    // Clean the deleted data directory.
    metadataManager.removeAllDeletedData()

    assetManager = UserAssetManager(driveSyncManager: nil,
                                    metadataManager: metadataManager,
                                    sensorDataManager: sensorDataManager)

    experimentDataDeleter = ExperimentDataDeleter(accountID: nil,
                                                  metadataManager: metadataManager,
                                                  sensorDataManager: sensorDataManager)

    documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                      metadataManager: metadataManager,
                                      sensorDataManager: sensorDataManager)
  }

  func tearDown() {
    metadataManager.tearDown()
    assetManager.tearDown()
    driveSyncManager?.tearDown()
  }

  func deleteAllUserData() throws {
    // Delete metadata.
    let directories = [metadataRootURL,
                       metadataManager.deletedAssetsDirectoryURL,
                       metadataManager.deletedDataDirectoryURL]
    for url in directories {
      guard FileManager.default.fileExists(atPath: url.path) else {
        continue
      }
      try FileManager.default.removeItem(at: url)
    }

    // Delete sqlite store, including supporting temp files which have the same name as the store
    // with a prefix (e.g. "store.sqlite-wal", "store.sqlite-shm", etc.).
    let contentsURLs =
      try FileManager.default.contentsOfDirectory(at: documentsDirectoryURL,
                                                  includingPropertiesForKeys: nil,
                                                  options: [])
    for url in contentsURLs {
      if url.lastPathComponent.hasPrefix(SensorDataManager.rootStoreName) {
        try FileManager.default.removeItem(at: url)
      }
    }

    // NOTE: Preferences are not deleted when deleting the root user because they will be used as
    // defaults for this device when new users are added. This is to ensure that if a user had
    // previously disabled tracking, the expectation carries over when they log into an account.
  }

}
