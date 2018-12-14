/*
 *  Copyright 2019 Google Inc. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License")
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

class FrequencyBufferTest: XCTestCase {

  func testTwenty() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 25, value: 1)
    _ = buffer.filterValue(timestamp: 50, value: 0)
    _ = buffer.filterValue(timestamp: 75, value: 1)
    let lastValue = buffer.filterValue(timestamp: 100, value: 0)
    XCTAssertEqual(20.0, lastValue, accuracy: 0.01)
  }

  func testRestrictWindowToCrosses() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 10, value: 1)
    _ = buffer.filterValue(timestamp: 35, value: 0)
    _ = buffer.filterValue(timestamp: 60, value: 1)
    var lastValue = buffer.filterValue(timestamp: 85, value: 0)
    XCTAssertEqual(20.0, lastValue, accuracy: 0.01)
    _ = buffer.filterValue(timestamp: 90, value: 0)
    _ = buffer.filterValue(timestamp: 95, value: 0)
    lastValue = buffer.filterValue(timestamp: 100, value: 0)
    XCTAssertEqual(20.0, lastValue, accuracy: 0.01)
  }

  func testTwentyWithOutlierValue() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 1, value: 0)
    _ = buffer.filterValue(timestamp: 25, value: 1)
    _ = buffer.filterValue(timestamp: 50, value: 0)
    _ = buffer.filterValue(timestamp: 75, value: 1)
    let lastValue = buffer.filterValue(timestamp: 100, value: 0)
    XCTAssertEqual(20.0, lastValue, accuracy: 0.01)
  }

  func testTen() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 50, value: 1)
    let lastValue = buffer.filterValue(timestamp: 100, value: 0)
    XCTAssertEqual(10.0, lastValue, accuracy: 0.01)
  }

  func testTenFiltered() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 4.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)

    // noise below the filter
    _ = buffer.filterValue(timestamp: 1, value: 3)
    _ = buffer.filterValue(timestamp: 2, value: 0)
    _ = buffer.filterValue(timestamp: 3, value: 3)
    _ = buffer.filterValue(timestamp: 4, value: 0)

    _ = buffer.filterValue(timestamp: 50, value: 10)
    let lastValue = buffer.filterValue(timestamp: 100, value: 0)
    XCTAssertEqual(10.0, lastValue, accuracy: 0.01)
  }

  func testRpm() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 60000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 50, value: 1)
    let lastValue = buffer.filterValue(timestamp: 100, value: 0)
    XCTAssertEqual(600.0, lastValue, accuracy: 0.01)
  }

  func testPruneAsWeGo() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 25, value: 1)
    _ = buffer.filterValue(timestamp: 50, value: 0)
    _ = buffer.filterValue(timestamp: 75, value: 1)
    _ = buffer.filterValue(timestamp: 100, value: 0)
    _ = buffer.filterValue(timestamp: 150, value: 1)
    let lastValue = buffer.filterValue(timestamp: 200, value: 0)
    XCTAssertEqual(10, lastValue, accuracy: 0.01)
  }

  func testIgnoreNearlyEmptyWindows() {
    let buffer = FrequencyBuffer(window: 100, denominatorInMillis: 1000, filter: 0.0)
    _ = buffer.filterValue(timestamp: 0, value: 0)
    _ = buffer.filterValue(timestamp: 10, value: 1)
    _ = buffer.filterValue(timestamp: 20, value: 0)
    let lastValue = buffer.filterValue(timestamp: 99, value: 0)
    XCTAssertEqual(0, lastValue, accuracy: 0.01)
  }

  func testSingleValue() {
    let buffer = FrequencyBuffer(window: 200, denominatorInMillis: 1000, filter: 0.0)
    let lastValue = buffer.filterValue(timestamp: 0, value: 0)
    XCTAssertEqual(0.0, lastValue, accuracy: 0.01)
  }

}
