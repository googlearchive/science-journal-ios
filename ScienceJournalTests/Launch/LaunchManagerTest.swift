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

class LaunchManagerTest: XCTestCase {

  func testCompletionIsCalled() {
    let manager = LaunchManager()

    let completionIsCalled = expectation(description: "completion is called")
    manager.performLaunchOperations {
      completionIsCalled.fulfill()
    }
    waitForExpectations(timeout: 0.1)
  }

  func testStateIsSet() {
    let manager = LaunchManager()
    XCTAssertEqual(manager.state, .launching)

    let e = expectation(description: "")
    manager.performLaunchOperations {
      e.fulfill()
      XCTAssertEqual(manager.state, .running)
    }
    waitForExpectations(timeout: 0.1)
  }

}
