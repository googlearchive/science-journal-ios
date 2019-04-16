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

extension Notification.Name {

  /// Notification posted when the keyboard observer has received the UIKeyboardWillChangeFrame
  /// notification, and has updated. Passes along the user info from the original UI keyboard
  /// notification.
  static let keyboardObserverWillChangeFrame =
      NSNotification.Name("KeyboardObserverKeyboardWillChangeFrame")

  /// Notification posted when the keyboard observer has received the UIKeyboardWillHide
  /// notification, and has updated. Passes along the user info from the original UI keyboard
  /// notification.
  static let keyboardObserverWillHide = NSNotification.Name("KeyboardObserverKeyboardWillHide")

  /// Notification posted when the keyboard observer has received the UIKeyboardWillShow
  /// notification, and has updated. Passes along the user info from the original UI keyboard
  /// notification.
  static let keyboardObserverWillShow = NSNotification.Name("KeyboardObserverKeyboardWillShow")

  /// Notification posted when the keyboard observer has received the UIKeyboardDidShow
  /// notification, and has updated. Passes along the user info from the original UI keyboard
  /// notification.
  static let keyboardObserverDidShow = NSNotification.Name("KeyboardObserverKeyboardDidShow")

}

/// Observes UI keyboard notifications, stores the current keyboard frame and parses animation
/// duration and curve.
class KeyboardObserver {

  // MARK: - Properties

  /// Keyboard observer singleton.
  static let shared = KeyboardObserver()

  /// The current keyboard frame.
  var currentKeyboardFrame = CGRect.zero

  /// Whether or not the keyboard is visible.
  var isKeyboardVisible = false

  // MARK: - Public

  /// Use `shared`.
  private init() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardWillShowNotification(_:)),
        name: UIResponder.keyboardWillShowNotification,
        object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardDidShowNotification(_:)),
        name: UIResponder.keyboardDidShowNotification,
        object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardWillChangeFrameNotification(_:)),
        name: UIResponder.keyboardWillChangeFrameNotification,
        object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardWillHideNotification(_:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil)
  }

  /// Returns animation curve stored in the user info of a UI keyboard or keyboard observer
  /// notification.
  ///
  /// - Parameter notification: A UI keyboard or keyboard observer notification.
  /// - Returns: The keyboard animation curve.
  static func animationCurve(fromKeyboardNotification notification: Notification) ->
      UIView.AnimationOptions? {
    guard let userInfo = notification.userInfo, let animationCurveWrapped =
        userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else {
      return nil
    }
    return UIView.AnimationOptions(rawValue: animationCurveWrapped.uintValue)
  }

  /// Returns the animation duration stored in the user info of a UIkeyboard or keyboard observer
  /// notification.
  ///
  /// - Parameter notification: A UI keyboard or keyboard observer notification.
  /// - Returns: The keyboard animation duration.
  static func animationDuration(fromKeyboardNotification notification: Notification) -> Double? {
    guard let userInfo = notification.userInfo, let durationWrapped =
        userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
      return nil
    }
    return durationWrapped.doubleValue
  }

  // MARK: - Private

  private func handleKeyboardNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo, let frameWrapped =
        userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    currentKeyboardFrame = frameWrapped.cgRectValue
  }

  // MARK: - Notifications

  @objc private func handleKeyboardWillChangeFrameNotification(_ notification: Notification) {
    handleKeyboardNotification(notification)
    isKeyboardVisible = UIScreen.main.bounds.intersection(currentKeyboardFrame).height > 0
    NotificationCenter.default.post(name: .keyboardObserverWillChangeFrame,
                                    object: nil,
                                    userInfo: notification.userInfo)
  }

  @objc private func handleKeyboardWillHideNotification(_ notification: Notification) {
    handleKeyboardNotification(notification)
    isKeyboardVisible = false
    NotificationCenter.default.post(name: .keyboardObserverWillHide,
                                    object: nil,
                                    userInfo: notification.userInfo)
  }

  @objc private func handleKeyboardWillShowNotification(_ notification: Notification) {
    handleKeyboardNotification(notification)
    isKeyboardVisible = true
    NotificationCenter.default.post(name: .keyboardObserverWillShow,
                                    object: nil,
                                    userInfo: notification.userInfo)
  }

  @objc private func handleKeyboardDidShowNotification(_ notification: Notification) {
    handleKeyboardNotification(notification)
    isKeyboardVisible = true
    NotificationCenter.default.post(name: .keyboardObserverDidShow,
                                    object: nil,
                                    userInfo: notification.userInfo)
  }

}
