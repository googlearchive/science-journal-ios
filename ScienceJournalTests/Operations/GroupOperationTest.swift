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

class GroupOperationTest: XCTestCase {

  func testGroupOperation() {
    let expectation1 = XCTestExpectation(description: "First operation finished.")
    let expectation2 = XCTestExpectation(description: "Second operation finished.")
    let expectation3 = XCTestExpectation(description: "Third operation finished.")

    let operation1 = SimpleOperation()
    operation1.completionBlock = {
      XCTAssertTrue(operation1.taskComplete)
      expectation1.fulfill()
    }

    var operation2Completed = false
    let operation2 = BlockOperation(block: {
      operation2Completed = true
    })
    operation2.completionBlock = {
      XCTAssertTrue(operation2Completed)
      expectation2.fulfill()
    }

    let operation3 = SimpleOperation()
    operation3.completionBlock = {
      XCTAssertTrue(operation3.taskComplete)
      expectation3.fulfill()
    }

    let groupOperation = GroupOperation(operations: [operation1, operation2, operation3])
    let queue = GSJOperationQueue()
    queue.addOperation(groupOperation)

    wait(for: [expectation1, expectation2, expectation3], timeout: 1)
  }

}
