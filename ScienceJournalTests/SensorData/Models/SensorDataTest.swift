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

class SensorDataTest: XCTestCase {

  var sensorDataManager: SensorDataManager!

  override func setUp() {
    super.setUp()

    sensorDataManager = createSensorDataManager()
  }

  func testStartEndTimestamps() {
    let dataPoints = [DataPoint(x: 0, y: 0),
                      DataPoint(x: 10, y: 1),
                      DataPoint(x: 20, y: 2),
                      DataPoint(x: 30, y: 3),
                      DataPoint(x: 40, y: 4),]

    // Add data points.
    sensorDataManager.performChanges(andWait: true, save: true) {
      for dataPoint in dataPoints {
        SensorData.insert(dataPoint: dataPoint,
                          forSensorID: "SENSOR_DATA_TEST_ID",
                          trialID: "SENSOR_DATA_TEST_TRIAL_ID",
                          resolutionTier: 0,
                          context: self.sensorDataManager.mainContext)
      }
    }

    // Fetch with start/end that excludes some and matches some data points
    let expectation = XCTestExpectation()
    sensorDataManager.performChanges(andWait: true) {
      self.sensorDataManager.fetchSensorData(forSensorID: "SENSOR_DATA_TEST_ID",
                                             trialID: "SENSOR_DATA_TEST_TRIAL_ID",
                                             resolutionTier: 0,
                                             startTimestamp: 10,
                                             endTimestamp: 30) { (sensorData) in
        XCTAssertNotNil(sensorData)
        XCTAssertEqual(3, sensorData!.count)
        XCTAssertEqual(10, sensorData![0].x)
        XCTAssertEqual(20, sensorData![1].x)
        XCTAssertEqual(30, sensorData![2].x)
        expectation.fulfill()
      }
    }
    wait(for: [expectation], timeout: 10)
  }

}
