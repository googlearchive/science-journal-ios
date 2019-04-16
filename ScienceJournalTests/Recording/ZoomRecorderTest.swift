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

class ZoomRecorderTest: XCTestCase {

  func testZoomLevel() {
    let zoomRecorder = ZoomRecorder(
        sensorID: "SENSOR_ID",
        trialID: "TRIAL_ID",
        bufferSize: 5,
        addingDataPointBlock: { (_, _, _, _) in
          // Just testing the number of tiers the zoom recorder makes, don't need to write data.
    })

    XCTAssertEqual(1, zoomRecorder.tierCount)
    for i: Int64 in 0...27 {
      zoomRecorder.addDataPoint(dataPoint: DataPoint(x: i, y: Double(i)))
    }
    XCTAssertEqual(3, zoomRecorder.tierCount)
  }

  func testMinMaxRecording() {
    // A struct to record the information ZoomRecorder reports.
    struct TestSensorData {
      var dataPoint: DataPoint
      var sensorID: String
      var trialID: String
      var resolutionTier: Int16
    }

    var zoomRecordedPoints = [TestSensorData]()
    let zoomRecorder = ZoomRecorder(
        sensorID: "MINMAX_SENSOR_ID",
        trialID: "TRIAL_ID",
        bufferSize: 4,
        addingDataPointBlock: { (dataPoint, sensorID, trialID, tier) in
          zoomRecordedPoints.append(TestSensorData(dataPoint: dataPoint,
                                                   sensorID: sensorID,
                                                   trialID: trialID,
                                                   resolutionTier: tier))
    })

    zoomRecorder.addDataPoint(dataPoint: DataPoint(x: 1, y: 4))
    zoomRecorder.addDataPoint(dataPoint: DataPoint(x: 2, y: -2))
    zoomRecorder.addDataPoint(dataPoint: DataPoint(x: 3, y: 10))
    zoomRecorder.addDataPoint(dataPoint: DataPoint(x: 4, y: 3))

    // A buffer size of 4 should result in 2 data points for every 4 added.
    XCTAssertEqual(2, zoomRecordedPoints.count)
    XCTAssertEqual(1, zoomRecordedPoints[0].resolutionTier)
    XCTAssertEqual(1, zoomRecordedPoints[1].resolutionTier)
    XCTAssertEqual(-2, zoomRecordedPoints[0].dataPoint.y)
    XCTAssertEqual(10, zoomRecordedPoints[1].dataPoint.y)
  }

}

