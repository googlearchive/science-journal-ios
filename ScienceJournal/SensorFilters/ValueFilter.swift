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

/// Protocol for taking a scalar value, and producing an altered value. Can be used to do simple
/// frequency extraction, or re-scale units.
protocol ValueFilter {
  /// Returns a new value given a value and timestamp.
  ///
  /// - Parameters:
  ///   - timestamp: A timestamp.
  ///   - value: A value.
  /// - Returns: A transformed value.
  func filterValue(timestamp: Int64, value: Double) -> Double
}

/// A base version of a value filter that does not transform the value.
class IdentityFilter: ValueFilter {
  func filterValue(timestamp: Int64, value: Double) -> Double  {
    return value
  }
}
