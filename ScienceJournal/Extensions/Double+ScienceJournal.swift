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

extension Double {

  /// Two Doubles are nearly equal if they are within a small value of each other.
  ///
  /// - Parameter otherDouble: The other double to compare the receiver to.
  /// - Returns: Whether or not the Doubles are equal.
  func isNearlyEqual(to otherDouble: Double) -> Bool {
    return Swift.abs(self - otherDouble) < 0.00001
  }

  /// Two Doubles are essentially equal if they are within a very small value of each other.
  /// Use when you want the Doubles to be even closer together before being considered
  /// equal to each other
  ///
  /// - Parameter otherDouble: The other double to compare the receiver to.
  /// - Returns: Whether or not the Doubles are equal.
  func isEssentiallyEqual(to otherDouble: Double) -> Bool {
    return Swift.abs(self - otherDouble) < Double.ulpOfOne
  }

}
