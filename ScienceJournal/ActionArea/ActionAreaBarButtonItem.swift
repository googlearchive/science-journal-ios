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

/// The delegate protocol for `ActionArea.BarButtonItem`s.
protocol ActionAreaBarButtonItemDelegate: class {

  /// The action is about to be executed.
  ///
  /// - Parameters:
  ///   - item: The item that owns the action about to be executed.
  func barButtonItemWillExecuteAction(_ item: ActionArea.BarButtonItem)

  /// The action was executed.
  ///
  /// - Parameters:
  ///   - item: The item that owns the action that was executed.
  func barButtonItemDidExecuteAction(_ item: ActionArea.BarButtonItem)

}

extension ActionArea {

  /// An item to be displayed in the Action Area.
  final class BarButtonItem: NSObject {

    weak var delegate: ActionAreaBarButtonItemDelegate?

    private(set) var title: String
    private(set) var image: UIImage?
    private(set) var action: () -> Void // TODO: Consider passing the AA controller here.

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - title: The title for the item.
    ///   - accessibilityHint: The accessibility hint for the item.
    ///   - image: The image for the item.
    ///   - action: A block to execute when the item is tapped.
    init(title: String, accessibilityHint: String?, image: UIImage?, action: @escaping () -> Void) {
      self.title = title
      self.image = image
      self.action = action
      super.init()
      self.accessibilityHint = accessibilityHint
    }

    @objc func execute() {
      delegate?.barButtonItemWillExecuteAction(self)
      action()
      delegate?.barButtonItemDidExecuteAction(self)
    }

  }

}
