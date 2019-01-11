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

@testable import third_party_objective_c_material_components_ios_components_Palettes_Palettes
@testable import third_party_sciencejournal_ios_ScienceJournalOpen
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class SensorLayoutTest: XCTestCase {

  func testProtoInput() {
    let proto = GSJSensorLayout()
    proto.sensorId = "123ABC"
    proto.audioEnabled = true
    proto.showStatsOverlay = true
    proto.colorIndex = 3
    proto.extras = NSMutableDictionary(dictionary: ["Test Key": "Test Value"])
    proto.minimumYaxisValue = 100
    proto.maximumYaxisValue = 9999
    proto.activeSensorTriggerIdsArray = NSMutableArray(array: ["1", "234", "5678"])
    // TODO: Set color once that is parsed correctly.

    let sensorLayout = SensorLayout(proto: proto)

    XCTAssertEqual("123ABC", sensorLayout.sensorID)
    XCTAssertTrue(sensorLayout.isAudioEnabled)
    XCTAssertTrue(sensorLayout.shouldShowStatsOverlay)
    XCTAssertEqual(MDCPalette.red, sensorLayout.colorPalette)
    XCTAssertEqual(["Test Key": "Test Value"], sensorLayout.extras)
    XCTAssertEqual(100, sensorLayout.visibleYAxis.min)
    XCTAssertEqual(9999, sensorLayout.visibleYAxis.max)
    XCTAssertEqual(["1", "234", "5678"], sensorLayout.activeSensorTriggerIDs)
  }

  func testProtoOutput() {
    let sensorLayout = SensorLayout(sensorID: "456DEF", colorPalette: .orange)
    sensorLayout.visibleYAxis = ChartAxis(min: -50, max: 50)
    sensorLayout.isAudioEnabled = true
    sensorLayout.shouldShowStatsOverlay = true
    sensorLayout.extras = ["Test Key": "Test Value"]
    sensorLayout.activeSensorTriggerIDs = ["A", "B", "C"]

    XCTAssertEqual("456DEF", sensorLayout.proto.sensorId)
    XCTAssertTrue(sensorLayout.proto.audioEnabled)
    XCTAssertTrue(sensorLayout.proto.showStatsOverlay)
    XCTAssertEqual(2, sensorLayout.proto.colorIndex)
    XCTAssertEqual(NSMutableDictionary(dictionary: ["Test Key": "Test Value"]),
                   sensorLayout.proto.extras)
    XCTAssertEqual(-50, sensorLayout.proto.minimumYaxisValue)
    XCTAssertEqual(50, sensorLayout.proto.maximumYaxisValue)
    XCTAssertEqual(["A", "B", "C"], sensorLayout.proto.activeSensorTriggerIdsArray)
  }

  func testActiveSensorTriggers() {
    let sensorLayout = SensorLayout(sensorID: "test sensor ID", colorPalette: .blue)
    sensorLayout.activeSensorTriggerIDs = ["A", "B", "C"]

    XCTAssertTrue(sensorLayout.isTriggerActive("A"))
    XCTAssertTrue(sensorLayout.isTriggerActive("B"))
    XCTAssertTrue(sensorLayout.isTriggerActive("C"))
    XCTAssertFalse(sensorLayout.isTriggerActive("D"))
  }

  func testEquality() {
    let sensorLayout1 = SensorLayout(sensorID: "SENSOR 1", colorPalette: .blue)
    sensorLayout1.visibleYAxis = ChartAxis(min: 10, max: 20)
    sensorLayout1.isAudioEnabled = true
    sensorLayout1.shouldShowStatsOverlay = true
    sensorLayout1.extras = ["foo": "bar"]
    sensorLayout1.activeSensorTriggerIDs = ["A", "B", "C"]

    let sensorLayout2 = SensorLayout(sensorID: "SENSOR 1", colorPalette: .blue)
    sensorLayout2.visibleYAxis = ChartAxis(min: 10, max: 20)
    sensorLayout2.isAudioEnabled = true
    sensorLayout2.shouldShowStatsOverlay = true
    sensorLayout2.extras = ["foo": "bar"]
    sensorLayout2.activeSensorTriggerIDs = ["A", "B", "C"]

    XCTAssertEqual(sensorLayout1, sensorLayout1)
    XCTAssertEqual(sensorLayout1, sensorLayout2)

    let sensorLayout3 = SensorLayout(sensorID: "SENSOR 2", colorPalette: .green)
    sensorLayout3.visibleYAxis = ChartAxis(min: 20, max: 30)
    XCTAssertEqual(sensorLayout3, sensorLayout3)
    XCTAssertNotEqual(sensorLayout1, sensorLayout3)

    XCTAssertEqual([sensorLayout1, sensorLayout2, sensorLayout3],
                   [sensorLayout1, sensorLayout2, sensorLayout3])
    XCTAssertNotEqual([sensorLayout1, sensorLayout3],
                      [sensorLayout1, sensorLayout2, sensorLayout3])
  }

  func testCopySensorLayout() {
    let sensorLayout1 = SensorLayout(sensorID: "SENSOR 1", colorPalette: .blue)
    sensorLayout1.visibleYAxis = ChartAxis(min: 99, max: 199)
    let sensorLayout2 = SensorLayout(proto: sensorLayout1.proto)
    XCTAssertTrue(sensorLayout1 == sensorLayout2)
    XCTAssertFalse(sensorLayout1 === sensorLayout2)
    XCTAssertFalse(sensorLayout1.proto === sensorLayout2.proto)
  }

}
