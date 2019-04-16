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
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class TriggerInformationTest: XCTestCase {

  func testValueToTrigger() {
    let triggerInformation = TriggerInformation()
    triggerInformation.valueToTrigger = 7
    XCTAssertEqual(triggerInformation.valueToTrigger, 7)
    XCTAssertEqual(triggerInformation.proto.valueToTrigger, 7)
  }

  func testTriggerWhen() {
    let triggerInformation = TriggerInformation()
    triggerInformation.triggerWhen = .triggerWhenBelow
    XCTAssertEqual(triggerInformation.triggerWhen, .triggerWhenBelow)
    XCTAssertEqual(triggerInformation.proto.triggerWhen, .triggerWhenBelow)
  }

  func testTriggerActionType() {
    let triggerInformation = TriggerInformation()
    triggerInformation.triggerActionType = .triggerActionNote
    XCTAssertEqual(triggerInformation.triggerActionType, .triggerActionNote)
    XCTAssertEqual(triggerInformation.proto.triggerActionType, .triggerActionNote)
  }

  func testTriggerAlertTypes() {
    let triggerInformation = TriggerInformation()
    triggerInformation.triggerAlertTypes = [.triggerAlertVisual, .triggerAlertPhysical]
    XCTAssertEqual(triggerInformation.triggerAlertTypes,
                   [.triggerAlertVisual, .triggerAlertPhysical])
    var containsAudio = false
    var containsPhysical = false
    var containsVisual = false
    triggerInformation.proto.triggerAlertTypesArray.enumerateValues({ (value, index, stop) in
      let enumValue = GSJTriggerInformation_TriggerAlertType(rawValue: value)!
      switch enumValue {
      case .triggerAlertAudio:
        containsAudio = true
      case .triggerAlertPhysical:
        containsPhysical = true
      case .triggerAlertVisual:
        containsVisual = true
      }
    })
    XCTAssertFalse(containsAudio)
    XCTAssertTrue(containsPhysical)
    XCTAssertTrue(containsVisual)
  }

  func testNoteText() {
    let triggerInformation = TriggerInformation()
    triggerInformation.noteText = "test note text"
    XCTAssertEqual(triggerInformation.noteText, "test note text")
    XCTAssertEqual(triggerInformation.proto.noteText, "test note text")
  }

  func testTriggerOnlyWhenRecording() {
    let triggerInformation = TriggerInformation()
    triggerInformation.triggerOnlyWhenRecording = true
    XCTAssertTrue(triggerInformation.triggerOnlyWhenRecording)
    XCTAssertTrue(triggerInformation.proto.triggerOnlyWhenRecording)
  }


}
