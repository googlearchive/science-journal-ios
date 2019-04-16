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

/// A condition that prevents operations with the same category from running concurrently. The
/// exclusivity key is composed of both the primary and sub category. The sub category is a
/// convenience for easily differentiating operations. For example if an operation was only mutually
/// exclusive if two instances had the same ID you could pass the name of the operation for the
/// primaryCategory and the ID as the sub category.
public struct MutuallyExclusive: OperationCondition {

  public var exclusivityKey: String? {
    return primaryCategory + (subCategory ?? "")
  }

  private let primaryCategory: String
  private let subCategory: String?

  private static let modalUIKey = "ModalUI"

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - primaryCategory: The primary category.
  ///   - subCategory: A sub category.
  public init(primaryCategory: String, subCategory: String? = nil) {
    self.primaryCategory = primaryCategory
    self.subCategory = subCategory
  }

  public func dependencyForOperation(_ operation: GSJOperation) -> Operation? {
    return nil
  }

  public func evaluateForOperation(_ operation: GSJOperation,
                                   completion: (OperationConditionResult) -> Void) {
    completion(.passed)
  }

  /// A mutually exclusive operation condition for modal UI.
  static var modalUI: MutuallyExclusive {
    return MutuallyExclusive(primaryCategory: modalUIKey)
  }

}
