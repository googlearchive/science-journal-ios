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

// TODO: Revisit testability http://b/134675146

/// Manages preferences that are device-specific, not tied to any user.
class DevicePreferenceManager {

  // MARK: - Nested types

  private enum Keys {
    static let hasAUserChosenAnExistingDataMigrationOption =
        "GSJ_HasAUserChosenAnExistingDataMigrationOptionKey"
    static let hasAUserCompletedPermissionsGuideKey =
        "GSJ_HasUserCompletedPermissionsGuide"
    static let fileSystemLayoutVersion =
        "GSJ_FileSystemLayoutVersion"
  }

  // MARK: - Properties

  /// Whether at least one user has chosen a migration option for existing data.
  var hasAUserChosenAnExistingDataMigrationOption: Bool {
    get {
      return defaults.bool(forKey: Keys.hasAUserChosenAnExistingDataMigrationOption)
    }
    set {
      // Store the boolean value.
      defaults.set(newValue, forKey: Keys.hasAUserChosenAnExistingDataMigrationOption)
      defaults.synchronize()
    }
  }

  /// Whether at least one user has completed the permissions guide.
  var hasAUserCompletedPermissionsGuide: Bool {
    get {
      return defaults.bool(forKey: Keys.hasAUserCompletedPermissionsGuideKey)
    }
    set {
      defaults.set(newValue, forKey: Keys.hasAUserCompletedPermissionsGuideKey)
      defaults.synchronize()
    }
  }

  /// The file system layout version.
  var fileSystemLayoutVersion: FileSystemLayout.Version {
    get {
      let intValue = defaults.object(forKey: Keys.fileSystemLayoutVersion) as? Int
      return intValue.flatMap(FileSystemLayout.Version.init(rawValue:)) ?? .one
    }
    set {
      defaults.set(newValue.rawValue, forKey: Keys.fileSystemLayoutVersion)
      defaults.synchronize()
    }
  }

  private let defaults: UserDefaults

  // MARK: - Public

  /// Designated Initializer.
  ///
  ///
  /// - Parameters:
  ///   - defaults: The `UserDefaults` instance to use. Defaults to `.standard`.
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

}
