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

import Foundation

/// The `LaunchManager` defines and executes the operations that
/// must occurr at launch before the user can begin interacting
/// with the app. These should be quick operations that are not
/// user or Experiment specific.
final class LaunchManager {

  /// The launch states
  enum State {
    /// Launch operations are still executing
    case launching

    /// Launch operations are complete
    case running
  }

  /// The standard `LaunchManager` configuration
  static let standard = LaunchManager()

  /// The current launch state.
  private(set) var state: State {
    get {
      return propertyQueue.sync { _state }
    }
    set {
      propertyQueue.sync(flags: .barrier) {
        _state = newValue
      }
    }
  }

  private let operationQueue = GSJOperationQueue()
  private var _state: State = .launching
  private let propertyQueue = DispatchQueue(
    label: "com.google.ScienceJournal.LaunchManager",
    attributes: .concurrent
  )

  /// Perform the launch operations.
  ///
  /// - Parameters:
  ///   - completion: A block that is called when the launch operations are complete.
  func performLaunchOperations(completion: @escaping () -> Void) {
    operationQueue.addOperation(GSJBlockOperation(mainQueueBlock: { finish in
      self.state = .running
      completion()
      finish()
    }))
  }

}
