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

import Foundation

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Snackbar_Snackbar

/// Displays a snackbar with a button to undo an action. This is displayed for destructive actions
/// to give the user a moment to undo that action. The undo block should encapsulate the
/// functionality to reverse the destructive action.
///
/// - Parameters:
///   - messageText: A message describing the action that was performed.
///   - category: The category of messages to which a message belongs.
///   - undoBlock: A block that will be called if the user taps undo.
///   - completion: A block that will be called when the snackbar is finished displaying.
func showUndoSnackbar(withMessage messageText: String,
                      category: String? = nil,
                      undoBlock: @escaping () -> Void,
                      completion: ((Bool) -> Void)? = nil) {
  showSnackbar(withMessage: messageText,
               category: category,
               actionTitle: String.actionUndo.uppercased(),
               actionHandler: undoBlock,
               completion: completion)
}

/// Displays a snackbar with message text and a button to perform an action.
///
/// - Parameters:
///   - messageText: A message.
///   - category: The category of messages to which a message belongs.
///   - actionTitle: The title for the action button.
///   - actionHandler: The handler that will be called if the user taps the action button.
///   - completion: A block that will be called when the snackbar is finished displaying.
func showSnackbar(withMessage messageText: String,
                  category: String? = nil,
                  actionTitle: String? = nil,
                  actionHandler: (() -> Void)? = nil,
                  completion: ((Bool) -> Void)? = nil) {
  let message = MDCSnackbarMessage()
  message.text = messageText
  message.category = category
  message.completionHandler = completion

  let action = MDCSnackbarMessageAction()
  action.handler = actionHandler
  action.title = actionTitle
  message.action = action

  DispatchQueue.main.async {
    MDCSnackbarManager.setButtonTitleColor(MDCPalette.yellow.tint200, for: .normal)
    MDCSnackbarManager.show(message)
  }
}
