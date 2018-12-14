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

/// An enum for the possible outcomes of an operation condition.
///
/// - passed: The condition was satisfied.
/// - failed: The condition failed.
public enum OperationConditionResult {
  case passed
  case failed(Error)

  /// An error corresponding to a condition failure state.
  var error: Error? {
    if case .failed(let error) = self {
      return error
    }
    return nil
  }
}

/// Errors associated with the execution of an operation.
///
/// - conditionFailed: A condition failed.
/// - executionFailed: The execution failed.
enum OperationError: Error {
  case conditionFailed
  case executionFailed
}

/// Objects conforming to this protocol can evaluate conditions determining whether an operation
/// can execute or not.
public protocol OperationCondition {
  /// A string key used to enforce mutual exclusivity, if necessary.
  var exclusivityKey: String? { get }

  /// A dependency required by the condition. This should be an operation to attempts to make the
  /// condition pass, such as requesting permission.
  ///
  /// - Parameter operation: The operation the condition is applied to.
  /// - Returns: A new operattion.
  func dependencyForOperation(_ operation: GSJOperation) -> Operation?


  /// A method called to evaluate the condition. The method will call the completion with either
  /// passed or failed.
  ///
  /// - Parameters:
  ///   - operation: The operation the condition is applied to.
  ///   - completion: A completion called after the condition has been evaluated.
  func evaluateForOperation(_ operation: GSJOperation,
                            completion: (OperationConditionResult) -> Void)
}

struct OperationConditionEvaluator {
  /// Evaluates conditions for an operation.
  ///
  /// - Parameters:
  ///   - conditions: An array of conditions.
  ///   - operation: The operation to evaluate against.
  ///   - completion: A closure called when the evaluation finished with an array of errors.
  static func evaluate(conditions: [OperationCondition],
                       forOperation operation: GSJOperation,
                       completion: @escaping (([Error]) -> Void)) {
    guard conditions.count > 0 else {
      completion([])
      return
    }

    // Use a dispatch group to evaluate the conditions concurrently.
    let group = DispatchGroup()

    // Define an array the size of the condition count in order to keep the errors in the same
    // order as the conditions.
    var results = [OperationConditionResult?](repeating: nil, count: conditions.count)

    for (index, condition) in conditions.enumerated() {
      group.enter()
      condition.evaluateForOperation(operation, completion: { (result) in
        results[index] = result
        group.leave()
      })
    }

    // Once all conditions are finished, call the completion.
    group.notify(queue: .global()) {
      let failures = results.compactMap { $0?.error }
      completion(failures)
    }
  }
}
