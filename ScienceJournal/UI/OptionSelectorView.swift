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

protocol OptionSelectorDelegate: class {
  /// Called when a pop up menu should be displayed with options.
  func optionSelectorView(_ optionSelectorView: OptionSelectorView,
                          didPressShowOptions actions: [PopUpMenuAction],
                          coveringView: UIView)
}

/// A view for selecting from a menu of options.
class OptionSelectorView: UIView {

  // MARK: Properties

  /// The option selector delegate.
  weak var optionSelectorDelegate: OptionSelectorDelegate?

  /// True if the bottom line is hidden, otherwise false. Defaults to false.
  var isLineHidden = false {
    didSet {
      line.isHidden = isLineHidden
    }
  }

  /// The label to display text describing the selected option.
  let selectionLabel = UILabel()

  /// The drop down menu button.
  let dropDownButton = MDCFlatButton()

  private let line = UIView()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    updateViewForOption()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
    updateViewForOption()
  }

  /// Text for the header label. Subclasses should override.
  var headerLabelText: String {
    return ""
  }

  /// Call when the view should be updated to display the selected option. Subclasses should
  /// override.
  func updateViewForOption() {
    // Does nothing.
  }

  /// Called when the drop down button is pressed. At this time, pop up menu actions should be
  /// created for each option and passed to the delegate to be presented. Subclasses should
  /// override and call super.
  @objc func dropDownButtonPressed() {}

  // MARK: - Private

  private func configureView() {
    let headerLabel = UILabel()
    headerLabel.font = MDCTypography.body2Font()
    headerLabel.text = headerLabelText
    headerLabel.textColor = MDCPalette.grey.tint600
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(headerLabel)
    headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
    headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

    selectionLabel.alpha = MDCTypography.body2FontOpacity()
    selectionLabel.font = MDCTypography.body2Font()
    selectionLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(selectionLabel)
    selectionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor,
                                        constant: 12).isActive = true
    selectionLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor).isActive = true

    line.backgroundColor = MDCPalette.grey.tint400
    line.translatesAutoresizingMaskIntoConstraints = false
    addSubview(line)
    line.topAnchor.constraint(equalTo: selectionLabel.bottomAnchor,
                              constant: 6).isActive = true
    line.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
    line.leadingAnchor.constraint(equalTo: selectionLabel.leadingAnchor).isActive = true
    line.heightAnchor.constraint(equalToConstant: 1).isActive = true
    line.widthAnchor.constraint(equalToConstant: 200).isActive = true

    dropDownButton.addTarget(self, action: #selector(dropDownButtonPressed), for: .touchUpInside)
    dropDownButton.hitAreaInsets = UIEdgeInsets(top: 0, left: -160, bottom: 0, right: 0)
    dropDownButton.setImage(UIImage(named: "ic_arrow_drop_down"), for: .normal)
    dropDownButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(dropDownButton)
    dropDownButton.bottomAnchor.constraint(equalTo: line.topAnchor, constant: 6).isActive = true
    dropDownButton.trailingAnchor.constraint(equalTo: line.trailingAnchor,
                                             constant: 12).isActive = true
    dropDownButton.accessibilityLabel = String.showOptionsContentDescription
  }

}
