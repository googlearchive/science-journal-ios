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

/// Set of common functions to aid in pitch detection.
final class SoundUtils {

  static let numberOfPianoKeys = 88
  static let halfStepFrequencyRatio = 1.05946
  static let lowestPianoFrequency = 27.5
  static let highestPianoFrequency = 4186.01
  static let highNotes = [
    4186.01, // c
    3951.07, // b
    3729.31, // a#
    3520, // a
    3322.44, // g#
    3135.96, // g
    2959.96, // f#
    2793.83, // f
    2637.02, // e
    2489.02, // d#
    2349.32, // d
    2217.46, // c#
  ]

  private static var calculatedPianoNoteFrequencies: [Double] = []

  /// All discrete piano notes we can detect as frequencies.
  public static var pianoNoteFrequencie: [Double] {
    if (calculatedPianoNoteFrequencies.isEmpty) {
      fillPianoNoteFrequencies()
    }
    return calculatedPianoNoteFrequencies
  }

  /// Calculates the uncalibrated number of decibals for the given samples.
  public static func calculateUncalibratedDecibels(samples: [Int16]) -> Double {
    let totalSquared = samples.reduce(0.0) { (result, sample) in
      return result + Double(sample) * Double(sample)
    }

    let quadraticMeanPressure = (totalSquared / Double(samples.count)).squareRoot()
    let uncalibratedDecibels = 20 * log10(quadraticMeanPressure)
    return uncalibratedDecibels
  }

  private static func fillPianoNoteFrequencies() {
    var multiplier = 1.0
    while calculatedPianoNoteFrequencies.count < numberOfPianoKeys {
      for note in SoundUtils.highNotes {
        if (calculatedPianoNoteFrequencies.count == numberOfPianoKeys) {
          break
        }
        calculatedPianoNoteFrequencies.append(note * multiplier)
      }
      multiplier = multiplier / 2
    }
    calculatedPianoNoteFrequencies.reverse()
  }

}
