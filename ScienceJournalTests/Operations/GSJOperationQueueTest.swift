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

class GSJOperationQueueTest: XCTestCase {

  let operationQueue = GSJOperationQueue()

  func testMutualExclusivity() {
    let operation1 = blockOperationWithDelay()
    let operation2 = blockOperationWithDelay()
    let operation3 = blockOperationWithDelay()

    let mutualExclusivityCondition = MutuallyExclusive(primaryCategory: "TEST_CATEGORY",
                                                       subCategory: "FOO")
    operation1.addCondition(mutualExclusivityCondition)
    operation2.addCondition(mutualExclusivityCondition)
    operation3.addCondition(mutualExclusivityCondition)

    var operation1EndTime: TimeInterval = 0
    var operation2StartTime: TimeInterval = 0
    var operation2EndTime: TimeInterval = 0
    var operation3StartTime: TimeInterval = 0

    let expectation = self.expectation(description: "Last operation finished.")

    operation1.addObserver(BlockObserver(
      startHandler: nil,
      spawnHandler: nil,
      finishHandler: { (operation, error) in
        operation1EndTime = Date.timeIntervalSinceReferenceDate
      }))

    operation2.addObserver(BlockObserver(
      startHandler: { (operation) in
        operation2StartTime = Date.timeIntervalSinceReferenceDate
      },
      spawnHandler: nil,
      finishHandler: { (operation, error) in
        operation2EndTime = Date.timeIntervalSinceReferenceDate
      }))

    operation3.addObserver(BlockObserver(
      startHandler: { (operation) in
        operation3StartTime = Date.timeIntervalSinceReferenceDate
      },
      spawnHandler: nil,
      finishHandler: { (operation, error) in
        expectation.fulfill()
      }))

    operationQueue.addOperation(operation1)
    operationQueue.addOperation(operation2)
    operationQueue.addOperation(operation3)

    waitForExpectations(timeout: 1)

    XCTAssertTrue(operation2StartTime > operation1EndTime)
    XCTAssertTrue(operation3StartTime > operation2EndTime)
  }

  func blockOperationWithDelay() -> GSJBlockOperation {
    return GSJBlockOperation { continuation in
      DispatchQueue.global().asyncAfter(deadline: .now() + 0.1, execute: {
        continuation()
      })
    }
  }

}
