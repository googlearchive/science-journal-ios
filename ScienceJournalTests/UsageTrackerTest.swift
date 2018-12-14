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

class UsageTrackerTest: XCTestCase {

  func testAddAndRemoveUsers() {
    let usageTracker = UsageTracker()

    // Create an object and add it to the usage tracker, then remove it.
    let anObject = MockSensor(sensorId: "A")
    XCTAssertTrue(usageTracker.addUser(anObject), "Adding the first object should return true.")
    XCTAssertTrue(usageTracker.removeUser(anObject),
                  "Removing the last object should return true.")

    // Add the object twice.
    XCTAssertTrue(usageTracker.addUser(anObject), "Adding the first object should return true.")
    XCTAssertFalse(usageTracker.addUser(anObject), "Adding an object again should return false.")

    // Add another object.
    let anotherObject = MockSensor(sensorId: "B")
    XCTAssertFalse(usageTracker.addUser(anotherObject),
                   "Adding a second object should return false.")

    // Remove the objects.
    XCTAssertFalse(usageTracker.removeUser(anObject),
                   "Removing the original object should return false.")
    XCTAssertTrue(usageTracker.removeUser(anotherObject),
                  "Removing the last object should return true.")

    // Remove an object too many times, then add it.
    XCTAssertFalse(usageTracker.removeUser(anotherObject),
                   "Removing an object that is not a current user should return false.")
    XCTAssertFalse(usageTracker.removeUser(anotherObject),
                   "Removing an object that is not a current user should return false.")
    XCTAssertFalse(usageTracker.removeUser(anotherObject),
                   "Removing an object that is not a current user should return false.")
    XCTAssertFalse(usageTracker.removeUser(anotherObject),
                   "Removing an object that is not a current user should return false.")
    XCTAssertFalse(usageTracker.removeUser(anotherObject),
                   "Removing an object that is not a current user should return false.")
    XCTAssertTrue(usageTracker.addUser(anotherObject),
                  "Even if an object is removed multiple times, adding the it should return true.")
  }

}
