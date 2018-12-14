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

class TimestampTest: XCTestCase {

  func testNonRelativeTimestamp() {
    let milliseconds = Int64(1494968318416)
    Timestamp.dateFormatter.timeZone = TimeZone(abbreviation: "EDT")
    let timestamp = Timestamp(milliseconds)
    var expectedDateString: String
    if #available(iOS 11.0, *) {
      expectedDateString = "May 16, 2017 at 4:58 PM"
    } else {
      expectedDateString = "May 16, 2017, 4:58 PM"
    }
    XCTAssertEqual(timestamp.string, expectedDateString)
  }

  func testRelativeTimestampSeconds() {
    let relativeMilliseconds = Int64(1494968318416)
    let milliseconds = Int64(1494968322416)
    let timestamp = Timestamp(milliseconds, relativeTo: relativeMilliseconds)
    XCTAssertEqual(timestamp.string, "0:04")
  }

  func testRelativeTimestampMinutes() {
    let relativeMilliseconds = Int64(1494968318416)
    let milliseconds = Int64(1494969038416)
    let timestamp = Timestamp(milliseconds, relativeTo: relativeMilliseconds)
    XCTAssertEqual(timestamp.string, "12:00")
  }

  func testRelativeTimestampHours() {
    let relativeMilliseconds = Int64(1494968318416)
    let milliseconds = Int64(1494980078416)
    let timestamp = Timestamp(milliseconds, relativeTo: relativeMilliseconds)
    XCTAssertEqual(timestamp.string, "3:16:00")
  }

}
