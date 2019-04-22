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

/// A single action to display in a pop up menu.
class PopUpMenuAction {

  /// The action title.
  let title: String

  /// The action icon.
  let icon: UIImage?

  /// A label that identifies the accessibility element. If none has been set, this will be the
  /// title.
  var accessibilityLabel: String {
    return a11yLabel ?? title
  }

  /// A description of the result of performing an action on the element.
  let accessibilityHint: String?

  /// Is the action enabled?
  let isEnabled: Bool

  /// The action handler.
  let handler: ((PopUpMenuAction) -> Swift.Void)?

  private var a11yLabel: String?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - title: The action title.
  ///   - icon: The action icon.
  ///   - accessibilityLabel: A label that identifies the accessibility element.
  ///   - accessibilityHint: A description of the result of performing an action on the element.
  ///   - isEnabled: Is the action enabled?
  ///   - handler: The action handler.
  init(title: String,
       icon: UIImage? = nil,
       accessibilityLabel: String? = nil,
       accessibilityHint: String? = nil,
       isEnabled: Bool = true,
       handler: ((PopUpMenuAction) -> Swift.Void)? = nil) {
    self.title = title
    self.icon = icon
    self.a11yLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.isEnabled = isEnabled
    self.handler = handler
  }

}
