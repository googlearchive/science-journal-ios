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

/// A group operation is a way of grouping dependent operations into a single operation.
open class GroupOperation: GSJOperation {

  // MARK: - Properties

  private let internalQueue = GSJOperationQueue()
  private let startingOperation = BlockOperation(block: {})
  private let finishingOperation = BlockOperation(block: {})

  /// A lock to guard reading and writing the `_groupErrors` property.
  private let groupErrorsLock = NSLock()

  /// The array that backs the `groupErrors` property.
  private var _groupErrors = [Error]()

  /// Each member operation's errors will aggregate in this array.
  private var groupErrors: [Error] {
    get {
      groupErrorsLock.lock()
      let returnValue = _groupErrors
      groupErrorsLock.unlock()
      return returnValue
    }
    set {
      groupErrorsLock.lock()
      _groupErrors = newValue
      groupErrorsLock.unlock()
    }
  }

  /// The max concurrent operations of the internal queue.
  public var maxConcurrentOperationCount: Int {
    get {
      return internalQueue.maxConcurrentOperationCount
    }
    set {
      internalQueue.maxConcurrentOperationCount = newValue
    }
  }

  // MARK: - Public

  /// Designated initializer. Dependencies should be established prior to calling this initializer.
  ///
  /// - Parameter operations: An array of options.
  public init(operations: [Operation]) {
    super.init()

    // Suspend the queue initially so we control its execution.
    internalQueue.isSuspended = true
    internalQueue.delegate = self

    // All added operations will be dependent on the starting operation. This operation gives us
    // control over exactly when the other operations begin.
    internalQueue.addOperation(startingOperation)

    operations.forEach { internalQueue.addOperation($0) }
  }

  open override func cancel() {
    internalQueue.cancelAllOperations()
    super.cancel()
  }

  override public func cancelWithError(_ error: Error) {
    internalQueue.cancelAllOperations()
    super.cancelWithError(error)
  }

  /// Subclasses can override this method to configure operations before group is executed. This
  /// allows configuration based on runtime conditions and dependencies that isn't possible during
  /// initialization.
  open func configureOperationsBeforeExecution() {}

  open override func execute() {
    configureOperationsBeforeExecution()
    internalQueue.isSuspended = false
    // The group operation cannot finish without the finishing operation.
    internalQueue.addOperation(finishingOperation)
  }

  /// Adds an operation to the group operation.
  ///
  /// - Parameter operation: An operation.
  public func addOperation(_ operation: Operation) {
    assert(!isFinished, "Cannot add operations after the group has finished.")
    internalQueue.addOperation(operation)
  }

  /// Adds an array of operations to the group operation.
  ///
  /// - Parameter operations: An array of operations.
  public func addOperations(_ operations: [Operation]) {
    assert(!isFinished, "Cannot add operations after the group has finished.")
    internalQueue.addOperations(operations, waitUntilFinished: false)
  }

  /// Adds an error to the aggregated group errors.
  ///
  /// - Parameter error: An error.
  override func addError(_ error: Error) {
    addErrors([error])
  }

  /// Adds the errors to the aggregated group errors.
  ///
  /// - Parameter errors: An array of errors.
  override func addErrors(_ errors: [Error]) {
    groupErrorsLock.lock()
    _groupErrors.append(contentsOf: errors)
    groupErrorsLock.unlock()
  }

  /// This method can be overridden by subclasses that need a hook when operations finish.
  ///
  /// - Parameters:
  ///   - operation: The finished operation.
  ///   - errors: An array of errors the operation finished with.
  func operationDidFinish(_ operation: Operation, withErrors errors: [Error]) {}

}

extension GroupOperation: OperationQueueDelegate {
  public func operationQueue(_ queue: GSJOperationQueue, willAddOperation operation: Operation) {
    assert(!finishingOperation.isFinished && !finishingOperation.isExecuting,
           "Cannot add operations to a group after the group has completed.")

    // The finishing operation can't execute until all other operations are finished. This includes
    // any operations spawned by the initial operations.
    if operation !== finishingOperation {
      finishingOperation.addDependency(operation)
    }

    // All operations are dependent on `startingOperation`. This ensures that no operations or
    // condition evaluations occur before the group operation is executing.
    if operation !== startingOperation {
      operation.addDependency(startingOperation)
    }
  }

  public func operationQueue(_ queue: GSJOperationQueue,
                             operationDidFinish operation: Operation,
                             withErrors errors: [Error]) {
    addErrors(errors)

    if operation === finishingOperation {
      // The group of operations has completed.
      internalQueue.isSuspended = true
      finish(withErrors: groupErrors)
    } else if operation !== startingOperation {
      // Notify finished operations for interested subclasses.
      operationDidFinish(operation, withErrors: errors)
    }
  }
}
