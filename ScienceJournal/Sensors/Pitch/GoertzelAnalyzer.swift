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

/// Determines the frequency by using a series of Goertzel filters.
final class GoertzelAnalyzer {

  private let sampleRateInHz: Double

  /// Initialize with the sample rate in hertz of all the samples you'll be using.
  init(sampleRateInHz: Double) {
    self.sampleRateInHz = sampleRateInHz
  }

  /// Finds frequency that has the highest Goertzel power out of all the samples.
  func findFrequencyWithHighestPower(samples: [Int16], frequencyEstimate: Double) -> Double {
    let accuracy: Double

    switch frequencyEstimate {
    case _ where frequencyEstimate < 100:
      accuracy = 0.01
    case _ where frequencyEstimate < 1000:
      accuracy = 0.1
    default:
      accuracy = 1
    }

    var loFrequency: Double = frequencyEstimate - 10
    var powerAtLoFrequency: Double = calculatePower(samples: samples, targetFrequency: loFrequency)
    var hiFrequency: Double = frequencyEstimate + 10
    var powerAtHiFrequency: Double = calculatePower(samples: samples, targetFrequency: hiFrequency)

    repeat {
      // greatestPower is greater than secondGreatestPower, but the order of
      // frequencyWithGreatestPower and frequencyWithSecondGreatestPower is not relevant.
      var greatestPower: Double
      var frequencyWithGreatestPower: Double
      var secondGreatestPower: Double
      var frequencyWithSecondGreatestPower: Double

      if powerAtLoFrequency > powerAtHiFrequency {
        greatestPower = powerAtLoFrequency
        frequencyWithGreatestPower = loFrequency
        secondGreatestPower = powerAtHiFrequency
        frequencyWithSecondGreatestPower = hiFrequency
      } else {
        greatestPower = powerAtHiFrequency
        frequencyWithGreatestPower = hiFrequency
        secondGreatestPower = powerAtLoFrequency
        frequencyWithSecondGreatestPower = loFrequency
      }

      // Divide the interval between loFrequency and hiFrequency into 4 parts and get the
      // Goertzel power at each division.
      let interval: Double = (hiFrequency - loFrequency) / 4
      var frequency: Double = loFrequency + interval
      while frequency < hiFrequency {
        let power: Double = calculatePower(samples: samples, targetFrequency: frequency)
        // Keep track of the greatest power as greatestPower and the second greatest
        // power as secondGreatestPower.
        if power > greatestPower {
          // Move greatestPower to secondGreatestPower.
          secondGreatestPower = greatestPower
          frequencyWithSecondGreatestPower = frequencyWithGreatestPower
          // Replace greatestPower.
          greatestPower = power
          frequencyWithGreatestPower = frequency
        } else if power > secondGreatestPower {
          // Replace secondGreatestPower.
          secondGreatestPower = power
          frequencyWithSecondGreatestPower = frequency
        }
        frequency += interval
      }

      let previousHi: Double = hiFrequency
      let previousLo: Double = loFrequency

      // Figure out which of the two frequencies with the greatest powers is lower and
      // which is higher.
      if frequencyWithGreatestPower > frequencyWithSecondGreatestPower {
        hiFrequency = frequencyWithGreatestPower
        powerAtHiFrequency = greatestPower
        loFrequency = frequencyWithSecondGreatestPower
        powerAtLoFrequency = secondGreatestPower
      } else {
        hiFrequency = frequencyWithSecondGreatestPower
        powerAtHiFrequency = secondGreatestPower
        loFrequency = frequencyWithGreatestPower
        powerAtLoFrequency = greatestPower
      }

      // If the low and high frequencies haven't changed, then we aren't finding a peak
      // and we can give up.
      if previousHi.isEssentiallyEqual(to: hiFrequency) &&
          previousLo.isEssentiallyEqual(to: loFrequency) {
        break
      }
    } while (hiFrequency - loFrequency > accuracy)

    let foundFrequency = (powerAtLoFrequency > powerAtHiFrequency) ? loFrequency : hiFrequency
    return foundFrequency
  }

  /// Calculates the power at the given target frequency.
  private func calculatePower(samples: [Int16], targetFrequency: Double) -> Double {
    let normalizedFrequency: Double = targetFrequency / Double(sampleRateInHz)
    let coeff: Double = 2 * cos(2 * Double.pi * normalizedFrequency)
    var sPrev1: Double = 0
    var sPrev2: Double = 0

    for sample in samples {
      let s: Double = Double(sample) + coeff * sPrev1 - sPrev2
      sPrev2 = sPrev1
      sPrev1 = s
    }
    return sPrev2 * sPrev2 + sPrev1 * sPrev1 - coeff * sPrev1 * sPrev2
  }

}
