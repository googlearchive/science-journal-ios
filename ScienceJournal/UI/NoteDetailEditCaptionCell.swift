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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_TextFields_TextFields

protocol NoteDetailEditCaptionCellDelegate: class {
  func didBeginEditingCaption()
  func captionEditingChanged(_ caption: String?)
}

/// A cell that displays an editable caption for a note.
class NoteDetailEditCaptionCell: UICollectionViewCell, UITextFieldDelegate {

  // MARK: - Constants

  static let height: CGFloat = 60.0

  // MARK: - Properties

  /// Whether to allow editing the caption.
  var shouldAllowEditing = true {
    didSet {
      textField.isUserInteractionEnabled = shouldAllowEditing
      textField.placeholder =
          shouldAllowEditing ? String.noteCaptionHint : String.noteCaptionHintReadOnly
    }
  }

  weak var delegate: NoteDetailEditCaptionCellDelegate?
  let textField = MDCTextField()
  private var textFieldController: MDCTextInputController?

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  // MARK: - UITextFieldDelegate

  func textFieldDidBeginEditing(_ textField: UITextField) {
    delegate?.didBeginEditingCaption()
  }

  // MARK: - Private

  private func configureView() {
    contentView.addSubview(textField)
    textField.addTarget(self,
                        action: #selector(textFieldEditingChanged),
                        for: .allEditingEvents)
    textField.delegate = self
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.placeholder = String.noteCaptionHint
    textField.clearButtonMode = .never
    textField.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

    let controller = MDCTextInputControllerUnderline(textInput: textField)
    controller.floatingPlaceholderNormalColor = .appBarReviewBackgroundColor
    controller.activeColor = .appBarReviewBackgroundColor

    textFieldController = controller
  }

  @objc private func textFieldEditingChanged() {
    delegate?.captionEditingChanged(textField.text)
  }

}
