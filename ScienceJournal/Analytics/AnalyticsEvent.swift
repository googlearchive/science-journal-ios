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

/// A struct for an Analytics Event which has a category and action, as well as an optional value
/// and label.
public struct AnalyticsEvent {

  // MARK: - Events

  // MARK: Claiming

  static let categoryClaimingData = "ClaimingData"

  static let claimAll = AnalyticsEvent(category: categoryClaimingData,
                                       action: "ClaimAll")

  static let claimingDeleteAll = AnalyticsEvent(category: categoryClaimingData,
                                                action: "DeleteAll")

  static let claimingSelectLater = AnalyticsEvent(category: categoryClaimingData,
                                                  action: "SelectLater")

  static let claimingClaimSingle = AnalyticsEvent(category: categoryClaimingData,
                                                  action: "ClaimSingle")

  static let claimingDeleteSingle = AnalyticsEvent(category: categoryClaimingData,
                                                   action: "DeleteSingle")

  static let claimingSaveToFiles = AnalyticsEvent(category: categoryClaimingData,
                                                  action: "SaveToFiles")

  static let claimingViewExperiment = AnalyticsEvent(category: categoryClaimingData,
                                                     action: "ViewExperiment")

  static let claimingViewTrial = AnalyticsEvent(category: categoryClaimingData,
                                                action: "ViewTrial")

  static func claimingViewTrialNote(_ displayNote: DisplayNote) -> AnalyticsEvent {
    return AnalyticsEvent(category: categoryClaimingData,
                          action: "ViewTrialNote",
                          label: displayNote.noteType.analyticsLabel,
                          value: displayNote.noteType.analyticsValue)
  }

  static func claimingViewNote(_ displayNote: DisplayNote) -> AnalyticsEvent {
    return AnalyticsEvent(category: categoryClaimingData,
                          action: "ViewNote",
                          label: displayNote.noteType.analyticsLabel,
                          value: displayNote.noteType.analyticsValue)
  }

  static let claimingRemoveCoverImage = AnalyticsEvent(category: categoryClaimingData,
                                                       action: "RemoveCoverImageForExperiment")

  static let claimingDeleteTrial = AnalyticsEvent(category: categoryClaimingData,
                                                  action: "DeleteTrial")

  static func claimingDeleteTrialNote(_ displayNote: DisplayNote) -> AnalyticsEvent {
    return AnalyticsEvent(category: categoryClaimingData,
                          action: "DeleteTrialNote",
                          label: displayNote.noteType.analyticsLabel,
                          value: displayNote.noteType.analyticsValue)
  }

  static func claimingDeleteNote(_ displayNote: DisplayNote) -> AnalyticsEvent {
    return AnalyticsEvent(category: categoryClaimingData,
                          action: "DeleteNote",
                          label: displayNote.noteType.analyticsLabel,
                          value: displayNote.noteType.analyticsValue)
  }

  // MARK: Trial export

  static let categoryTrialExport = "ExportTrial"

  static let trialExported = AnalyticsEvent(category: categoryTrialExport,
                                            action: "DidExport")

  static let trialExportCancelled = AnalyticsEvent(category: categoryTrialExport,
                                                   action: "ExportCancelled")

  static let trialExportError = AnalyticsEvent(category: categoryTrialExport,
                                               action: "ExportError")

  // MARK: Sidebar

  static let categorySidebar = "Sidebar"

  static let sidebarOpened = AnalyticsEvent(category: categorySidebar,
                                            action: "Opened")

  static let sidebarClosed = AnalyticsEvent(category: categorySidebar,
                                            action: "Closed")

  // MARK: Sign in

  static let categorySignIn = "SignIn"

  public static let signInStart = AnalyticsEvent(category: categorySignIn,
                                                 action: "StartSignIn")

  public static let signInStartSwitch = AnalyticsEvent(category: categorySignIn,
                                                       action: "StartSwitchAccount")

  static let signInFromWelcome = AnalyticsEvent(category: categorySignIn,
                                                action: "SignInFromWelcome")

  static let signInFromSidebar = AnalyticsEvent(category: categorySignIn,
                                                action: "SignInFromSidebar")

  static let signInLearnMore = AnalyticsEvent(category: categorySignIn,
                                              action: "LearnMore")

  public static let signInContinueWithoutAccount = AnalyticsEvent(category: categorySignIn,
                                                                  action: "ContinueWithoutAccount")

  public static let signInAccountChanged = AnalyticsEvent(category: categorySignIn,
                                                          action: "AccountChanged")

  public static let signInAccountSignedIn = AnalyticsEvent(category: categorySignIn,
                                                           action: "AccountSignedIn")

  public static let signInFailed = AnalyticsEvent(category: categorySignIn,
                                                  action: "Failed")

  public static let signInSwitchFailed = AnalyticsEvent(category: categorySignIn,
                                                        action: "SwitchFailed")

  public static let signInNoChange = AnalyticsEvent(category: categorySignIn,
                                                    action: "NoChange")

  public static let signInRemovedAccount = AnalyticsEvent(category: categorySignIn,
                                                          action: "RemovedAccount")

  public static let signInError = AnalyticsEvent(category: categorySignIn,
                                                 action: "Error")

  public static func signInAccountType(_ accountType: AnalyticsAccountType) -> AnalyticsEvent {
    return AnalyticsEvent(category: categorySignIn,
                          action: "AccountType",
                          label: accountType.analyticsLabel,
                          value: accountType.rawValue)
  }

  static let signInPermissionDenied = AnalyticsEvent(category: categorySignIn,
                                                     action: "PermissionDenied")

  static let signInSyncExistingAccount = AnalyticsEvent(category: categorySignIn,
                                                        action: "SyncExistingAccount")

  // MARK: Sync

  static let categorySync = "Sync"

  public static let syncExperimentFromDrive = AnalyticsEvent(category: categorySync,
                                                             action: "SyncExperimentFromDrive")

  static let syncManualRefresh = AnalyticsEvent(category: categorySync,
                                                action: "ManualSyncStarted")

  // MARK: - Base struct

  public var category: String
  public var action: String
  public var label: String?
  public var value: NSNumber?

  init(category: String, action: String, label: String? = nil, value: NSNumber? = nil) {
    self.category = category
    self.action = action
    self.label = label
    self.value = value
  }

}

// MARK: - Account type values

/// Analytics values for signed in account types.
public enum AnalyticsAccountType: NSNumber {

  case other = 0
  case gmail
  case gsuite
  case googleCorp
  case unknownOffline

  var analyticsLabel: String {
    switch self {
    case .other: return "Other"
    case .gmail: return "Gmail"
    case .gsuite: return "GSuite"
    case .googleCorp: return "GoogleCorp"
    case .unknownOffline: return "UnknownOffline"
    }
  }

}

// MARK: - Note type values

/// Extends the DisplayNoteType enum to add values for analytics tracking various note types.
extension DisplayNoteType {

  var analyticsValue: NSNumber {
    switch self {
    case .textNote: return 0
    case .pictureNote: return 1
    case .triggerNote: return 2
    case .snapshotNote: return 3
    }
  }

  var analyticsLabel: String {
    switch self {
    case .textNote: return "Text"
    case .pictureNote: return "Picture"
    case .triggerNote: return "Trigger"
    case .snapshotNote: return "Snapshot"
    }
  }

}
