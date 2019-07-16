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

import UIKit

/// The export option type to show for the user.
enum UserExportType {
  /// Show the save to files export option.
  case saveToFiles
  /// Show the share export option.
  case share

  var title: String {
    switch self {
    case .saveToFiles:
      return String.saveToFilesTitle
    case .share:
      return String.sendCopyAction
    }
  }

  var icon: UIImage? {
    switch self {
    case .saveToFiles:
      return UIImage(named: "ic_save_alt")
    case .share:
      return UIImage(named: "ic_share")
    }
  }

  var accessibilityHint: String? {
    switch self {
    case .saveToFiles:
      return String.saveToFilesContentDescription
    case .share:
      return nil
    }
  }
}

/// Protocol for an object that manages a single user and their data. A user is not the same as an
/// account. A user represents one set of data on one device. It may be associated with an account
/// but in the case of the root user (the user data stored to device before account support was
/// added) it does not have to be. See `AccountsManager` for account specific features.
protocol UserManager {

  /// The drive sync manager configured for the user.
  var driveSyncManager: DriveSyncManager? { get }

  /// The metadata manager configured for the user.
  var metadataManager: MetadataManager { get }

  /// The preference manager configured for the user.
  var preferenceManager: PreferenceManager { get }

  /// The sensor data manager configured for the user.
  var sensorDataManager: SensorDataManager { get }

  /// The asset manager for the user.
  var assetManager: UserAssetManager { get }

  /// The document manager for the user.
  var documentManager: DocumentManager { get }

  /// The experiment data deleter for the user.
  var experimentDataDeleter: ExperimentDataDeleter { get }

  /// The export type to use for the user.
  var exportType: UserExportType { get }

  /// Whether Drive sync is enabled for the user.
  var isDriveSyncEnabled: Bool { get }

  /// Do any needed work in preparation of the user session ending.
  func tearDown()

  /// Deletes all user data.
  ///
  /// - Throws: Any error encountered while deleting data.
  func deleteAllUserData() throws

}
