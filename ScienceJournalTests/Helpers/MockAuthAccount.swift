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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen
import googlemac_iPhone_Shared_SSOAuth_SSOAuth

/// An auth account that uses a mock ID, email, display name and profile image.
class MockAuthAccount: AuthAccount {
  var ID: String
  var email: String
  var displayName: String
  var profileImage: UIImage?
  var isShareRestricted: Bool = true
  var authorization: GTMFetcherAuthorizationProtocol? = MockAuthorization()

  init(ID: String = "MockAuthAccountID",
       email: String = "",
       displayName: String = "",
       profileImage: UIImage? = nil,
       isShareRestricted: Bool = true) {
    self.ID = ID
    self.email = email
    self.displayName = displayName
    self.profileImage = profileImage
    self.isShareRestricted = isShareRestricted
  }
}

/// A mock authorization object for use in tests.
class MockAuthorization: NSObject, GTMFetcherAuthorizationProtocol {
  func authorizeRequest(_ request: NSMutableURLRequest?, delegate: Any, didFinish sel: Selector) {}
  func stopAuthorization() {}
  func stopAuthorization(for request: URLRequest) {}
  func isAuthorizingRequest(_ request: URLRequest) -> Bool { return false }
  func isAuthorizedRequest(_ request: URLRequest) -> Bool { return false }
  var userEmail: String?
}
