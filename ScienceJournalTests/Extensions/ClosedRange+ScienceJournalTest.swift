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

class ClosedRange_ScienceJournalTest: XCTestCase {

  func testClampDouble() {
    let lowerBound = 0.0
    let upperBound = 3.0

    let valueWithin = 2.2
    let valueAbove = 3.1
    let valueBelow = -1.0

    XCTAssertEqual((lowerBound...upperBound).clamp(valueWithin),
                   valueWithin,
                   "If the value falls between the lower and upper bound, it should be returned.")
    XCTAssertEqual((lowerBound...upperBound).clamp(valueAbove),
                   upperBound,
                   "If the value is above the upper bound, the upper bound should be returned.")
    XCTAssertEqual((lowerBound...upperBound).clamp(valueBelow),
                   lowerBound,
                   "If the value is below the lower bound, the lower bound should be returned.")
  }

  func testClampInt() {
    let lowerBound = 0
    let upperBound = 3

    let valueWithin = 2
    let valueAbove = 4
    let valueBelow = -1

    XCTAssertEqual((lowerBound...upperBound).clamp(valueWithin),
                   valueWithin,
                   "If the value falls between the lower and upper bound, it should be returned.")
    XCTAssertEqual((lowerBound...upperBound).clamp(valueAbove),
                   upperBound,
                   "If the value is above the upper bound, the upper bound should be returned.")
    XCTAssertEqual((lowerBound...upperBound).clamp(valueBelow),
                   lowerBound,
                   "If the value is below the lower bound, the lower bound should be returned.")
  }
}
