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

import StoreKit
import UIKit

/// A class for managing tracking of actions that lead to ratings prompts and the actual
/// presentation of the App Store ratings prompt using StoreKit.
class RatingsPromptManager {

  // MARK: - Nested types

  private enum TrackingKeys {
    static let successfulRecordingCount =
        "GSJ_RP_SuccessfulRecordingCount_\(Bundle.appVersionString)"

    // Add all prompt keys to the allKeys array for test reset purposes.
    static let allKeys = [successfulRecordingCount]
  }

  // MARK: - Properties

  /// The RatingsPromptManager singleton.
  static let shared = RatingsPromptManager()

  /// The required number of successful recordings before a rating prompt can be triggered.
  let minimumSuccessfulRecordings = 2

  /// Counter for the number of times a user has successfully ended a recording, used as a signpost
  /// for ratings prompts.
  var successfulRecordingCount: Int {
    set { defaults.set(newValue, forKey: TrackingKeys.successfulRecordingCount); sync() }
    get { return defaults.integer(forKey: TrackingKeys.successfulRecordingCount) }
  }

  // MARK: - Public

  /// Increments the recording count and prompts for rating if necessary.
  func incrementSuccessfulRecordingCount() {
    successfulRecordingCount += 1
    #if !SCIENCEJOURNAL_DEV_BUILD && !SCIENCEJOURNAL_DOGFOOD_BUILD
      promptForRatingIfNecessary()
    #endif
  }

  /// Prompts a user to rate the app in the App Store if necessary. iOS uses internal logic to
  /// determine if a user should be prompted, so even if this logic results in a request, it
  /// does not guarantee the user will actually be prompted. Repeated requests will not cause
  /// unwanted requests. Returns true if the prompt was requested.
  /// Exposed for testing purposes.
  @discardableResult func promptForRatingIfNecessary() -> Bool {
    if #available(iOS 10.3, *) {
      guard successfulRecordingCount >= minimumSuccessfulRecordings else { return false }
      SKStoreReviewController.requestReview()
      return true
    }
    return false
  }

  /// For debugging purposes only, removes all keys from user defaults.
  func resetAll() {
    TrackingKeys.allKeys.forEach { defaults.removeObject(forKey: $0); sync() }
  }

  // MARK: - Private

  // Convenience var to standard defaults.
  private let defaults = UserDefaults.standard

  // Use shared.
  private init() {}

  // Synchronizes user defaults.
  private func sync() { defaults.synchronize() }

}
