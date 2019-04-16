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

import third_party_objective_c_material_components_ios_components_CollectionCells_CollectionCells
import third_party_objective_c_material_components_ios_components_Typography_Typography

protocol TriggerListCellDelegate: class {
  /// Called when the switch value changes.
  func triggerListCellSwitchValueChanged(_ triggerListCell: TriggerListCell)

  /// Called when the menu button is pressed.
  func triggerListCellMenuButtonPressed(_ triggerListCell: TriggerListCell)
}

/// A cell used to display a trigger in the trigger list.
class TriggerListCell: MDCCollectionViewCell {

  // MARK: - Constants

  /// The cell height.
  static let height: CGFloat = 54

  private let horizontalPadding: CGFloat = 16

  // MARK: - Properties

  /// The delegate.
  weak var delegate: TriggerListCellDelegate?

  /// The text label.
  let textLabel = UILabel()

  /// The switch.
  let aSwitch = UISwitch()

  /// The menu button.
  let menuButton = MenuButton()

  // MARK: - Public

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
    // Stack view.
    let stackView = UIStackView()
    stackView.alignment = .center
    stackView.spacing = horizontalPadding
    stackView.layoutMargins =
        UIEdgeInsets(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding)
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stackView)
    stackView.pinToEdgesOfView(contentView)

    // Text label.
    textLabel.alpha = MDCTypography.body1FontOpacity()
    textLabel.font = MDCTypography.body1Font()
    textLabel.lineBreakMode = .byTruncatingTail
    textLabel.numberOfLines = 2
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    stackView.addArrangedSubview(textLabel)

    // Switch.
    aSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
    aSwitch.translatesAutoresizingMaskIntoConstraints = false
    aSwitch.setContentHuggingPriority(.required, for: .horizontal)
    stackView.addArrangedSubview(aSwitch)

    // Menu button.
    menuButton.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuButton.tintColor = .darkGray
    menuButton.translatesAutoresizingMaskIntoConstraints = false
    menuButton.hitAreaInsets = UIEdgeInsets(top: -20, left: -10, bottom: -20, right: -10)
    stackView.addArrangedSubview(menuButton)
  }

  // MARK: - User actions

  @objc func switchValueChanged(_ aSwitch: UISwitch) {
    delegate?.triggerListCellSwitchValueChanged(self)
  }

  @objc func menuButtonPressed() {
    delegate?.triggerListCellMenuButtonPressed(self)
  }

}
