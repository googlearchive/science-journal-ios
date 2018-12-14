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

import UIKit

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// An accounts manager that can return a mock auth account.
class MockAccountsManager: AccountsManager {
  var mockAuthAccount: MockAuthAccount?
  var mockSupportsAccounts = true

  weak var delegate: AccountsManagerDelegate?

  var supportsAccounts: Bool {
    return mockSupportsAccounts
  }

  var currentAccount: AuthAccount? {
    return mockAuthAccount
  }

  init(mockAuthAccount: MockAuthAccount? = nil) {
    self.mockAuthAccount = mockAuthAccount
  }

  func signInAsCurrentAccount(completion: @escaping SignInBlock) {}

  func signOutCurrentAccount() {}

  func presentSignIn(fromViewController viewController: UIViewController,
                     completion: @escaping (Bool, Bool) -> Void) {}

  @discardableResult func reauthenticateCurrentAccount() -> Bool { return false }

  func removeLingeringAccounts() {}
}
