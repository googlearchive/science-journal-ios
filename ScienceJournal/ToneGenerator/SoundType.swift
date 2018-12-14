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

/// Provides information for the tone generator. This can be subclasses to provide different sound
/// types.
class SoundType {

  /// The lowest frequency tone a sound type can make.
  var frequencyMin = 220.0
  /// The highest frequency tone a sound type can make.
  var frequencyMax = 783.991

  /// The name of the sound type.
  let name: String

  /// The designated initializer for `SoundType`.
  ///
  /// - Parameter name: The name of the sound type.
  init(name: String) {
    self.name = name
  }

  /// Whether or not the tone generator should animate to the next frequency for this sound type.
  var shouldAnimateToNextFrequency: Bool = true

  /// Returns the tone frequency for a sensor value, based on the value min/max and timestamp.
  ///
  /// Important: Must be overridden by the subclass.
  ///
  /// - Parameters:
  ///   - value: The sensor data value.
  ///   - valueMin: The minimum sensor data value.
  ///   - valueMax: The maximum sensor data value.
  ///   - timestamp: The timestamp of the value.
  /// - Returns: The calculated tone frequency or nil. When the frequeny is non-nil the tone
  ///            generator should be audible. Otherwise, it should be silent until a non-nil
  ///            frequency is returned.
  func frequency(from value: Double,
                 valueMin: Double,
                 valueMax: Double,
                 timestamp: Int64) -> Double? {
      fatalError("`frequency(from:, valueMin:, valueMax:, timestamp:)` must be overridden by the " +
          "subclass.")
  }

}
