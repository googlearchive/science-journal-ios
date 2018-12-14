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

/// The options for interacting with an experiment. This includes interactions with the experiment
/// as a whole as well in as detail views within an experiment.
struct ExperimentInteractionOptions: OptionSet {

  let rawValue: Int

  /// The experiment can be added to.
  static let canAdd = ExperimentInteractionOptions(rawValue: 1 << 0)

  /// The experiment can be edited.
  static let canEdit = ExperimentInteractionOptions(rawValue: 1 << 1)

  /// The experiment's items can be deleted.
  static let canDelete = ExperimentInteractionOptions(rawValue: 1 << 2)

  /// The experiment can be added to, edited and items can be deleted.
  static let normal: ExperimentInteractionOptions = [.canAdd, .canEdit, .canDelete]

  /// The experiment can be edited and items can be deleted, but it cannot be added to.
  static let archived: ExperimentInteractionOptions = [.canEdit, .canDelete]

  /// The experiment is in read-only state, but items can be deleted.
  static let readOnlyWithItemDelete: ExperimentInteractionOptions = [.canDelete]

  /// The experiment is in read-only state.
  static let readOnly: ExperimentInteractionOptions = []

  /// Whether the drawer should be shown.
  var shouldShowDrawer: Bool {
    return contains(.canAdd)
  }

  /// Whether edits can be made.
  var shouldAllowEdits: Bool {
    return contains(.canEdit)
  }

  /// Whether items can be deleted.
  var shouldAllowDeletes: Bool {
    return contains(.canDelete)
  }

  /// Whether the experiment's cover image should be removable.
  var shouldAllowCoverRemoval: Bool {
    return !contains(.canEdit) && contains(.canDelete)
  }

}
