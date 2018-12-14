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

class SensorTriggerTest: XCTestCase {

  func testSensorId() {
    let sensorTrigger = SensorTrigger(sensorID: "test sensor ID")
    XCTAssertEqual(sensorTrigger.sensorID, "test sensor ID")
    XCTAssertEqual(sensorTrigger.proto.sensorId, "test sensor ID")
  }

  func testLastUsedMs() {
    let sensorTrigger = SensorTrigger(sensorID: "test sensor ID")
    sensorTrigger.lastUsedDate = Date(milliseconds: 123)
    XCTAssertEqual(sensorTrigger.lastUsedDate, Date(milliseconds: 123))
    XCTAssertEqual(sensorTrigger.proto.lastUsedMs, 123)
  }

  func testTriggerInformation() {
    let triggerInformation = TriggerInformation()
    triggerInformation.noteText = "test note text"

    let sensorTrigger = SensorTrigger(sensorID: "test sensor ID")
    sensorTrigger.triggerInformation = triggerInformation
    XCTAssertEqual(sensorTrigger.triggerInformation.noteText, triggerInformation.noteText)
    XCTAssertEqual(sensorTrigger.proto.triggerInformation.noteText, triggerInformation.noteText)
  }

  func testTriggerId() {
    let sensorTrigger = SensorTrigger(sensorID: "test sensor ID")
    sensorTrigger.triggerID = "test trigger ID"
    XCTAssertEqual(sensorTrigger.triggerID, "test trigger ID")
    XCTAssertEqual(sensorTrigger.proto.triggerId, "test trigger ID")
  }

  func testIsVisualTrigger() {
    // Set up a new trigger.
    let trigger = SensorTrigger(sensorID: "test trigger")
    XCTAssertFalse(trigger.isVisualTrigger,
                   "Triggers with no trigger information set are not visual triggers.")

    trigger.triggerInformation.triggerActionType = .triggerActionAlert
    XCTAssertFalse(trigger.isVisualTrigger,
                   "Triggers that are alert action, but not visual alert type are not visual " +
                       "triggers.")

    trigger.triggerInformation.triggerAlertTypes = [.triggerAlertVisual]
    XCTAssertTrue(trigger.isVisualTrigger,
                  "Triggers that are alert action and visual alert type are visual triggers.")

    trigger.triggerInformation.triggerActionType = .triggerActionNote
    XCTAssertFalse(trigger.isVisualTrigger,
                   "Triggers that are not alert action, but are visual alert type are not visual " +
                       "triggers.")
  }

}
