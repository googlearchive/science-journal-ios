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

class UnifiedSensorTimerTest: XCTestCase {

  // MARK: - Nested types

  /// A mock sensor that has an expectation that is fulfilled when
  /// `callListenerBlocksWithDataCalled()` is called, and a block called with the most recent
  /// timestamp at which it is called.
  class MockSensor: Sensor {

    var callListenerBlocksWithDataCalledExpectation = XCTestExpectation()

    var timestampBlock: ((Int64) -> ())?

    init(unifiedSensorTimer: UnifiedSensorTimer, timestampBlock: ((Int64) -> ())? = nil) {
      super.init(sensorId: "",
                 name: "",
                 textDescription: "",
                 iconName: "",
                 animatingIconView: SensorAnimationView(),
                 unitDescription: nil,
                 learnMore: LearnMore(firstParagraph: "", secondParagraph: "", imageName: ""),
                 sensorTimer: unifiedSensorTimer)
      self.timestampBlock = timestampBlock
      isSupported = true
    }

    override func start() {}

    override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
      timestampBlock?(milliseconds)
      callListenerBlocksWithDataCalledExpectation.fulfill()
    }

  }

  // MARK: - Properties

  let unifiedSensorTimer = UnifiedSensorTimer()

  // MARK: - Test cases

  func testAddedSensorIsCalled() {
    // A sensor should be called to update data by its unified sensor timer.
    let sensor = MockSensor(unifiedSensorTimer: unifiedSensorTimer)
    sensor.addListener(self, using: { _ in })
    wait(for: [sensor.callListenerBlocksWithDataCalledExpectation], timeout: 1)
  }

  func testSensorsCalledWithSameTimestamp() {
    // Each time sensors are called to update data, they should be called with the same timestamp.
    var sensors = [Sensor]()
    var timestamps = [Int: Int64]()
    for key in 1...10 {
      let sensor = MockSensor(unifiedSensorTimer: unifiedSensorTimer) {
        timestamps[key] = $0
      }
      sensor.addListener(self, using: { _ in })
      sensors.append(sensor)
      wait(for: [sensor.callListenerBlocksWithDataCalledExpectation], timeout: 1)
    }
    XCTAssertEqual(sensors.count, timestamps.count, "There should be a timestamp per sensor.")
    timestamps.forEach {
      XCTAssertEqual(timestamps.first!.value, $0.value, "All timestamps should be equal.")
    }
  }

}
