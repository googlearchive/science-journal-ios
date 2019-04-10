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
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")
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
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")
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
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")
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

  func testDefaultExperiment() {
    // Set up a root preference manager and two for specific accounts, and reset each.
    let rootPrefsManager = PreferenceManager()
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")
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
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")
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
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")
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
    let prefsManagerForAccount1 = PreferenceManager(accountID: "1")
    let prefsManagerForAccount2 = PreferenceManager(accountID: "2")

    // Set everything to true for each preference manager.
    rootPrefsManager.shouldShowArchivedExperiments = true
    rootPrefsManager.shouldShowArchivedRecordings = true
    rootPrefsManager.hasUserSeenExperimentHighlight = true
    rootPrefsManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    rootPrefsManager.defaultExperimentWasCreated = true
    rootPrefsManager.hasUserOptedOutOfUsageTracking = true
    prefsManagerForAccount1.shouldShowArchivedExperiments = true
    prefsManagerForAccount1.shouldShowArchivedRecordings = true
    prefsManagerForAccount1.hasUserSeenExperimentHighlight = true
    prefsManagerForAccount1.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    prefsManagerForAccount1.defaultExperimentWasCreated = true
    prefsManagerForAccount1.hasUserOptedOutOfUsageTracking = true
    prefsManagerForAccount2.shouldShowArchivedExperiments = true
    prefsManagerForAccount2.shouldShowArchivedRecordings = true
    prefsManagerForAccount2.hasUserSeenExperimentHighlight = true
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
    XCTAssertFalse(prefsManagerForAccount2.hasUserSeenAudioAndBrightnessSensorBackgroundMessage,
                   "User has not seen audio and brightness sensor background message for account " +
                       "2.")
    XCTAssertFalse(prefsManagerForAccount2.defaultExperimentWasCreated,
                   "Default experiment was not created for account 2.")
    XCTAssertFalse(prefsManagerForAccount2.hasUserOptedOutOfUsageTracking,
                   "User has not opted out of usage tracking for account 2.")
  }

  func testMigratePreferencesFromManager() {
    let preferenceManagerToCopy = PreferenceManager()
    let preferenceManager = PreferenceManager(accountID: "test")
    preferenceManager.resetAll()

    // Set preferences to true.
    preferenceManagerToCopy.shouldShowArchivedExperiments = true
    preferenceManagerToCopy.shouldShowArchivedRecordings = true
    preferenceManagerToCopy.hasUserSeenExperimentHighlight = true
    preferenceManagerToCopy.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    preferenceManagerToCopy.defaultExperimentWasCreated = true
    preferenceManagerToCopy.hasUserOptedOutOfUsageTracking = true

    // Migrate preferences.
    preferenceManager.migratePreferences(fromManager: preferenceManagerToCopy)

    // Assert the preference that should be migrated is true.
    XCTAssertTrue(preferenceManager.hasUserOptedOutOfUsageTracking)

    // The rest should be the default value.
    XCTAssertFalse(preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(preferenceManager.defaultExperimentWasCreated)

    // Set the preference that migrates to false.
    preferenceManagerToCopy.hasUserOptedOutOfUsageTracking = false

    // Migrate preferences.
    preferenceManager.migratePreferences(fromManager: preferenceManagerToCopy)

    // Assert the preference that should be migrated is false.
    XCTAssertFalse(preferenceManager.hasUserOptedOutOfUsageTracking)

    // The rest should still be the default value.
    XCTAssertFalse(preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(preferenceManager.defaultExperimentWasCreated)
  }

  func testMigrateRemoveUserBirthdate() {
    // Build the birthdate key to match what preference manager uses.
    let accountID = "accountID"
    let birthdateKey = "GSJ_UserBirthdate_\(accountID)"

    // Set a date in user defaults the user, then create a preference manager. It should
    // remove the birthdate.
    UserDefaults.standard.set(Date(), forKey: birthdateKey)
    let _ = PreferenceManager(accountID: accountID)
    XCTAssertNil(UserDefaults.standard.object(forKey: birthdateKey),
                 "The birthdate should be removed from user defaults.")
  }

}
