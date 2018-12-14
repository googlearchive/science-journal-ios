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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons

/// A view controller that displays a centered button.
class ButtonViewController: UIViewController {

  /// The button, centered in the view.
  let button = MDCFlatButton()

  /// A 1pt horizontal line at the top of the view.
  let topSeparatorView = SeparatorView(direction: .horizontal, style: .light)

  override func viewDidLoad() {
    super.viewDidLoad()

    button.translatesAutoresizingMaskIntoConstraints = false
    topSeparatorView.translatesAutoresizingMaskIntoConstraints = false

    let buttonStackView = UIStackView(arrangedSubviews: [button])
    buttonStackView.translatesAutoresizingMaskIntoConstraints = false
    buttonStackView.alignment = .center
    buttonStackView.axis = .vertical

    let stackView = UIStackView(arrangedSubviews: [topSeparatorView, buttonStackView])
    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical

    let topConstraint: NSLayoutConstraint
    if #available(iOS 11.0, *) {
      topConstraint =
          stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
    } else {
      topConstraint = stackView.topAnchor.constraint(equalTo: view.topAnchor)
    }

    let bottomConstraint: NSLayoutConstraint
    if #available(iOS 11.0, *) {
      bottomConstraint =
          stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    } else {
      bottomConstraint = stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    }

    NSLayoutConstraint.activate([
      topConstraint,
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomConstraint
    ])
  }

}
