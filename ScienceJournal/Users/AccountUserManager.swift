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

/// Manages user data for a single account based user.
class AccountUserManager: UserManager {

  // MARK: - Properties

  let metadataManager: MetadataManager
  let preferenceManager: PreferenceManager
  let sensorDataManager: SensorDataManager
  let assetManager: UserAssetManager
  var driveSyncManager: DriveSyncManager?

  var shouldVerifyAge: Bool {
    // Age verification is not required for accounts.
    return false
  }

  var isSharingAllowed: Bool {
    // Sharing is allowed for accounts.
    return true
  }

  var isDriveSyncEnabled: Bool {
    return driveSyncManager != nil
  }

  /// The root URL under which all user data is stored.
  let rootURL: URL

  /// The user account.
  let account: AuthAccount

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - account: A user account.
  ///   - driveConstructor: The drive constructor.
  ///   - networkAvailability: Network availability.
  ///   - sensorController: The sensor controller.
  ///   - analyticsReporter: An analytics reporter.
  init(account: AuthAccount,
       driveConstructor: DriveConstructor,
       networkAvailability: NetworkAvailability,
       sensorController: SensorController,
       analyticsReporter: AnalyticsReporter) {
    self.account = account

    // Create a root URL for this account.
    rootURL = AccountUserManager.rootURLForAccount(withID: account.ID)

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
    let storeURL = rootURL.appendingPathComponent("sensor_data.sqlite")
    sensorDataManager = SensorDataManager(storeURL: storeURL)

    // Configure metadata manager.
    metadataManager = MetadataManager(rootURL: rootURL,
                                      deletedRootURL: rootURL,
                                      preferenceManager: preferenceManager,
                                      sensorController: sensorController,
                                      sensorDataManager: sensorDataManager)

    // Clean the deleted data directory.
    metadataManager.removeAllDeletedData()

    // Configure drive sync.
    if let authorization = account.authorization {
      driveSyncManager = driveConstructor.driveSyncManager(withAuthorization: authorization,
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
    try AccountDeleter(accountID: account.ID).deleteData()
  }

  /// Whether or not there is a root directory for this account.
  ///
  /// - Parameter accountID: An account ID.
  /// - Returns: True if there is a root directory for this account, otherwise false.
  static func hasRootDirectoryForAccount(withID accountID: String) -> Bool {
    let rootURL = AccountUserManager.rootURLForAccount(withID: accountID)
    return FileManager.default.fileExists(atPath: rootURL.path)
  }

  static func rootURLForAccount(withID accountID: String) -> URL {
    assert(accountID.trimmedOrNil != nil, "Account ID cannot be an empty string.")
    return URL.accountsDirectoryURL.appendingPathComponent(accountID)
  }

}
