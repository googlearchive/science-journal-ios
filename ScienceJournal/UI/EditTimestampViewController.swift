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

import Foundation

import third_party_objective_c_material_components_ios_components_TextFields_TextFields

protocol EditTimestampViewControllerDelegate: class {
  /// Tells the delegate the user pressed the cancel button.
  func editTimestampViewCancelPressed()

  /// Tells the delegate the user pressed the save button.
  func editTimestampViewSavePressed()
}

/// View controller for the edit timestamp alert view.
class EditTimestampViewController: UIViewController {

  // MARK: - Properties

  weak var delegate: EditTimestampViewControllerDelegate?

  /// The edit timestamp view.
  var editTimestampView: EditTimestampView {
    // swiftlint:disable force_cast
    return view as! EditTimestampView
    // swiftlint:enable force_cast
  }

  private static let selectedTextRangeKey = "selectedTextRange"

  // MARK: - Public

  override func loadView() {
    view = EditTimestampView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Register to observe when the text field content or selection changes, in order to hide
    // the validation message.
    editTimestampView.textField.addTarget(self,
                                          action: #selector(textFieldChanged),
                                          for: .editingChanged)
    editTimestampView.textField.addObserver(self,
        forKeyPath: EditTimestampViewController.selectedTextRangeKey,
        options: [.new, .old],
        context: nil)

    editTimestampView.cancelButton.addTarget(self,
                                             action: #selector(cancelPressed),
                                             for: .touchUpInside)
    editTimestampView.saveButton.addTarget(self,
                                           action: #selector(savePressed),
                                           for: .touchUpInside)

    preferredContentSize = CGSize(width: 200, height: editTimestampView.preferredHeight)
  }

  deinit {
    editTimestampView.textField.removeObserver(self,
        forKeyPath: EditTimestampViewController.selectedTextRangeKey)
  }

  // MARK: - Private

  // Disabling because we can't control this yet (MDComponents).
  // swiftlint:disable block_based_kvo
  override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
    guard keyPath == EditTimestampViewController.selectedTextRangeKey,
        let textField = object as? MDCTextField,
        textField == editTimestampView.textField else {
      return
    }
    editTimestampView.hideValidationError()
  }
  // swiftlint:enable block_based_kvo

  @objc private func textFieldChanged() {
    editTimestampView.hideValidationError()
  }

  @objc private func cancelPressed() {
    delegate?.editTimestampViewCancelPressed()
  }

  @objc private func savePressed() {
    delegate?.editTimestampViewSavePressed()
  }

}
