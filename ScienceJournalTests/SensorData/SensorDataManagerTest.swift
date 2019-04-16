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

class SensorDataManagerTest: XCTestCase {

  var sensorDataManager = SensorDataManager.testStore

  override func setUp() {
    super.setUp()

    // Clean up any old data.
    sensorDataManager.performChanges(andWait: true, save: true) {
      self.sensorDataManager.removeData(forTrialID: "TEST_TRIAL")
      self.sensorDataManager.removeData(forTrialID: "TEST_TRIAL_2")
      self.sensorDataManager.removeData(forTrialID: "TEST_TRIAL_3")
    }
  }


  func testRemoveTrialData() {
    sensorDataManager.privateContext.performAndWait {
      SensorData.insert(dataPoint: DataPoint(x: 3, y: 7),
                        forSensorID: "TEST_SENSOR",
                        trialID: "TEST_TRIAL",
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      SensorData.insert(dataPoint: DataPoint(x: 4, y: 8),
                        forSensorID: "TEST_SENSOR",
                        trialID: "TEST_TRIAL",
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      try! sensorDataManager.privateContext.save()
    }

    let expectationCreate =
        XCTestExpectation(description: "Completion should be called when fetching sensor data.")
    sensorDataManager.fetchSensorData(forSensorID: "TEST_SENSOR",
                                      trialID: "TEST_TRIAL") { (dataPoints) in
      XCTAssertEqual(dataPoints!.count, 2, "There should be 2 data points.")
      expectationCreate.fulfill()
    }

    wait(for: [expectationCreate], timeout: 2)

    // Remove the trial data.
    sensorDataManager.removeData(forTrialID: "TEST_TRIAL")

    // Assert that the sensor data is deleted.
    let expectationDelete =
        XCTestExpectation(description: "Completion should be called when fetching sensor data.")
    sensorDataManager.fetchSensorData(forSensorID: "test sensor",
                                      trialID: "TEST_TRIAL") { (dataPoints) in
      XCTAssertTrue(dataPoints!.isEmpty, "There should be no data points.")
      expectationDelete.fulfill()
    }

    wait(for: [expectationDelete], timeout: 2)
  }

  func testMultipleStoreURLs() {
    let rootSensorDataManager = SensorDataManager.rootStore

    // First clean up any old data.
    rootSensorDataManager.removeData(forTrialID: "TEST_TRIAL")

    for index: Int64 in 0...9 {
      rootSensorDataManager.privateContext.performAndWait {
        SensorData.insert(dataPoint: DataPoint(x: index, y: Double(index)),
                          forSensorID: "TEST_SENSOR",
                          trialID: "TEST_TRIAL",
                          resolutionTier: 0,
                          context: rootSensorDataManager.privateContext)
        try! rootSensorDataManager.privateContext.save()
      }
      sensorDataManager.privateContext.performAndWait {
        SensorData.insert(dataPoint: DataPoint(x: index, y: Double(index)),
                          forSensorID: "TEST_SENSOR",
                          trialID: "TEST_TRIAL",
                          resolutionTier: 0,
                          context: sensorDataManager.privateContext)
        try! self.sensorDataManager.privateContext.save()
      }
    }

    let expectation1 = expectation(description: "Root fetch completion.")
    rootSensorDataManager.fetchSensorData(forSensorID: "TEST_SENSOR",
                                          trialID: "TEST_TRIAL") { (dataPoints) in
      XCTAssertNotNil(dataPoints)
      XCTAssertEqual(10, dataPoints!.count)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "User fetch completion.")
    sensorDataManager.fetchSensorData(forSensorID: "TEST_SENSOR",
                                      trialID: "TEST_TRIAL") { (dataPoints) in
      XCTAssertNotNil(dataPoints)
      XCTAssertEqual(10, dataPoints!.count)
      expectation2.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)

    sensorDataManager.privateContext.performAndWait {
      self.sensorDataManager.removeData(forTrialID: "TEST_TRIAL")
    }

    let expectation3 = expectation(description: "Root fetch completion.")
    rootSensorDataManager.fetchSensorData(forSensorID: "TEST_SENSOR",
                                          trialID: "TEST_TRIAL") { (dataPoints) in
      XCTAssertNotNil(dataPoints)
      XCTAssertEqual(10, dataPoints!.count)
      expectation3.fulfill()
    }

    let expectation4 = expectation(description: "User fetch completion.")
    sensorDataManager.fetchSensorData(forSensorID: "TEST_SENSOR",
                                      trialID: "TEST_TRIAL") { (dataPoints) in
      XCTAssertNotNil(dataPoints)
      XCTAssertEqual(0, dataPoints!.count)
      expectation4.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testSensorDataExistsForExperiment() {
    // Create some trials and add them to an experiment.
    let trial1 = Trial()
    trial1.ID = "TEST_TRIAL"
    let trial2 = Trial()
    trial2.ID = "TEST_TRIAL_2"
    let trial3 = Trial()
    trial3.ID = "TEST_TRIAL_3"
    let experiment = Experiment(ID: "TEST_EXPERIMENT")
    experiment.trials = [trial1, trial2, trial3]

    // The sensor data does not exist for any of the trials in the experiment.
    let expectation1 = expectation(description: "Sensor data exists for experiment completion.")
    sensorDataManager.sensorDataExists(forExperiment: experiment) { (exists) in
      XCTAssertFalse(exists, "The sensor data should not exist for the experiment.")
      expectation1.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)

    // Add sensor data to one of the trials.
    sensorDataManager.privateContext.performAndWait {
      SensorData.insert(dataPoint: DataPoint(x: 1, y: 7),
                        forSensorID: "",
                        trialID: trial3.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      SensorData.insert(dataPoint: DataPoint(x: 2, y: 8),
                        forSensorID: "",
                        trialID: trial3.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      try! sensorDataManager.privateContext.save()
    }

    // The sensor data does not exist for all of the trials in the experiment.
    let expectation2 = expectation(description: "Sensor data exists for experiment completion.")
    sensorDataManager.sensorDataExists(forExperiment: experiment) { (exists) in
      XCTAssertFalse(exists, "The sensor data should not exist for the experiment.")
      expectation2.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)

    // Add sensor data to another of the trials.
    sensorDataManager.privateContext.performAndWait {
      SensorData.insert(dataPoint: DataPoint(x: 3, y: 9),
                        forSensorID: "",
                        trialID: trial1.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      SensorData.insert(dataPoint: DataPoint(x: 4, y: 10),
                        forSensorID: "",
                        trialID: trial1.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      try! sensorDataManager.privateContext.save()
    }

    // The sensor data does not exist for all of the trials in the experiment.
    let expectation3 = expectation(description: "Sensor data exists for experiment completion.")
    sensorDataManager.sensorDataExists(forExperiment: experiment) { (exists) in
      XCTAssertFalse(exists, "The sensor data should not exist for the experiment.")
      expectation3.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)

    // Add sensor data for all of the trials.
    sensorDataManager.privateContext.performAndWait {
      SensorData.insert(dataPoint: DataPoint(x: 5, y: 11),
                        forSensorID: "",
                        trialID: trial2.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      SensorData.insert(dataPoint: DataPoint(x: 6, y: 12),
                        forSensorID: "",
                        trialID: trial2.ID,
                        resolutionTier: 0,
                        context: self.sensorDataManager.privateContext)
      try! sensorDataManager.privateContext.save()
    }

    // The sensor data exists for all of the trials in the experiment.
    let expectation4 = expectation(description: "Sensor data exists for experiment completion.")
    sensorDataManager.sensorDataExists(forExperiment: experiment) { (exists) in
      XCTAssertTrue(exists, "The sensor data should exist for the experiment.")
      expectation4.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
  }

}
