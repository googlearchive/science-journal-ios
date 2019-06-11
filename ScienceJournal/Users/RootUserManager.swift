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

  var exportType: UserExportType {
    return .saveToFiles
  }

  var isDriveSyncEnabled: Bool {
    return false
  }

  /// Whether there is a root user experiments directory on disk. This is a reliable indicator for
  /// whether the root user has been used before or not.
  var hasExperimentsDirectory: Bool {
    return FileManager.default.fileExists(atPath: metadataManager.experimentsDirectoryURL.path)
  }

  private let rootURL: URL

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - fileSystemLayout: The file system layout.
  ///   - sensorController: The sensor controller.
  init(fileSystemLayout: FileSystemLayout, sensorController: SensorController) {
    self.rootURL = fileSystemLayout.rootUserURL

    // Configure preference manager with no account ID.
    preferenceManager = PreferenceManager()

    sensorDataManager = SensorDataManager(rootURL: rootURL)

    metadataManager = MetadataManager(rootURL: rootURL,
                                      deletedRootURL: rootURL,
                                      preferenceManager: preferenceManager,
                                      sensorController: sensorController,
                                      sensorDataManager: sensorDataManager)

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
    try FileManager.default.removeItem(at: rootURL)

    // NOTE: Preferences are not deleted when deleting the root user because they will be used as
    // defaults for this device when new users are added. This is to ensure that if a user had
    // previously disabled tracking, the expectation carries over when they log into an account.
  }

}
