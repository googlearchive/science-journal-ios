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

// MARK: - Base protocol

/// A protocol for view controllers to provide a constant string name for analytics purposes.
protocol AnalyticsTrackable: class {
  var analyticsViewName: String { get }
}

// MARK: - View controller extensions

// MARK: Base classes

extension ScienceJournalCollectionViewController: AnalyticsTrackable {
  @objc open var analyticsViewName: String {
    assert(false, "ERROR: View controller does not have a custom analyticsViewName.")
    return String(describing: type(of: self))
  }
}

extension ScienceJournalViewController: AnalyticsTrackable {
  @objc open var analyticsViewName: String {
    assert(false, "ERROR: View controller does not have a custom analyticsViewName.")
    return String(describing: type(of: self))
  }
}

extension MaterialHeaderCollectionViewController: AnalyticsTrackable {
  @objc open var analyticsViewName: String {
    assert(false, "ERROR: View controller does not have a custom analyticsViewName.")
    return String(describing: type(of: self))
  }
}

// MARK: About

extension AboutViewController {
  override open var analyticsViewName: String { return "About" }
}

extension LicensesViewController {
  override open var analyticsViewName: String { return "LicensesList" }
}

extension LicenseViewController {
  override open var analyticsViewName: String { return "LicenseDetail" }
}

// MARK: Claim experiments

extension ClaimExperimentsViewController {
  override open var analyticsViewName: String { return "ClaimExperiments" }
}

// MARK: Drawer

extension CameraViewController {
  override open var analyticsViewName: String { return "DrawerCamera" }
}

extension NotesViewController {
  override open var analyticsViewName: String { return "DrawerNote" }
}

extension ObserveViewController {
  override open var analyticsViewName: String { return "DrawerObserve" }
}

extension PhotoLibraryViewController {
  override open var analyticsViewName: String { return "DrawerPhotoPicker" }
}

// MARK: Existing data options

extension ExistingDataOptionsViewController {
  override open var analyticsViewName: String { return "ExistingDataOptions" }
}

// MARK: Experiments

extension EditExperimentPhotoLibraryViewController {
  override open var analyticsViewName: String { return "ExperimentEditPickPhoto" }
}

extension EditExperimentViewController {
  override open var analyticsViewName: String { return "ExperimentEdit" }
}

extension ExperimentsListViewController {
  override open var analyticsViewName: String { return "ExperimentList" }
}

extension RenameExperimentViewController {
  override open var analyticsViewName: String { return "ExperimentRename" }
}

extension ExperimentCoordinatorViewController {
  override open var analyticsViewName: String { return "ExperimentDetail" }
}

// MARK: Notes

extension PictureDetailViewController {
  override open var analyticsViewName: String { return "PictureNoteDetail" }
}

extension PictureInfoViewController {
  override open var analyticsViewName: String { return "PictureNoteImageInfo" }
}

extension SnapshotDetailViewController {
  override open var analyticsViewName: String { return "SnapshotNoteDetail" }
}

extension TextNoteDetailViewController {
  override open var analyticsViewName: String { return "TextNoteEdit" }
}

extension TriggerDetailViewController {
  override open var analyticsViewName: String { return "TriggerNoteDetail" }
}

// MARK: Permissions guide

extension PermissionsGuideViewController {
  override open var analyticsViewName: String { return "PermissionsGuide" }
}

// MARK: Sensors

extension SensorSettingsViewController {
  override open var analyticsViewName: String { return "SensorSettings" }
}

extension LearnMoreViewController {
  override open var analyticsViewName: String { return "SensorLearnMore" }
}

// MARK: Bluetooth sensors

extension MakingScienceSensorConfigViewController {
  override open var analyticsViewName: String { return "BluetoothSensorConfig" }
}

// MARK: Settings

extension SettingsViewController {
  override open var analyticsViewName: String { return "Settings" }
}

// MARK: Sign in

extension SignInViewController {
  override open var analyticsViewName: String { return "SignIn" }
}

extension WelcomeViewController {
  override open var analyticsViewName: String { return "Welcome" }
}

// MARK: Standalone camera

extension StandaloneCameraViewController {
  override open var analyticsViewName: String { return "CameraStandalone" }
}

// MARK: Standalone photo picker

extension StandalonePhotoLibraryViewController {
  override open var analyticsViewName: String { return "PhotoPickerStandalone" }
}

// MARK: Trials

extension AddTrialNoteViewController {
  override open var analyticsViewName: String { return "TrialAddNote" }
}

extension RenameTrialViewController {
  override open var analyticsViewName: String { return "TrialRename" }
}

extension TrialDetailViewController {
  override open var analyticsViewName: String { return "TrialDetail" }
}

extension TrialShareSettingsViewController {
  override open var analyticsViewName: String { return "TrialShare" }
}

// MARK: Triggers

extension TriggerEditViewController {
  override open var analyticsViewName: String { return "TriggerEdit" }
}

extension TriggerListViewController {
  override open var analyticsViewName: String { return "TriggersList" }
}
