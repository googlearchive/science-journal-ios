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

import CoreMotion

extension CMMagneticField {

  /// Sometimes we can get junk readings. The easiest way to check is to compare all axes
  /// to make sure their individual readings aren't extremely far apart.
  var isValid: Bool {
    // Axes can be negative.
    let xAxis = abs(x)
    let yAxis = abs(y)
    let zAxis = abs(z)

    let largestAxisValue = max(max(xAxis, yAxis), zAxis)
    let smallestAxisValue = min(min(xAxis, yAxis), zAxis)

    // If we can multiply the smallest value by 10,000 and it's larger than the largest value, that
    // means our values are relatively close together, so they are likely to be valid. By testing
    // various axes, we've been able to deduce that the absolute value difference between axes is
    // typically less than a factor of 10,000.
    if smallestAxisValue * 10_000 > largestAxisValue {
      return true
    }
    return false
  }

}
