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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view for typing a trigger value, in the trigger edit view.
class TriggerValueEntryView: TriggerOptionEntryView {

  // MARK: - Properties

  /// The trigger value string.
  var triggerValueString: String? {
    get {
      return textField.text
    }
    set {
      textField.text = newValue
    }
  }

  /// The unit description to display.
  var unitDescription: String? {
    didSet {
      unitDescriptionLabel.text = unitDescription
    }
  }

  private let errorDialog = ErrorDialog()
  private let errorIcon = UIImageView(image: UIImage(named: "ic_error"))
  private let unitDescriptionLabel = UILabel()

  override var textFieldPlaceholderText: String {
    return String.triggerValueLabel
  }

  override var textFieldKeyboardType: UIKeyboardType {
    return .numbersAndPunctuation
  }

  override var textFieldWidth: CGFloat {
    return 110
  }

  override var textInputIsFloatingEnabled: Bool {
    return true
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Shows the validation error dialog and icon.
  ///
  /// - Parameter animated: Whether or not to animate it.
  func showValidationError() {
    errorDialog.show()
    UIView.animate(withDuration: 0.2) {
      self.errorIcon.alpha = 1
    }
  }

  /// Hides the validation error dialog and icon.
  ///
  /// - Parameter animated: Whether or not to animate it.
  func hideValidationError() {
    errorDialog.hide()
    UIView.animate(withDuration: 0.2) {
      self.errorIcon.alpha = 0
    }
  }

  // MARK: - Private

  private func configureView() {
    textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

    unitDescriptionLabel.alpha = MDCTypography.body2FontOpacity()
    unitDescriptionLabel.font = MDCTypography.body2Font()
    unitDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(unitDescriptionLabel)
    unitDescriptionLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor).isActive = true
    unitDescriptionLabel.leadingAnchor.constraint(equalTo: textField.trailingAnchor,
                                                  constant: 6).isActive = true

    errorIcon.alpha = 0
    errorIcon.tintColor = MDCPalette.red.tint600
    errorIcon.translatesAutoresizingMaskIntoConstraints = false
    addSubview(errorIcon)
    errorIcon.centerYAnchor.constraint(equalTo: unitDescriptionLabel.centerYAnchor).isActive = true
    errorIcon.trailingAnchor.constraint(equalTo: unitDescriptionLabel.leadingAnchor,
                                        constant: -6).isActive = true

    errorDialog.textLabel.text = String.cannotSaveInvalidValue
    errorDialog.translatesAutoresizingMaskIntoConstraints = false
    addSubview(errorDialog)
    errorDialog.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6).isActive = true
    errorDialog.topAnchor.constraint(equalTo: textField.bottomAnchor,
                                     constant: -10).isActive = true
    errorDialog.widthAnchor.constraint(equalToConstant: 300).isActive = true
  }

  // MARK: - Private

  @objc func textFieldChanged() {
    hideValidationError()
  }

}
