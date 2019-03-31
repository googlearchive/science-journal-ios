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
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class TrialStatsAdjusterTest: XCTestCase {

  let sensorDataManager = SensorDataManager.testStore

  override func tearDown() {
    sensorDataManager.performChanges {
      self.sensorDataManager.mainContext.rollback()
    }
    super.tearDown()
  }

  func testRecalculateStats() {
    let sensorLayout2 = SensorLayout(proto: GSJSensorLayout())
    sensorLayout2.sensorID = "TEST_ID_2"
    let sensorLayout3 = SensorLayout(proto: GSJSensorLayout())
    sensorLayout3.sensorID = "TEST_ID_3"

    let trial = Trial()
    trial.ID = "TRIAL_ID"
    trial.sensorLayouts = [sensorLayout2, sensorLayout3]

    var sensorData = [SensorData]()
    sensorDataManager.performChanges(andWait: true) {
      for index: Int64 in 0...9 {
        let data1 = SensorData.insert(dataPoint: DataPoint(x: index, y: Double(index * 3)),
                                      forSensorID: "TEST_ID_1",
                                      trialID: "TRIAL_ID",
                                      resolutionTier: 0,
                                      context: self.sensorDataManager.mainContext)
        sensorData.append(data1)

        let data2 = SensorData.insert(dataPoint: DataPoint(x: index, y: Double(index * 10)),
                                      forSensorID: "TEST_ID_2",
                                      trialID: "TRIAL_ID",
                                      resolutionTier: 0,
                                      context: self.sensorDataManager.mainContext)
        sensorData.append(data2)

        let data3 = SensorData.insert(dataPoint: DataPoint(x: index, y: Double(index)),
                                      forSensorID: "TEST_ID_3",
                                      trialID: "TRIAL_ID",
                                      resolutionTier: 0,
                                      context: self.sensorDataManager.mainContext)
        sensorData.append(data3)
      }
    }

    let expectation = XCTestExpectation()

    let statsAdjuster = TrialStatsAdjuster(trial: trial, sensorData: sensorData)
    statsAdjuster.recalculateStats { (trialStats) in

      XCTAssertEqual(2, trialStats.count)

      let stats2Index = trialStats.firstIndex(where: { $0.sensorID == "TEST_ID_2" })
      XCTAssertNotNil(stats2Index)
      if let index = stats2Index {
        XCTAssertEqual(0, trialStats[index].minimumValue!)
        XCTAssertEqual(90, trialStats[index].maximumValue!)
      }

      let stats3Index = trialStats.firstIndex(where: { $0.sensorID == "TEST_ID_3" })
      XCTAssertNotNil(stats3Index)
      if let index = stats3Index {
        XCTAssertEqual(0, trialStats[index].minimumValue!)
        XCTAssertEqual(9, trialStats[index].maximumValue!)
      }

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)
  }

  func testPreservesZoomInformation() {
    let trial = Trial()
    let sensorLayout = SensorLayout(sensorID: "SENSOR_ID", colorPalette: .blue)
    trial.sensorLayouts = [sensorLayout]
    let stats = TrialStats(sensorID: "SENSOR_ID")
    stats.zoomLevelBetweenTiers = 50
    stats.zoomPresenterTierCount = 13
    stats.maximumValue = 999
    stats.minimumValue = 111
    stats.averageValue = 555
    trial.trialStats = [stats]

    var sensorData = [SensorData]()
    sensorDataManager.performChanges(andWait: true) {
      let dataPoint1 = SensorData.insert(dataPoint: DataPoint(x: 1000, y: 1),
                                         forSensorID: "SENSOR_ID",
                                         trialID: trial.ID,
                                         resolutionTier: 0,
                                         context: self.sensorDataManager.mainContext)
      sensorData.append(dataPoint1)
      let dataPoint2 = SensorData.insert(dataPoint: DataPoint(x: 1500, y: 10),
                                         forSensorID: "SENSOR_ID",
                                         trialID: trial.ID,
                                         resolutionTier: 0,
                                         context: self.sensorDataManager.mainContext)
      sensorData.append(dataPoint2)
    }

    let expectation = XCTestExpectation()

    let statsAdjuster = TrialStatsAdjuster(trial: trial, sensorData: sensorData)
    statsAdjuster.recalculateStats { (trialStats) in
      XCTAssertEqual(1, trialStats.count)
      XCTAssertEqual("SENSOR_ID", trialStats[0].sensorID)
      XCTAssertEqual(1, trialStats[0].minimumValue)
      XCTAssertEqual(10, trialStats[0].maximumValue)
      XCTAssertEqual(5.5, trialStats[0].averageValue)
      XCTAssertEqual(50, trialStats[0].zoomLevelBetweenTiers)
      XCTAssertEqual(13, trialStats[0].zoomPresenterTierCount)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)
  }

}
