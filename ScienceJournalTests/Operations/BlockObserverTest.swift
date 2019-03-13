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

class BlockObserverTest: XCTestCase {

  let operationQueue = GSJOperationQueue()

  func testStartAndFinishHandlersNotCancelled() {
    let operation = TestOperation()

    let startExpectation = expectation(description: "start")
    let spawnExpectation = expectation(description: "spawn")
    let finishExpectation = expectation(description: "finish")

    let blockObserver = BlockObserver(startHandler: { (op) in
      startExpectation.fulfill()
    }, spawnHandler: { (op, spawnedOp) in
      XCTAssertEqual("SpawnedOperation", spawnedOp.name)
      spawnExpectation.fulfill()
    }) { (op, errors) in
      finishExpectation.fulfill()
    }

    operation.addObserver(blockObserver)

    operationQueue.addOperation(operation)

    waitForExpectations(timeout: 0.5)
  }

  func testStartAndFinishHandlersCancelled() {
    operationQueue.isSuspended = true

    let operation = TestOperation()

    let startExpectation = expectation(description: "start")
    let spawnExpectation = expectation(description: "spawn")
    let finishExpectation = expectation(description: "finish")

    startExpectation.isInverted = true
    spawnExpectation.isInverted = true

    let blockObserver = BlockObserver(startHandler: { (op) in
      startExpectation.fulfill()
    }, spawnHandler: { (op, spawnedOp) in
      spawnExpectation.fulfill()
    }) { (op, errors) in
      finishExpectation.fulfill()
    }
    operation.addObserver(blockObserver)
    operationQueue.addOperation(operation)

    operation.cancel()

    operationQueue.isSuspended = false

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - TestOperation

  class TestOperation: GSJOperation {
    override func execute() {
      let spawnedOperation = Operation()
      spawnedOperation.name = "SpawnedOperation"
      spawnOperation(spawnedOperation)
      finish()
    }
  }

}
