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
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// Rename view controller that has the title for naming an experiment.
class RenameExperimentViewController: RenameViewController {

  override var titleText: String {
    return String.nameExperimentDialogTitle
  }

}

/// Rename view controller that has the title for renaming a recording.
class RenameTrialViewController: RenameViewController {

  override var titleText: String {
    return String.runRenameDialogTitle
  }

}

/// A view controller used as a modal dialog allowing a user to rename an untitled item.
class RenameViewController: ScienceJournalViewController, UITextFieldDelegate {

  // MARK: - Constants

  let buttonHeight: CGFloat = 40.0
  let buttonOffset: CGFloat = 16.0
  let dialogInsets = UIEdgeInsets(top: 28.0, left: 28.0, bottom: 4.0, right: 28.0)
  let maxViewWidth: CGFloat = 200.0
  let outerPadding: CGFloat = 40.0
  let textFieldHeight: CGFloat = 62.0
  let titleFontSize: CGFloat = 19.0
  let verticalSpacing: CGFloat = 4.0

  // MARK: - Properties

  /// The title text. Subclasses should override.
  var titleText: String {
    return ""
  }

  let titleLabel = UILabel()
  let okayButton = MDCFlatButton()
  private let scrollView = UIScrollView()
  let textField = MDCTextField()
  private var textFieldController: MDCTextInputController?

  // MARK: - Public

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    let titleFont = MDCTypography.fontLoader().boldFont?(ofSize: titleFontSize) ??
        UIFont.boldSystemFont(ofSize: titleFontSize)

    // Title for the dialog.
    titleLabel.font = titleFont
    titleLabel.numberOfLines = 0
    titleLabel.text = titleText
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    // The text field and its controller.
    textField.delegate = self
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
    textField.clearButtonMode = .whileEditing

    let controller = MDCTextInputControllerUnderline(textInput: textField)
    controller.isFloatingEnabled = false
    controller.activeColor = .appBarReviewBackgroundColor
    textFieldController = controller

    // Wrapper to allow us to right-align a button in a fill-mode stack view.
    let buttonWrapper = UIView()
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false
    buttonWrapper.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

    // OK button.
    buttonWrapper.addSubview(okayButton)
    okayButton.translatesAutoresizingMaskIntoConstraints = false
    okayButton.setTitle(String.actionOk, for: .normal)
    okayButton.inkColor = .clear
    okayButton.setTitleColor(.appBarReviewBackgroundColor, for: .normal)
    okayButton.setBackgroundColor(.clear, for: .normal)
    okayButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor,
                                    constant: -buttonOffset).isActive = true
    okayButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor,
                                         constant: buttonOffset).isActive = true
    okayButton.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor).isActive = true

    // Scroll view.
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    scrollView.pinToEdgesOfView(view)

    // Wrapping stack view.
    let stackView = UIStackView(arrangedSubviews: [titleLabel, textField, buttonWrapper])
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)
    stackView.pinToEdgesOfView(scrollView, withInsets: dialogInsets)
    stackView.widthAnchor.constraint(
        equalTo: scrollView.widthAnchor,
        constant: -dialogInsets.left - dialogInsets.right).isActive = true

    // Make sure the wrapper and text field are full width.
    textField.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    buttonWrapper.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

    // Calculate the preferred content size for the presenting controller.
    var totalHeight = dialogInsets.top + textFieldHeight + buttonHeight +
        dialogInsets.bottom
    totalHeight += titleText.labelHeight(withConstrainedWidth: maxViewWidth, font: titleFont)
    preferredContentSize = CGSize(width: maxViewWidth,
                                  height: totalHeight)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillShow,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillChangeFrame,
                                           object: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    textField.becomeFirstResponder()
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    // Make sure the text field remains first responder so another view like the drawer doesn't
    // override it.
    coordinator.animate(alongsideTransition: { _ in }) { (_) in
      self.textField.becomeFirstResponder()
    }
  }

  // MARK: - Notifications

  @objc private func handleKeyboardNotification(_ notification: Notification) {
    guard let duration = KeyboardObserver.animationDuration(fromKeyboardNotification: notification),
        let options = KeyboardObserver.animationCurve(fromKeyboardNotification: notification) else {
      return
    }

    let convertedKeyboardFrame = view.convert(KeyboardObserver.shared.currentKeyboardFrame,
                                              from: nil)
    let contentOffset = CGPoint(x: 0,
                                y: scrollView.frame.intersection(convertedKeyboardFrame).height)

    UIView.animate(withDuration: duration,
                   delay: 0,
                   options: options,
                   animations: {
                     self.scrollView.setContentOffset(contentOffset, animated: false)
    })
  }

}
