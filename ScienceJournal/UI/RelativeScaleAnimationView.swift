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

/// Animation view for sensors that operate on a relative scale.
class RelativeScaleAnimationView: ImageAnimationView {

  override func imageIndex(forValue value: Double, minValue: Double, maxValue: Double) -> Int {
    // To calculate a relative scale, there must be a valid range.
    guard maxValue - minValue > 0 else {
      return 0
    }

    var valuePercentage = (value - minValue) / (maxValue - minValue)
    valuePercentage = max(min(valuePercentage, 1.0), 0)
    let index = Int(exactly: floor(valuePercentage * Double(images.count)))

    if let index = index {
      // If percentage is 1.0 index can be beyond count so clamp it.
      return min(index, images.count - 1)
    } else {
      return 0
    }
  }

}
