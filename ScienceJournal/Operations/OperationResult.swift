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

/// A class wrapper for a value that can be passed into multiple operations in order to easily share
/// the result of an operation. An operation result can be both a means of inputting and outputting
/// data.
public class OperationResult<T> {

  /// The value of the result, nil if it has not yet been populated.
  public var value: T?

  public init() {}

  /// A convenience initializer if the result value is already known.
  ///
  /// - Parameter value: A result value.
  public convenience init(value: T?) {
    self.init()
    self.value = value
  }

}
