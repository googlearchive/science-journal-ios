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

/// Displays a spinner in front of a darkened view after a delay.
class SpinnerViewController: UIViewController {

  // MARK: - Properties

  private let transitionController = AlphaFadeTransitionController()
  private let spinner = MaterialFloatingSpinner()

  private enum Metrics {
    static let darkenedColor = UIColor(white: 0, alpha: 0.7)
  }

  public var backgroundColor = Metrics.darkenedColor
  public var statusBarStyle = UIStatusBarStyle.lightContent

  // MARK: Public

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = backgroundColor

    view.addSubview(spinner)
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    spinner.isAccessibilityElement = false
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    spinner.startAnimating()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  /// Presents the spinner view controller.
  ///
  /// - Parameters:
  ///   - viewController: The presenting view controller.
  ///   - completion: A block called when view controller presentation completes.
  func present(fromViewController viewController: UIViewController,
               completion: (() -> Void)? = nil) {
    modalPresentationStyle = .custom
    transitioningDelegate = transitionController
    viewController.present(self, animated: true, completion: completion)
    accessibilityViewIsModal = true
  }

  /// Dismisses the spinner view controller.
  ///
  /// - Parameter completion: The block to execute after the spinner view controller is dismissed.
  func dismissSpinner(completion: (() -> Void)? = nil) {
    if let presentingViewController = presentingViewController {
      presentingViewController.dismiss(animated: true, completion: completion)
    } else {
      completion?()
    }
  }

}
