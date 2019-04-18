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

/// Detects the fundamental frequency of a given array of samples.
final class AudioAnalyzer {

  public static let bufferSize = 4096
  private static let minimumNoiseLevel = 32.0

  private let fftAnalyzer: FFTAnalyzer
  private let goertzelAnalyzer: GoertzelAnalyzer
  private var peaks: [Peak] = []
  private var mapOfFundamentalFrequencies: [Int : [Double]] = [:]

  /// Sample rate in hertz must be the expected rate for the samples that are used for the analyzer.
  init(sampleRateInHz: Double) {
    fftAnalyzer = FFTAnalyzer(sampleRateInHz: sampleRateInHz)
    goertzelAnalyzer = GoertzelAnalyzer(sampleRateInHz: sampleRateInHz)
  }

  /// Given an array of samples, detects a fundamental frequency if there is one.
  func detectFundamentalFrequency(samples: [Int16]) -> Double? {
    peaks.removeAll()
    mapOfFundamentalFrequencies.removeAll()

    // Don't bother trying to determine the frequency if the buffer is half (or
    // more) filled with zeros or if the volume is too low to hear.
    let zeroCount = samples.reduce(0) { (zeroCount, sample) in
      sample == 0 ? zeroCount + 1 : 0
    }

    guard zeroCount < samples.count / 2 else {
      return nil
    }

    let uncalibratedDecibels: Double = SoundUtils.calculateUncalibratedDecibels(samples: samples)
    guard uncalibratedDecibels >= AudioAnalyzer.minimumNoiseLevel else {
      return nil
    }

    peaks = fftAnalyzer.findPeaks(samples: samples)
    // At this point, peaks is sorted by FFT value, in descending order.
    guard !peaks.isEmpty else {
      return nil
    }

    // Use Goertzel analyzer to more accurately determine the frequency of each peak.
    for peak in peaks {
      let frequency = goertzelAnalyzer.findFrequencyWithHighestPower(
        samples: samples,
        frequencyEstimate: peak.frequencyEstimate
      )
      peak.goertzelFilteredFrequency = frequency
    }

    let tallestPeak = peaks[0]
    if peaks.count == 1 {
      return tallestPeak.goertzelFilteredFrequency
    }

    // Determine the fundamental frequency by examining harmonic ratios.
    var fundamentalFrequency = determineFundamentalFrequencyFromHarmonics()

    if fundamentalFrequency == nil {
      // No harmonics were recognized. Return the frequency of the tallest peak.
      fundamentalFrequency = tallestPeak.goertzelFilteredFrequency
    }
    return fundamentalFrequency
  }

  /// Determines the fundamental frequency by examining the harmonic ratios between peaks in the
  /// FFT output. Returns null if no harmonic ratios are identified.
  private func determineFundamentalFrequencyFromHarmonics() -> Double? {
    // Sort in ascending order by frequency
    peaks.sort { (peak1, peak2) -> Bool in
      return peak1.goertzelFilteredFrequency < peak2.goertzelFilteredFrequency
    }

    // Look for harmonic ratios to determine the fundamental frequency.
    var harmonics: [Harmonic] = []
    // We look for harmonics 1 through 8, and even more if there are more than 8 peaks.

    let maxHarmonic = max(8, peaks.count)
    // Look at the ratios between peak frequencies.
    for (i, peakI) in peaks.enumerated() {
      // Find harmonics between peakI and other peaks.
      for j in i + 1..<peaks.count {
        let peakJ = peaks[j]
        let harmonic = identifyHarmonicRatio(peakA: peakI, peakB: peakJ, maxHarmonic: maxHarmonic)
        if let harmonic = harmonic {
          harmonics.append(harmonic)
        }
      }
    }

    guard !harmonics.isEmpty else {
      return nil
    }

    // Adjust harmonics and then calculate the fundamental frequency for each harmonic relationship.
    harmonics.forEach {
      $0.adjustHarmonic()
      addFundamentalFrequencyToMap(harmonic: $0)
    }

    return chooseBestFundamentalFrequency()
  }

  /// Identifies the harmonic ratio between the two given peaks. Returns nil if no harmonic ratio
  /// is found.
  private func identifyHarmonicRatio(peakA: Peak, peakB: Peak, maxHarmonic: Int) -> Harmonic? {
    let ratio = peakB.goertzelFilteredFrequency / peakA.goertzelFilteredFrequency

    var foundHarmonicRatio = false
    var termA = 0
    var termB = 0
    var smallestError = Double.greatestFiniteMagnitude

    for a in 1..<maxHarmonic {
      for b in a + 1..<maxHarmonic {
        // Skip ratios if we've already looked at an equivalent ratio.
        // For instance, we skip 2:4 because we already looked at 1:2.
        if AudioAnalyzer.gcd(a, b) != 1 {
          continue
        }
        let r = Double(b) / Double(a)
        let error = abs(ratio - r)
        if error <= 0.01 {
          if error < smallestError {
            smallestError = error
            termA = a
            termB = b
            foundHarmonicRatio = true
          }
        }
      }
    }
    if foundHarmonicRatio {
      return Harmonic.addHarmonic(peakA: peakA, peakB: peakB, termA: termA, termB: termB)
    }
    return nil
  }

  /// Returns the greatest common divisor of the given integers.
  private static func gcd(_ a: Int, _ b: Int) -> Int {
    var a = a
    var b = b
    while b > 0 {
      let temp = b
      b = a % b
      a = temp
    }
    return a
  }

  /// Calculates the fundamental frequencies indicated by the given harmonic relationship and adds
  /// them to the mapOfFundamentalFrequencies.
  private func addFundamentalFrequencyToMap(harmonic: Harmonic) {
    let peakA = harmonic.peakA
    let peakB = harmonic.peakB
    let termA = Double(harmonic.termA)
    let termB = Double(harmonic.termB)

    addFundamentalFrequencyToMap(fundamentalFrequency: peakA.goertzelFilteredFrequency / termA)
    addFundamentalFrequencyToMap(fundamentalFrequency: peakB.goertzelFilteredFrequency / termB)
  }

  /// Adds the given fundamentalFrequency to the mapOfFundamentalFrequencies.
  private func addFundamentalFrequencyToMap(fundamentalFrequency: Double) {
    // Determine the appropriate Integer key, based on the given fundamentalFrequency.
    let roundedFrequency = Int(round(fundamentalFrequency))
    // Look for existing keys close to the rounded frequency.
    var frequencies: [Double]?

    let sortedFundamentalFrequencies = mapOfFundamentalFrequencies.sorted {
      let (roundedFrequency1, _) = $0
      let (roundedFrequency2, _) = $1
      return roundedFrequency1 > roundedFrequency2
    }
    for (key, existingFrequencies) in sortedFundamentalFrequencies {
      if abs(key - roundedFrequency) < 10 {
        frequencies = existingFrequencies
        break
      }
    }

    if frequencies == nil {
      // No keys are close enough to roundedFrequency.
      frequencies = []
    }

    frequencies?.append(fundamentalFrequency)
    mapOfFundamentalFrequencies[roundedFrequency] = frequencies
  }

  /// Chooses the best fundamental frequency based on what has been added to the
  /// mapOfFundamentalFrequencies.
  private func chooseBestFundamentalFrequency() -> Double {
    // mapOfFundamentalFrequencies contains one or more approximate frequencies (keys),
    // each of which is associated with one or more actual frequencies. The number of
    // actual frequencies corresponds to the number of harmonic ratios that indicate that
    // the frequency is the fundamental frequency.
    //
    // Look for the one with the most actual frequencies.
    //
    // TODO: If we had a TreeMap, and there were two approximate frequencies with the same number
    // of actual frequencies, we could choose the one with the lower approximate frequency.
    var bestFrequencies: [Double] = []

    mapOfFundamentalFrequencies.forEach { (_, frequencies: [Double]) in
      if frequencies.count > bestFrequencies.count {
        bestFrequencies = frequencies
      }
    }

    // bestFrequencies contains one or more actual frequencies that are close to the
    // fundamental frequency. Calculate the mean. That's a good estimate of the fundamental
    // frequency.
    let summedFrequencies = bestFrequencies.reduce(0.0, +)
    let meanFrequency = summedFrequencies / Double(bestFrequencies.count)

    return meanFrequency
  }

}
