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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view for switching a trigger attribute, in the trigger edit view.
class TriggerOptionSwitchView: UIView {

  // MARK: Properties

  weak var delegate: TriggerEditDelegate?

  let aSwitch = UISwitch()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Text for the title label.
  var titleText: String? {
    didSet {
      titleLabel.text = titleText
    }
  }

  /// Vertical padding, added to the entire height, if it needs to be specified. Subclasses should
  /// override.
  var verticalPadding: CGFloat {
    return 17
  }

  private let titleLabel = UILabel()

  // MARK: - Private

  private func configureView() {
    titleLabel.font = MDCTypography.body2Font()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true

    aSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    aSwitch.translatesAutoresizingMaskIntoConstraints = false
    addSubview(aSwitch)
    aSwitch.topAnchor.constraint(equalTo: topAnchor, constant: verticalPadding / 2).isActive = true
    aSwitch.bottomAnchor.constraint(equalTo: bottomAnchor,
                                    constant: -verticalPadding / 2).isActive = true
    aSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
  }

  // MARK: - User actions

  @objc func switchValueChanged() {
    delegate?.triggerEditDelegateDidBeginEditing()
  }

}
