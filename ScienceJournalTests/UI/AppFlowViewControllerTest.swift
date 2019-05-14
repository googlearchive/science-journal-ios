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

class AppFlowViewControllerTest: XCTestCase, TestDirectories {

  var appFlowViewController: AppFlowViewController!
  private var mockAccountsManager: MockAccountsManager!
  let mockDriveConstructor = MockDriveConstructor()

  override func setUp() {
    super.setUp()

    mockAccountsManager =
        MockAccountsManager(mockAuthAccount: MockAuthAccount(ID: "AppFlowViewControllerTestID"))
    let analyticsReporter = AnalyticsReporterOpen()
    let sensorController = MockSensorController()
    let documentsDirectoryURL = createUniqueTestDirectoryURL()
    #if FEATURE_FIREBASE_RC
    appFlowViewController =
        AppFlowViewController(accountsManager: mockAccountsManager,
                              analyticsReporter: analyticsReporter,
                              commonUIComponents: CommonUIComponentsOpen(),
                              drawerConfig: DrawerConfigOpen(),
                              driveConstructor: mockDriveConstructor,
                              feedbackReporter: FeedbackReporterOpen(),
                              networkAvailability: SettableNetworkAvailability(),
                              remoteConfigManager: RemoteConfigManagerDisabled(),
                              sensorController: sensorController,
                              documentsDirectoryURL: documentsDirectoryURL)
    #else
    appFlowViewController =
        AppFlowViewController(accountsManager: mockAccountsManager,
                              analyticsReporter: analyticsReporter,
                              commonUIComponents: CommonUIComponentsOpen(),
                              drawerConfig: DrawerConfigOpen(),
                              driveConstructor: mockDriveConstructor,
                              feedbackReporter: FeedbackReporterOpen(),
                              networkAvailability: SettableNetworkAvailability(),
                              sensorController: sensorController,
                              documentsDirectoryURL: documentsDirectoryURL)
    #endif
  }

  override func tearDown() {
    // Calling `currentAccountUserManager` creates the account user manager, which creates the
    // directory for the account. Calling `deleteAllUserData` will remove that directory and disrupt
    // the nautrual flow of this class.
    try! appFlowViewController.currentAccountUserManager!.deleteAllUserData()
  }

  func testPrefStoredAfterUserMadeAMigrationChoice() {
    appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption =
        false

    // Create an unclaimed experiment.
    _ = appFlowViewController.rootUserManager.metadataManager.createExperiment()

    // Enter sign in flow.
    appFlowViewController.accountsManagerPermissionCheckComplete(permissionState: .granted,
                                                                 signInType: .newSignIn)

    appFlowViewController.existingDataOptionsViewControllerDidSelectSaveAllExperiments()
    XCTAssertTrue(
        appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption)

    appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption =
        false
    appFlowViewController.existingDataOptionsViewControllerDidSelectDeleteAllExperiments()
    XCTAssertTrue(
        appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption)

    appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption =
        false
    appFlowViewController.existingDataOptionsViewControllerDidSelectSelectExperimentsToSave()
    XCTAssertTrue(
        appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption)
  }

  func testSigningInMigratesPrefsForFirstTimeAccount() {
    // Set up a root user manager with all preferences set to true.
    let rootUserManager = appFlowViewController.rootUserManager
    rootUserManager.preferenceManager.shouldShowArchivedExperiments = true
    rootUserManager.preferenceManager.shouldShowArchivedRecordings = true
    rootUserManager.preferenceManager.hasUserSeenExperimentHighlight = true
    rootUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    rootUserManager.preferenceManager.defaultExperimentWasCreated = true
    rootUserManager.preferenceManager.hasUserOptedOutOfUsageTracking = true

    // Sign in.
    appFlowViewController.accountsManagerPermissionCheckComplete(permissionState: .granted,
                                                                 signInType: .newSignIn)

    // Assert that the account user manager preferences have been migrated from the root user
    // manager, by checking the preference for data tracking.
    let accountUserManager = appFlowViewController.currentAccountUserManager!
    XCTAssertTrue(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)
  }

  func testSigningInDoesNotMigratePrefsIfCurrentAccountManagerIsCalled() {
    // Set up a root user manager with all preferences set to true.
    let rootUserManager = appFlowViewController.rootUserManager
    rootUserManager.preferenceManager.shouldShowArchivedExperiments = true
    rootUserManager.preferenceManager.shouldShowArchivedRecordings = true
    rootUserManager.preferenceManager.hasUserSeenExperimentHighlight = true
    rootUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    rootUserManager.preferenceManager.defaultExperimentWasCreated = true
    rootUserManager.preferenceManager.hasUserOptedOutOfUsageTracking = true

    // Call `currentAccountUserManager` and sign in.
    let accountUserManager = appFlowViewController.currentAccountUserManager!
    appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption =
    false
    appFlowViewController.accountsManagerPermissionCheckComplete(permissionState: .granted,
                                                                 signInType: .newSignIn)

    // Assert that the account user manager preferences have not been migrated from the root user
    // manager.
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(
      accountUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(accountUserManager.preferenceManager.defaultExperimentWasCreated)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)
  }

  func testSigningInDoesNotMigratePrefsForExistingAccount() {
    // Set up a root user manager with all preferences set to true.
    let rootUserManager = appFlowViewController.rootUserManager
    rootUserManager.preferenceManager.shouldShowArchivedExperiments = true
    rootUserManager.preferenceManager.shouldShowArchivedRecordings = true
    rootUserManager.preferenceManager.hasUserSeenExperimentHighlight = true
    rootUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
    rootUserManager.preferenceManager.defaultExperimentWasCreated = true
    rootUserManager.preferenceManager.hasUserOptedOutOfUsageTracking = true

    // Reset all account user manager prefs, and assert they are false.
    mockAccountsManager.mockAuthAccount = MockAuthAccount(ID: "AppFlowViewControllerTestNewAccount")
    let accountUserManager = appFlowViewController.currentAccountUserManager!
    accountUserManager.preferenceManager.resetAll()
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(
        accountUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(accountUserManager.preferenceManager.defaultExperimentWasCreated)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)

    // Sign in.
    appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption =
        false
    appFlowViewController.accountsManagerPermissionCheckComplete(permissionState: .granted,
                                                                 signInType: .newSignIn)

    // Assert that account user manager preferences were not migrated from the root user
    // preferences.
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(
        accountUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)
  }

  func testPreferencesAreDefaultValuesWithNoPreviousUser() {
    // Reset root preferences.
    let rootUserManager = appFlowViewController.rootUserManager
    rootUserManager.preferenceManager.resetAll()

    // Sign in.
    appFlowViewController.devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption =
        false
    appFlowViewController.accountsManagerPermissionCheckComplete(permissionState: .granted,
                                                                 signInType: .newSignIn)

    // Assert that account user manager preferences are the expected default values.
    let accountUserManager = appFlowViewController.currentAccountUserManager!
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedExperiments)
    XCTAssertFalse(accountUserManager.preferenceManager.shouldShowArchivedRecordings)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserSeenExperimentHighlight)
    XCTAssertFalse(
        accountUserManager.preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage)
    XCTAssertFalse(accountUserManager.preferenceManager.hasUserOptedOutOfUsageTracking)
  }

  func testAccountUserManagerUpdatesForNewAccounts() {
    // The account user manager should be for the accounts manager's current account.
    let accountID = "AppFlowViewControllerTestID"
    mockAccountsManager.mockAuthAccount = MockAuthAccount(ID: accountID)
    let accountUserManager = appFlowViewController.currentAccountUserManager!
    XCTAssertEqual(accountUserManager.account.ID, mockAccountsManager.currentAccount!.ID)
    XCTAssertEqual(accountUserManager.account.ID, accountID)

    // The account user manager property should continue to return the same instance.
    XCTAssertTrue(appFlowViewController.currentAccountUserManager! === accountUserManager)

    // When the current account changes, there should be a new account user manager.
    let newAccountID = "AppFlowViewControllerTestNewID"
    mockAccountsManager.mockAuthAccount = MockAuthAccount(ID: newAccountID)
    let newAccountUserManager = appFlowViewController.currentAccountUserManager!
    XCTAssertEqual(newAccountUserManager.account.ID, mockAccountsManager.currentAccount!.ID)
    XCTAssertEqual(newAccountUserManager.account.ID, newAccountID)

    // The account user manager property should continue to return the same instance.
    XCTAssertTrue(appFlowViewController.currentAccountUserManager! === newAccountUserManager)
  }

  func testDriveSyncManagerTearDownWhenUserSignedOut() {
    _ = appFlowViewController.currentAccountUserManager
    XCTAssertFalse(mockDriveConstructor.mockDriveSyncManager.tearDownCalled)
    appFlowViewController.forceSignInViaNotification()
    XCTAssertTrue(mockDriveConstructor.mockDriveSyncManager.tearDownCalled)
  }

}
