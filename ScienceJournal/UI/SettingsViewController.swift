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

import UIKit

import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs
import third_party_objective_c_material_components_ios_components_Snackbar_Snackbar

#if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
public extension Notification.Name {
  /// Posted when root data should be created to test the claim flow.
  static let DEBUG_createRootUserData = NSNotification.Name("GSJ_DEBUG_CreateRootUserData")
  /// Posted when the current user should now be destroyed.
  static let DEBUG_destroyCurrentUser = NSNotification.Name("GSJ_DEBUG_DestroyCurrentUser")
  /// Posted when auth should be forced to test the migration flow.
  static let DEBUG_forceAuth = NSNotification.Name("GSJ_DEBUG_ForceAuth")
}
#endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD

/// A view controller that presents users with a list of various settings.
class SettingsViewController: MaterialHeaderCollectionViewController {

  // MARK: - Data model

  enum SettingsItemType {
    case settingButton
    case settingSwitch
  }

  class SettingsItem {
    var title = String()
    var description: String?
    var actionTitle: String?
    var isEnabled = true
    var settingAction: Selector?
    var settingType = SettingsItemType.settingSwitch
  }

  // MARK: - Constants

  let buttonCellIdentifier = "SettingsButtonCell"
  let switchCellIdentifier = "SettingsSwitchCell"

  // MARK: - Properties

  private var rows: [SettingsItem] = []
  private let driveSyncManager: DriveSyncManager?
  private let preferenceManager: PreferenceManager

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: The analytics reporter.
  ///   - driveSyncManager: The drive sync manager.
  ///   - preferenceManager: The preference manager.
  init(analyticsReporter: AnalyticsReporter,
       driveSyncManager: DriveSyncManager?,
       preferenceManager: PreferenceManager) {
    self.preferenceManager = preferenceManager
    self.driveSyncManager = driveSyncManager
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(SettingsButtonCell.self,
                             forCellWithReuseIdentifier: buttonCellIdentifier)
    collectionView?.register(SettingsSwitchCell.self,
                             forCellWithReuseIdentifier: switchCellIdentifier)

    styler.cellStyle = .default
    collectionView?.backgroundColor = .white

    title = String.navigationItemSettings

    if isPresented {
      appBar.hideStatusBarOverlay()
      let closeMenuItem = MaterialCloseBarButtonItem(target: self,
                                                     action: #selector(closeButtonPressed))
      navigationItem.leftBarButtonItem = closeMenuItem
    } else {
      let backMenuItem = MaterialBackBarButtonItem(target: self,
                                                   action: #selector(backButtonPressed))
      navigationItem.leftBarButtonItem = backMenuItem
    }

    configureSettingsItems()
  }

  // MARK: - Private

  // Configure each setting item and add it to the data source.
  private func configureSettingsItems() {
    // Data usage setting.
    let dataUsageSetting = SettingsItem()
    dataUsageSetting.title = String.settingsDataUsageTitle
    dataUsageSetting.description = String.settingsDataUsageDescription
    dataUsageSetting.isEnabled = !preferenceManager.hasUserOptedOutOfUsageTracking
    dataUsageSetting.settingAction = #selector(dataUsageSwitchChanged(sender:))
    rows.append(dataUsageSetting)

    #if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
    // Generate root user data for testing the claim existing experiments flow.
    let generateRootDataSetting = SettingsItem()
    generateRootDataSetting.title = "Generate root user data"
    generateRootDataSetting.description = "Useful for testing the unclaimed experiments flow."
    generateRootDataSetting.actionTitle = "Go"
    generateRootDataSetting.settingType = .settingButton
    generateRootDataSetting.settingAction = #selector(generateRootDataSettingPressed(sender:))
    rows.append(generateRootDataSetting)

    // Generate root user data and force the user to log in to test the migration flow.
    let forceAuthSetting = SettingsItem()
    forceAuthSetting.title = "Force login/migration flow"
    forceAuthSetting.description = "Generate root user data first, if necessary."
    forceAuthSetting.actionTitle = "Go"
    forceAuthSetting.settingType = .settingButton
    forceAuthSetting.settingAction = #selector(forceAuthSettingPressed(sender:))
    rows.append(forceAuthSetting)

    let removeAllDriveUserDataSetting = SettingsItem()
    removeAllDriveUserDataSetting.title = "Remove data from Google Drive"
    removeAllDriveUserDataSetting.description = "Removes experiment_library.proto and all " +
        "experiments from Drive for testing."
    removeAllDriveUserDataSetting.actionTitle = "Go"
    removeAllDriveUserDataSetting.settingType = .settingButton
    removeAllDriveUserDataSetting.settingAction =
        #selector(removeAllDriveUserDataSettingPressed(sender:))
    // Temporarily removed from the build as it might end up confusing testers. It's possible we'll
    // want to bring this back with more functionality (delete ScienceJournal folder, reset app,
    // etc) so leaving the debug code in for now. http://b/112312805
    //
    // rows.append(removeAllDriveUserDataSetting)
    #endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func closeButtonPressed() {
    dismiss(animated: true)
  }

  // MARK: - Settings Actions

  @objc private func dataUsageSwitchChanged(sender: UISwitch) {
    let isOptedOut = !sender.isOn
    preferenceManager.hasUserOptedOutOfUsageTracking = isOptedOut
    analyticsReporter.setOptOut(isOptedOut)
  }

  #if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
  @objc private func generateRootDataSettingPressed(sender: UIButton) {
    NotificationCenter.default.post(name: .DEBUG_createRootUserData, object: nil, userInfo: nil)
  }

  @objc private func forceAuthSettingPressed(sender: UIButton) {
    NotificationCenter.default.post(name: .DEBUG_forceAuth,
                                    object: nil,
                                    userInfo: nil)
  }

  @objc private func removeAllDriveUserDataSettingPressed(sender: UIButton) {
    guard let driveSyncManager = driveSyncManager else { return }

    let message = "Are you sure you want to remove all data from Google Drive for this user? " +
        "This cannot be undone. This is ONLY for testing purposes."
    let alertController = MDCAlertController(title: "Confirm", message: message)
    let removeDataAction = MDCAlertAction(title: "Yes, remove all data") { (action) in
      let spinnerVC = SpinnerViewController()
      spinnerVC.present(fromViewController: self) {
        driveSyncManager.debug_removeAllUserDriveData() { (deletedFileCount, errors) in
          spinnerVC.dismissSpinner() {
            guard errors.count == 0 else {
              print("[SettingsViewController] Error removing all Drive user data: \(errors)")
              return
            }

            let snackbarMessage = MDCSnackbarMessage()
            snackbarMessage.text = "Deleted \(deletedFileCount) files from Drive"
            MDCSnackbarManager.show(snackbarMessage)
          }
        }
      }
    }

    let cancelAction = MDCAlertAction(title: String.actionCancel)
    alertController.addAction(cancelAction)
    alertController.addAction(removeDataAction)
    alertController.accessibilityViewIsModal = true
    self.present(alertController, animated: true)
  }
  #endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD

  // MARK: - UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return rows.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let settingItem = rows[indexPath.row]
    switch settingItem.settingType {
    case .settingButton:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: buttonCellIdentifier,
                                                    for: indexPath)
      if let cell = cell as? SettingsButtonCell {
        cell.titleLabel.text = settingItem.title
        cell.descriptionLabel.text = settingItem.description
        cell.aButton.isEnabled = settingItem.isEnabled
        if let buttonAction = settingItem.settingAction {
          cell.aButton.setTitle(settingItem.actionTitle, for: .normal)
          cell.aButton.addTarget(self, action: buttonAction, for: .touchUpInside)
        }
      }
      return cell
    case .settingSwitch:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: switchCellIdentifier,
                                                    for: indexPath)
      if let cell = cell as? SettingsSwitchCell {
        cell.titleLabel.text = settingItem.title
        cell.descriptionLabel.text = settingItem.description
        cell.aSwitch.isOn = settingItem.isEnabled
        if let switchAction = settingItem.settingAction {
          cell.aSwitch.addTarget(self, action: switchAction, for: .valueChanged)
        }
      }
      return cell
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    let settingsItem = rows[indexPath.row]
    let viewWidth = collectionView.bounds.size.width - view.safeAreaInsetsOrZero.left -
        view.safeAreaInsetsOrZero.right
    var viewHeight: CGFloat = 0
    switch settingsItem.settingType {
    case .settingButton:
      viewHeight = SettingsButtonCell.height(inWidth: viewWidth,
                                             title: settingsItem.title,
                                             buttonTitle: settingsItem.actionTitle ?? "",
                                             description: settingsItem.description)
    case .settingSwitch:
      viewHeight = SettingsSwitchCell.height(inWidth: viewWidth,
                                             title: settingsItem.title,
                                             description: settingsItem.description)
    }
    return CGSize(width: viewWidth, height: viewHeight)
  }

}
