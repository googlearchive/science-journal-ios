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

@testable import third_party_objective_c_material_components_ios_components_Palettes_Palettes
@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class ChartControllerTest: XCTestCase, ChartControllerDelegate {

  let sensorDataManager = SensorDataManager.testStore

  var sensor1 = Sensor.mock(sensorId: "TestSensorID",
                            name: "TestSensorName1",
                            textDescription: "Test description 1.",
                            iconName: "test icon 1")

  let sensorDataPoints = [DataPoint(x: 1234, y: 5),
                          DataPoint(x: 2345, y: 6),
                          DataPoint(x: 3456, y: 7),
                          DataPoint(x: 4567, y: 8),
                          DataPoint(x: 5678, y: 9)]

  // This closure is run when a chart's data finishes loading. Put asserts that rely on data here.
  var didFinishLoadingClosure: (() -> ())?

  override func setUp() {
    super.setUp()

    // Clean up any old data.
    sensorDataManager.performChanges(andWait: true, save: true) {
      self.sensorDataManager.removeData(forTrialID: "TestTrialID")
    }

    // Add data points.
    sensorDataManager.performChanges(andWait: true) {
      for dataPoint in self.sensorDataPoints {
        SensorData.insert(dataPoint: dataPoint,
                          forSensorID: self.sensor1.sensorId,
                          trialID: "TestTrialID",
                          resolutionTier: 1,
                          context: self.sensorDataManager.mainContext)
      }
    }
  }

  override func tearDown() {
    didFinishLoadingClosure = nil
    super.tearDown()
  }

  func testDataLoadingEmpty() {
    let chartController = ChartController(placementType: .observe, colorPalette: MDCPalette.blue)
    XCTAssertTrue(chartController.chartData.isEmpty)
  }

  func testDataLoadingWithSensor() {
    let chartController = ChartController(placementType: .observe,
                                          colorPalette: MDCPalette.blue,
                                          trialID: "TestTrialID",
                                          sensorID: "TestSensorID")
    didFinishLoadingClosure = {
      XCTAssertFalse(chartController.chartData.isEmpty)
      XCTAssertEqual(5, chartController.chartData.dataPoints.count)
      for (index, dataPoint) in self.sensorDataPoints.enumerated() {
        XCTAssertEqual(dataPoint.x,
                       chartController.chartData.dataPoints[index].x,
                       "Chart data should contain data points equal to the sensor data inserted.")
        XCTAssertEqual(dataPoint.y, chartController.chartData.dataPoints[index].y,
                       "Chart data should contain data points equal to the sensor data inserted.")
      }
    }
  }

  func testViewPointsInOrderInPreviewReviewPlacement() {
    let chartController = ChartController(placementType: .previewReview,
                                          colorPalette: MDCPalette.blue)
    chartController.chartView.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
    chartController.chartView.layoutSubviews()

    // A mix of data points that will always be out of order if min and max are added in a fixed
    // order.
    let dataPoints = [
      DataPoint(x: 0, y: 0),
      DataPoint(x: 1, y: 0),
      DataPoint(x: 2, y: 10),
      DataPoint(x: 3, y: 1),
      DataPoint(x: 4, y: 9),
      DataPoint(x: 5, y: 8),
      DataPoint(x: 6, y: 2),
      DataPoint(x: 7, y: 7),
      DataPoint(x: 8, y: 3),
      DataPoint(x: 9, y: 4),
    ]

    chartController.chartData.addDataPoints(dataPoints)
    chartController.updateAxesForChartData()

    chartController.recreateViewPoints()

    var lastViewPointX = chartController.viewDataPoints.first!.x
    for viewPoint in chartController.viewDataPoints {
      XCTAssertTrue(viewPoint.x >= lastViewPointX,
                    "All view points must be in order by the X coordinate.")
      lastViewPointX = viewPoint.x
    }
  }

  func testViewPointResolutionInPreviewReview() {
    let chartController = ChartController(placementType: .previewReview,
                                          colorPalette: MDCPalette.blue)
    chartController.chartView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    chartController.chartView.layoutSubviews()

    var dataPoints = [DataPoint]()
    for i in 1...100_000 {
      dataPoints.append(DataPoint(x: Int64(i), y: Double(i)))
    }

    chartController.chartData.addDataPoints(dataPoints)
    chartController.updateAxesForChartData()

    chartController.recreateViewPoints()

    XCTAssertEqual(200,
                   chartController.viewDataPoints.count,
                   "There should be double as many view points as display points wide.")

    for i in 1...100_000 {
      dataPoints.append(DataPoint(x: Int64(i), y: Double(i)))
    }

    XCTAssertEqual(200_000, dataPoints.count)

    chartController.chartData.removeAll()
    chartController.chartData.addDataPoints(dataPoints)
    chartController.updateAxesForChartData()

    chartController.recreateViewPoints()

    XCTAssertEqual(200,
                   chartController.viewDataPoints.count,
                   "Adding data points should not increase the number of display points.")
  }

  func testViewPointsChangeWithWidthInPreviewReviewPlacement() {
    let chartController = ChartController(placementType: .previewReview,
                                          colorPalette: MDCPalette.blue)
    chartController.chartView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    chartController.chartView.layoutSubviews()

    var dataPoints = [DataPoint]()
    for i in 1...100_000 {
      dataPoints.append(DataPoint(x: Int64(i), y: Double(i)))
    }

    // This mimics what happens after chart data is loaded.
    chartController.chartData.addDataPoints(dataPoints)
    chartController.updateAxesForChartData()
    chartController.updateView()

    XCTAssertEqual(200,
                   chartController.viewDataPoints.count,
                   "There should be double as many view points as display points wide.")

    // Bounds change simulates the view rotating.
    chartController.chartView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)

    XCTAssertEqual(400,
                   chartController.viewDataPoints.count,
                   "There should be double as many view points as display points wide.")
  }

  func testNonPreviewReviewPlacementDoesNotReduceResolution() {
    func testChartWithPlacementType(_ placementType: ChartPlacementType) {
      let chartController = ChartController(placementType: placementType,
                                            colorPalette: MDCPalette.blue)
      chartController.chartView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
      chartController.chartView.layoutSubviews()

      var dataPoints = [DataPoint]()
      for i in 1...1000 {
        dataPoints.append(DataPoint(x: Int64(i), y: Double(i)))
      }

      chartController.chartData.addDataPoints(dataPoints)
      chartController.updateAxesForChartData()

      chartController.recreateViewPoints()

      XCTAssertEqual(dataPoints.count,
                     chartController.viewDataPoints.count,
                     "There should be the same number of view points as data points.")

      for i in 1...1000 {
        dataPoints.append(DataPoint(x: Int64(i), y: Double(i)))
      }

      XCTAssertEqual(2000, dataPoints.count)

      chartController.chartData.removeAllDataPoints()
      chartController.chartData.addDataPoints(dataPoints)
      chartController.updateAxesForChartData()

      chartController.recreateViewPoints()

      XCTAssertEqual(dataPoints.count,
                     chartController.viewDataPoints.count,
                     "Adding data points should increase the number of display points.")
    }

    testChartWithPlacementType(.observe)
    testChartWithPlacementType(.runReview)
  }

  func chartControllerDidFinishLoadingData(_ chartController: ChartController) {
    didFinishLoadingClosure?()
  }

  func chartController(_ chartController: ChartController,
                       scrollStateChanged isUserScrolling: Bool) {}
  func chartController(_ chartController: ChartController,
                       didUpdateVisibleXAxis visibleAxis: ChartAxis<Int64>) {}
  func chartController(_ chartController: ChartController, shouldPinToNow: Bool) {}

}
