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

/// Custom Fast Fourier Transform.
final class FFTAnalyzer {

  private static let movingAverageWindowSize = 5
  private final let sampleRateInHz: Double
  private final let indexOfLowestNote: Int
  private final let indexOfHighestNote: Int

  private var a = [Double](repeating: 0.0, count: AudioAnalyzer.bufferSize)
  private var b = [Double](repeating: 0.0, count: AudioAnalyzer.bufferSize)
  private var magnitudes: [Double]
  private var movingAverageValues: [Double]
  private final let movingAverage: MovingAverage = MovingAverage(size: movingAverageWindowSize)

  /// Designated initializer.
  ///
  /// - Parameter sampleRateInHz: sample rate for sound
  init(sampleRateInHz: Double) {
    self.sampleRateInHz = sampleRateInHz

    indexOfLowestNote = FFTAnalyzer.frequencyToIndex(
      frequency: SoundUtils.lowestPianoFrequency,
      sampleRateInHz: sampleRateInHz
    )
    indexOfHighestNote = FFTAnalyzer.frequencyToIndex(
      frequency: SoundUtils.highestPianoFrequency,
      sampleRateInHz: sampleRateInHz
    )

    magnitudes = [Double](
      repeating: 0.0,
      count: indexOfHighestNote + FFTAnalyzer.movingAverageWindowSize
    )

    movingAverageValues = [Double](
      repeating: 0.0,
      count: indexOfHighestNote + FFTAnalyzer.movingAverageWindowSize
    )
  }

  /// Given an array of samples, uses a FFT to find where the frequency peaks are.
  func findPeaks(samples: [Int16]) -> [Peak] {
    // At this point, peaks is sorted by FFT value, in descending order.
    // Copy the samples into the a array, converting shorts to doubles.
    for sampleIndex in 0..<AudioAnalyzer.bufferSize {
      if (sampleIndex < samples.count) {
        a[sampleIndex] = Double(samples[sampleIndex]) / Double(Int16.max)
      } else {
        a[sampleIndex] = 0.0
      }
      b[sampleIndex] = 0.0
    }

    // Use FFT to convert the audio signal from time domain to frequency domain.
    // performFft() calculates the FFT in place, modifying the elements of a and b arrays.
    // The results of FFT are complex numbers expressed in the form a + bi, where a and b are
    // real numbers and i is the imaginary unit. a[] will contain the "a" numbers and b[]
    // will contain the "b" numbers.
    performFft()

    // Calculate the magnitudes.
    // Use a moving average to smooth out the magnitudes.
    movingAverage.clear()
    var mean = 0.0
    for magnitudeIndex in indexOfLowestNote..<magnitudes.count {
      // The magnitude of a complex number a + bi, is the square root of (a*a + b*b).
      magnitudes[magnitudeIndex] = sqrt(
        a[magnitudeIndex] *
        a[magnitudeIndex] +
        b[magnitudeIndex] *
        b[magnitudeIndex]
      )
      // Note that movingAverageValues[] is skewed since it averages the window of values
      // up to and including [i]. In findIndexOfMaxMagnitude below, we take that into
      // account.
      movingAverageValues[magnitudeIndex] =
        movingAverage.insertAndReturnAverage(magnitudes[magnitudeIndex])
      mean += movingAverageValues[magnitudeIndex]
    }
    mean /= Double(magnitudes.count - indexOfLowestNote)

    // Find peaks.
    var peaks: [Peak] = []
    for peakIndex in 0...indexOfHighestNote {
      // AudioAnalyzer and FFTAnalyzer.
      if (movingAverageValues[peakIndex] < 2.0 * mean) {
        // Not a peak because the value is too low.
        // Peaks must be at least two times the global mean.
        continue
      }

      let prominenceOfPeak = determineProminenceOfPeak(index: peakIndex, boundaryValue: mean / 10)
      if (prominenceOfPeak > 1.0) {
        let indexOfMaxMagnitude = findIndexOfMaxMagnitude(index: peakIndex)
        let frequencyEstimate = indexToFrequency(index: indexOfMaxMagnitude)
        peaks.append(
          Peak(fftIndex: indexOfMaxMagnitude,
               frequencyEstimate: frequencyEstimate,
               fftMagnitude: magnitudes[indexOfMaxMagnitude],
               fftProminence: prominenceOfPeak)
        )
      }
    }

    guard !peaks.isEmpty else {
      return []
    }

    // We only need 10 (or fewer) good peaks.
    // A "good" peak is defined as having an FFT value that is greater than or equal to
    // 1/25th of the highest FFT value.
    peaks.sort { (first, second) -> Bool in
      return first.fftValue > second.fftValue
    }

    let highestFft = peaks[0].fftValue
    for i in (1..<peaks.count).reversed() {
      if (i < 10 && peaks[i].fftValue >= highestFft / 25) {
        break
      }
      peaks.remove(at: i)
    }
    return peaks
  }

  private func performFft() {
    // Non-recursive version of the Cooley-Tukey FFT, based on code from
    // https://introcs.cs.princeton.edu/java/97data/InplaceFFT.java.html
    // Bit reversal permutation.
    let shift = 1 + AudioAnalyzer.bufferSize.leadingZeroBitCount

    for shiftIndex in (1..<AudioAnalyzer.bufferSize) {
      let j = shiftIndex.reverseBits() >>> shift
      if (j > shiftIndex) {
        var temp = a[j]
        a[j] = a[shiftIndex]
        a[shiftIndex] = temp
        temp = b[j]
        b[j] = b[shiftIndex]
        b[shiftIndex] = temp
      }
    }

    // Butterfly updates.
    var firstLevel = 2
    while (firstLevel <= AudioAnalyzer.bufferSize) {
      let lHalf = firstLevel / 2
      for secondLevel in 0..<lHalf {
        let kth = -2 * Double(secondLevel) * Double.pi / Double(firstLevel)
        let wA = cos(kth)
        let wB = sin(kth)
        for thirdLevel in 0..<AudioAnalyzer.bufferSize / firstLevel {
          let index1 = thirdLevel * firstLevel + secondLevel + lHalf
          let index2 = thirdLevel * firstLevel + secondLevel
          let xA = a[index1]
          let xB = b[index1]

          // Multiply complex numbers.
          // tao = x * w
          let taoA = xA * wA - xB * wB
          let taoB = xA * wB + xB * wA

          a[index1] = a[index2] - taoA
          b[index1] = b[index2] - taoB
          a[index2] = a[index2] + taoA
          b[index2] = b[index2] + taoB
        }
      }
      firstLevel = firstLevel + firstLevel
    }
  }

  private func findIndexOfMaxMagnitude(index: Int) -> Int {
    // Remember that movingAverageValues[] is skewed since it averages the window of values up
    // to and including [index].
    var indexOfMaxMagnitude = index
    var maxMagnitude = magnitudes[index]

    let maxOrZero = max(0, index - FFTAnalyzer.movingAverageWindowSize + 1)
    for magnitudeIndex in maxOrZero..<index {
      if (magnitudes[magnitudeIndex] > maxMagnitude) {
        indexOfMaxMagnitude = magnitudeIndex
        maxMagnitude = magnitudes[indexOfMaxMagnitude]
      }
    }
    return indexOfMaxMagnitude
  }

  private func indexToFrequency(index: Int) -> Double {
    return Double(index) * (sampleRateInHz / Double(AudioAnalyzer.bufferSize))
  }

  private static func frequencyToIndex(frequency: Double, sampleRateInHz: Double) -> Int {
    let frequencyIndex = (frequency * Double(AudioAnalyzer.bufferSize)) / Double(sampleRateInHz)

    return Int(frequencyIndex)
  }

  private func determineProminenceOfPeak(index: Int, boundaryValue: Double) -> Double {
    let value: Double = movingAverageValues[index]
    // Look at values at lower and higher indices to determine the local area. The
    // boundaries of the local area are values that are less than or equal to the given
    // boundaryValue or greater than the value at index.
    // At the same time, calculate the local mean.
    var localMean = 0.0
    var count = 0
    var indexStartArea = index - 1
    var indexEndArea = index + 1

    while (indexStartArea >= 0 && indexEndArea < movingAverageValues.count) {
      if (movingAverageValues[indexStartArea] <= boundaryValue) {
        break
      }
      if (movingAverageValues[indexStartArea] > value) {
        if (index - indexStartArea < 5) {
        // Not a peak because a greater value is nearby.
          return 0
        }
        break
      }
      if (movingAverageValues[indexEndArea] <= boundaryValue) {
        break
      }
      if (movingAverageValues[indexEndArea] > value) {
        if (indexEndArea - index < 5) {
        // Not a peak because a greater value is nearby.
          return 0
        }
        break
      }
      localMean += movingAverageValues[indexStartArea] + movingAverageValues[indexEndArea]
      count += 2
      indexStartArea = indexStartArea - 1
      indexEndArea = indexEndArea + 1
    }
    localMean = localMean / Double(count)

    // Avoid unexpected divide by zero.
    if (localMean == 0.0) {
      return 0
    }
    return value / localMean
  }

}

/// Create an operator for logical shift right (typically >>> in other languages).
infix operator >>> : BitwiseShiftPrecedence

private func >>> (lhs: Int, rhs: Int) -> Int {
  return Int(bitPattern: UInt(bitPattern: lhs) >> UInt(rhs))
}
