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

@testable import third_party_objective_c_material_components_ios_components_Palettes_Palettes
@testable import third_party_sciencejournal_ios_ScienceJournalOpen
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class WriteTrialSensorDataToDiskOperationTest: XCTestCase {

  var sensorDataManager: SensorDataManager!
  let operationQueue = GSJOperationQueue()
  let testingDirectoryName = "ExportExperimentSensorDataOperationTest"

  override func setUp() {
    super.setUp()

    sensorDataManager = createSensorDataManager()
  }

  func testSensorDataProtoFromExperiment() {
    let sensor1 = SensorLayout(sensorID: "Sensor_1", colorPalette: MDCPalette.blue)
    let sensor2 = SensorLayout(sensorID: "Sensor_2", colorPalette: MDCPalette.blue)
    let sensor3 = SensorLayout(sensorID: "Sensor_3", colorPalette: MDCPalette.blue)

    let trial = Trial()
    trial.ID = "TEST_TRIAL"
    trial.sensorLayouts = [sensor1, sensor2, sensor3]

    // Add data points.
    let context = sensorDataManager.privateContext
    context.performAndWait {
      trial.sensorLayouts.forEach {
        for value in 0...9 {
          let dataPoint = DataPoint(x: Int64(value), y: Double(value))
          SensorData.insert(dataPoint: dataPoint,
                            forSensorID: $0.sensorID,
                            trialID: trial.ID,
                            resolutionTier: 0,
                            context: context)
        }
      }
    }
    sensorDataManager.savePrivateContext(andWait: true)

    let expectation = XCTestExpectation()

    let saveURL = createUniqueTestDirectoryURL().appendingPathComponent("test.proto")
    let writeTrialSensorDataToDiskOperation =
        WriteTrialSensorDataToDiskOperation(saveFileURL: saveURL,
                                            sensorDataManager: sensorDataManager,
                                            trial: trial)
    let observer = BlockObserver { (operation, errors) in
      let data = try? Data(contentsOf: saveURL)
      XCTAssertNotNil(data)

      let sensorDataProto = try? GSJScalarSensorData(data: data!)

      XCTAssertNotNil(sensorDataProto)
      let sensors = sensorDataProto!.sensorsArray!.map { $0 as! GSJScalarSensorDataDump }
      XCTAssertEqual(3, sensors.count)
      // Sensor dumps can be in any order so fetch them by ID.
      for number in 1...3 {
        let sensorID = "Sensor_\(number)"
        let sensorProto1 = sensors.first(where: { $0.tag == sensorID })!
        XCTAssertEqual(10, sensorProto1.rowsArray.count)
        XCTAssertEqual(trial.ID, sensorProto1.trialId)
      }
      expectation.fulfill()
    }
    writeTrialSensorDataToDiskOperation.addObserver(observer)
    operationQueue.addOperation(writeTrialSensorDataToDiskOperation)

    wait(for: [expectation], timeout: 10)
  }

}

