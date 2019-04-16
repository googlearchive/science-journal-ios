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

/// A tone generator sound type that plays a note only when the value changes or a period of time
/// has gone by without having played a note.
class NotesSoundType: SoundType {

  /// The minimum percent change in value that can trigger a sound.
  let minimumPercentChange = 10.0
  /// The minimum change in time (milliseconds) that can trigger a sound.
  let minimumTimeChange: Int64 = 125
  /// The maximum time (milliseconds) that can go by without a sound.
  let maximumTimeWithoutSound: Int64 = 1000

  /// The timestamp of the last value that played a sound.
  var previousTimestamp = Date().millisecondsSince1970
  /// The last value that played a sound.
  var previousValue: Double?

  init() {
    let name = String.notes
    super.init(name: name)
    shouldAnimateToNextFrequency = false
  }

  override func frequency(from value: Double,
                          valueMin: Double,
                          valueMax: Double,
                          timestamp: Int64) -> Double? {
    guard let previousValue = previousValue else {
      self.previousValue = value
      return nil
    }

    let valueDifference = value - previousValue
    let valueRange = valueMax - valueMin
    let valuePercentChange = abs(valueDifference / valueRange * 100.0)

    let timestampDifference = timestamp - previousTimestamp

    // If the `value` hasn't changed more than `minimumPercentChange`, suppress new notes for up to
    // `maximumTimeWithoutSound`.  If the `value` has changed more than `minimumPercentChange`,
    // suppress new notes for `minimumTimeChange`.
    let percentChangeAboveMinimum = valuePercentChange >= minimumPercentChange
    let timeChangeAboveMinimum = timestampDifference > minimumTimeChange
    let timeChangeAboveMaximum = timestampDifference > maximumTimeWithoutSound
    if percentChangeAboveMinimum && timeChangeAboveMinimum || timeChangeAboveMaximum {
      previousTimestamp = timestamp
      self.previousValue = value

      return frequencyMin +
          (value - valueMin) / (valueMax - valueMin) * (frequencyMax - frequencyMin)
    }
    return nil
  }

}
