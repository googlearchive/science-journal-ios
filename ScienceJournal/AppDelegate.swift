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

import UIKit
import third_party_objective_c_material_components_ios_components_Snackbar_Snackbar

open class AppDelegate: UIResponder, UIApplicationDelegate {

  /// The accounts manager to inject into clases.
  open var accountsManager: AccountsManager {
    fatalError("Subclasses must override and provide an accounts manager instance!")
  }

  /// The analytics reporter to inject into classes.
  open var analyticsReporter: AnalyticsReporter {
    fatalError("Subclasses must override and provide an analytics reporter instance!")
  }

  /// The common UI components to inject into classes.
  open var commonUIComponents: CommonUIComponents {
    fatalError("Subclasses must override and provide a common UI components instance!")
  }

  /// The drawer config to inject into classes.
  open var drawerConfig: DrawerConfig {
    fatalError("Subclasses must override and provide a drawer config instance!")
  }

  /// The drive constructor to inject into classes.
  open var driveConstructor: DriveConstructor {
    fatalError("Subclasses must override and provide a drive constructor instance!")
  }

  /// The feedback reporter to inject into classes.
  open var feedbackReporter: FeedbackReporter {
    fatalError("Subclasses must override and provide a feedback reporter instance!")
  }

  /// The file system layout to inject into classes.
  open var fileSystemLayout: FileSystemLayout {
    fatalError("Subclasses must override and provide a file system layout instance!")
  }

  /// The network availability to inject into classes.
  open var networkAvailability: NetworkAvailability {
    fatalError("Subclasses must override and provide a network availability instance!")
  }

  #if FEATURE_FIREBASE_RC
  /// The remote config manager to inject into classes.
  open var remoteConfigManager: RemoteConfigManager {
    fatalError("Subclasses must override and provide a remote config manager instance!")
  }
  #endif

  /// The sensor controller to inject into classes. Implicitly unwrapped to delay initialization
  /// until launch is done.
  open var sensorController: SensorController!

  var appFlowViewController: AppFlowViewController!

  open var window: UIWindow?

  private let launchManager = LaunchManager.standard

  // swiftlint:disable vertical_parameter_alignment
  open func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    sensorController = SensorController()

    excludeDataFromiCloudBackups()

    // Initialize the capture session interruption observer.
    _ = CaptureSessionInterruptionObserver.shared

    // Sets the Snackbar to use its legacy presentation
    MDCSnackbarMessage.usesLegacySnackbar = true

    window = UIWindow.init(frame: UIScreen.main.bounds)

    let launchContainerViewController = createLaunchContainerViewController()
    window?.rootViewController = launchContainerViewController
    window?.makeKeyAndVisible()

    launchManager.performLaunchOperations { completionState in
      switch completionState {
      case .success:
        launchContainerViewController.presentLaunchSuccessViewController()
      case .failure:
        launchContainerViewController.presentLaunchFailureViewController()
      }
    }

    return true
  }
  // swiftlint:enable vertical_parameter_alignment

  private func excludeDataFromiCloudBackups() {
    URL.excludeFromiCloudBackups(url: URL.documentsDirectoryURL)
    URL.excludeFromiCloudBackups(url: FileSystemLayout.Version.two.baseURL)
  }

  private func createLaunchContainerViewController() -> LaunchContainerViewController {
    return LaunchContainerViewController(
      onSuccess: self.createAppFlowViewController(),
      onFailure: LaunchFailureViewController(feedbackReporter: self.feedbackReporter)
    )
  }

  private func createAppFlowViewController() -> AppFlowViewController {
    #if FEATURE_FIREBASE_RC
    appFlowViewController = AppFlowViewController(fileSystemLayout: fileSystemLayout,
                                                  accountsManager: accountsManager,
                                                  analyticsReporter: analyticsReporter,
                                                  commonUIComponents: commonUIComponents,
                                                  drawerConfig: drawerConfig,
                                                  driveConstructor: driveConstructor,
                                                  feedbackReporter: feedbackReporter,
                                                  networkAvailability: networkAvailability,
                                                  remoteConfigManager: remoteConfigManager,
                                                  sensorController: sensorController)
    #else
    appFlowViewController = AppFlowViewController(fileSystemLayout: fileSystemLayout,
                                                  accountsManager: accountsManager,
                                                  analyticsReporter: analyticsReporter,
                                                  commonUIComponents: commonUIComponents,
                                                  drawerConfig: drawerConfig,
                                                  driveConstructor: driveConstructor,
                                                  feedbackReporter: feedbackReporter,
                                                  networkAvailability: networkAvailability,
                                                  sensorController: sensorController)
    #endif
    return appFlowViewController
  }

  open func applicationDidBecomeActive(_ application: UIApplication) {
    guard launchManager.state == .completed(.success) else { return }
    // When the app becomes active, attempt to reauthenticate the current user account and remove
    // any lingering accounts.
    accountsManager.reauthenticateCurrentAccount()
    accountsManager.removeLingeringAccounts()
  }

  open func application(_ app: UIApplication,
                        open url: URL,
                        options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    guard launchManager.state == .completed(.success) else { return false }
    return appFlowViewController.handleImportURL(url)
  }

}
