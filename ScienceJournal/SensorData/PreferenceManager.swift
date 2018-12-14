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
import UIKit

/// The manager for user preferences.
open class PreferenceManager {

  // MARK: - Nested types

  /// The keys used to store preferences to user defaults.
  private struct Keys {

    // MARK: - Properties

    // An account ID that is appended to the keys for account specific preferences. If this is nil,
    // it will store preferences that are not tied to an account.
    private let accountID: String?

    // Note: If you add a key here, you must add it to `rootKeys` and `all`.
    private let shouldShowArchivedExperimentsKey = "GSJ_ShouldShowArchivedExperiments"
    private let shouldShowArchivedRecordingsKey = "GSJ_ShouldShowArchivedRecordings"
    private let hasUserSeenExperimentHighlightKey = "GSJ_HasUserSeenExperimentHighlight"
    private let isUser13OrOlderKey = "GSJ_IsUser13OrOlderKey"
    private let hasUserVerifiedAgeKey = "GSJ_HasUserVerifiedAgeKey"
    private let hasUserSeenAudioAndBrightnessSensorBackgroundMessageKey =
        "GSJ_HasUserSeenAudioAndBrightnessSensorBackgroundMessage"
    private let defaultExperimentWasCreatedKey = "GSJ_DefaultExperimentWasCreated"
    private let hasUserOptedOutOfUsageTrackingKey = "GSJ_HasUserOptedOutOfUsageTracking"
    private let deletedExperimentIDsKey = "GSJ_DeletedExperimentIDsKey"
    private let deletedImageAssetsKey = "GSJ_DeletedImageAssetsKey"
    private let deletedSensorDataAssetsKey = "GSJ_DeletedSensorDataAssetsKey"

    // Legacy keys
    private let userBirthdateKey = "GSJ_UserBirthdate"

    // MARK: - Public

    /// Designated initializer.
    ///
    /// - Parameter accountID: The ID to append to the keys for storing account specific
    ///             preferences.
    init(accountID: String? = nil) {
      self.accountID = accountID
    }

    /// The key to use for the preference for whether or not to show archived experiments.
    var shouldShowArchivedExperiments: String {
      return keyAppendingAccountID(shouldShowArchivedExperimentsKey)
    }

    /// The key to use for the preference for whether or not to show archived recordings.
    var shouldShowArchivedRecordings: String {
      return keyAppendingAccountID(shouldShowArchivedRecordingsKey)
    }

    /// The key to use for the preference for whether or not the user has seen the experiment
    /// highlight.
    var hasUserSeenExperimentHighlight: String {
      return keyAppendingAccountID(hasUserSeenExperimentHighlightKey)
    }

    /// The key that was once used for the preference for the user's birthdate. We can no longer
    /// store birthdates. However, this key needs to remain to calculate if the user is over 13 and
    /// to remove any birthdates stored previously.
    var userBirthdate: String {
      return keyAppendingAccountID(userBirthdateKey)
    }

    /// The key for whether the user is 13 or older.
    var isUser13OrOlder: String {
      return keyAppendingAccountID(isUser13OrOlderKey)
    }

    /// The key for whether the user has verified their age.
    var hasUserVerifiedAge: String {
      return keyAppendingAccountID(hasUserVerifiedAgeKey)
    }

    /// The key to use for the preference for whether or not the user has seen the audio and
    /// brightness sensor background message.
    var hasUserSeenAudioAndBrightnessSensorBackgroundMessage: String {
      return keyAppendingAccountID(hasUserSeenAudioAndBrightnessSensorBackgroundMessageKey)
    }

    /// The key to use for the preference for whether or not the default experiment was created.
    var defaultExperimentWasCreated: String {
      return keyAppendingAccountID(defaultExperimentWasCreatedKey)
    }

    /// The key to use for the preference for whether or not the user has opted out of usage
    /// tracking.
    var hasUserOptedOutOfUsageTracking: String {
      return keyAppendingAccountID(hasUserOptedOutOfUsageTrackingKey)
    }

    /// The key for the array of IDs of deleted experiments.
    var deletedExperimentIDs: String {
      return keyAppendingAccountID(deletedExperimentIDsKey)
    }

    /// The key for the array of dictionary objects of deleted image assets.
    var deletedImageAssets: String {
      return keyAppendingAccountID(deletedImageAssetsKey)
    }

    /// The key for the array of dictionary objects of deleted sensor data assets.
    var deletedSensorDataAssets: String {
      return keyAppendingAccountID(deletedSensorDataAssetsKey)
    }

    /// All keys for preferences, for the current account ID (if one was passed during
    /// initialization.
    var all: [String] {
      return [shouldShowArchivedExperiments,
              shouldShowArchivedRecordings,
              hasUserSeenExperimentHighlight,
              userBirthdate,
              isUser13OrOlder,
              hasUserVerifiedAge,
              hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
              defaultExperimentWasCreated,
              hasUserOptedOutOfUsageTracking,
              deletedExperimentIDs,
              deletedImageAssets,
              deletedSensorDataAssets]
    }

    // All root keys used for preferences, without any account ID appended.
    fileprivate var rootKeys: [String] {
      return [shouldShowArchivedExperimentsKey,
              shouldShowArchivedRecordingsKey,
              hasUserSeenExperimentHighlightKey,
              userBirthdateKey,
              isUser13OrOlderKey,
              hasUserVerifiedAgeKey,
              hasUserSeenAudioAndBrightnessSensorBackgroundMessageKey,
              defaultExperimentWasCreatedKey,
              hasUserOptedOutOfUsageTrackingKey,
              deletedExperimentIDsKey,
              deletedImageAssetsKey,
              deletedSensorDataAssetsKey]
    }

    // MARK: - Private

    fileprivate func keyAppendingAccountID(_ key: String) -> String {
      var key = key
      if let accountID = accountID {
        key += "_\(accountID)"
      }
      return key
    }

  }

  // MARK: - Properties

  private let keys: Keys
  private let clock: Clock

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - clock: The clock to use for date calculations.
  ///   - accountID: The ID to use for storing account specific preferences.
  init(clock: Clock, accountID: String? = nil) {
    self.clock = clock
    keys = Keys(accountID: accountID)
    migrateUserBirthdateTo13OrOlderBool()
  }

  /// Convenience initializer that uses a default clock and no account ID.
  public convenience init() {
    self.init(clock: Clock())
  }

  /// Convenience initializer that uses a default clock.
  ///
  /// - Parameter accountID: The ID to use for storing account specific preferences.
  public convenience init(accountID: String) {
    self.init(clock: Clock(), accountID: accountID)
  }

  // Convenience var to standard defaults.
  private let defaults = UserDefaults.standard

  /// Show archived experiments in the experiments list?
  public var shouldShowArchivedExperiments: Bool {
    set { defaults.set(newValue, forKey: keys.shouldShowArchivedExperiments); sync() }
    get { return defaults.bool(forKey: keys.shouldShowArchivedExperiments) }
  }

  /// Show archived recordings in experiments?
  public var shouldShowArchivedRecordings: Bool {
    set { defaults.set(newValue, forKey: keys.shouldShowArchivedRecordings); sync() }
    get { return defaults.bool(forKey: keys.shouldShowArchivedRecordings) }
  }

  /// Has the user been presented with the "create an experiment" feature highlight?
  public var hasUserSeenExperimentHighlight: Bool {
    set { defaults.set(newValue, forKey: keys.hasUserSeenExperimentHighlight); sync() }
    get { return defaults.bool(forKey: keys.hasUserSeenExperimentHighlight) }
  }

  /// Whether the user is 13 or older.
  public var isUser13OrOlder: Bool {
    set {
      hasUserVerifiedAge = true
      defaults.set(newValue, forKey: keys.isUser13OrOlder)
      sync()
    }
    get { return defaults.bool(forKey: keys.isUser13OrOlder) }
  }

  /// Whether the user has verified their age. This is set automatically when `isUser13OrOlder` is
  /// set.
  public private(set) var hasUserVerifiedAge: Bool {
    set { defaults.set(newValue, forKey: keys.hasUserVerifiedAge); sync() }
    get { return defaults.bool(forKey: keys.hasUserVerifiedAge) }
  }

  /// Has the user seen the message saying that the audio and brightness sensors won't continue in
  /// the background?
  public var hasUserSeenAudioAndBrightnessSensorBackgroundMessage: Bool {
    set { defaults.set(newValue,
                       forKey: keys.hasUserSeenAudioAndBrightnessSensorBackgroundMessage); sync() }
    get { return defaults.bool(forKey: keys.hasUserSeenAudioAndBrightnessSensorBackgroundMessage) }
  }

  /// Was the default experiment created for the user the first time they used the app?
  public var defaultExperimentWasCreated: Bool {
    set { defaults.set(newValue, forKey: keys.defaultExperimentWasCreated); sync() }
    get { return defaults.bool(forKey: keys.defaultExperimentWasCreated) }
  }

  /// Has the user opted out of usage tracking?
  public var hasUserOptedOutOfUsageTracking: Bool {
    set { defaults.set(newValue, forKey: keys.hasUserOptedOutOfUsageTracking); sync() }
    get { return defaults.bool(forKey: keys.hasUserOptedOutOfUsageTracking) }
  }

  /// Array of IDs of deleted experiments.
  public var deletedExperimentIDs: [String] {
    set { defaults.set(newValue, forKey: keys.deletedExperimentIDs); sync() }
    get {
      return defaults.object(forKey: keys.deletedExperimentIDs) as? [String] ?? []
    }
  }

  /// Array of dictionary objects of deleted image assets.
  public var deletedImageAssets: [[String: String]] {
    set { defaults.set(newValue, forKey: keys.deletedImageAssets); sync() }
    get {
      return defaults.object(forKey: keys.deletedImageAssets) as? [[String: String]] ?? [[:]]
    }
  }

  /// Array of dictionary objects of deleted sensor data assets.
  public var deletedSensorDataAssets: [[String: String]] {
    set { defaults.set(newValue, forKey: keys.deletedSensorDataAssets); sync() }
    get {
      return defaults.object(forKey: keys.deletedSensorDataAssets) as? [[String: String]] ?? [[:]]
    }
  }

  // Removes all keys from user defaults corresponding to the current account ID. We can't use the
  // simpler domain removal because this is a cross-module function with different domains for
  // test vs. app.
  func resetAll() {
    keys.all.forEach { defaults.removeObject(forKey: $0) }
  }

  /// Copies preferences from a given preference manager.
  ///
  /// - Parameter: preferenceManager: A preference manager.
  func copyPreferences(fromManager preferenceManager: PreferenceManager) {
    keys.rootKeys.forEach {
      let keyToCopy = preferenceManager.keys.keyAppendingAccountID($0)
      let keyToWrite = keys.keyAppendingAccountID($0)

      let prefToCopy = defaults.object(forKey: keyToCopy)
      defaults.set(prefToCopy, forKey: keyToWrite)
    }
  }

  // MARK: - Private

  // Synchronizes user defaults.
  private func sync() { defaults.synchronize() }

  // Calculates whether the user is over 13, if there was a value for user birthdate, then removes
  // the user's birthdate from user defaults.
  private func migrateUserBirthdateTo13OrOlderBool() {
    if let userBirthdate = defaults.object(forKey: keys.userBirthdate) as? Date {
      isUser13OrOlder = userBirthdate.isBirthdateAge13OrOlder
    }

    defaults.removeObject(forKey: keys.userBirthdate)
  }

}
