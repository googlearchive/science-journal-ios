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

/// View that lets a user take notes.
class NotesView: UIView {

  class SendButtonView: UIView {

    /// The send button.
    let sendButton = MDCFlatButton(type: .custom)

    init() {
      super.init(frame: .zero)
      configureView()
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      configureView()
    }

    func configureView() {
      sendButton.disabledAlpha = 0.4
      let sendButtonImage = UIImage(named: "ic_send")?.imageFlippedForRightToLeftLayoutDirection()
      sendButton.setImage(sendButtonImage, for: .normal)
      sendButton.autoresizesSubviews = false
      sendButton.contentEdgeInsets = .zero
      sendButton.imageEdgeInsets = .zero
      sendButton.inkColor = .clear
      sendButton.tintColor = MDCPalette.blue.tint500
      addSubview(sendButton)
      sendButton.translatesAutoresizingMaskIntoConstraints = false
      sendButton.pinToEdgesOfView(self)
      sendButton.accessibilityLabel = String.addTextNoteContentDescription
    }
  }

  /// Styles for displaying the send button.
  ///
  /// - toolbar: As a toolbar below the text view.
  /// - button: As a button to the right of the text view.
  enum SendButtonStyle {
    case toolbar
    case button
  }

  // MARK: - Properties

  /// The text view.
  let textView = UITextView()

  /// The send button action bar.
  let sendButtonActionBar = ActionBar(buttonType: .send)

  /// The send button view.
  let sendButtonView = SendButtonView()

  /// The text view's placeholder label.
  let placeholderLabel = UILabel()

  /// The maximum text height for the custom drawer position.
  lazy var maximumCustomTextHeight: CGFloat = {
    return self.threeLineTextHeight + self.textView.textContainerInset.top +
      self.textView.textContainerInset.bottom
  }()

  /// One line text height.
  lazy var oneLineTextHeight: CGFloat = {
    guard let textViewFont = self.textView.font else { return 0 }
    return "onelinestring".labelHeight(withConstrainedWidth: 0, font: textViewFont)
  }()

  /// Three line text height.
  lazy var threeLineTextHeight: CGFloat = {
    guard let textViewFont = self.textView.font else { return 0 }
    return "three\nline\nstring".labelHeight(withConstrainedWidth: 0, font: textViewFont)
  }()

  private var placeholderLabelLeadingConstraint: NSLayoutConstraint?
  private var placeholderLabelTopConstraint: NSLayoutConstraint?
  private var placeholderLabelTrailingConstraint: NSLayoutConstraint?
  private var sendButtonActionBarWrapperBottomConstraint: NSLayoutConstraint?
  private var sendButtonActionBarWrapperHeightConstraint: NSLayoutConstraint?
  private let sendButtonViewHorizontalInset: CGFloat = 16
  private let sendButtonViewTopInset: CGFloat = 40
  private static let textContainerHorizontalInset: CGFloat = 16
  private let textViewHorizontalBuffer: CGFloat = 5
  private var sendButtonStyle = SendButtonStyle.button
  private let sendButtonActionBarWrapper = UIView()
  private var sendButtonViewTrailingConstraint: NSLayoutConstraint?

  private var textViewTextContainerInset: UIEdgeInsets {
    return UIEdgeInsets(top: 18,
                        left: NotesView.textContainerHorizontalInset + safeAreaInsetsOrZero.left,
                        bottom: 16,
                        right: NotesView.textContainerHorizontalInset + safeAreaInsetsOrZero.right)
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)

    configureView()
    registerForNotifications()
    setSendButtonStyle(.toolbar)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    configureView()
    registerForNotifications()
    setSendButtonStyle(.toolbar)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func safeAreaInsetsDidChange() {
    updateActionBarHeight()
    updateTextViewTextContainerInset()

    sendButtonViewTrailingConstraint?.constant =
        -sendButtonViewHorizontalInset - safeAreaInsetsOrZero.right
  }

  /// Returns the height of the notes view that fits the current text.
  var heightFittingText: CGFloat {
    return textHeight + textView.textContainerInset.top + textView.textContainerInset.bottom
  }

  /// Sets the alpha, constraints and insets for the send button style.
  func setSendButtonStyle(_ sendButtonStyle: SendButtonStyle, animated: Bool = false) {
    guard self.sendButtonStyle != sendButtonStyle else { return }

    self.sendButtonStyle = sendButtonStyle
    updateTextViewTextContainerInset()

    let duration: TimeInterval = animated ? 0.4 : 0
    UIView.animate(withDuration: duration, animations: {
      switch sendButtonStyle {
      case .toolbar:
        self.sendButtonView.alpha = 0
      case .button:
        self.sendButtonView.alpha = 1
      }
    })

    animateToolbarAndUpdateInsets(withDuration: 0.2)
  }

  /// The current text view text height.
  var textHeight: CGFloat {
    guard let textViewFont = textView.font else { return 0 }
    let textViewWidth = textView.bounds.size.width - textView.textContainerInset.left -
        textView.textContainerInset.right - textViewHorizontalBuffer * 2
    return textView.text.labelHeight(withConstrainedWidth: textViewWidth, font: textViewFont)
  }

  /// Adjusts the action bar to extend into the bottom safe area, when the keyboard is not up.
  func updateActionBarHeight() {
    sendButtonActionBarWrapperHeightConstraint?.constant =
        !textView.isFirstResponder ? safeAreaInsetsOrZero.bottom : 0
  }

  // MARK: - Private

  private func configureView() {
    // Text view.
    textView.alwaysBounceVertical = false
    textView.font = MDCTypography.fontLoader().regularFont(ofSize: 16)
    addSubview(textView)
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.pinToEdgesOfView(self)

    // Send button action bar.
    sendButtonActionBar.translatesAutoresizingMaskIntoConstraints = false
    sendButtonActionBar.setContentHuggingPriority(.defaultHigh, for: .vertical)
    sendButtonActionBarWrapper.addSubview(sendButtonActionBar)
    sendButtonActionBar.topAnchor.constraint(
        equalTo: sendButtonActionBarWrapper.topAnchor).isActive = true
    sendButtonActionBar.leadingAnchor.constraint(
        equalTo: sendButtonActionBarWrapper.leadingAnchor).isActive = true
    sendButtonActionBar.trailingAnchor.constraint(
        equalTo: sendButtonActionBarWrapper.trailingAnchor).isActive = true
    sendButtonActionBar.button.accessibilityLabel = String.addTextNoteContentDescription

    sendButtonActionBarWrapper.backgroundColor = DrawerView.actionBarBackgroundColor
    sendButtonActionBarWrapper.translatesAutoresizingMaskIntoConstraints = false
    addSubview(sendButtonActionBarWrapper)
    sendButtonActionBarWrapper.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    sendButtonActionBarWrapper.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    sendButtonActionBarWrapperBottomConstraint =
        sendButtonActionBarWrapper.bottomAnchor.constraint(equalTo: bottomAnchor)
    sendButtonActionBarWrapperBottomConstraint?.isActive = true
    sendButtonActionBarWrapperHeightConstraint = sendButtonActionBarWrapper.heightAnchor.constraint(
        equalTo: sendButtonActionBar.heightAnchor)
    sendButtonActionBarWrapperHeightConstraint?.isActive = true

    // Send button view.
    addSubview(sendButtonView)
    sendButtonView.translatesAutoresizingMaskIntoConstraints = false
    sendButtonView.bottomAnchor.constraint(equalTo: topAnchor,
                                           constant: sendButtonViewTopInset).isActive = true
    sendButtonViewTrailingConstraint = sendButtonView.trailingAnchor.constraint(
        equalTo: trailingAnchor, constant: -sendButtonViewHorizontalInset)
    sendButtonViewTrailingConstraint?.isActive = true

    // Placeholder label.
    placeholderLabel.font = textView.font
    placeholderLabel.numberOfLines = 0
    placeholderLabel.text = String.textLabelHint
    placeholderLabel.textColor = .lightGray
    textView.addSubview(placeholderLabel)
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    placeholderLabelTopConstraint =
        placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor)
    placeholderLabelTopConstraint?.isActive = true
    placeholderLabelLeadingConstraint =
        placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
    placeholderLabelLeadingConstraint?.isActive = true
    placeholderLabelTrailingConstraint =
        placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
    placeholderLabelTrailingConstraint?.isActive = true

    updateTextViewTextContainerInset()
  }

  private func registerForNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillShow,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillHide,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: .keyboardObserverWillChangeFrame,
                                           object: nil)
  }

  // Animates the toolbar and updates the text view insets for the current keyboard height and send
  // button style.
  private func animateToolbarAndUpdateInsets(withDuration duration: TimeInterval,
                                             options: UIView.AnimationOptions = []) {
    let convertedKeyboardFrame = convert(KeyboardObserver.shared.currentKeyboardFrame, from: nil)
    let keyboardOffset = KeyboardObserver.shared.isKeyboardVisible ?
        bounds.intersection(convertedKeyboardFrame).height : 0

    var sendButtonActionBarBottomConstraintConstant: CGFloat
    switch sendButtonStyle {
    case .toolbar:
      sendButtonActionBar.isHidden = false
      textView.contentInset.bottom = keyboardOffset +
          sendButtonActionBar.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      sendButtonActionBarBottomConstraintConstant = -keyboardOffset
    case .button:
      textView.contentInset.bottom = keyboardOffset
      sendButtonActionBarBottomConstraintConstant = -keyboardOffset +
          sendButtonActionBar.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    textView.scrollIndicatorInsets = textView.contentInset

    UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
      self.sendButtonActionBarWrapperBottomConstraint?.constant =
          sendButtonActionBarBottomConstraintConstant
      self.layoutIfNeeded()
    }) { (_) in
      if self.sendButtonStyle == .button {
        self.sendButtonActionBar.isHidden = true
      }
    }
  }

  private func updateTextViewTextContainerInset() {
    var textInset = textViewTextContainerInset

    var textViewHorizontalInset: CGFloat {
      switch sendButtonStyle {
      case .button:
        return sendButtonViewHorizontalInset * 2 +
            sendButtonView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
      case .toolbar:
        return NotesView.textContainerHorizontalInset
      }
    }
    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
      textInset.left = textViewHorizontalInset + safeAreaInsetsOrZero.left
    } else {
      textInset.right = textViewHorizontalInset + safeAreaInsetsOrZero.right
    }

    textView.textContainerInset = textInset

    placeholderLabelTopConstraint?.constant = textView.textContainerInset.top
    placeholderLabelLeadingConstraint?.constant = textView.textContainerInset.left +
        textViewHorizontalBuffer
    placeholderLabelTrailingConstraint?.constant = -textView.textContainerInset.right -
        textViewHorizontalBuffer
  }

  // MARK: - Notifications

  @objc func handleKeyboardNotification(_ notification: Notification) {
    guard let duration = KeyboardObserver.animationDuration(fromKeyboardNotification: notification),
      let animationCurve =
          KeyboardObserver.animationCurve(fromKeyboardNotification: notification) else { return }
    animateToolbarAndUpdateInsets(withDuration: duration, options: [animationCurve])
  }

}
