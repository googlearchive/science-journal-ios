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

/// Represents one point of sensor data.
struct DataPoint {

  typealias Millis = Int64

  var x: Millis
  var y: Double

  /// Returns a `DataPoint` initialized with the given x and y values.
  ///
  /// - Parameters:
  ///   - x: The x value to include in the data point.
  ///   - y: The y value to include in the data point.
  init(x: Millis, y: Double) {
    self.x = x
    self.y = y
  }

}
