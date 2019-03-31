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

/// A shared exclusivity controller that ensures mutually exclusive operations do not
/// execute concurrently.
public class ExclusivityController {

  /// The exclusivity controller shared intance.
  static let shared = ExclusivityController()

  private let serialQueue = DispatchQueue(label: "com.google.ScienceJournal.ExclusivityController")
  private var operations = [String: [GSJOperation]]()

  // Prevent creating multiple instances of this class.
  private init() {}

  /// Adds an operation to the exclusivity controller. If an operation with the same category
  /// is known, it will become a depdendency of the operation.
  ///
  /// - Parameters:
  ///   - operation: The operation to add.
  ///   - categories: The exclusivity categories the operation belongs to.
  func addOperation(_ operation: GSJOperation, categories: [String]) {
    serialQueue.sync {
      for category in categories {
        var categoryOperations = operations[category] ?? []
        if let last = categoryOperations.last {
          operation.addDependency(last)
        }
        categoryOperations.append(operation)
        operations[category] = categoryOperations
      }
    }
  }

  /// Removes an operation from the exclusivity controller.
  ///
  /// - Parameters:
  ///   - operation: The operation to remove.
  ///   - categories: The exclusivity categories the operation belongs to.
  func removeOperation(_ operation: GSJOperation, categories: [String]) {
    serialQueue.sync {
      for category in categories {
        if var categoryOperations = operations[category],
            let index = categoryOperations.firstIndex(of: operation) {
          categoryOperations.remove(at: index)
          operations[category] = categoryOperations
        }
      }
    }
  }

}

// MARK: - Testing-only Methods

extension ExclusivityController {
  /// Unit tests can create scenarios that are otherwise impossible during the normal operation
  /// of the app. This includes operations with exclusivity being added but not removed. For this
  /// reason it is necessary to create a method to reset the exclusivity operations.
  /// WARNING: Do not use outside of unit tests.
  func resetForUnitTesting() {
    operations.removeAll()
  }
}
