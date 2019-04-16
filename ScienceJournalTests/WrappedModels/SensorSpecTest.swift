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

class SensorSpecTest: XCTestCase {

  func testInitWithBuiltInSensor() {
    let sensor = Sensor.mock(sensorId: "sensor ID",
                             name: "sensor name",
                             textDescription: "sensor description",
                             iconName: "sensor icon name",
                             unitDescription: "sensor units")
    sensor.pointsAfterDecimal = 3
    let sensorSpec = SensorSpec(sensor: sensor)
    XCTAssertEqual(sensorSpec.rememberedAppearance.locale, Locale.current.identifier)
    XCTAssertEqual(sensorSpec.rememberedAppearance.name, sensor.name)
    XCTAssertEqual(sensorSpec.rememberedAppearance.units, sensor.unitDescription)
    XCTAssertEqual(sensorSpec.rememberedAppearance.shortDescription, sensor.textDescription)
    XCTAssertEqual(sensorSpec.rememberedAppearance.pointsAfterDecimal, sensor.pointsAfterDecimal)
    XCTAssertEqual(sensorSpec.rememberedAppearance.iconPath?.pathString, sensor.sensorId)
    XCTAssertEqual(sensorSpec.rememberedAppearance.iconPath?.type, .builtin)
    XCTAssertEqual(sensorSpec.gadgetInfo.providerID,
                   "com.google.android.apps.forscience.whistlepunk.hardware")
    XCTAssertEqual(sensorSpec.gadgetInfo.address, sensor.sensorId)
    XCTAssertEqual(sensorSpec.gadgetInfo.hostID, UIDevice.current.identifierForVendor!.uuidString)
    XCTAssertEqual(sensorSpec.gadgetInfo.hostDescription, UIDevice.deviceType)
    XCTAssertEqual(sensorSpec.gadgetInfo.platform, .ios)
  }

  func testInitWithBluetoothSensor() {
    let interface = TestSensorInterface(identifier: "TEST IDENTIFIER")
    let bluetoothSensor = BluetoothSensor(sensorInterface: interface,
                                          sensorTimer: UnifiedSensorTimer())
    let sensorSpec = SensorSpec(sensor: bluetoothSensor)
    XCTAssertEqual(sensorSpec.gadgetInfo.address, interface.identifier)
    XCTAssertEqual(sensorSpec.gadgetInfo.providerID, interface.providerId)
    XCTAssertEqual(sensorSpec.rememberedAppearance.name, interface.name)
    XCTAssertNil(sensorSpec.rememberedAppearance.iconPath?.pathString)
    XCTAssertEqual(sensorSpec.rememberedAppearance.iconPath?.type, .proto)
    XCTAssertEqual(sensorSpec.rememberedAppearance.units, interface.unitDescription)
    XCTAssertEqual(sensorSpec.rememberedAppearance.shortDescription, interface.textDescription)
    XCTAssertEqual(sensorSpec.gadgetInfo.hostID, UIDevice.current.identifierForVendor!.uuidString)
    XCTAssertEqual(sensorSpec.gadgetInfo.hostDescription, UIDevice.deviceType)
    XCTAssertEqual(sensorSpec.gadgetInfo.platform, .ios)
  }

}
