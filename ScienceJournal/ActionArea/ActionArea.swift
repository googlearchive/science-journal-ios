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

/// Top-level namespace for Action Area types.
enum ActionArea {

  /// The mode for content view controllers displayed in the Action Area.
  enum ContentMode {

    /// The states used in the `stateful` mode.
    typealias State = (

      /// The primary action that toggles to the other state.
      primary: BarButtonItem,

      /// The items to display in this state.
      items: [BarButtonItem]

    )

    /// The `stateless` mode displays the same actions at all times.
    ///
    /// - Parameters:
    ///   - items: The items to display in the `ActionArea.Bar`.
    case stateless(items: [BarButtonItem])

    /// The `stateful` mode toggles between two sets of actions when the primary action is taken.
    /// In the `nonModal` state, the Action Area behaves the same as when in the `stateless` mode.
    /// In the `modal` state, the Action Area hides close and back buttons, and attempting to
    /// present or dismiss content view controllers is an error.
    ///
    /// - Parameters:
    ///   - nonModal: The primary action and action items for the `nonModal` state.
    ///   - modal: The primary action and action items for the `modal` state.
    case stateful(nonModal: State, modal: State)

  }

  /// The requirements for all Action Area content.
  typealias Content = UIViewController & _ActionAreaContent

  /// The requirements for master content displayed displayed in the Action Area.
  typealias MasterContent = _ActionAreaMasterContent

  /// The requirements for detail content displayed displayed in the Action Area.
  typealias DetailContent = _ActionAreaDetailContent

}

// Swift does not support nested protocol defintions. Defining our protocols here and creating
// typealiases under the top-level namespace allows us to have consistent type names.

protocol _ActionAreaContent {

  /// The `mode` for this content.
  var mode: ActionArea.ContentMode { get }

}

protocol _ActionAreaMasterContent: ActionArea.Content {

  /// The `emptyState` to display in the detail area when this master content is displayed.
  var emptyState: UIViewController { get }

}

protocol _ActionAreaDetailContent: ActionArea.Content {
}
