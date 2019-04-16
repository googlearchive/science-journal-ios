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

/// Deletes all data associated with a user account.
class AccountDeleter {

  private let accountID: String
  private let preferenceManager: PreferenceManager
  private let rootURL: URL

  /// Designated initializer.
  ///
  /// - Parameter accountID: An account ID.
  init(accountID: String) {
    self.accountID = accountID
    preferenceManager = PreferenceManager(accountID: accountID)
    rootURL = AccountUserManager.rootURLForAccount(withID: accountID)
  }

  /// Deletes all data for the user account.
  ///
  /// - Throws: A FileManager error if the account directory cannot be removed.
  func deleteData() throws {
    try FileManager.default.removeItem(at: rootURL)
    preferenceManager.resetAll()
  }

}
