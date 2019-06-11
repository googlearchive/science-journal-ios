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

  /// The launch states.
  enum State: Equatable {

    /// Launch operations are still executing.
    case launching

    /// Launch completed.
    case completed(CompletionState)

  }

  /// The launch completion states
  enum CompletionState: Equatable {

    /// Launch operations succeeded.
    case success

    /// Launch operations failed.
    case failure

  }

  /// The standard `LaunchManager` configuration.
  static let standard: LaunchManager = {
    let operations = [FileSystemLayoutMigrationOperation()]
    return LaunchManager(operations: operations)
  }()

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

  /// The operations that this `LaunchManager` instance will execute when
  /// `performLaunchOperations(completion:)` is called.
  let operations: [GSJOperation]

  private var _state: State = .launching
  private var errors: [Error] = []
  private let operationQueue: GSJOperationQueue
  private let propertyQueue = DispatchQueue(
    label: "com.google.ScienceJournal.LaunchManager",
    attributes: .concurrent
  )

  /// Designated Initializer.
  ///
  /// - Parameters:
  ///   - operations: The oprations to execute.
  ///   - operationQueue: The queue on which to execute the operations.
  init(operations: [GSJOperation] = [], queue operationQueue: GSJOperationQueue? = nil) {
    self.operations = operations
    self.operationQueue = operationQueue ?? GSJOperationQueue()
    self.operationQueue.maxConcurrentOperationCount = 1
    self.operationQueue.delegate = self
  }

  /// Perform the launch operations.
  ///
  /// The completion block will be called *before* the `state` property is updated to ensure
  /// any cleanup or final logic is executed before clients of this class see the state change.
  /// Code inside of the completion block should use the `CompletionState` value that is passed in.
  ///
  /// - Parameters:
  ///   - completion: A block that is called when the launch operations are complete.
  func performLaunchOperations(completion: @escaping (CompletionState) -> Void) {
    operationQueue.addOperations(operations, waitUntilFinished: false)
    operationQueue.addOperation(GSJBlockOperation(mainQueueBlock: { finish in
      let completionState: CompletionState = self.errors.isEmpty ? .success : .failure
      completion(completionState)
      self.state = .completed(completionState)
      finish()
    }))
  }

}

extension LaunchManager: OperationQueueDelegate {

  func operationQueue(_ queue: GSJOperationQueue, willAddOperation operation: Operation) {
  }

  func operationQueue(_ queue: GSJOperationQueue,
                      operationDidFinish operation: Operation,
                      withErrors errors: [Error]) {
    self.errors.append(contentsOf: errors)
  }

}
