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

/// Manages preferences that are device-specific, not tied to any user.
class DevicePreferenceManager {

  // MARK: - Nested types

  private enum Keys {
    static let hasAUserChosenAnExistingDataMigrationOption =
        "GSJ_HasAUserChosenAnExistingDataMigrationOptionKey"
    static let hasAUserCompletedPermissionsGuideKey =
        "GSJ_HasUserCompletedPermissionsGuide"
  }

  // MARK: - Properties

  /// Whether at least one user has chosen a migration option for existing data.
  var hasAUserChosenAnExistingDataMigrationOption: Bool {
    get {
      return UserDefaults.standard.bool(forKey: Keys.hasAUserChosenAnExistingDataMigrationOption)
    }
    set {
      // Store the boolean value.
      UserDefaults.standard.set(newValue, forKey: Keys.hasAUserChosenAnExistingDataMigrationOption)
      UserDefaults.standard.synchronize()
    }
  }

  /// Whether at least one user has completed the permissions guide.
  var hasAUserCompletedPermissionsGuide: Bool {
    get {
      return UserDefaults.standard.bool(forKey: Keys.hasAUserCompletedPermissionsGuideKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.hasAUserCompletedPermissionsGuideKey)
      UserDefaults.standard.synchronize()
    }
  }

}
