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

/// A filter that applies two filters in order.
class ComposeFilter: ValueFilter {

  private let firstFilter: ValueFilter
  private let secondFilter: ValueFilter

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - firstFilter: The first filter to apply
  ///   - secondFilter: The second filter to apply.
  init(firstFilter: ValueFilter, secondFilter: ValueFilter) {
    self.firstFilter = firstFilter
    self.secondFilter = secondFilter
  }

  func filterValue(timestamp: Int64, value: Double) -> Double {
    let firstValue = firstFilter.filterValue(timestamp: timestamp, value: value)
    return secondFilter.filterValue(timestamp: timestamp, value: firstValue)
  }

}
