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

/// The `LaunchContainerViewController` presents the app launch screen
/// until it is asked to present the post-launch view controller. The
/// post-launch view controller is passed as an autoclosure, which ensures
/// it is not instantiated until it is presented.
final public class LaunchContainerViewController: UIViewController {

  // MARK: - Properties

  // TODO: Use a typealias after we're on Swift 5.1.
  // https://bugs.swift.org/browse/SR-2688
  private let launchSuccessViewController: () -> UIViewController
  private let launchFailureViewController: () -> UIViewController
  private var launchScreenViewController: UIViewController?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - launchSuccessViewController: An autoclosure that returns the view controller to present
  ///     on launch success.
  ///   - launchFailureViewController: An autoclosure that returns the view controller to present
  ///     on launch failure.
  public init(
    onSuccess launchSuccessViewController: @escaping @autoclosure () -> UIViewController,
    onFailure launchFailureViewController: @escaping @autoclosure () -> UIViewController
  ) {
    self.launchSuccessViewController = launchSuccessViewController
    self.launchFailureViewController = launchFailureViewController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    let launchScreenViewController = createLaunchScreenViewController()
    transitionToViewController(launchScreenViewController, animated: false)
    self.launchScreenViewController = launchScreenViewController
  }

  override public var preferredStatusBarStyle: UIStatusBarStyle {
    return children.last?.preferredStatusBarStyle ?? .lightContent
  }

  /// Present the launch success view controller.
  public func presentLaunchSuccessViewController() {
    transitionToViewController(launchSuccessViewController(), animated: false) {
      self.launchCleanup()
    }
  }

  private func launchCleanup() {
    // Ensure the `launchScreenViewController` is released.
    self.launchScreenViewController = nil
  }

  /// Present the launch failure view controller.
  public func presentLaunchFailureViewController() {
    transitionToViewController(launchFailureViewController(), animated: true) {
      self.launchCleanup()
    }
  }

  // MARK: - Private

  private func createLaunchScreenViewController() -> UIViewController {
    return UIStoryboard(name: "LaunchScreen", bundle: Bundle.currentBundle)
      .instantiateViewController(withIdentifier: "viewController")
  }

}
