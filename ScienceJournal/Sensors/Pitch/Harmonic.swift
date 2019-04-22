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

/// Represents a harmonic relationship between two frequencies.
final class Harmonic {

  internal var peakA: Peak
  internal var peakB: Peak

  internal var termA: Int
  internal var termB: Int

  /// Create harmonic ratio relationship between two frequencies, peak a, and peak b, along with
  /// the antecedent term of the ratio (termA) and consequent term (termB).
  init(peakA: Peak, peakB: Peak, termA: Int, termB: Int) {
    self.peakA = peakA
    self.peakB = peakB
    self.termA = termA
    self.termB = termB
  }

  /// Find term associated with the given peak. Assumes that the peak is part of this relationship
  /// otherwise returns 0.
  func getTermForPeak(_ peak: Peak) -> Int {
    if peak == peakA {
      return termA
    } else if peak == peakB {
      return termB
    }
    return 0
  }

  /// Adjusts the harmonic based on other harmonic relationships.
  func adjustHarmonic() {
    var multiplier = 0

    let peakADescendingHarmonicTerms = peakA.harmonicTerms.sorted { $0 > $1 }
    for term in peakADescendingHarmonicTerms {
      if term <= termA {
        // We only care about terms larger than a.
        break
      }
      if term % termA == 0 {
        multiplier = term / termA
        break
      }
    }

    let peakBDescendingHarmonicTerms = peakB.harmonicTerms.sorted { $0 > $1 }
    for term in peakBDescendingHarmonicTerms {
      if term <= termB {
        // We only care about terms larger than b.
        break
      }
      if term % termB == 0 {
        let m = term / termB
        if m > multiplier {
          multiplier = m
        }
        break
      }
    }

    if multiplier != 0 {
      multiply(multiplier)
    }
  }

  private func multiply(_ multiplier: Int) {
    termA *= multiplier
    termB *= multiplier
  }

  static func addHarmonic(peakA: Peak, peakB: Peak, termA: Int, termB: Int) -> Harmonic {
    let harmonic = Harmonic(peakA: peakA, peakB: peakB, termA: termA, termB: termB)
    peakA.addHarmonic(harmonic)
    peakB.addHarmonic(harmonic)
    return harmonic
  }

}

extension Harmonic: Equatable {

  static func == (lhs: Harmonic, rhs: Harmonic) -> Bool {
    return lhs.peakA == rhs.peakA && lhs.peakB == rhs.peakB
  }

}

extension Harmonic: Hashable {

  func hash(into hasher: inout Hasher) {
    hasher.combine(peakA)
    hasher.combine(peakB)
  }

}
