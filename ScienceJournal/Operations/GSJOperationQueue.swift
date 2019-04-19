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

public protocol OperationQueueDelegate: class {
  /// Informs the delegate when an operation will be added to the queue.
  ///
  /// - Parameters:
  ///   - queue: The queue the operation was on.
  ///   - operation: The operation that will be added.
  func operationQueue(_ queue: GSJOperationQueue, willAddOperation operation: Operation)

  /// Informs the delegate when an operation finished.
  ///
  /// - Parameters:
  ///   - queue: The queue the operation was on.
  ///   - operation: The operation that finished.
  ///   - errors: Any errors the operation finished with.
  func operationQueue(_ queue: GSJOperationQueue,
                      operationDidFinish operation: Operation,
                      withErrors errors: [Error])
}

/// A subclass of OperationQueue with additional support for the features added by `GSJOperation`.
/// This queue must be used when working with `GSJOperation` subclasses.
open class GSJOperationQueue: OperationQueue {

  /// If the queue is terminated it is permanently stopped and won't accept adding new operations.
  private var isTerminated = false

  /// A delegate which will be notified when operations are added and finish. This is an alternate
  /// way of observing operations if an observer isn't a good fit.
  weak var delegate: OperationQueueDelegate?

  open override func addOperation(_ op: Operation) {
    guard !isTerminated else {
      return
    }

    // If the operation is a `GSJOperation`, add support for conditions and spawned operations.
    if let gsjOp = op as? GSJOperation {
      // Add an observer to every operation to watch for spawned operations.
      let spawnObserver = BlockObserver(
        spawnHandler: { [weak self] (_, spawnedOperation) in
          self?.addOperation(spawnedOperation)
        },
        finishHandler: { [weak self] (operation, errors) in
          guard let strongSelf = self else { return }
          strongSelf.delegate?.operationQueue(strongSelf,
                                              operationDidFinish: operation, withErrors: errors)
        }
      )
      gsjOp.addObserver(spawnObserver)

      // If any conditions have dependencies, add them as dependencies to this operation.
      for condition in gsjOp.conditions {
        guard let dependency = condition.dependencyForOperation(gsjOp) else {
          continue
        }
        gsjOp.addDependency(dependency)
        addOperation(dependency)
      }

      let concurrencyCategories = gsjOp.conditions.compactMap { $0.exclusivityKey }
      if !concurrencyCategories.isEmpty {
        let exclusivityController = ExclusivityController.shared
        exclusivityController.addOperation(gsjOp, categories: concurrencyCategories)
        gsjOp.addObserver(BlockObserver { operation, _ in
          exclusivityController.removeOperation(operation, categories: concurrencyCategories)
        })
      }

      // Inform the operation it is being enqueued. This is a required step for the operation to
      // enter the ready state.
      gsjOp.willEnqueue()
    } else {
      // If it's a plain Operation, use the completion block to call the delegate when it's
      // finished.
      let delegateBlock: () -> Void = { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.delegate?.operationQueue(strongSelf, operationDidFinish: op, withErrors: [])
      }

      // If a completion block is already set, add to it.
      if let existingCompletion = op.completionBlock {
        op.completionBlock = {
          existingCompletion()
          delegateBlock()
        }
      } else {
        op.completionBlock = delegateBlock
      }
    }

    delegate?.operationQueue(self, willAddOperation: op)
    super.addOperation(op)
  }

  open override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
    // The base implementation does not call `addOperation` so we need to re-implement it.
    ops.forEach { addOperation($0) }

    if wait {
      ops.forEach { $0.waitUntilFinished() }
    }
  }

  /// Permanently stops the queue, cancelling all existing operations and preventing new operations
  /// from being added.
  public func terminate() {
    isTerminated = true
    isSuspended = true
    cancelAllOperations()
  }

}
