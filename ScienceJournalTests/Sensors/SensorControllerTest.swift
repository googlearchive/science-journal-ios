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

class SensorControllerTest: XCTestCase {

  func testAddingDuplicateBluetoothSensor() {
    let sensorController = SensorController()
    XCTAssertEqual(0, sensorController.bluetoothSensorCount)

    let interface = TestSensorInterface(identifier: "INTERFACE 1")
    let sensor = BluetoothSensor(sensorInterface: interface, sensorTimer: UnifiedSensorTimer())
    sensorController.addOrUpdateBluetoothSensor(sensor)
    XCTAssertEqual(1, sensorController.bluetoothSensors.count)

    sensorController.addOrUpdateBluetoothSensor(sensor)
    XCTAssertEqual(1,
                   sensorController.bluetoothSensorCount,
                   "The same sensor added again should not add a new sensor instance.")

    let interface2 = TestSensorInterface(identifier: "INTERFACE 2")
    let sensor2 = BluetoothSensor(sensorInterface: interface2, sensorTimer: UnifiedSensorTimer())
    sensorController.addOrUpdateBluetoothSensor(sensor2)
    XCTAssertEqual(2, sensorController.bluetoothSensorCount)
  }

}
