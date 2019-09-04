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

/// A type-erased wrapper for reading from and observing a `Bool` property of an arbitrary
/// `NSObject` subclass, specified by its `KeyPath`.
final class ActionEnabler {

  /// The signature of the block to be called when the value of the enabling property changes.
  typealias ChangeHandler = (_ isEnabled: Bool) -> Void

  /// The current value of the enabling property.
  var isEnabled: Bool {
    return _isEnabled()
  }

  /// Observe the enabling property. An initial value is *not* sent to the observer.
  ///
  /// - Parameters:
  ///   - didChange: The block to call when the enabling property changes.
  ///
  /// - SeeAlso: `isEnabled`
  /// - Precondition: The enabling property must be declared `@objc` and `dynamic`.
  func observe(_ didChange: @escaping ChangeHandler) {
    observation = _observe(didChange)
  }

  /// Stop observing the enabling property.
  func unobserve() {
    observation?.invalidate()
  }

  private let _isEnabled: () -> Bool
  private let _observe: (@escaping ChangeHandler) -> NSKeyValueObservation
  private var observation: NSKeyValueObservation?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - target: The object that provides the enabling property.
  ///   - keyPath: The `KeyPath` of the enabling property.
  init<T: NSObject>(target: T, keyPath: KeyPath<T, Bool>) {
    self._isEnabled = {
      target[keyPath: keyPath]
    }

    self._observe = { didChange in
      target.observe(keyPath, options: [.new]) { _, change in
        change.newValue.map(didChange)
      }
    }
  }
}
