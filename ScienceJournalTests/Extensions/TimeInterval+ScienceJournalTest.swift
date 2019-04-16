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

class TimeInterval_ScienceJournalTest: XCTestCase {

  func testDurationString() {
    let interval: TimeInterval = 3792
    XCTAssertEqual(interval.durationString, "1h 3m 12s")
  }

  func testAccessibleDurationString() {
    let interval: TimeInterval = 3792
    XCTAssertEqual(interval.accessibleDurationString, "one hour, three minutes, twelve seconds")
  }

}
