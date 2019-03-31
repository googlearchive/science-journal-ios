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
@testable import ScienceJournalProtos

class TriggerNoteTest: XCTestCase {

  func testSensorSpec() {
    let sensorSpec =
        SensorSpec(sensor: Sensor.mock(sensorId: "test sensor ID",
                                       name: "test sensor name",
                                       textDescription: "test sensor description",
                                       iconName: "test sensor icon name"))
    sensorSpec.gadgetInfo.providerID = "test provider ID"

    let triggerNote = TriggerNote()
    triggerNote.sensorSpec = sensorSpec
    XCTAssertEqual(triggerNote.sensorSpec?.gadgetInfo.providerID,
                   sensorSpec.gadgetInfo.providerID,
                   "The provider ID of the trigger note's sensor spec should equal the sensor " +
                       "spec's provider ID.")
    let value = try! GSJSensorTriggerLabelValue(data: triggerNote.proto.protoData)
    XCTAssertEqual(value.sensor.info.providerId,
                   sensorSpec.gadgetInfo.providerID,
                   "The provider ID of the trigger note's sensor spec should equal the sensor " +
                       "spec's provider ID.")
  }

  func testTriggerInformation() {
    let triggerInformation = TriggerInformation()
    triggerInformation.noteText = "test trigger note text"

    let triggerNote = TriggerNote()
    triggerNote.triggerInformation = triggerInformation
    XCTAssertEqual(triggerNote.triggerInformation?.noteText,
                   triggerInformation.noteText,
                   "The note text of the trigger note's trigger information should equal the " +
                       "trigger information's note text.")
    let value = try! GSJSensorTriggerLabelValue(data: triggerNote.proto.protoData)
    XCTAssertEqual(value.triggerInformation.noteText,
                   triggerInformation.noteText,
                   "The note text of the trigger note's trigger information should equal the " +
                       "trigger information's note text.")
  }

  func testTimestamp() {
    let sensorSpec =
        SensorSpec(sensor: Sensor.mock(sensorId: "test sensor ID",
                                       name: "test sensor name",
                                       textDescription: "test sensor description",
                                       iconName: "test sensor icon name"))
    let triggerNote = TriggerNote(sensorSpec: sensorSpec,
                                  triggerInformation: TriggerInformation(),
                                  timestamp: 234)
    XCTAssertEqual(triggerNote.timestamp, 234)
  }

}
