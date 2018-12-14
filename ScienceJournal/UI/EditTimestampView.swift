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
import third_party_objective_c_material_components_ios_components_TextFields_TextFields
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// View for the alert that allows a user to manually enter a timestamp.
class EditTimestampView: UIView {

  private enum Metrics {
    static let errorDialogTopPadding: CGFloat = -20
    static let errorDialogMaxWidth: CGFloat = 270
    static let errorDialogRightPadding: CGFloat = -6
    static let stackSpacing: CGFloat = 10
    static let viewInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
  }

  // MARK: - Properties

  /// A vertical stack view.
  private let stackView = UIStackView()
  /// The header label.
  let headerLabel = UILabel()
  /// The error dialog.
  private let errorDialog = ErrorDialog()
  /// The error icon.
  private let errorIcon = UIImageView(image: UIImage(named: "ic_error"))

  /// The note text field.
  let textField = MDCTextField()
  /// The save button.
  let saveButton = MDCFlatButton()
  /// The cancel button.
  let cancelButton = MDCFlatButton()

  let textInputController: MDCTextInputControllerUnderline

  var preferredHeight: CGFloat {
    let headerHeight =
        headerLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let textFieldHeight =
        textField.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let saveButtonHeight =
        saveButton.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    return textFieldHeight + headerHeight + saveButtonHeight + Metrics.stackSpacing +
        Metrics.viewInsets.top + Metrics.viewInsets.bottom
  }

  // MARK: - Public

  override init(frame: CGRect) {
    textInputController = MDCTextInputControllerUnderline(textInput: textField)
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    textInputController = MDCTextInputControllerUnderline(textInput: textField)
    super.init(coder: aDecoder)
    configureView()
  }

  /// Shows a validation error message and error icon.
  ///
  /// - Parameter message: The message to display.
  func showValidationError(withMessage message: String) {
    errorDialog.textLabel.text = message
    errorDialog.show()
    errorIcon.isHidden = false
  }

  /// Hides the validation message and error icon.
  func hideValidationError() {
    errorIcon.isHidden = true
    errorDialog.hide()
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = .white

    // Stack view.
    stackView.axis = .vertical
    stackView.spacing = Metrics.stackSpacing
    stackView.layoutMargins = Metrics.viewInsets
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.pinToEdgesOfView(self)

    // Header label.
    headerLabel.font = MDCTypography.titleFont()
    headerLabel.text = String.editCropStartTime
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(headerLabel)

    // Text field.
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.placeholder = String.timestampPickerPrompt
    stackView.addArrangedSubview(textField)

    textInputController.isFloatingEnabled = true
    textInputController.floatingPlaceholderNormalColor = MDCPalette.grey.tint600
    textInputController.floatingPlaceholderScale = 1
    textInputController.activeColor = .appBarReviewBackgroundColor

    // Save and Cancel buttons.
    let buttonWrapper = UIView()
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(buttonWrapper)

    cancelButton.setTitle(String.actionCancel, for: .normal)
    saveButton.setTitle(String.actionSave, for: .normal)
    [cancelButton, saveButton].forEach { (button) in
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setTitleColor(.appBarReviewBackgroundColor, for: .normal)
      button.setBackgroundColor(.clear, for: .normal)
    }

    let buttonStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    buttonWrapper.addSubview(buttonStack)
    buttonStack.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor).isActive = true
    buttonStack.topAnchor.constraint(equalTo: buttonWrapper.topAnchor).isActive = true
    buttonStack.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor).isActive = true

    // Error dialog.
    errorDialog.translatesAutoresizingMaskIntoConstraints = false
    addSubview(errorDialog)
    errorDialog.trailingAnchor.constraint(equalTo: trailingAnchor,
                                          constant: Metrics.errorDialogRightPadding).isActive = true
    errorDialog.topAnchor.constraint(equalTo: textField.bottomAnchor,
                                     constant: Metrics.errorDialogTopPadding).isActive = true
    errorDialog.widthAnchor.constraint(
        lessThanOrEqualToConstant: Metrics.errorDialogMaxWidth).isActive = true

    // Error icon.
    errorIcon.isHidden = true
    errorIcon.tintColor = MDCPalette.red.tint600
    errorIcon.translatesAutoresizingMaskIntoConstraints = false
    addSubview(errorIcon)
    errorIcon.centerYAnchor.constraint(equalTo: textField.centerYAnchor).isActive = true
    errorIcon.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
  }

}
