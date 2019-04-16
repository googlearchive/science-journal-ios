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

class TrialStatsTest: XCTestCase {

  func testCreatingTrialStats() {
    let statCalculator = StatCalculator()
    statCalculator.addDataPoint(DataPoint(x: 0, y: 1))
    statCalculator.addDataPoint(DataPoint(x: 0, y: 2))
    statCalculator.addDataPoint(DataPoint(x: 0, y: 3))

    let trialStats = TrialStats(sensorID: "test sensor ID")
    trialStats.addStatsFromStatCalculator(statCalculator)

    XCTAssertEqual(trialStats.minimumValue!, 1,
                   "The minimum value should be 1.")
    XCTAssertEqual(trialStats.maximumValue!, 3,
                   "The maximum value should be 3.")
    XCTAssertEqual(trialStats.averageValue!, 2,
                   "The average value should be 2.")
  }

}
