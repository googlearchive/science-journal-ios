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

/// Tracks the usage of a service by adding and removing users.
class UsageTracker {

  private var userObjectIDs = [ObjectIdentifier]()

  /// Adds a user object.
  ///
  /// - Parameter user: The user object.
  /// - Returns: True if usage just went from 0 to 1.
  func addUser(_ user: AnyObject) -> Bool {
    let userID = ObjectIdentifier(user)
    guard !userObjectIDs.contains(userID) else { return false }
    userObjectIDs.append(userID)
    return userObjectIDs.count == 1
  }

  /// Removes a user object.
  ///
  /// - Parameter user: The user object.
  /// - Returns: True if usage just went from 1 to 0.
  func removeUser(_ user: AnyObject) -> Bool {
    let userID = ObjectIdentifier(user)
    guard let index = userObjectIDs.firstIndex(where: { $0 == userID }) else { return false }
    userObjectIDs.remove(at: index)
    return userObjectIDs.count == 0
  }
}
