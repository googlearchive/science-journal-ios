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

class TrialDataWriterTest: XCTestCase {

  var sensorDataManager: SensorDataManager!

  override func setUp() {
    super.setUp()

    sensorDataManager = createSensorDataManager()
  }

  func testWritingNonRelativeTimestamps() {
    // Sensor 1
    let sensor1dataPoints = [DataPoint(x: 500, y: 0),
                             DataPoint(x: 600, y: 1),
                             DataPoint(x: 700, y: 2),
                             DataPoint(x: 800, y: 3)]

    // Sensor 2
    let sensor2dataPoints = [DataPoint(x: 550, y: 0),
                             DataPoint(x: 650, y: 1),
                             DataPoint(x: 700, y: 2),
                             DataPoint(x: 850, y: 3)]

    sensorDataManager.performChanges(andWait: true, save: true) {
      sensor1dataPoints.forEach {
        SensorData.insert(dataPoint: $0,
                          forSensorID: "SENSOR_1_ID",
                          trialID: "CSV_TRIAL_ID",
                          resolutionTier: 0,
                          context: self.sensorDataManager.mainContext)
      }
      sensor2dataPoints.forEach {
        SensorData.insert(dataPoint: $0,
                          forSensorID: "SENSOR_2_ID",
                          trialID: "CSV_TRIAL_ID",
                          resolutionTier: 0,
                          context: self.sensorDataManager.mainContext)
      }
    }

    let trialWriter = TrialDataWriter(trialID: "CSV_TRIAL_ID",
                                      filename: "TEST.csv",
                                      isRelativeTime: false,
                                      sensorIDs: ["SENSOR_1_ID", "SENSOR_2_ID"],
                                      range: ChartAxis<Int64>(min: 500, max: 850),
                                      sensorDataManager: sensorDataManager)!

    let expectation = XCTestExpectation(description: "Trial write complete")

    trialWriter.write(progress: {_ in }) { (success) in
      XCTAssertTrue(success)

      let fileContents = try! String(contentsOf: trialWriter.fileURL)

      let expectedContents = "timestamp,SENSOR_1_ID,SENSOR_2_ID\n" +
          "500,0.0,\n" +
          "550,,0.0\n" +
          "600,1.0,\n" +
          "650,,1.0\n" +
          "700,2.0,2.0\n" +  // Both sensors had a value at 700 so there should only be one 700 row.
          "800,3.0,\n" +
          "850,,3.0\n"

      XCTAssertEqual(expectedContents, fileContents)

      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2)
  }

  func testWritingRelativeTimestamps() {
    let sensorDataPoints = [DataPoint(x: 900, y: 0),
                            DataPoint(x: 1000, y: 1),
                            DataPoint(x: 1100, y: 2),
                            DataPoint(x: 1200, y: 3)]

    sensorDataManager.performChanges(andWait: true, save: true) {
      sensorDataPoints.forEach {
        SensorData.insert(dataPoint: $0,
                          forSensorID: "CSV_SENSOR_ID",
                          trialID: "CSV_TRIAL_ID",
                          resolutionTier: 0,
                          context: self.sensorDataManager.mainContext)
      }
    }

    let trialWriter = TrialDataWriter(trialID: "CSV_TRIAL_ID",
                                      filename: "TEST.csv",
                                      isRelativeTime: true,
                                      sensorIDs: ["CSV_SENSOR_ID"],
                                      range: ChartAxis<Int64>(min: 900, max: 1200),
                                      sensorDataManager: sensorDataManager)!

    let expectation = XCTestExpectation(description: "Trial write complete")

    trialWriter.write(progress: {_ in }) { (success) in
      XCTAssertTrue(success)

      let fileContents = try! String(contentsOf: trialWriter.fileURL)

      let expectedContents = "relative_time,CSV_SENSOR_ID\n" +
          "0,0.0\n" +
          "100,1.0\n" +
          "200,2.0\n" +  // Both sensors had a value at 700 so there should only be one 700 row.
          "300,3.0\n"

      XCTAssertEqual(expectedContents, fileContents)

      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2)
  }

  func testWritingUnknownSensorIDs() {
    // Sensor 1
    let sensor1dataPoints = [DataPoint(x: 100, y: 0),
                             DataPoint(x: 200, y: 1),
                             DataPoint(x: 300, y: 2),
                             DataPoint(x: 400, y: 3)]

    // Sensor 2
    let sensor2dataPoints = [DataPoint(x: 150, y: 0),
                             DataPoint(x: 250, y: 1),
                             DataPoint(x: 350, y: 2)]

    sensorDataManager.performChanges(andWait: true, save: true) {
      sensor1dataPoints.forEach {
        SensorData.insert(dataPoint: $0,
                          forSensorID: "SENSOR_1_ID",
                          trialID: "CSV_TRIAL_ID",
                          resolutionTier: 0,
                          context: self.sensorDataManager.mainContext)
      }
      sensor2dataPoints.forEach {
        SensorData.insert(dataPoint: $0,
                          forSensorID: "SENSOR_2_ID",
                          trialID: "CSV_TRIAL_ID",
                          resolutionTier: 0,
                          context: self.sensorDataManager.mainContext)
      }
    }

    let trialWriter = TrialDataWriter(trialID: "CSV_TRIAL_ID",
                                      filename: "TEST.csv",
                                      isRelativeTime: false,
                                      sensorIDs: ["SENSOR_1_ID"],  // Only one of the sensors.
                                      range: ChartAxis<Int64>(min: 100, max: 400),
                                      sensorDataManager: sensorDataManager)!

    let expectation = XCTestExpectation(description: "Trial write complete")

    trialWriter.write(progress: {_ in }) { (success) in
      XCTAssertTrue(success)

      let fileContents = try! String(contentsOf: trialWriter.fileURL)

      let expectedContents = "timestamp,SENSOR_1_ID\n" +
        "100,0.0\n" +
        "200,1.0\n" +
        "300,2.0\n" +  // Both sensors had a value at 700 so there should only be one 700 row.
        "400,3.0\n"

      XCTAssertEqual(expectedContents, fileContents)

      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2)
  }

}
