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

  func testQueueIsSerial() {
    let queue = GSJOperationQueue()
    XCTAssertNotEqual(queue.maxConcurrentOperationCount, 1)

    _ = LaunchManager(queue: queue)

    XCTAssertEqual(queue.maxConcurrentOperationCount, 1)
  }

  func testCompletionIsCalledBeforeRunningStateIsSet() {
    let manager = LaunchManager()

    let e = expectation(description: "")
    manager.performLaunchOperations { completionState in
      XCTAssertEqual(manager.state, .launching)
      XCTAssertEqual(completionState, .success)
      e.fulfill()
    }
    waitForExpectations(timeout: 0.1)

    XCTAssertEqual(manager.state, .completed(.success))
  }

  func testCompletionIsCalledBeforeFailedStateIsSet() {
    let manager = LaunchManager(operations: [FailingOperation()])

    let e = expectation(description: "")
    manager.performLaunchOperations { completionState in
      XCTAssertEqual(manager.state, .launching)
      XCTAssertEqual(completionState, .failure)
      e.fulfill()
    }
    waitForExpectations(timeout: 0.1)

    XCTAssertEqual(manager.state, .completed(.failure))
  }

  func testStandardOperations() {
    let manager = LaunchManager.standard

    XCTAssertEqual(manager.operations.count, 1)
    XCTAssert(manager.operations.first is FileSystemLayoutMigrationOperation,
              "expected an instance of FileSystemLayoutMigrationOperation")
  }

  class FailingOperation: GSJOperation {
    enum Error: Swift.Error {
      case test
    }
    override func execute() {
      finish(withErrors: [Error.test])
    }
  }

}
