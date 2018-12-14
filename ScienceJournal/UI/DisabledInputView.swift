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
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view used to overlay the camera or photo library picker when either is disabled for any
/// reason.
class DisabledInputView: UIView {

  enum Metrics {
    static let paddingInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
    static let stackViewSpacing: CGFloat = 10.0
  }

  // MARK: - Public

  /// The message to relay to the user explaining why this input view is disabled.
  let messageLabel = UILabel()

  /// The optional action button to display to the user. Requires `displaysActionButton` be true.
  let actionButton = MDCFlatButton()

  /// Should display the action button?
  var shouldDisplayActionButton: Bool = true {
    didSet {
      if oldValue != shouldDisplayActionButton {
        actionButton.isHidden = !shouldDisplayActionButton
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = MDCPalette.grey.tint300

    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.font = MDCTypography.body1Font()
    messageLabel.textColor = MDCPalette.grey.tint500
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0
    messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.setBackgroundColor(MDCPalette.grey.tint600, for: .normal)
    actionButton.setTitleColor(.white, for: .normal)
    actionButton.setContentHuggingPriority(.required, for: .vertical)

    let wrappingView = UIView()
    addSubview(wrappingView)
    wrappingView.translatesAutoresizingMaskIntoConstraints = false
    wrappingView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    wrappingView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    wrappingView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

    let stackView = UIStackView(arrangedSubviews: [messageLabel, actionButton])
    wrappingView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = Metrics.stackViewSpacing
    stackView.layoutMargins = Metrics.paddingInsets
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.pinToEdgesOfView(wrappingView)
  }

}
