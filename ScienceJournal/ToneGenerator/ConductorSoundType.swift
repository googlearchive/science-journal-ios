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

/// A tone generator sound type that plays a note only when the value change is above 5%.
class ConductorSoundType: PitchedSoundType {

  /// The value percent change that will create a sound.
  let valuePercentChange = 0.05

  /// The minimum value so far.
  var currentMinimumValue: Double = .greatestFiniteMagnitude
  /// The maximum value so far.
  var currentMaximumValue: Double = .leastNormalMagnitude

  init() {
    let name = String.conductor
    super.init(name: name)
    frequencyMin = 261.63
    frequencyMax = 440.0
    shouldAnimateToNextFrequency = false
  }

  override func frequency(from value: Double,
                          valueMin: Double,
                          valueMax: Double,
                          timestamp: Int64) -> Double? {
    if value < currentMinimumValue {
      currentMinimumValue = value
    }
    if (value > currentMaximumValue) {
      currentMaximumValue = value
    }

    // If value < min + 5%, map to silence
    let valueThreshhold =
        currentMinimumValue + (currentMaximumValue - currentMinimumValue) * valuePercentChange
    guard value > valueThreshhold else {
      return nil
    }

    let index = Int(exactly: floor((value - valueThreshhold) / (currentMaximumValue - valueThreshhold) *
        Double(pitches.count - 1)))
    if let index = index {
      return frequency(from: Double(pitches[index]))
    } else {
      return nil
    }
  }

}
