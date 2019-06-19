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

import UIKit

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// Responsible for presentation of a chart in review mode. Derived from PlaybackViewController
/// for the purposes of rendering a chart for PDF export from view hierarchy.
class ChartExportViewController: UIViewController, ChartControllerDelegate {

  // MARK: - Properties

  let chartController: ChartController
  private let sensorID: String
  private let timeAxisController: TimeAxisController
  private let trialID: String
  private let rightInset: CGFloat = -16

  let colorPalette: MDCPalette?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - sensorID: A sensor ID.
  ///   - sensorStats: The sensor stats.
  ///   - cropRange: A crop range.
  ///   - notes: An array of notes to display on the chart.
  ///   - colorPalette: The color palette for drawing some aspects of the chart.
  ///   - sensorDataManager: The sensor data manager.
  init(trialID: String,
       sensorID: String,
       sensorStats: DisplaySensorStats,
       cropRange: ChartAxis<Int64>? = nil,
       notes: [DisplayNote],
       colorPalette: MDCPalette?,
       sensorDataManager: SensorDataManager) {
    self.sensorID = sensorID
    self.trialID = trialID
    self.colorPalette = colorPalette
    chartController = ChartController(placementType: .runReview,
                                      colorPalette: colorPalette,
                                      trialID: trialID,
                                      sensorID: sensorID,
                                      sensorStats: sensorStats,
                                      cropRange: cropRange,
                                      notes: notes,
                                      sensorDataManager: sensorDataManager)
    timeAxisController = TimeAxisController(style: .review, xAxis: chartController.visibleXAxis)

    super.init(nibName: nil, bundle: nil)

    timeAxisController.timeAxisView.isAccessibilityElement = true
    timeAxisController.timeAxisView.accessibilityTraits = .adjustable
    timeAxisController.timeAxisView.accessibilityLabel = String.chartContentDescription
    timeAxisController.timeAxisView.accessibilityHint = String.chartContentDetails

    chartController.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    chartController.chartView.translatesAutoresizingMaskIntoConstraints = false
    timeAxisController.timeAxisView.translatesAutoresizingMaskIntoConstraints = false

    let bottomWrapper = UIView()
    bottomWrapper.translatesAutoresizingMaskIntoConstraints = false
    bottomWrapper.addSubview(timeAxisController.timeAxisView)
    timeAxisController.timeAxisView.leftAnchor.constraint(
      equalTo: bottomWrapper.leftAnchor,
        constant: chartController.chartView.leftMargin).isActive = true
    timeAxisController.timeAxisView.topAnchor.constraint(
        equalTo: bottomWrapper.topAnchor).isActive = true
    timeAxisController.timeAxisView.bottomAnchor.constraint(
        equalTo: bottomWrapper.bottomAnchor).isActive = true
    timeAxisController.timeAxisView.rightAnchor.constraint(
        equalTo: bottomWrapper.rightAnchor).isActive = true

    let verticalStack = UIStackView(arrangedSubviews: [chartController.chartView, bottomWrapper])
    verticalStack.translatesAutoresizingMaskIntoConstraints = false
    verticalStack.axis = .vertical

    view.addSubview(verticalStack)

    verticalStack.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    verticalStack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    verticalStack.rightAnchor.constraint(equalTo: view.rightAnchor,
                                         constant: rightInset).isActive = true
    verticalStack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  /// Loads data for the chart to display. Replaces any existing data.
  ///
  /// - Parameters:
  ///   - cropRange: The crop range to load, optional. If no range is set the entire recorded range
  ///                will be loaded.
  ///   - completion: A block called when the loading is finished.
  func resetAndloadData(cropRange: ChartAxis<Int64>?,
                        completion: (() -> Void)? = nil) {
    chartController.resetAndloadData(cropRange: cropRange, completion: completion)
  }

  // MARK: - ChartControllerDelegate

  func chartController(_ chartController: ChartController,
                       didUpdateVisibleXAxis visibleAxis: ChartAxis<Int64>) {
    timeAxisController.visibleAxisChanged(visibleAxis, by: chartController)
  }

  func chartController(_ chartController: ChartController,
                       scrollStateChanged isUserScrolling: Bool) {
    timeAxisController.isUserScrolling = isUserScrolling
  }

  func chartControllerDidFinishLoadingData(_ chartController: ChartController) {
    // Set time axis zero time first so labels are correct after setting visible axis.
    if let firstX = chartController.chartData.firstX {
      timeAxisController.timeAxisView.zeroTime = firstX
    }
    timeAxisController.dataXAxis = chartController.dataXAxis
    timeAxisController.visibleAxisChanged(chartController.visibleXAxis)
  }

  func chartController(_ chartController: ChartController, shouldPinToNow: Bool) {}

}
