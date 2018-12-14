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

class ElapsedTimeEventManagerTest: XCTestCase {

  var elapsedTimeEventManager: ElapsedTimeEventManager!
  var eventExpectation: XCTestExpectation?
  var eventCallCount = 0
  let settableClock = SettableClock(now: 10000)
  var userInfo: Any?

  override func setUp() {
    super.setUp()
    elapsedTimeEventManager = ElapsedTimeEventManager(clock: settableClock,
                                                      timeIntervalBetweenEvents: 2,
                                                      event: { (userInfo) in
      self.eventCallCount += 1
      self.userInfo = userInfo
      self.eventExpectation?.fulfill()
    })
  }

  func testPerformEventForcedAlwaysAllows() {
    // The event should always be allowed.
    elapsedTimeEventManager.performEventIfAllowed(forced: true)
    XCTAssertEqual(1, eventCallCount)

    elapsedTimeEventManager.performEventIfAllowed(forced: true)
    XCTAssertEqual(2, eventCallCount)

    elapsedTimeEventManager.performEventIfAllowed(forced: true)
    XCTAssertEqual(3, eventCallCount)

    settableClock.setNow(10500)
    elapsedTimeEventManager.performEventIfAllowed(forced: true)
    XCTAssertEqual(4, eventCallCount)
  }

  func testShouldAllowFirstEvent() {
    // The event should be allowed if none have been performed before.
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)
  }

  func testShouldAllowEventWhenIntervalPassed() {
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)

    // Set the clock so it will be allowed to be performed again.
    settableClock.setNow(12000)
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(2, eventCallCount)
  }

  func testShouldNotAllowEventWhenIntervalHasNotPassed() {
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)

    // Set the clock so it will not be allowed to be performed again.
    settableClock.setNow(10500)
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)
  }

  func testShouldPerformEventAfterIntervalIfNotAllowed() {
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)

    // Try to perform the event again. It won't be called right away, but will be called after the
    // time interval expires.
    eventExpectation = expectation(description: "The event should be allowed.")
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)
    waitForExpectations(timeout: 3)
    XCTAssertEqual(2, eventCallCount)
  }

  func testShouldAllowEventAfterReset() {
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(1, eventCallCount)

    // Set the clock so it wouldn't be allowed to be performed again, but also call reset.
    settableClock.setNow(11000)
    elapsedTimeEventManager.reset()
    elapsedTimeEventManager.performEventIfAllowed()
    XCTAssertEqual(2, eventCallCount)
  }

  func testUserInfo() {
    // Perform the event and make sure user infos match.
    let userInfoString = "testUserInfo"
    elapsedTimeEventManager.performEventIfAllowed(userInfo: userInfoString)
    XCTAssertEqual(1, eventCallCount)
    XCTAssertEqual(userInfo as! String, userInfoString)

    // Try to perform the event again. It won't be called right away, but will be called after the
    // time interval expires. At that point, make sure the user infos match.
    let userInfoInt = 4
    eventExpectation = expectation(description: "The event should be allowed.")
    elapsedTimeEventManager.performEventIfAllowed(userInfo: userInfoInt)
    XCTAssertEqual(1, eventCallCount)
    waitForExpectations(timeout: 3)
    XCTAssertEqual(2, eventCallCount)
    XCTAssertEqual(userInfo as! Int, userInfoInt)
  }

  func testDefaultAutoFireUserInfo() {
    elapsedTimeEventManager.defaultAutoFireUserInfo = "defaultUserInfo"

    // Perform the event and make sure user infos match.
    let userInfoString = "testUserInfo"
    elapsedTimeEventManager.performEventIfAllowed(userInfo: userInfoString)
    XCTAssertEqual(1, eventCallCount)
    XCTAssertEqual(userInfo as! String, userInfoString)

    // Try to perform the event again. It won't be called right away, but will be called after the
    // time interval expires. At that point, make sure the user info matches the default.
    eventExpectation = expectation(description: "The event should be allowed.")
    elapsedTimeEventManager.performEventIfAllowed(userInfo: userInfoString)
    XCTAssertEqual(1, eventCallCount)
    waitForExpectations(timeout: 3)
    XCTAssertEqual(2, eventCallCount)
    XCTAssertEqual(userInfo as! String, elapsedTimeEventManager.defaultAutoFireUserInfo as! String)
  }

}
