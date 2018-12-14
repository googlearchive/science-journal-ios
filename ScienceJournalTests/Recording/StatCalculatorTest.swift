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

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class StatCalculatorTest: XCTestCase {

  // MARK: - Test cases

  func testMaximum() {
    let values = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
    let statCalculator = StatCalculator()
    values.forEach { statCalculator.addDataPoint(DataPoint(x: Int64($0), y: $0)) }
    XCTAssertEqual(statCalculator.maximum, 9, "9 is the maximum value.")
    statCalculator.addDataPoint(DataPoint(x: 10, y: 4))
    XCTAssertEqual(statCalculator.maximum, 9, "9 is still the maximum value.")
    statCalculator.addDataPoint(DataPoint(x: 11, y: 12))
    XCTAssertEqual(statCalculator.maximum, 12, "The maximum value has changed.")
    XCTAssertEqual(12, statCalculator.numberOfValues)
    XCTAssertEqual(11, statCalculator.duration)
  }

  func testMinimum() {
    let values = [-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0]
    let statCalculator = StatCalculator()
    values.forEach { statCalculator.addDataPoint(DataPoint(x: Int64($0), y: $0)) }
    XCTAssertEqual(statCalculator.minimum, -4, "-4 is the minimum value.")
    statCalculator.addDataPoint(DataPoint(x: 5, y: -2))
    XCTAssertEqual(statCalculator.minimum, -4, "-4 is still the minimum value.")
    statCalculator.addDataPoint(DataPoint(x: 6, y: -7))
    XCTAssertEqual(statCalculator.minimum, -7, "The minimum value has changed.")
    XCTAssertEqual(11, statCalculator.numberOfValues)
    XCTAssertEqual(10, statCalculator.duration)
  }

  func testAverage() {
    let values = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
    let statCalculator = StatCalculator()
    values.forEach { statCalculator.addDataPoint(DataPoint(x: Int64($0), y: $0)) }
    XCTAssertEqual(statCalculator.average, 8, "8 is the average value.")
    statCalculator.addDataPoint(DataPoint(x: 15, y: 19))
    XCTAssertEqual(statCalculator.average, 9.375, "The average value has changed.")
    XCTAssertEqual(8, statCalculator.numberOfValues)
    XCTAssertEqual(13, statCalculator.duration)
  }

  func testReset() {
    let values = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
    let statCalculator = StatCalculator()
    values.forEach { statCalculator.addDataPoint(DataPoint(x: Int64($0), y: $0)) }
    XCTAssertEqual(statCalculator.maximum, 9)
    XCTAssertEqual(statCalculator.minimum, 0)
    XCTAssertEqual(statCalculator.average, 4.5)
    XCTAssertEqual(statCalculator.numberOfValues, 10)
    XCTAssertEqual(statCalculator.duration, 9)

    statCalculator.reset()
    XCTAssertNil(statCalculator.maximum)
    XCTAssertNil(statCalculator.minimum)
    XCTAssertNil(statCalculator.average)
    XCTAssertEqual(statCalculator.numberOfValues, 0)
    XCTAssertNil(statCalculator.duration)
  }

}
