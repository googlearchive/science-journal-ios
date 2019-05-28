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

/// Manages user data for a single account based user.
class AccountUserManager: UserManager {

  // MARK: - Properties

  let metadataManager: MetadataManager
  let preferenceManager: PreferenceManager
  let sensorDataManager: SensorDataManager
  let assetManager: UserAssetManager
  var driveSyncManager: DriveSyncManager?
  let experimentDataDeleter: ExperimentDataDeleter
  let documentManager: DocumentManager

  var exportType: UserExportType {
    return .share
  }

  var isDriveSyncEnabled: Bool {
    return driveSyncManager != nil
  }

  /// The root URL under which all user data is stored.
  let rootURL: URL

  /// The user account.
  let account: AuthAccount

  private let fileSystemLayout: FileSystemLayout

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - fileSystemLayout: The file system layout.
  ///   - account: A user account.
  ///   - driveConstructor: The drive constructor.
  ///   - networkAvailability: Network availability.
  ///   - sensorController: The sensor controller.
  ///   - analyticsReporter: An analytics reporter.
  init(fileSystemLayout: FileSystemLayout,
       account: AuthAccount,
       driveConstructor: DriveConstructor,
       networkAvailability: NetworkAvailability,
       sensorController: SensorController,
       analyticsReporter: AnalyticsReporter) {
    self.fileSystemLayout = fileSystemLayout
    self.account = account

    // Create a root URL for this account.
    rootURL = fileSystemLayout.accountURL(for: account.ID)

    // Create the directory if needed.
    do {
      try FileManager.default.createDirectory(at: rootURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
    } catch {
      print("[AccountUserManager] Error creating rootURL: \(error.localizedDescription)")
    }

    // Configure preference manager with account ID.
    preferenceManager = PreferenceManager(accountID: account.ID)

    // Configure Core Data store.
    sensorDataManager = SensorDataManager(rootURL: rootURL, store: .account)

    // Configure metadata manager.
    metadataManager = MetadataManager(rootURL: rootURL,
                                      deletedRootURL: rootURL,
                                      preferenceManager: preferenceManager,
                                      sensorController: sensorController,
                                      sensorDataManager: sensorDataManager)

    // Configure experiment data deleter.
    experimentDataDeleter = ExperimentDataDeleter(accountID: account.ID,
                                                  metadataManager: metadataManager,
                                                  sensorDataManager: sensorDataManager)

    documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                      metadataManager: metadataManager,
                                      sensorDataManager: sensorDataManager)

    // Configure drive sync.
    if let authorization = account.authorization {
      driveSyncManager =
          driveConstructor.driveSyncManager(withAuthorization: authorization,
                                            experimentDataDeleter: experimentDataDeleter,
                                            metadataManager: metadataManager,
                                            networkAvailability: networkAvailability,
                                            preferenceManager: preferenceManager,
                                            sensorDataManager: sensorDataManager,
                                            analyticsReporter: analyticsReporter)
    }

    // Configure user asset manager.
    assetManager = UserAssetManager(driveSyncManager: driveSyncManager,
                                    metadataManager: metadataManager,
                                    sensorDataManager: sensorDataManager)
  }

  func tearDown() {
    metadataManager.tearDown()
    assetManager.tearDown()
    driveSyncManager?.tearDown()
  }

  /// Deletes the user's data and preferences.
  func deleteAllUserData() throws {
    // TODO: Fix SQLite warning b/132878667
    try AccountDeleter(fileSystemLayout: fileSystemLayout, accountID: account.ID).deleteData()
  }

}
