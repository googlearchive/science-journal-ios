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

/// Animation view for accelerometer sensors.
class AccelerometerAnimationView: ImageAnimationView {

  override func imageIndex(forValue value: Double, minValue: Double, maxValue: Double) -> Int {
    // Because acceleromter values have a predictable normal range, calculate index based on actual
    // value.
    if value > 3.0 {
      return 4
    } else if value > 0.5 {
      return 3
    } else if value > -0.5 {
      return 2
    } else if value > -3 {
      return 1
    } else {
      return 0
    }
  }

}
