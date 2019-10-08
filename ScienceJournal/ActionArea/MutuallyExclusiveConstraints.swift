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

import SnapKit
import UIKit

/// Mutually exclusive Auto Layout constraints.
struct MutuallyExclusiveConstraints<Key: Hashable> {

  private let constraints: [Key: [NSLayoutConstraint]]

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - constraints: A dictionary containing one entry for each set of constraints.
  init(constraints: [Key: [NSLayoutConstraint]]) {
    self.constraints = constraints
  }

  /// Activate the specified constraints after deactivating all other constraints.
  ///
  /// - Parameters:
  ///   - key: The key for the constraints to activate.
  func activate(_ key: Key) {
    guard let toActivate = constraints[key] else {
      preconditionFailure("No constraints for key: \(key)")
    }

    deactivateAll()
    NSLayoutConstraint.activate(toActivate)
  }

  /// Deactivate all constraints.
  func deactivateAll() {
    constraints.values.forEach(NSLayoutConstraint.deactivate)
  }

}

// MARK: - SnapKit Extensions

extension MutuallyExclusiveConstraints {

  /// Convenience initializer for converting SnapKit constraints to native constraints.
  ///
  /// - Parameters:
  ///   - constraints: The constraints to convert.
  init(constraints: [Key: [Constraint]]) {
    self.constraints = constraints.mapValues { $0.flatMap { $0.layoutConstraints } }
  }

  /// Convenience initializer to build constraints.
  ///
  /// - Parameters:
  ///   - build: The block to execute to build the constraints.
  init(build: (inout [Key: [Constraint]]) -> Void) {
    var constraints: [Key: [Constraint]] = [:]
    build(&constraints)
    self.init(constraints: constraints)
  }

}
