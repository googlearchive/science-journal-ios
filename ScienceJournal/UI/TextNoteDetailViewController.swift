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

/// The detail view of a text note which allows for editing of the text contents.
class TextNoteDetailViewController: MaterialHeaderViewController, NoteDetailController {

  // MARK: - Properties

  private weak var delegate: ExperimentItemDelegate?
  private var displayTextNote: DisplayTextNote
  private let experimentInteractionOptions: ExperimentInteractionOptions
  private let textView = UITextView()

  private var textViewDefaultInsets: UIEdgeInsets {
    return UIEdgeInsets(top: 12.0,
                        left: 12.0 + view.safeAreaInsetsOrZero.left,
                        bottom: 12.0,
                        right: 12.0 + view.safeAreaInsetsOrZero.right)
  }

  // MARK: - NoteDetailController

  var displayNote: DisplayNote {
    get {
      return displayTextNote
    }
    set {
      if let textNote = newValue as? DisplayTextNote {
        displayTextNote = textNote
        updateViewForDisplayNote()
      }
    }
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// Parameters:
  ///  - displayTextNote: The text note to display.
  ///  - delegate: The experiment item delegate.
  ///  - experimentInteractionOptions: The experiment interaction options.
  ///  - analyticsReporter: The analytics reporter.
  init(displayTextNote: DisplayTextNote,
       delegate: ExperimentItemDelegate?,
       experimentInteractionOptions: ExperimentInteractionOptions,
       analyticsReporter: AnalyticsReporter) {
    self.delegate = delegate
    self.displayTextNote = displayTextNote
    self.experimentInteractionOptions = experimentInteractionOptions
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    appBar.headerViewController.headerView.backgroundColor = .appBarTextEditingBarBackgroundColor

    title = experimentInteractionOptions.shouldAllowEdits ?
        String.textLabelDetailsTitle : String.textLabelDetailsTitleReadOnly

    let backMenuItem = MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    navigationItem.leftBarButtonItem = backMenuItem

    func showDeleteButton() {
      let deleteBarButton = MaterialBarButtonItem()
      deleteBarButton.button.addTarget(self,
                                       action: #selector(deleteButtonPressed),
                                       for: .touchUpInside)
      deleteBarButton.button.setImage(UIImage(named: "ic_delete"), for: .normal)
      deleteBarButton.accessibilityLabel = String.deleteNoteMenuItem
      navigationItem.rightBarButtonItem = deleteBarButton
    }

    if experimentInteractionOptions.shouldAllowDeletes {
      showDeleteButton()
    }

    view.addSubview(textView)
    textView.isEditable = experimentInteractionOptions.shouldAllowEdits
    textView.text = displayTextNote.text
    textView.font = MDCTypography.body1Font()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
    textView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    textView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    textView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    updateTextViewContentInset()

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardNotification(_:)),
        name: .MDCKeyboardWatcherKeyboardWillChangeFrame,
        object: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    textView.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Save the note's text if necessary.
    guard let newTrimmedText = textView.text.trimmedOrNil else { return }
    if newTrimmedText != displayTextNote.text {
      displayTextNote.text = newTrimmedText
      delegate?.detailViewControllerDidUpdateTextForNote(displayTextNote)
    }
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    appBar.headerViewController.updateTopLayoutGuide()
  }

  override func viewSafeAreaInsetsDidChange() {
    if #available(iOS 11.0, *) {
      super.viewSafeAreaInsetsDidChange()
    }

    textView.textContainerInset = textViewDefaultInsets
  }

  // MARK: - Notifications

  @objc func handleKeyboardNotification(_ notification: Notification) {
    updateTextViewContentInset()
    textView.scrollRangeToVisible(NSRange(location: displayTextNote.text.count - 1,
                                          length: 1))
  }

  // MARK: - Private

  private func updateTextViewContentInset() {
    let keyboardHeight = MDCKeyboardWatcher.shared().visibleKeyboardHeight
    textView.contentInset.bottom = keyboardHeight
    textView.scrollIndicatorInsets = textView.contentInset
  }

  private func updateViewForDisplayNote() {
    textView.endEditing(true)
    textView.text = displayTextNote.text
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func deleteButtonPressed() {
    delegate?.detailViewControllerDidDeleteNote(displayTextNote)
    navigationController?.popViewController(animated: true)
  }

}
