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
import third_party_objective_c_material_components_ios_components_Tabs_Tabs

protocol SensorCardCellDelegate: class {
  /// Called when the sensor card expand button is pressed.
  ///
  /// - Parameter sensorCardCell: The sensor card cell.
  func sensorCardCellExpandButtonPressed(_ sensorCardCell: SensorCardCell)

  /// Called when the sensor card cell menu button was pressed.
  ///
  /// - Parameters:
  ///   - sensorCardCell: The sensor card cell.
  ///   - menuButton: The menu button.
  func sensorCardCell(_ sensorCardCell: SensorCardCell, menuButtonPressed menuButton: MenuButton)

  /// Called when the sensor card cell sensor settings button is pressed.
  ///
  /// - Parameter sensorCardCell: The sensor card cell.
  func sensorCardCellSensorSettingsButtonPressed(_ sensorCardCell: SensorCardCell)

  /// Called when the sensor card info button is pressed.
  ///
  /// - Parameter sensorCardCell: The sensor card cell.
  func sensorCardCellInfoButtonPressed(_ sensorCardCell: SensorCardCell)

  /// Delegate should return the available sensors, without removing the sensor passed as
  /// `selectedSensor`, even if it is in use, in order to maintain sort for display.
  ///
  /// - Parameters:
  ///   - sensorCardCell: The sensor card cell.
  ///   - selectedSensor: A sensor to leave in the array of available sensors, even if it is in use.
  /// - Returns: The available sensors.
  func sensorCardAvailableSensors(_ sensorCardCell: SensorCardCell,
                                  withSelectedSensor selectedSensor: Sensor?) -> [Sensor]

  /// Called when a sensor is selected.
  ///
  /// - Parameters:
  ///   - sensorCardCell: The sensor card cell.
  ///   - sensor: The selected sensor.
  func sensorCardCell(_ sensorCardCell: SensorCardCell, didSelectSensor sensor: Sensor)

  /// Called when the user taps the stats view.
  ///
  /// - Parameter sensorCardCell: The sensor card cell.
  func sensorCardCellDidTapStats(_ sensorCardCell: SensorCardCell)
}

/// A cell representing a single sensor card.
class SensorCardCell: AutoLayoutMaterialCardCell, MDCTabBarDelegate {

  // MARK: - Nested types

  /// The state of the sensor card cell.
  struct State {

    /// The option set for the state of the sensor card cell.
    struct Options: OptionSet {

      let rawValue: Int

      /// Sensor picker is visible.
      static let sensorPickerVisible = Options(rawValue: 1 << 0)

      /// Stats view is visible.
      static let statsViewVisible = Options(rawValue: 1 << 1)

      /// Visual trigger view is visible.
      static let visualTriggersVisible = Options(rawValue: 1 << 2)

      /// The cell's sensor picker, stats view, visual triggers view are all hidden.
      static let normal: Options = []

      /// The cell is showing the sensor picker, but not the stats or visual trigger views.
      static let showingSensorPicker: Options = [.sensorPickerVisible]

    }

    /// Sensor card cell state options.
    var options: Options {
      didSet {
        // Ensure the options combination is valid.
        if options.contains(.sensorPickerVisible) && options.contains(.statsViewVisible) {
          assert(false,
                 "ERROR: A sensor card can not have the sensor picker and stats view visible.")
        }
      }
    }

    /// The height of the sensor card cell for its state.
    var height: CGFloat {
      var height = SensorCardHeaderView.height + CurrentValueView.height +
          SeparatorView.Metrics.dimension + SensorCardCell.chartViewHeight
      if options.contains(.sensorPickerVisible) {
        height += SensorPickerView.height
      }
      if options.contains(.statsViewVisible) {
        height += (SensorCardCell.statsViewSpacing * 2) + SensorStatsView.height
      }
      if options.contains(.visualTriggersVisible) {
        height += VisualTriggerView.height
      }
      return height
    }

    /// The arrow direction for the state of the cell.
    var arrowDirection: RotatingExpandButton.ArrowDirection {
      if options.contains(.sensorPickerVisible) {
        return .down
      } else {
        return .up
      }
    }

  }

  // MARK: - Properties

  static let stateOptionsChangeAnimationDuration: TimeInterval = 0.3
  static let stateOptionsChangeAnimationOptions: UIView.AnimationOptions = [.beginFromCurrentState,
                                                                           .curveEaseInOut]
  static let statsViewSpacing: CGFloat = 10.0

  let currentValueView = CurrentValueView()
  let headerView = SensorCardHeaderView()
  let statsView = SensorStatsView(min: "0", average: "0", max: "0")
  let visualTriggerView = VisualTriggerView()
  let sensorLoadingView = SensorLoadingView()
  let sensorFailedView = SensorFailedView()

  private let chartViewContainer = UIView()
  private weak var delegate: SensorCardCellDelegate?

  private(set) var sensor: Sensor?
  private let sensorPickerView = SensorPickerView()
  private let stackView = UIStackView()
  private var stackViewTopConstraint: NSLayoutConstraint!
  private let statsViewStack = UIStackView()

  // The fixed height of the chart view.
  private static let chartViewHeight: CGFloat = 130

  // All sensors shown in the cell.
  private var allSensors: [Sensor] = []

  // The state of the sensor card cell.
  private var state = State(options: .showingSensorPicker)

  // The chart view. Setting this will add the chart view to the cell as a subview, removing any
  // previous chart views.
  private var chartView: ChartView? {
    didSet {
      let chartSubviews = chartViewContainer.subviews
      chartSubviews.forEach { $0.removeFromSuperview() }

      guard let chartView = self.chartView else { return }
      chartViewContainer.addSubview(chartView)
      chartView.translatesAutoresizingMaskIntoConstraints = false
      chartView.topAnchor.constraint(
          equalTo: chartViewContainer.topAnchor).isActive = true
      chartView.bottomAnchor.constraint(
          equalTo: chartViewContainer.bottomAnchor).isActive = true
      chartView.leadingAnchor.constraint(
          equalTo: chartViewContainer.leadingAnchor).isActive = true
      chartView.trailingAnchor.constraint(
          equalTo: chartViewContainer.trailingAnchor).isActive = true
    }
  }

  // The color palette automatically tints views as needed.
  private var colorPalette: MDCPalette? {
    didSet {
      guard let palette = colorPalette else {
        return
      }
      sensorPickerView.backgroundColor = palette.tint600
      headerView.backgroundColor = palette.tint700
      sensorLoadingView.activityView.cycleColors = [palette.tint600]
      statsView.textColor = palette.tint600
    }
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    sensor = nil
    delegate = nil
    headerView.expandButton.isHidden = false
    stackView.removeArrangedSubview(statsViewStack)
    statsViewStack.removeFromSuperview()
    stackView.removeArrangedSubview(visualTriggerView)
    visualTriggerView.removeFromSuperview()
    sensorPickerView.tabBar.items = []
    chartView = nil
    currentValueView.animatingIconView.reset()
    currentValueView.textLabel.text = ""
    setStateOptions(.showingSensorPicker, animated: false)
  }

  // MARK: - Configuring and updating the cell

  /// Configure the cell for display.
  ///
  /// - Parameters:
  ///   - sensor: The sensor for this cell.
  ///   - delegate: The delegate for this cell.
  ///   - stateOptions: The state options for the sensor card cell.
  ///   - colorPalette: The cell's color palette.
  ///   - chartView: The chart view to embed in this cell.
  ///   - visualTriggers: The visual triggers for the visual trigger view.
  func configureWithSensor(_ sensor: Sensor,
                           delegate: SensorCardCellDelegate,
                           stateOptions: State.Options,
                           colorPalette: MDCPalette,
                           chartView: ChartView,
                           visualTriggers: [SensorTrigger]) {
    self.sensor = sensor
    self.delegate = delegate
    headerView.titleLabel.text = titleFromSensor(sensor)
    self.colorPalette = colorPalette
    self.chartView = chartView
    currentValueView.animatingIconView = sensor.animatingIconView
    updateSensorLoadingState()
    updateSensorPicker()
    visualTriggerView.setTriggers(visualTriggers, forSensor: sensor)
    setStateOptions(stateOptions, animated: false)
  }

  /// Update the sensor used by this cell.
  ///
  /// - Parameters:
  ///   - sensor: The new sensor.
  ///   - chartView: The new chart view.
  func updateSensor(_ sensor: Sensor, chartView: ChartView) {
    self.sensor = sensor
    headerView.titleLabel.text = titleFromSensor(sensor)
    self.chartView = chartView
    currentValueView.animatingIconView = sensor.animatingIconView
    updateSensorLoadingState()
  }

  /// Updates the sensors in the sensor picker and selects the sensor in use by this card.
  func updateSensorPicker() {
    // Get all sensors that are not in use by other cards.
    guard let availableSensors =
        delegate?.sensorCardAvailableSensors(self, withSelectedSensor: sensor) else { return }
    self.allSensors = availableSensors

    // Create an array of tab bar items for each sensor. Capture the index of the sensor in use, if
    // there is one. If there is not one, select the first item.
    var sensorTabBarItems: [UITabBarItem] = []
    var selectedItemIndex: Int?
    for (index, sensor) in self.allSensors.enumerated() {
      sensorTabBarItems.append(UITabBarItem(title: sensor.name,
                                            image: UIImage(named: sensor.iconName),
                                            tag: index))
      if let selectedSensor = self.sensor {
        if sensor.sensorId == selectedSensor.sensorId {
          selectedItemIndex = index
        }
      }
    }

    if sensorPickerView.tabBar.items != sensorTabBarItems {
      sensorPickerView.tabBar.items = sensorTabBarItems
    }
    if let selectedItemIndex = selectedItemIndex,
        sensorPickerView.tabBar.selectedItem != sensorTabBarItems[selectedItemIndex] {
      sensorPickerView.tabBar.selectedItem = sensorTabBarItems[selectedItemIndex]
    }
  }

  /// Sets the state options for the cell and optionally animates the change.
  ///
  /// - Parameters:
  ///   - stateOptions: The state options for the cell.
  ///   - animated: Whether or not to animate the change.
  func setStateOptions(_ stateOptions: State.Options, animated: Bool) {
    if (!state.options.contains(.sensorPickerVisible) &&
        stateOptions.contains(.sensorPickerVisible)) || !animated {
      // Update the sensor picker before showing it.
      updateSensorPicker()
    }

    state.options = stateOptions
    if animated {
      headerView.expandButton.setDirectionAnimated(state.arrowDirection)
    } else {
      headerView.expandButton.direction = state.arrowDirection
    }

    UIView.animate(withDuration: animated ? SensorCardCell.stateOptionsChangeAnimationDuration : 0,
                   delay: 0,
                   options: SensorCardCell.stateOptionsChangeAnimationOptions,
                   animations: {
      let constant =
          self.state.options.contains(.sensorPickerVisible) ? SensorCardHeaderView.height : 0
      self.sensorPickerView.isAccessible = self.state.options.contains(.sensorPickerVisible)
      self.stackViewTopConstraint.constant = constant
      self.cellContentView.bringSubviewToFront(self.headerView)
      self.cellContentView.layoutIfNeeded()

      // TODO: Adding/removing the statsViewStack as a subview does not animate. Revisit.
      // http://b/63903019
      if self.state.options.contains(.statsViewVisible) {
        self.headerView.expandButton.isHidden = true
        self.stackView.addArrangedSubview(self.statsViewStack)
      } else {
        self.headerView.expandButton.isHidden = false
        self.stackView.removeArrangedSubview(self.statsViewStack)
        self.statsViewStack.removeFromSuperview()
      }

      if self.state.options.contains(.visualTriggersVisible) {
        self.stackView.insertArrangedSubview(self.visualTriggerView, at: 1)
      } else {
        self.stackView.removeArrangedSubview(self.visualTriggerView)
        self.visualTriggerView.removeFromSuperview()
      }
    })
  }

  func updateSensorLoadingState() {
    guard let sensor = sensor else {
      sensorFailedView.isHidden = true
      sensorLoadingView.isHidden = true
      return
    }

    sensorLoadingView.activityView.stopAnimating()

    switch sensor.state {
    case .failed(let error), .noPermission(let error):
      sensorFailedView.messageLabel.text = error.message
      if let buttonTitle = error.actionButtonTitle {
        sensorFailedView.showActionButton(withTitle: buttonTitle)
      } else {
        sensorFailedView.hideActionButton()
      }
      sensorFailedView.isHidden = false
      sensorLoadingView.isHidden = true
    case .loading:
      sensorLoadingView.activityView.startAnimating()
      sensorFailedView.isHidden = true
      sensorLoadingView.isHidden = false
    case .ready, .paused:
      sensorFailedView.isHidden = true
      sensorLoadingView.isHidden = true
    case .interrupted:
      if sensor is BrightnessSensor {
        sensorFailedView.messageLabel.text = String.brightnessSensorBlockedByInterruption
      } else {
        sensorFailedView.messageLabel.text = String.sensorCardErrorText
      }
      sensorFailedView.hideActionButton()
      sensorFailedView.isHidden = false
      sensorLoadingView.isHidden = true
    }
  }

  // MARK: - MDCTabBarDelegate

  func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
    let newSensor = allSensors[item.tag]
    delegate?.sensorCardCell(self, didSelectSensor: newSensor)
  }

  // MARK: - Private

  private func configureView() {
    // Header view.
    cellContentView.addSubview(headerView)
    headerView.expandButton.addTarget(self,
                                      action: #selector(expandButtonPressed),
                                      for: .touchUpInside)
    headerView.menuButton.addTarget(self,
                                    action: #selector(menuButtonPressed(_:)),
                                    for: .touchUpInside)
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.topAnchor.constraint(equalTo: cellContentView.topAnchor).isActive = true
    headerView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor).isActive = true
    headerView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor).isActive = true

    // Sensor picker.
    stackView.addArrangedSubview(sensorPickerView)
    sensorPickerView.tabBar.delegate = self
    sensorPickerView.settingsButton.addTarget(self,
                                              action: #selector(sensorSettingsButtonPressed),
                                              for: .touchUpInside)
    sensorPickerView.translatesAutoresizingMaskIntoConstraints = false

    // Visual trigger view, only shown when visual triggers are present.
    visualTriggerView.translatesAutoresizingMaskIntoConstraints = false

    // Current value view.
    stackView.addArrangedSubview(currentValueView)
    currentValueView.infoButton.addTarget(self,
                                          action: #selector(infoButtonPressed),
                                          for: .touchUpInside)
    currentValueView.translatesAutoresizingMaskIntoConstraints = false
    currentValueView.heightAnchor.constraint(
      equalToConstant: CurrentValueView.height).isActive = true

    // Separator
    let separator = SeparatorView(direction: .horizontal, style: .dark)
    stackView.addArrangedSubview(separator)
    separator.translatesAutoresizingMaskIntoConstraints = false

    // Chart view container.
    stackView.addArrangedSubview(chartViewContainer)
    chartViewContainer.translatesAutoresizingMaskIntoConstraints = false
    chartViewContainer.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    chartViewContainer.heightAnchor.constraint(
        equalToConstant: SensorCardCell.chartViewHeight).isActive = true

    // Stats view, only shown when recording.
    statsViewStack.addArrangedSubview(statsView)
    statsView.translatesAutoresizingMaskIntoConstraints = false

    // Stack view to wrap stats view so it is proper width. SensorStatsView cannot be laid out
    // in a fill-based stack view without being stretched in an undesirable way. Wrapping it in
    // an inner stack view set to centering maintains its intrinsic size appropriately.
    statsViewStack.translatesAutoresizingMaskIntoConstraints = false
    statsViewStack.axis = .vertical
    statsViewStack.distribution = .equalCentering
    statsViewStack.alignment = .center
    statsViewStack.layoutMargins = UIEdgeInsets(top: SensorCardCell.statsViewSpacing,
                                                left: 0,
                                                bottom: SensorCardCell.statsViewSpacing,
                                                right: 0)
    statsViewStack.isLayoutMarginsRelativeArrangement = true

    let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                      action: #selector(handleStatsTapGesture))
    statsViewStack.addGestureRecognizer(tapGestureRecognizer)

    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    cellContentView.addSubview(stackView)
    stackViewTopConstraint = stackView.topAnchor.constraint(equalTo: cellContentView.topAnchor,
                                                            constant: SensorCardHeaderView.height)
    stackViewTopConstraint.isActive = true
    stackView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor).isActive = true
    stackView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor).isActive = true

    // Loading state views. These cover the chart and current value view.
    cellContentView.addSubview(sensorFailedView)
    sensorFailedView.isHidden = true
    sensorFailedView.translatesAutoresizingMaskIntoConstraints = false
    sensorFailedView.topAnchor.constraint(equalTo: sensorPickerView.bottomAnchor).isActive = true
    sensorFailedView.leadingAnchor.constraint(
        equalTo: cellContentView.leadingAnchor).isActive = true
    sensorFailedView.trailingAnchor.constraint(
        equalTo: cellContentView.trailingAnchor).isActive = true
    sensorFailedView.bottomAnchor.constraint(equalTo: cellContentView.bottomAnchor).isActive = true

    sensorFailedView.actionButton.addTarget(self,
                                            action: #selector(failedActionButtonPressed),
                                            for: .touchUpInside)

    cellContentView.addSubview(sensorLoadingView)
    sensorLoadingView.isHidden = true
    sensorLoadingView.translatesAutoresizingMaskIntoConstraints = false
    sensorLoadingView.topAnchor.constraint(equalTo: sensorPickerView.bottomAnchor).isActive = true
    sensorLoadingView.leadingAnchor.constraint(
        equalTo: cellContentView.leadingAnchor).isActive = true
    sensorLoadingView.trailingAnchor.constraint(
        equalTo: cellContentView.trailingAnchor).isActive = true
    sensorLoadingView.bottomAnchor.constraint(equalTo: cellContentView.bottomAnchor).isActive = true
  }

  // Returns a title derived from the sensor name and unit description if it exists.
  private func titleFromSensor(_ sensor: Sensor) -> String {
    var titleText = sensor.name
    if let unitDescription = sensor.unitDescription {
      titleText += " (\(unitDescription))"
    }
    return titleText
  }

  // MARK: User Actions

  @objc private func expandButtonPressed() {
    delegate?.sensorCardCellExpandButtonPressed(self)
  }

  @objc private func infoButtonPressed() {
    delegate?.sensorCardCellInfoButtonPressed(self)
  }

  @objc private func menuButtonPressed(_ menuButton: MenuButton) {
    delegate?.sensorCardCell(self, menuButtonPressed: menuButton)
  }

  @objc private func sensorSettingsButtonPressed() {
    delegate?.sensorCardCellSensorSettingsButtonPressed(self)
  }

  @objc private func handleStatsTapGesture() {
    delegate?.sensorCardCellDidTapStats(self)
  }

  @objc private func failedActionButtonPressed() {
    guard let sensor = sensor else {
      return
    }

    switch sensor.state {
    case .failed:
      sensor.retry()
    case .noPermission:
      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL)
      }
    default: break
    }
  }

}
