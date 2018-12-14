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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class PreferenceManagerTest: XCTestCase {

  func testShowArchivedExperiments() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.shouldShowArchivedExperiments,
                   "Should not show archived experiments.")
    rootPrefsManager.shouldShowArchivedExperiments = true
    XCTAssertTrue(rootPrefsManager.shouldShowArchivedExperiments,
                  "Should show archived experiments.")
    rootPrefsManager.shouldShowArchivedExperiments = false
    XCTAssertFalse(rootPrefsManager.shouldShowArchivedExperiments,
                   "Should not show archived experiments.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.shouldShowArchivedExperiments,
                   "Should not show archived experiments for account 1.")
    prefsManagerForAccount1.shouldShowArchivedExperiments = true
    XCTAssertTrue(prefsManagerForAccount1.shouldShowArchivedExperiments,
                  "Should show archived experiments for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.shouldShowArchivedExperiments,
                   "Should not show archived experiments for account 2.")
    prefsManagerForAccount2.shouldShowArchivedExperiments = true
    XCTAssertTrue(prefsManagerForAccount2.shouldShowArchivedExperiments,
                  "Should show archived experiments for account 2.")
  }

  func testShowArchivedRecordings() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.shouldShowArchivedRecordings,
                   "Should not show archived recordings.")
    rootPrefsManager.shouldShowArchivedRecordings = true
    XCTAssertTrue(rootPrefsManager.shouldShowArchivedRecordings, "Should show archived recordings.")
    rootPrefsManager.shouldShowArchivedRecordings = false
    XCTAssertFalse(rootPrefsManager.shouldShowArchivedRecordings,
                   "Should not show archived recordings.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.shouldShowArchivedRecordings,
                   "Should not show archived recordings for account 1.")
    prefsManagerForAccount1.shouldShowArchivedRecordings = true
    XCTAssertTrue(prefsManagerForAccount1.shouldShowArchivedRecordings,
                  "Should show archived recordings for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.shouldShowArchivedRecordings,
                   "Should not show archived recordings for account 2.")
    prefsManagerForAccount2.shouldShowArchivedRecordings = true
    XCTAssertTrue(prefsManagerForAccount2.shouldShowArchivedRecordings,
                  "Should show archived recordings for account 2.")
  }

  func testUserHasSeenExperimentHighlight() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.hasUserSeenExperimentHighlight,
                   "User has not seen experiment highlight yet.")
    rootPrefsManager.hasUserSeenExperimentHighlight = true
    XCTAssertTrue(rootPrefsManager.hasUserSeenExperimentHighlight,
                 "User has seen experiment highlight.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.hasUserSeenExperimentHighlight,
                   "User has not seen experiment highlight yet for account 1.")
    prefsManagerForAccount1.hasUserSeenExperimentHighlight = true
    XCTAssertTrue(prefsManagerForAccount1.hasUserSeenExperimentHighlight,
                  "User has seen experiment highlight for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.hasUserSeenExperimentHighlight,
                   "User has not seen experiment highlight yet for account 2.")
    prefsManagerForAccount2.hasUserSeenExperimentHighlight = true
    XCTAssertTrue(prefsManagerForAccount2.hasUserSeenExperimentHighlight,
                  "User has seen experiment highlight for account 2.")
  }

  func testIsUser13OrOlder() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.isUser13OrOlder, "User is not 13 or older.")
    rootPrefsManager.isUser13OrOlder = true
    XCTAssertTrue(rootPrefsManager.isUser13OrOlder, "User is 13 or older.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.isUser13OrOlder,
                   "User is not 13 or older for account 1.")
    prefsManagerForAccount1.isUser13OrOlder = true
    XCTAssertTrue(prefsManagerForAccount1.isUser13OrOlder,
                  "User is 13 or older for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.isUser13OrOlder,
                   "User is not 13 or older for account 2.")
    prefsManagerForAccount2.isUser13OrOlder = true
    XCTAssertTrue(prefsManagerForAccount2.isUser13OrOlder,
                  "User is 13 or older for account 2.")
  }

  func testHasUserVerifiedAgeIsSetByIsUser13OrOlder() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.hasUserVerifiedAge, "User has not verified their age.")
    rootPrefsManager.isUser13OrOlder = true
    XCTAssertTrue(rootPrefsManager.hasUserVerifiedAge, "User has verified their age.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.hasUserVerifiedAge,
                   "User has not verified their age for account 1.")
    prefsManagerForAccount1.isUser13OrOlder = false
    XCTAssertTrue(prefsManagerForAccount1.hasUserVerifiedAge,
                  "User has verified their age for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.hasUserVerifiedAge,
                   "User has not verified their age for account 2.")
    prefsManagerForAccount2.isUser13OrOlder = true
    XCTAssertTrue(prefsManagerForAccount2.hasUserVerifiedAge,
                  "User has verified their age for account 2.")
  }

  func testDefaultExperiment() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.defaultExperimentWasCreated,
                   "Default experiment has not been created yet.")
    rootPrefsManager.defaultExperimentWasCreated = true
    XCTAssertTrue(rootPrefsManager.defaultExperimentWasCreated,
                  "Default experiment was created.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.defaultExperimentWasCreated,
                   "Default experiment has not been created yet for account 1.")
    prefsManagerForAccount1.defaultExperimentWasCreated = true
    XCTAssertTrue(prefsManagerForAccount1.defaultExperimentWasCreated,
                  "Default experiment was created for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.defaultExperimentWasCreated,
                   "Default experiment has not been created yet for account 2.")
    prefsManagerForAccount2.defaultExperimentWasCreated = true
    XCTAssertTrue(prefsManagerForAccount2.defaultExperimentWasCreated,
                  "Default experiment was created for account 2.")
  }

  func testUserHasOptedOutOfUsageTracking() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking.")
    rootPrefsManager.hasUserOptedOutOfUsageTracking = true
    XCTAssertTrue(rootPrefsManager.hasUserOptedOutOfUsageTracking,
                  "User has opted out of usage tracking.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking for account 1.")
    prefsManagerForAccount1.hasUserOptedOutOfUsageTracking = true
    XCTAssertTrue(prefsManagerForAccount1.hasUserOptedOutOfUsageTracking,
                  "User has opted out of usage tracking for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking for account 2.")
    prefsManagerForAccount2.hasUserOptedOutOfUsageTracking = true
    XCTAssertTrue(prefsManagerForAccount2.hasUserOptedOutOfUsageTracking,
                  "User has opted out of usage tracking for account 2.")
  }

  func testHasUserSeenAudioAndBrightnessSensorBackgroundMessage() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")
    [rootPrefsManager, prefsManagerForAccount1, prefsManagerForAccount2].forEach { $0.resetAll() }

    // Root preference manager.
    XCTAssertFalse(rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen the audio and brightness sensor background message yet.")
    rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    XCTAssertTrue(rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                  "User has seen the audio and brightness sensor background message.")

    // The preference manager for account 1 should not be affected by the root preference manager.
    XCTAssertFalse(prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen the audio and brightness sensor background message yet for " +
                       "account 1.")
    prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    XCTAssertTrue(prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                  "User has seen the audio and brightness sensor background message for account 1.")

    // The preference manager for account 2 should not be affected by the root preference manager or
    // the one for account 1.
    XCTAssertFalse(prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen the audio and brightness sensor background message yet for " +
                       "account 2.")
    prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    XCTAssertTrue(prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                  "User has seen the audio and brightness sensor background message for account 2.")
  }

  func testResetAll() {
    // Set up a root preference manager and two for specific accounts.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(clock: Clock(), accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(clock: Clock(), accountID: "2")

    // Set everything to true for each preference manager.
    rootPrefsManager.shouldShowArchivedExperiments = true
    rootPrefsManager.shouldShowArchivedRecordings = true
    rootPrefsManager.hasUserSeenExperimentHighlight = true
    rootPrefsManager.isUser13OrOlder = true
    rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    rootPrefsManager.defaultExperimentWasCreated = true
    rootPrefsManager.hasUserOptedOutOfUsageTracking = true
    prefsManagerForAccount1.shouldShowArchivedExperiments = true
    prefsManagerForAccount1.shouldShowArchivedRecordings = true
    prefsManagerForAccount1.hasUserSeenExperimentHighlight = true
    prefsManagerForAccount1.isUser13OrOlder = true
    prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    prefsManagerForAccount1.defaultExperimentWasCreated = true
    prefsManagerForAccount1.hasUserOptedOutOfUsageTracking = true
    prefsManagerForAccount2.shouldShowArchivedExperiments = true
    prefsManagerForAccount2.shouldShowArchivedRecordings = true
    prefsManagerForAccount2.hasUserSeenExperimentHighlight = true
    prefsManagerForAccount2.isUser13OrOlder = true
    prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    prefsManagerForAccount2.defaultExperimentWasCreated = true
    prefsManagerForAccount2.hasUserOptedOutOfUsageTracking = true

    // Everything in the root preference manager should be true.
    XCTAssertTrue(rootPrefsManager.shouldShowArchivedExperiments,
                  "Should show archived experiments.")
    XCTAssertTrue(rootPrefsManager.shouldShowArchivedRecordings,
                  "Should show archived recordings.")
    XCTAssertTrue(rootPrefsManager.hasUserSeenExperimentHighlight,
                  "User has seen experiment highlight.")
    XCTAssertTrue(rootPrefsManager.isUser13OrOlder,
                  "User is 13 or older.")
    XCTAssertTrue(rootPrefsManager.hasUserVerifiedAge,
                  "User has verified age.")
    XCTAssertTrue(rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                  "User has seen audio and brightness sensor background message.")
    XCTAssertTrue(rootPrefsManager.defaultExperimentWasCreated,
                  "Default experiment was created.")
    XCTAssertTrue(rootPrefsManager.hasUserOptedOutOfUsageTracking,
                  "User has opted out of usage tracking.")

    // Reset the root preference manager, and everything should be false (or nil).
    rootPrefsManager.resetAll()
    XCTAssertFalse(rootPrefsManager.shouldShowArchivedExperiments,
                   "Should not show archived experiments.")
    XCTAssertFalse(rootPrefsManager.shouldShowArchivedRecordings,
                   "Should not show archived recordings.")
    XCTAssertFalse(rootPrefsManager.hasUserSeenExperimentHighlight,
                   "User has not seen experiment highlight.")
    XCTAssertFalse(rootPrefsManager.isUser13OrOlder,
                   "User is not 13 or older.")
    XCTAssertFalse(rootPrefsManager.hasUserVerifiedAge,
                   "User has not verified age.")
    XCTAssertFalse(rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen audio and brightness sensor background message.")
    XCTAssertFalse(rootPrefsManager.defaultExperimentWasCreated,
                   "Default experiment was not created.")
    XCTAssertFalse(rootPrefsManager.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking.")

    // Everything in the preference manager for account 1 should be true, despite resetting the root
    // preference manager.
    XCTAssertTrue(prefsManagerForAccount1.shouldShowArchivedExperiments,
                  "Should show archived experiments for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.shouldShowArchivedRecordings,
                  "Should show archived recordings for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.hasUserSeenExperimentHighlight,
                  "User has seen experiment highlight for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.isUser13OrOlder,
                  "User is 13 or older for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.hasUserVerifiedAge,
                  "User has verified age for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                  "User has seen audio and brightness sensor background message for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.defaultExperimentWasCreated,
                  "Default experiment was created for account 1.")
    XCTAssertTrue(prefsManagerForAccount1.hasUserOptedOutOfUsageTracking,
                  "User has opted out of usage tracking for account 1.")

    // Reset the preference manager for account 1, and everything should be false (or nil).
    prefsManagerForAccount1.resetAll()
    XCTAssertFalse(prefsManagerForAccount1.shouldShowArchivedExperiments,
                   "Should not show archived experiments for account 1.")
    XCTAssertFalse(prefsManagerForAccount1.shouldShowArchivedRecordings,
                   "Should not show archived recordings for account 1.")
    XCTAssertFalse(prefsManagerForAccount1.hasUserSeenExperimentHighlight,
                   "User has not seen experiment highlight for account 1.")
    XCTAssertFalse(prefsManagerForAccount1.isUser13OrOlder,
                   "User is not 13 or older for account 1.")
    XCTAssertFalse(prefsManagerForAccount1.hasUserVerifiedAge,
                   "User has not verified age for account 1.")
    XCTAssertFalse(prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen audio and brightness sensor background message for account " +
                       "1.")
    XCTAssertFalse(prefsManagerForAccount1.defaultExperimentWasCreated,
                   "Default experiment was not created for account 1.")
    XCTAssertFalse(prefsManagerForAccount1.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking for account 1.")

    // Everything in the preference manager for account 2 should be true, despite resetting the root
    // preference manager and the one for account 1.
    XCTAssertTrue(prefsManagerForAccount2.shouldShowArchivedExperiments,
                  "Should show archived experiments for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.shouldShowArchivedRecordings,
                  "Should show archived recordings for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.hasUserSeenExperimentHighlight,
                  "User has seen experiment highlight for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.isUser13OrOlder,
                  "User is 13 or older for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.hasUserVerifiedAge,
                  "User has verified age for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                  "User has seen audio and brightness sensor background message for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.defaultExperimentWasCreated,
                  "Default experiment was created for account 2.")
    XCTAssertTrue(prefsManagerForAccount2.hasUserOptedOutOfUsageTracking,
                  "User has opted out of usage tracking for account 2.")

    // Reset the preference manager for account 2, and everything should be false (or nil).
    prefsManagerForAccount2.resetAll()
    XCTAssertFalse(prefsManagerForAccount2.shouldShowArchivedExperiments,
                   "Should not show archived experiments for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.shouldShowArchivedRecordings,
                   "Should not show archived recordings for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.hasUserSeenExperimentHighlight,
                   "User has not seen experiment highlight for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.isUser13OrOlder,
                   "User is not 13 or older for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.hasUserVerifiedAge,
                   "User has not verified age for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen audio and brightness sensor background message for account " +
                       "2.")
    XCTAssertFalse(prefsManagerForAccount2.defaultExperimentWasCreated,
                   "Default experiment was not created for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking for account 2.")
  }

  func testCopyPreferencesFromManager() {
    let preferenceManagerToCopy = PreferenceManager()
    let preferenceManager = PreferenceManager(accountID: "test")
    preferenceManager.resetAll()

    // Set preferences to true.
    preferenceManagerToCopy.shouldShowArchivedExperiments = true
    preferenceManagerToCopy.shouldShowArchivedRecordings = true
    preferenceManagerToCopy.hasUserSeenExperimentHighlight = true
    preferenceManagerToCopy.isUser13OrOlder = true
    preferenceManagerToCopy.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    preferenceManagerToCopy.defaultExperimentWasCreated = true
    preferenceManagerToCopy.hasUserOptedOutOfUsageTracking = true

    // Assert the account preferences are false.
    XCTAssertFalse(preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(preferenceManager.isUser13OrOlder)
    XCTAssertFalse(preferenceManager.hasUserVerifiedAge)
    XCTAssertFalse(preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(preferenceManager.defaultExperimentWasCreated)
    XCTAssertFalse(preferenceManager.hasUserOptedOutOfUsageTracking)

    // Copy preferences.
    preferenceManager.copyPreferences(fromManager: preferenceManagerToCopy)

    // Assert the account preferences are true.
    XCTAssertTrue(preferenceManager.shouldShowArchivedExperiments)
    XCTAssertTrue(preferenceManager.shouldShowArchivedRecordings)
    XCTAssertTrue(preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertTrue(preferenceManager.isUser13OrOlder)
    XCTAssertTrue(preferenceManager.hasUserVerifiedAge)
    XCTAssertTrue(preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertTrue(preferenceManager.defaultExperimentWasCreated)
    XCTAssertTrue(preferenceManager.hasUserOptedOutOfUsageTracking)

    // Set the preferences to false.
    preferenceManagerToCopy.shouldShowArchivedExperiments = false
    preferenceManagerToCopy.shouldShowArchivedRecordings = false
    preferenceManagerToCopy.hasUserSeenExperimentHighlight = false
    preferenceManagerToCopy.isUser13OrOlder = false
    preferenceManagerToCopy.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = false
    preferenceManagerToCopy.defaultExperimentWasCreated = false
    preferenceManagerToCopy.hasUserOptedOutOfUsageTracking = false

    // Copy preferences.
    preferenceManager.copyPreferences(fromManager: preferenceManagerToCopy)

    // Assert the account user's preferences are false.
    XCTAssertFalse(preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(preferenceManager.isUser13OrOlder)
    XCTAssertTrue(preferenceManager.hasUserVerifiedAge)
    XCTAssertFalse(preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(preferenceManager.defaultExperimentWasCreated)
    XCTAssertFalse(preferenceManager.hasUserOptedOutOfUsageTracking)
  }

  func testMigrateUserBirthdateTo13OrOlderBool() {
    // Build the birthdate key to match what preference manager uses.
    let noAgeGivenAccountID = "noAgeGivenAccountID"
    let noAgeGivenBirthdateKey = "GSJ_UserBirthdate_\(noAgeGivenAccountID)"

    // Make sure there is no date in user defaults for the user, then create a preference manager.
    // It should not calculate whether that user is 13 or older.
    UserDefaults.standard.removeObject(forKey: noAgeGivenBirthdateKey)
    let noAgeGivenPreferenceManager = PreferenceManager(accountID: noAgeGivenAccountID)
    XCTAssertFalse(noAgeGivenPreferenceManager.hasUserVerifiedAge,
                   "User has not verified their age.")

    let oneYearTimeInterval: TimeInterval = 60 * 60 * 24 * 365

    // Again, build the birthdate key to match what preference manager uses.
    let over13AccountID = "over13AccountID"
    let over13BirthdateKey = "GSJ_UserBirthdate_\(over13AccountID)"
    let birthdateOver13 = Date(timeIntervalSinceNow: -oneYearTimeInterval * 15)

    // Set a date in user defaults for a user over 13, then create a preference manager. It should
    // calculate whether that user is 13 or older.
    UserDefaults.standard.set(birthdateOver13, forKey: over13BirthdateKey)
    let over13PreferenceManager = PreferenceManager(accountID: over13AccountID)
    XCTAssertTrue(over13PreferenceManager.isUser13OrOlder, "User is 13 or older.")
    XCTAssertTrue(over13PreferenceManager.hasUserVerifiedAge, "User has verified their age.")
    XCTAssertNil(UserDefaults.standard.object(forKey: over13BirthdateKey),
                 "The birthdate should be removed from user defaults.")

    // Again, build the birthdate key to match what preference manager uses.
    let under13AccountID = "under13AccountID"
    let under13BirthdateKey = "GSJ_UserBirthdate_\(under13AccountID)"
    let birthdateUnder13 = Date(timeIntervalSinceNow: -oneYearTimeInterval * 10)

    // Set a date in user defaults for a user under 13, then create a preference manager. It should
    // calculate whether that user is 13 or older.
    UserDefaults.standard.set(birthdateUnder13, forKey: under13BirthdateKey)
    let under13PreferenceManager = PreferenceManager(accountID: under13AccountID)
    XCTAssertFalse(under13PreferenceManager.isUser13OrOlder, "User is not 13 or older.")
    XCTAssertTrue(under13PreferenceManager.hasUserVerifiedAge, "User has verified their age.")
    XCTAssertNil(UserDefaults.standard.object(forKey: under13BirthdateKey),
                 "The birthdate should be removed from user defaults.")
  }

}
