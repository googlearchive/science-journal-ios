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

extension ActionArea {

  /// A container for master content view controllers in the Action Area.
  final class MasterContentContainerViewController: ContentContainerViewController, MasterContent {

    /// The empty state to display in the detail area for this content.
    let emptyState: EmptyState

    /// The mode for this content.
    let mode: ContentMode

    var actionEnabler: ActionEnabler?

    // TODO: Remove when `childForStatusBarStyle` works.
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    // MARK: - Initializers

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - content: The content view controller.
    ///   - emptyState: The empty state to display in the detail area for this content.
    ///   - keyPath: The `KeyPath` of the property to use to disable actions.
    ///   - mode: The mode for this content.
    init<T: UIViewController>(
      content: T,
      emptyState: UIViewController,
      keyPath: KeyPath<T, Bool>? = nil,
      mode: ContentMode
    ) {
      self.emptyState = EmptyStateContainerViewController(emptyState: emptyState)
      self.actionEnabler = keyPath.map { ActionEnabler(target: content, keyPath: $0) }
      self.mode = mode
      super.init(content: content)
    }

    /// Convenience initializer.
    ///
    /// - Parameters:
    ///   - content: The content view controller.
    ///   - emptyState: The empty state to display in the detail area for this content.
    ///   - keyPath: The `KeyPath` of the property to use to disable actions.
    ///   - mode: A block that returns the mode for this content.
    convenience init<T: UIViewController>(
      content: T,
      emptyState: UIViewController,
      keyPath: KeyPath<T, Bool>? = nil,
      mode: () -> ContentMode
    ) {
      self.init(content: content, emptyState: emptyState, keyPath: keyPath, mode: mode())
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    // MARK: - Implementation

    override var description: String {
      return "ActionArea.MasterContentContainerViewController(content: \(content))"
    }

  }

}
