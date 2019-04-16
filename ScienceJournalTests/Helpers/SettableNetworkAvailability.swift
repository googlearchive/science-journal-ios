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

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// A settable version of network availability.
class SettableNetworkAvailability: NetworkAvailability {

  var isAvailable: Bool? {
    return mockAvailability
  }

  private var mockAvailability: Bool?

  /// Sets the network availability.
  ///
  /// - Parameter availability: Network availability.
  func setAvailability(_ availability: Bool?) {
    guard mockAvailability != availability else { return }
    mockAvailability = availability
    NotificationCenter.default.post(name: .NetworkAvailabilityChanged, object: self)
  }

}
