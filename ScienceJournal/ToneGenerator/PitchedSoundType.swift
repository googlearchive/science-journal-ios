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

/// A sound type for pitched tones that play along a scale.
class PitchedSoundType : SoundType {

  /// Pentatonic scale (C, D, E, G, A)
  let scale = [0, 2, 4, 7, 9]

  // All of the pitches to use, based on the `scale`.
  var pitches = [Int]()

  /// The lowest pitch tone a pitched sound type can make.
  var pitchMin: Int {
    return Int(floor(pitch(from: frequencyMin)))
  }
  /// The highest pitch tone a pitched sound type can make.
  var pitchMax: Int {
    return Int(floor(pitch(from: frequencyMax)))
  }

  override init(name: String) {
    super.init(name: name)

    // Pitches
    var pitch = pitchMin
    while pitch <= pitchMax {
      for index in 0..<scale.endIndex {
        if (pitch + scale[index] > pitchMax) {
          break
        }
        pitches.append(pitch + scale[index])
      }
      pitch += 12
    }
  }

  // MARK: - Helpers

  /// Returns a pitch converted from a frequency.
  ///
  /// - Parameter frequency: The frequency to convert to a pitch.
  /// - Returns: The pitch.
  func pitch(from frequency: Double) -> Double {
    return 69.0 + 12.0 * log(frequency / 440.0) / log(2.0)
  }

  /// Returns a frequency converted from a pitch.
  ///
  /// - Parameter pitch: The pitch to convert to a frequency.
  /// - Returns: The frequency.
  func frequency(from pitch: Double) -> Double {
    return 440.0 * pow(2.0, (pitch - 69.0) * 0.08333333333333333)
  }

}
