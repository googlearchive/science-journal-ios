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

/// An operation observer that runs arbitrary blocks of code at the various observation points.
public struct BlockObserver {
  /// A closure with a parameter for the operation that started.
  let startHandler: ((GSJOperation) -> Void)?
  /// A closure with parameters for an operation and the operation it spawned.
  let spawnHandler: ((GSJOperation, Operation) -> Void)?
  /// A closure with a parameter for the operation that finished.
  let finishHandler: ((GSJOperation, [Error]) -> Void)?

  /// Designated initializer with optional parameters.
  ///
  /// - Parameters:
  ///   - startHandler: The start handler.
  ///   - spawnHandler: The spawn handler.
  ///   - finishHandler: The finish handler.
  public init(startHandler: ((GSJOperation) -> Void)? = nil,
              spawnHandler: ((GSJOperation, Operation) -> Void)? = nil,
              finishHandler: ((GSJOperation, [Error]) -> Void)? = nil) {
    self.startHandler = startHandler
    self.spawnHandler = spawnHandler
    self.finishHandler = finishHandler
  }
}

extension BlockObserver: OperationObserver {
  public func operationDidStart(_ operation: GSJOperation) {
    startHandler?(operation)
  }

  public func operation(_ operation: GSJOperation, didSpawnOperation newOperation: Operation) {
    spawnHandler?(operation, newOperation)
  }

  public func operationDidFinish(_ operation: GSJOperation, withErrors errors: [Error]) {
    finishHandler?(operation, errors)
  }
}
