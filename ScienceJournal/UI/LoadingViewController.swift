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

/// Shows a view with a white background and a spinner. Used to block the UI while performing
/// loading operations.
class LoadingViewController: UIViewController {

  private enum Metrics {
    static let backgroundColor = UIColor(red: 0.290, green: 0.078, blue: 0.549, alpha: 1.0)
    static let innerSpacing: CGFloat = 40.0
  }

  private let logoImage = UIImageView(image: UIImage(named: "launch_image_icon"))
  private let spinner = MaterialFloatingSpinner()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = Metrics.backgroundColor

    logoImage.translatesAutoresizingMaskIntoConstraints = false
    logoImage.isAccessibilityElement = false

    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.isAccessibilityElement = false

    let stackView = UIStackView(arrangedSubviews: [logoImage, spinner])
    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.spacing = Metrics.innerSpacing
    stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    spinner.startAnimating()
  }

}
