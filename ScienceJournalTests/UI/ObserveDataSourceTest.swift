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

class ObserveDataSourceTest: XCTestCase {

  func testSensorCardForSensor() {
    // Create some sensors.
    let sensor1 = Sensor.mock(sensorId: "TestSensorID1",
                              name: "TestSensorName1",
                              textDescription: "Test description 1.",
                              iconName: "test icon 1")
    let sensor2 = Sensor.mock(sensorId: "TestSensorID2",
                              name: "TestSensorName2",
                              textDescription: "Test description 2.",
                              iconName: "test icon 2")
    let sensor3 = Sensor.mock(sensorId: "TestSensorID3",
                              name: "TestSensorName3",
                              textDescription: "Test description 3.",
                              iconName: "test icon 3")

    // Create sensor cards for 2 of the sensors.
    let sensorCard1 = SensorCard(sensor: sensor1, colorPalette: .blue)
    let sensorCard2 = SensorCard(sensor: sensor2, colorPalette: .green)

    // Create an observe data source, and add the two sensor cards. The mock sensor controller
    // should have no available sensors, so that `count` does not add 1, accounting for a footer
    // cell.
    let mockSensorController = MockSensorController()
    let observeDataSource = ObserveDataSource(sensorController: mockSensorController)
    observeDataSource.addItem(sensorCard1)
    observeDataSource.addItem(sensorCard2)

    XCTAssertEqual(observeDataSource.numberOfItemsInSection(0), 2,
                   "The observe data source count should be the same as the number of sensor " +
                       "cards added.")

    XCTAssertEqual(observeDataSource.sensorCard(for: sensor1), sensorCard1,
                   "The sensor card returned should be the one added for the passed sensor.")
    XCTAssertEqual(observeDataSource.sensorCard(for: sensor2), sensorCard2,
                   "The sensor card returned should be the one added for the passed sensor.")

    XCTAssertNil(observeDataSource.sensorCard(for: sensor3),
                 "Nil should be returned for a sensor that did not have a sensor card added.")

    // Remove a sensor card.
    observeDataSource.removeItem(sensorCard1)

    XCTAssertNil(observeDataSource.sensorCard(for: sensor1),
                 "Nil should be returned for a sensor if its sensor card was removed.")
  }

}
