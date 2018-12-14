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

protocol SignInFlowViewControllerDelegate: class {
  /// Tells the delegate the sign in flow is complete. Will only be called if the user successfully
  /// signed into an account.
  func signInFlowDidCompleteWithAccount()

  /// Tells the delegate the sign in flow completed and the user will proceed without signing in.
  func signInFlowDidCompleteWithoutAccount()
}

/// Manages the navigation of the sign in flow, including any account migration options if
/// necessary.
class SignInFlowViewController: UIViewController, SignInViewControllerDelegate,
                                WelcomeViewControllerDelegate {

  /// The delegate.
  weak var delegate: SignInFlowViewControllerDelegate?

  /// The existing data migration manager. Exposed for testing.
  var existingDataMigrationManager: ExistingDataMigrationManager?

  private let accountsManager: AccountsManager
  private var accountUserManager: AccountUserManager?
  private let analyticsReporter: AnalyticsReporter
  private let navController = UINavigationController()
  private let rootUserManager: RootUserManager
  private let sensorController: SensorController

  private static var hasUserSeenWelcomeView = false

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - accountsManager: The accounts manager.
  ///   - analyticsReporter: The analytics reporter.
  ///   - rootUserManager: The root user manager.
  ///   - sensorController: The sensor controller.
  init(accountsManager: AccountsManager,
       analyticsReporter: AnalyticsReporter,
       rootUserManager: RootUserManager,
       sensorController: SensorController) {
    self.accountsManager = accountsManager
    self.analyticsReporter = analyticsReporter
    self.rootUserManager = rootUserManager
    self.sensorController = sensorController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if SignInFlowViewController.hasUserSeenWelcomeView {
      showSignInViewController()
    } else {
      showWelcomeViewController()
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return children.last?.preferredStatusBarStyle ?? .lightContent
  }

  // MARK: - SignInViewControllerDelegate

  func signInViewControllerDidSignIn() {
    delegate?.signInFlowDidCompleteWithAccount()
  }

  func signInViewControllerContinueWithoutSigningIn() {
    delegate?.signInFlowDidCompleteWithoutAccount()
  }

  // MARK: - WelcomeViewControllerDelegate

  func welcomeViewControllerDidGetStarted() {
    showSignInViewController()
  }

  // MARK: - Private

  private func showSignInViewController() {
    let signInViewController = SignInViewController(accountsManager: accountsManager,
                                                    analyticsReporter: analyticsReporter)
    signInViewController.delegate = self
    transitionToViewController(signInViewController)
  }

  private func showWelcomeViewController() {
    SignInFlowViewController.hasUserSeenWelcomeView = true
    let welcomeViewController = WelcomeViewController(analyticsReporter: analyticsReporter)
    welcomeViewController.delegate = self
    transitionToViewController(welcomeViewController)
  }

}
