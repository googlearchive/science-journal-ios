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
import MaterialComponents

/// A view for typing a trigger attribute, in the trigger edit view.
class TriggerOptionEntryView: UIView {

  // MARK: Properties

  let textField = MDCTextField()
  let textInputController: MDCTextInputControllerUnderline

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

  /// Text for the text field placeholder. Subclasses should override.
  var textFieldPlaceholderText: String {
    return ""
  }

  /// Keyboard type for the text field. Default is the default keyboard type. Subclasses should
  /// override.
  var textFieldKeyboardType: UIKeyboardType? {
    return nil
  }

  /// Width for the text field, if it needs to be specified. Subclasses should override.
  var textFieldWidth: CGFloat? {
    return nil
  }

  /// Vertical padding, added to the entire height, if it needs to be specified. Subclasses should
  /// override.
  var verticalPadding: CGFloat {
    return 0
  }

  /// Is the text input's presentation style floating? Defaults to false. Subclasses should
  /// override.
  var textInputIsFloatingEnabled: Bool {
    return false
  }

  // MARK: - Private

  private func configureView() {
    textField.font = MDCTypography.body2Font()
    if let textFieldKeyboardType = textFieldKeyboardType {
      textField.keyboardType = textFieldKeyboardType
    }
    textField.placeholder = textFieldPlaceholderText
    textField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textField)
    textField.topAnchor.constraint(equalTo: topAnchor,
                                   constant: verticalPadding / 2).isActive = true
    textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
    let textFieldBottomConstraint =
        textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -verticalPadding / 2)
    textFieldBottomConstraint.isActive = true
    textFieldBottomConstraint.priority = .defaultLow
    var textFieldWidthOrTrailingConstraint: NSLayoutConstraint
    if let textFieldWidth = textFieldWidth {
      textFieldWidthOrTrailingConstraint =
          textField.widthAnchor.constraint(equalToConstant: textFieldWidth)
    } else {
      textFieldWidthOrTrailingConstraint =
          textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
    }
    textFieldWidthOrTrailingConstraint.isActive = true
    textFieldWidthOrTrailingConstraint.priority = .defaultHigh

    textInputController.isFloatingEnabled = textInputIsFloatingEnabled
    textInputController.floatingPlaceholderNormalColor = MDCPalette.grey.tint600
    textInputController.floatingPlaceholderScale = 1
    textInputController.activeColor = .appBarReviewBackgroundColor
  }

}
