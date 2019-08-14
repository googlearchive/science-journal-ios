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

/// Delegate protocol for NotesViewController to communicate when text has been created for a note.
protocol NotesViewControllerDelegate: class {
  /// Tells the delegate when text has been created for a note.
  func notesViewController(_ notesViewController: NotesViewController,
                           didCreateTextForNote text: String)
}

/// Manages the view that lets a user take notes.
open class NotesViewController: ScienceJournalViewController, DrawerItemViewController,
                                DrawerPositionListener, UITextViewDelegate {

  // MARK: - Properties

  /// The delegate.
  weak var delegate: NotesViewControllerDelegate?

  var notesView: NotesView {
    // swiftlint:disable force_cast
    return view as! NotesView
    // swiftlint:enable force_cast
  }

  // Cached text height, to only pan the drawer up or down if the text height has changed.
  private var textHeight: CGFloat = 0

  // Cached notes view keyboard offset, to only update the drawer position if it has changed. As
  // well as for calculating visible notes height.
  private var notesViewKeyboardOffset: CGFloat = 0

  private var drawerPanner: DrawerPanner?

  private var visibleNotesHeight: CGFloat? {
    guard let drawerViewController = drawerViewController else { return nil }
    return drawerViewController.drawerView.visibleContentHeight - notesViewKeyboardOffset
  }

  // MARK: - Public

  override open func loadView() {
    view = NotesView()
    notesView.textView.delegate = self
    notesView.sendButtonActionBar.button.addTarget(self,
                                                   action: #selector(sendButtonPressed),
                                                   for: .touchUpInside)
    notesView.sendButtonActionBar.button.isEnabled = false
    notesView.sendButtonView.sendButton.addTarget(self,
                                                  action: #selector(sendButtonPressed),
                                                  for: .touchUpInside)
    notesView.sendButtonView.sendButton.isEnabled = false
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // TODO: Localize this string
    title = "Add new text note"

    // Don't allow the custom position until editing begins.
    drawerViewController?.drawerView.canOpenToCustomPosition = false

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillShow,
                                           object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardDidShowNotification(_:)),
        name: .keyboardObserverDidShow,
        object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillHide,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillChangeFrame,
                                           object: nil)

    notesView.textView.panGestureRecognizer.addTarget(
        self,
        action: #selector(handleTextViewPanGesture(_:)))
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if let drawerViewController = drawerViewController {
      // Set the custom notes drawer position.
      let drawerPosition = DrawerPosition(canShowKeyboard: true) {
        // The text view height, not to exceed the maximum, plus half drawer height.
        let textHeight = min(self.notesView.maximumCustomTextHeight,
                             self.notesView.heightFittingText)
        let convertedKeyboardFrame =
            self.notesView.convert(KeyboardObserver.shared.currentKeyboardFrame, from: nil)
        let customDrawerHeight =
            self.notesView.bounds.intersection(convertedKeyboardFrame).height + textHeight
        return max(customDrawerHeight,
                   drawerViewController.drawerView.openHalfPosition.contentHeight)
      }
      drawerViewController.drawerView.setCustomPosition(drawerPosition)

      updateSendButtonStyle(forDrawerPosition: drawerViewController.drawerView.currentPosition)
    }
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // If the drawer is open full, show the keyboard.
    guard let drawerViewController = drawerViewController else { return }
    if drawerViewController.isOpenFull {
      notesView.textView.becomeFirstResponder()
    }
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // If the drawer is in the custom position when leaving this view, set it to half since other
    // views might not support custom positions. Then remove notes' custom position.
    guard let drawerViewController = drawerViewController else { return }
    drawerViewController.setPositionToHalfIfCustom()
    drawerViewController.drawerView.removeCustomPosition()

    // This view controller is only created once in the drawer, and the instance is used for every
    // experiment. End editing so the text view does not retain first responder between view
    // appearances.
    view.endEditing(true)
  }

  // MARK: - Private

  // Whether or not there is text not including whitespace and newlines.
  private var textViewHasTextToSave: Bool {
    guard let noteTextTrimmed = notesView.textView.text.trimmedOrNil else { return false }
    return noteTextTrimmed.count > 0
  }

  // Adjusts the text view height to show between 1 and 3 lines of text in the text view, depending
  // on how many lines of text there are currently.
  private func updateDrawerPositionToFitText(ifTextHeightChanged: Bool = true) {
    guard let drawerViewController = drawerViewController else { return }

    let previousTextHeight = textHeight
    textHeight = min(notesView.heightFittingText, notesView.maximumCustomTextHeight)

    // If the drawer is in the custom position and the text height changed, or an update is
    // requested, update the drawer position to change the text view visible height.
    if drawerViewController.isCustomPosition &&
        (!ifTextHeightChanged || previousTextHeight != textHeight) {
      drawerViewController.setPositionToCustom(animated: false)
    }
  }

  // Updates the send button enabled state.
  private func updateSendButton() {
    // If the text view has text, enable the send buttons, otherwise disable them.
    notesView.sendButtonActionBar.button.isEnabled = textViewHasTextToSave
    notesView.sendButtonView.sendButton.isEnabled = textViewHasTextToSave
  }

  private func updateSendButtonStyle(forDrawerPosition drawerPosition: DrawerPosition) {
    guard let drawerViewController = drawerViewController else { return }
    let sendButtonStyle: NotesView.SendButtonStyle =
        traitCollection.verticalSizeClass == .compact ||
        drawerViewController.isPositionCustom(drawerPosition) ? .button : .toolbar
    notesView.setSendButtonStyle(sendButtonStyle, animated: true)
  }

  private func updatePlaceholder() {
    // Show the placeholder when there is no text. It should also not show if there is a newline or
    // whitespace.
    notesView.placeholderLabel.isHidden = notesView.textView.text.count > 0
  }

  private func animateForKeyboardNotification(_ notification: Notification) {
    guard let duration = KeyboardObserver.animationDuration(fromKeyboardNotification: notification),
        let options =
            KeyboardObserver.animationCurve(fromKeyboardNotification: notification) else { return }
    UIView.animate(withDuration: duration,
                   delay: 0,
                   options: options,
                   animations: {
                     self.updateDrawerPositionToFitText(ifTextHeightChanged: false)
                     self.notesView.updateActionBarHeight()
    })
  }

  /// Clears the text from the text view, and updates the send button and placeholder.
  private func clearText() {
    notesView.textView.text = ""
    updateSendButton()
    updatePlaceholder()
  }

  // MARK: - User actions

  @objc private func sendButtonPressed() {
    notesView.textView.commitPendingAutocomplete()
    guard textViewHasTextToSave, let text = notesView.textView.text else { return }

    clearText()
    let saveText: () -> Void = {
      self.delegate?.notesViewController(self, didCreateTextForNote: text)
    }

    if let drawerViewController = drawerViewController {
      if drawerViewController.drawerView.hasCustomPosition &&
          drawerViewController.canOpenPartially {
        drawerViewController.setToCustomPositionIfFull(completion: saveText)
      } else {
        drawerViewController.minimizeFromFull(completion: saveText)
      }
    } else {
      saveText()
    }
  }

  // MARK: - DrawerItemViewController

  public func setUpDrawerPanner(with drawerViewController: DrawerViewController) {
    drawerPanner = DrawerPanner(drawerViewController: drawerViewController,
                                scrollView: notesView.textView,
                                allowsPanningUp: true)
  }

  public func reset() {
    clearText()
  }

  // MARK: - DrawerPositionListener

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   willChangeDrawerPosition position: DrawerPosition) {
    updateSendButtonStyle(forDrawerPosition: position)

    if !drawerViewController.isPositionOpenFull(position) {
      notesView.textView.setContentOffset(.zero, animated: true)
    }
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   didChangeDrawerPosition position: DrawerPosition) {
    if isDisplayedInDrawer {
      // If opening the drawer to a position that allows showing the keyboard, show it. Otherwise
      // hide the keyboard.
      if position.canShowKeyboard {
        if !drawerViewController.isDisplayedAsSidebar {
          notesView.textView.becomeFirstResponder()
        }
      } else {
        notesView.textView.resignFirstResponder()
      }
    }

    notesView.updateActionBarHeight()
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   isPanningDrawerView drawerView: DrawerView) {
    guard KeyboardObserver.shared.isKeyboardVisible &&
        KeyboardObserver.shared.currentKeyboardFrame != .zero else { return }

    let convertedKeyboardFrame = drawerView.convert(KeyboardObserver.shared.currentKeyboardFrame,
                                                    from: nil)
    let keyboardOffset = drawerView.bounds.maxY - convertedKeyboardFrame.minY
    if drawerView.visibleHeight < keyboardOffset {
      drawerViewController.setPositionToPeeking(animated: true)
    }
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   didPanBeyondBounds panDistance: CGFloat) {}

  // MARK: - UITextViewDelegate

  public func textViewDidBeginEditing(_ textView: UITextView) {
    guard let drawerViewController = drawerViewController else { return }

    // While editing on a device that is not full screen iPad, allow opening the drawer to the
    // custom notes position. Do not let the drawer open halfway.
    if !(traitCollection.horizontalSizeClass == .regular &&
        traitCollection.verticalSizeClass == .regular) {
      drawerViewController.drawerView.canOpenToCustomPosition =
          drawerViewController.canOpenPartially
      drawerViewController.drawerView.canOpenHalf = false
    }

    // If the drawer is peeking or open half, open the drawer to the custom position if it is
    // allowed, otherwise open it to full.
    if drawerViewController.isPeeking || drawerViewController.isOpenHalf {
      if drawerViewController.drawerView.canOpenToCustomPosition {
        drawerViewController.setPositionToCustom()
      } else {
        drawerViewController.setPositionToFull()
      }
    }
  }

  public func textViewDidEndEditing(_ textView: UITextView) {
    // When ending editing on a device that is not full screen iPad, do not let the drawer open to
    // the custom notes position. Let it open halfway.
    if !(traitCollection.horizontalSizeClass == .regular &&
        traitCollection.verticalSizeClass == .regular),
        let drawerViewController = drawerViewController {
      drawerViewController.drawerView.canOpenToCustomPosition = false
      drawerViewController.drawerView.canOpenHalf = drawerViewController.canOpenPartially
    }

    // When ending editing, if the position was custom, switch to open half.
    if let drawerViewController = drawerViewController {
      drawerViewController.setPositionToHalfIfCustom()
    }
  }

  public func textViewDidChange(_ textView: UITextView) {
    updateSendButton()
    updatePlaceholder()
    updateDrawerPositionToFitText()
  }

  // MARK: - UIScrollViewDelegate

  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    drawerPanner?.scrollViewWillBeginDragging(scrollView)
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                       willDecelerate decelerate: Bool) {
    drawerPanner?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
  }

  // MARK: - Gesture recognizer

  @objc func handleTextViewPanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    drawerPanner?.handlePanGesture(panGestureRecognizer)
  }

  // MARK: - Notifications

  @objc func handleKeyboardNotification(_ notification: Notification) {
    // Did the keyboard height change?
    let convertedKeyboardFrame = notesView.convert(KeyboardObserver.shared.currentKeyboardFrame,
                                                   from: nil)
    let previousNotesViewKeyboardOffset = notesViewKeyboardOffset
    notesViewKeyboardOffset = notesView.bounds.maxY - convertedKeyboardFrame.minY
    guard previousNotesViewKeyboardOffset != notesViewKeyboardOffset else { return }

    animateForKeyboardNotification(notification)
  }

  @objc func handleKeyboardDidShowNotification(_ notification: Notification) {
    animateForKeyboardNotification(notification)
  }

}
