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

class ElapsedTimeFormatterTest: XCTestCase {

  let formatter = ElapsedTimeFormatter()

  func testPositiveTimestamp() {
    var string = formatter.string(fromTimestamp: 0)
    XCTAssertEqual("0:00", string)

    string = formatter.string(fromTimestamp: 6000)
    XCTAssertEqual("0:06", string)

    string = formatter.string(fromTimestamp: 1000 * 60 * 60 * 2)
    XCTAssertEqual("2:00:00", string)

    formatter.shouldDisplayTenths = true
    string = formatter.string(fromTimestamp: 76500)
    XCTAssertEqual("1:16.5", string)

    formatter.shouldDisplayTenths = false
    string = formatter.string(fromTimestamp: 76500)
    XCTAssertEqual("1:16", string)
  }

  func testNegativeTimestamp() {
    var string = formatter.string(fromTimestamp: -6000)
    XCTAssertEqual("-0:06", string)

    string = formatter.string(fromTimestamp: -1000 * 60 * 60 * 2)
    XCTAssertEqual("-2:00:00", string)

    formatter.shouldDisplayTenths = true
    string = formatter.string(fromTimestamp: -76500)
    XCTAssertEqual("-1:16.5", string)

    formatter.shouldDisplayTenths = false
    string = formatter.string(fromTimestamp: -76500)
    XCTAssertEqual("-1:16", string)
  }

}
