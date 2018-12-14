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

class TimestampFormatterTest: XCTestCase {

  let timestampFormatter = TimestampFormatter()

  func testBadStringsDontParse() {
    XCTAssertNil(timestampFormatter.timestamp(fromString: "ABC"))
    XCTAssertNil(timestampFormatter.timestamp(fromString: "1234"))
    XCTAssertNil(timestampFormatter.timestamp(fromString: "9:15:20Y"))
    XCTAssertNil(timestampFormatter.timestamp(fromString: "9-15-20"))
    XCTAssertNil(timestampFormatter.timestamp(fromString: "0:0:1"))
  }

  func testValidStringsWillParse() {
    XCTAssertEqual(1000, timestampFormatter.timestamp(fromString: "00:00:01")!)
    XCTAssertEqual(659_000, timestampFormatter.timestamp(fromString: "00:10:59")!)
    XCTAssertEqual(3_750_000, timestampFormatter.timestamp(fromString: "1:02:30")!)
    XCTAssertEqual(3_750_000, timestampFormatter.timestamp(fromString: "01:02:30")!)
    XCTAssertEqual(51_069_123, timestampFormatter.timestamp(fromString: "14:11:09.123")!)
  }

  func testNegativeTimestamps() {
    XCTAssertNil(timestampFormatter.string(fromTimestamp: -10))
  }

  func testPositiveTimestamps() {
    XCTAssertEqual("0:00:00.001", timestampFormatter.string(fromTimestamp: 1))
    XCTAssertEqual("1:00:00.001", timestampFormatter.string(fromTimestamp: 3_600_001))
    XCTAssertEqual("13:44:19.756", timestampFormatter.string(fromTimestamp: 49_459_756))
  }

}
