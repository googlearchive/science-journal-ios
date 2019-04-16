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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class PitchSensorAnimationViewTest: XCTestCase {

  func testSettingValueSetsAccessibilityLabel() {
    func setValue(_ value: Double, andAssertA11yLabel a11yLabel: String) {
      let pitchSensorAnimationView = PitchSensorAnimationView()
      pitchSensorAnimationView.setValue(value, minValue: 0, maxValue: 1)
      XCTAssertEqual(pitchSensorAnimationView.accessibilityLabel, a11yLabel)
    }

    // Low pitch
    setValue(0, andAssertA11yLabel: "low pitch")

    // High pitch
    setValue(4435, andAssertA11yLabel: "high pitch")

    // Flat notes
    setValue(58, andAssertA11yLabel: "0.08 half steps flatter than B flat, octave 1")
    setValue(58.27046875, andAssertA11yLabel: "B flat, octave 1")
    setValue(59, andAssertA11yLabel: "0.21 half steps sharper than B flat, octave 1")

    // Sharp notes
    setValue(69, andAssertA11yLabel: "0.08 half steps flatter than C sharp, octave 2")
    setValue(69.295625, andAssertA11yLabel: "C sharp, octave 2")
    setValue(70, andAssertA11yLabel: "0.17 half steps sharper than C sharp, octave 2")

    // Natural notes
    setValue(145, andAssertA11yLabel: "0.22 half steps flatter than D, octave 3")
    setValue(146.8325, andAssertA11yLabel: "D, octave 3")
    setValue(148, andAssertA11yLabel: "0.13 half steps sharper than D, octave 3")
  }

}
