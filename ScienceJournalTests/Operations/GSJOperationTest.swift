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

class GSJOperationTest: XCTestCase {

  func testSimpleOperation() {
    let expectation = XCTestExpectation()

    let operation = SimpleOperation()
    operation.completionBlock = {
      XCTAssertTrue(operation.taskComplete)
      expectation.fulfill()
    }
    XCTAssertFalse(operation.taskComplete)

    let queue = GSJOperationQueue()
    queue.addOperation(operation)

    wait(for: [expectation], timeout: 1)
  }

  func testObservers() {
    let startExpectation = XCTestExpectation(description: "Start operation")
    let finishExpectation = XCTestExpectation(description: "Finish operation")

    let operation = SimpleOperation()
    let observer = BlockObserver(
        startHandler: { _ in
          XCTAssertFalse(operation.taskComplete)
          startExpectation.fulfill()
        },
        finishHandler: { (_, _) in
          XCTAssertTrue(operation.taskComplete)
          finishExpectation.fulfill()
        })
    operation.addObserver(observer)

    let queue = GSJOperationQueue()
    queue.addOperation(operation)

    wait(for: [startExpectation, finishExpectation], timeout: 1)
  }

  func testFailingCondition() {
    // A condition that fails with a dependenct operation that will execute only if it fails.
    let condition = PassFailCondition(shouldPass: false, dependency: nil)

    let finishExpectation = XCTestExpectation(description: "Operation finished")

    // A simple operation with the one condition.
    let operation = SimpleOperation()
    operation.completionBlock = {
      XCTAssertFalse(operation.taskComplete,
                     "Condition failure should prevent task from executing.")
      finishExpectation.fulfill()
    }
    operation.addCondition(condition)

    XCTAssertFalse(operation.taskComplete)

    let queue = GSJOperationQueue()
    queue.addOperation(operation)

    wait(for: [finishExpectation], timeout: 1)
  }

  func testPassingCondition() {
    // A condition that will always pass.
    let condition = PassFailCondition(shouldPass: true, dependency: nil)

    let finishExpectation = XCTestExpectation()

    let operation = SimpleOperation()
    operation.completionBlock = {
      XCTAssertTrue(operation.taskComplete,
                    "Condition failure should not prevent task from executing.")
      finishExpectation.fulfill()
    }
    operation.addCondition(condition)

    XCTAssertFalse(operation.taskComplete)

    let queue = GSJOperationQueue()
    queue.addOperation(operation)

    wait(for: [finishExpectation], timeout: 1)
  }

  func testConditionWithDependency() {
    let finishExpectation = XCTestExpectation(description: "Main operation finished")
    let dependencyFinishExpectation = XCTestExpectation(description: "Dependent operation finished")

    // A simple operation with the one condition.
    let operation = SimpleOperation()
    // The depenency added by a condition.
    let dependentOperation = SimpleOperation()

    // Condition dependencies are added regardless of the condition passing or failing.
    let condition = PassFailCondition(shouldPass: true, dependency: dependentOperation)
    operation.addCondition(condition)

    // Observe both operations so we know when they finish.
    let observer = BlockObserver { (op, _) in
      if op == operation {
        XCTAssertTrue(dependentOperation.taskComplete,
                      "Dependent operation should already be complete.")
        XCTAssertTrue(operation.taskComplete)
        finishExpectation.fulfill()
      } else if op == dependentOperation {
        XCTAssertTrue(dependentOperation.taskComplete, "Dependent operation should execute.")
        XCTAssertFalse(operation.taskComplete, "Main condition has not executed yet.")
        dependencyFinishExpectation.fulfill()
      }
    }
    operation.addObserver(observer)
    dependentOperation.addObserver(observer)

    XCTAssertFalse(operation.taskComplete)
    XCTAssertFalse(dependentOperation.taskComplete)

    let queue = GSJOperationQueue()
    queue.addOperation(operation)

    wait(for: [finishExpectation, dependencyFinishExpectation], timeout: 1)
  }

  func testCancelWithError() {
    let expectation = XCTestExpectation()
    let operation = SimpleOperation()
    operation.addObserver(BlockObserver { op, errors in
      XCTAssertEqual(1, errors.count)
      XCTAssertEqual(TestError.cancelled, errors[0] as! TestError)
      expectation.fulfill()
    })

    let queue = GSJOperationQueue()
    queue.addOperation(operation)
    operation.cancelWithError(TestError.cancelled)

    wait(for: [expectation], timeout: 1)
  }

  func testSpawnedOperation() {
    let spawnedExpectation = XCTestExpectation(description: "Spawned operation finished.")
    let originalExpectation = XCTestExpectation(description: "Original operation finished.")

    let spawnedOperation = SimpleOperation()
    let originalOperation = SpawningOperation(spawnedOperation: spawnedOperation)

    // Observe the execution so we can test order of execution and fulfill expectations.
    let observer = BlockObserver { (op, _) in
      if op == originalOperation {
        XCTAssertTrue(originalOperation.taskComplete)
        XCTAssertFalse(spawnedOperation.taskComplete)
        originalExpectation.fulfill()
      } else if op == spawnedOperation {
        XCTAssertTrue(originalOperation.taskComplete)
        XCTAssertTrue(spawnedOperation.taskComplete)
        spawnedExpectation.fulfill()
      }
    }
    originalOperation.addObserver(observer)
    spawnedOperation.addObserver(observer)

    let queue = GSJOperationQueue()
    queue.addOperation(originalOperation)

    wait(for: [originalExpectation, spawnedExpectation], timeout: 1)
  }

  // MARK: - Test Subclasses

  // An operation that spawns a new operation when it finishes.
  class SpawningOperation: SimpleOperation {
    var spawnedOperation: Operation

    init(spawnedOperation: Operation) {
      self.spawnedOperation = spawnedOperation
    }

    override func finished(withErrors errors: [Error]) {
      spawnOperation(spawnedOperation)
    }
  }

  enum TestError: Error {
    case testConditionFailed
    case cancelled
  }

  struct PassFailCondition: OperationCondition {
    var shouldPass: Bool
    var dependency: Operation?

    var exclusivityKey: String? { return nil }

    func dependencyForOperation(_ operation: GSJOperation) -> Operation? {
      return dependency
    }

    func evaluateForOperation(_ operation: GSJOperation,
                              completion: (OperationConditionResult) -> Void) {
      if shouldPass {
        completion(.passed)
      } else {
        completion(.failed(TestError.testConditionFailed))
      }
    }
  }

}
