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

/// Shared constants for analytics events and categories, view names and more.
public struct AnalyticsConstants {

  // MARK: - Events

  // MARK: Sidebar

  static let eventCategorySidebar = "Sidebar"
  static let eventSidebarOpened = "Opened"
  static let eventSidebarClosed = "Closed"

  // MARK: Export

  static let eventCategoryExportTrial = "ExportTrial"
  static let eventDidExport = "DidExport"
  static let eventExportCancelled = "ExportCancelled"

  // MARK: - Views

  // MARK: About

  static let viewAbout = "About"
  static let viewLicenses = "LicensesList"
  static let viewLicenseDetail = "LicenseDetail"

  // MARK: Claim experiments

  static let viewClaimExperiments = "ClaimExperiments"

  // MARK: Drawer

  static let viewDrawerObserve = "DrawerObserve"
  static let viewDrawerNote = "DrawerNote"
  static let viewDrawerCamera = "DrawerCamera"
  static let viewDrawerPhotoPicker = "DrawerPhotoPicker"

  // MARK: Existing data options

  static let viewExistingDataOptions = "ExistingDataOptions"

  // MARK: Experiments

  static let viewExperimentList = "ExperimentList"
  static let viewExperimentDetail = "ExperimentDetail"
  static let viewExperimentEdit = "ExperimentEdit"
  static let viewExperimentEditPickPhoto = "ExperimentEditPickPhoto"
  static let viewExperimentRename = "ExperimentRename"

  // MARK: Notes

  static let viewPictureNoteDetail = "PictureNoteDetail"
  static let viewPictureNoteInfo = "PictureNoteImageInfo"
  static let viewSnapshotNoteDetail = "SnapshotNoteDetail"
  static let viewTextNoteEdit = "TextNoteEdit"
  static let viewTriggerNoteDetail = "TriggerNoteDetail"

  // MARK: Permissions guide

  static let viewPermissionsGuide = "PermissionsGuide"

  // MARK: Sensors

  static let viewSensorSettings = "SensorSettings"
  static let viewBluetoothSensorConfig = "BluetoothSensorConfig"
  static let viewLearnMore = "SensorLearnMore"

  // MARK: Sign in

  static let viewSignIn = "SignIn"
  static let viewWelcome = "Welcome"

  // MARK: Settings

  static let viewSettings = "Settings"

  // MARK: Standalone camera

  static let viewCameraStandalone = "CameraStandalone"

  // MARK: Standalone photo picker

  static let viewPhotoPickerStandalone = "PhotoPickerStandalone"

  // MARK: Trials

  static let viewTrialAddNote = "TrialAddNote"
  static let viewTrialRename = "TrialRename"
  static let viewTrialDetail = "TrialDetail"
  static let viewTrialShare = "TrialShare"

  // MARK: Triggers

  static let viewTriggersList = "TriggersList"
  static let viewTriggerEdit = "TriggerEdit"

  // MARK: Verify age

  static let viewVerifyAge = "VerifyAge"

}
