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

import XCTest

@testable import third_party_objective_c_material_components_ios_components_Palettes_Palettes
@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class MDCPalette_ScienceJournalTest: XCTestCase {

  func testNextExperimentListCardColorPaletteWithUsedPalettes() {
    XCTAssertEqual(MDCPalette.nextExperimentListCardColorPalette(withUsedPalettes: []),
                   .deepPurple,
                   "If there are no used palettes, the color should be deep purple.")
    XCTAssertEqual(MDCPalette.nextExperimentListCardColorPalette(withUsedPalettes: [.deepPurple]),
                   .blue,
                   "If deep purple is used, the color should be blue.")
    XCTAssertEqual(MDCPalette.nextExperimentListCardColorPalette(withUsedPalettes: [.blue, .green]),
                   .deepPurple,
                   "If blue and deep orange were used, the color should be deep purple.")
    XCTAssertEqual(MDCPalette.nextExperimentListCardColorPalette(
        withUsedPalettes: [.deepPurple, .blue, .green, .orange, .red, .grey]),
        .deepPurple,
        "If all colors were used once each, the color should be deep purple.")
    XCTAssertEqual(
        MDCPalette.nextExperimentListCardColorPalette(withUsedPalettes: [.deepPurple, .blue,
            .green, .orange, .red, .grey, .deepPurple, .blue, .green, .red, .grey]),
        .orange,
        "If all colors were used twice each, but orange was used once the color should be orange.")
  }

  func testNextSensorCardColorPaletteWithUsedPalettes() {
    XCTAssertEqual(MDCPalette.nextSensorCardColorPalette(withUsedPalettes: []),
                   .blue,
                   "If there are no used palettes, the color should be blue.")
    XCTAssertEqual(MDCPalette.nextSensorCardColorPalette(withUsedPalettes: [.blue]),
                   .green,
                   "If blue is used, the color should be green.")
    XCTAssertEqual(MDCPalette.nextSensorCardColorPalette(withUsedPalettes: [.green, .orange]),
                   .blue,
                   "If green and orange were used, the color should be blue.")
    XCTAssertEqual(MDCPalette.nextSensorCardColorPalette(withUsedPalettes: [.blue, .green, .orange,
                       .red, .grey]),
                   .blue,
                   "If all colors were used once each, the color should be blue.")
    XCTAssertEqual(MDCPalette.nextSensorCardColorPalette(
        withUsedPalettes: [.blue, .green, .orange, .red, .grey, .blue, .green, .orange, .grey]),
        .red,
        "If all colors were used twice each, but red was used once the color should be red.")
  }

}
