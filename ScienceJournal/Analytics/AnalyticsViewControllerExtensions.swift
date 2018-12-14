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

/// A protocol for view controllers to provide a constant string name for analytics purposes.
protocol AnalyticsTrackable: class {
  var analyticsViewName: String { get }
}

/// View controller extensions for adopting the AnalyticsTrackable protocol.

// MARK: - Base classes

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

// MARK: - View controllers

// MARK: About

extension AboutViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewAbout }
}

extension LicensesViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewLicenses }
}

extension LicenseViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewLicenseDetail }
}

// MARK: Claim experiments

extension ClaimExperimentsViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewClaimExperiments }
}

// MARK: Drawer

extension CameraViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewDrawerCamera }
}

extension NotesViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewDrawerNote }
}

extension ObserveViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewDrawerObserve }
}

extension PhotoLibraryViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewDrawerPhotoPicker }
}

// MARK: Existing data options

extension ExistingDataOptionsViewController {
  override open var analyticsViewName: String {
    return AnalyticsConstants.viewExistingDataOptions
  }
}

// MARK: Experiments

extension EditExperimentPhotoLibraryViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewExperimentEditPickPhoto }
}

extension EditExperimentViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewExperimentEdit }
}

extension ExperimentsListViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewExperimentList }
}

extension RenameExperimentViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewExperimentRename }
}

extension ExperimentCoordinatorViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewExperimentDetail }
}

// MARK: Notes

extension PictureDetailViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewPictureNoteDetail }
}

extension PictureInfoViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewPictureNoteInfo }
}

extension SnapshotDetailViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewSnapshotNoteDetail }
}

extension TextNoteDetailViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTextNoteEdit }
}

extension TriggerDetailViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTriggerNoteDetail }
}

// MARK: Permissions guide

extension PermissionsGuideViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewPermissionsGuide }
}

// MARK: Sensors

extension SensorSettingsViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewSensorSettings }
}

extension LearnMoreViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewLearnMore }
}

// MARK: Bluetooth sensors

extension MakingScienceSensorConfigViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewBluetoothSensorConfig }
}

// MARK: Settings

extension SettingsViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewSettings }
}

// MARK: Sign in

extension SignInViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewSignIn }
}

extension WelcomeViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewWelcome }
}

// MARK: Standalone camera

extension StandaloneCameraViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewCameraStandalone }
}

// MARK: Standalone photo picker

extension StandalonePhotoLibraryViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewPhotoPickerStandalone }
}

// MARK: Trials

extension AddTrialNoteViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTrialAddNote }
}

extension RenameTrialViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTrialRename }
}

extension TrialDetailViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTrialDetail }
}

extension TrialShareSettingsViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTrialShare }
}

// MARK: Triggers

extension TriggerEditViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTriggerEdit }
}

extension TriggerListViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewTriggersList }
}

// MARK: Verify age

extension VerifyAgeViewController {
  override open var analyticsViewName: String { return AnalyticsConstants.viewVerifyAge }
}
