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

/// Represents a peak in FFT (Fast Fourier Transform) output.
final class Peak {

  internal var goertzelFilteredFrequency = 0.0
  internal let frequencyEstimate: Double
  internal let fftValue: Double

  private let fftIndex: Int
  private var harmonics: [Harmonic] = []

  /// Adds the given harmonic relationship to the harmonics list.
  func addHarmonic(_ harmonic: Harmonic) {
    harmonics.append(harmonic)
  }

  init(fftIndex: Int, frequencyEstimate: Double, fftMagnitude: Double, fftProminence: Double) {
    self.fftIndex = fftIndex
    self.frequencyEstimate = frequencyEstimate
    self.fftValue = fftMagnitude * fftProminence
  }

  /// Returns the set of harmonic ratio terms that have been identified for this peak.
  var harmonicTerms: [Int] {
    return harmonics
      .map { $0.getTermForPeak(self) }
      .sorted()
  }

}

extension Peak: Hashable {

  public var hashValue: Int {
    return fftIndex
  }

}

extension Peak: Equatable {

  static func == (lhs: Peak, rhs: Peak) -> Bool {
    return lhs.fftIndex == rhs.fftIndex
  }

}
