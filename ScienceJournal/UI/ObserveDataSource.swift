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

protocol ObserveDataSourceDelegate: class {
  /// Tells the delegate a sensor's state changed.
  ///
  /// - Parameters:
  ///   - observeDataSource: The observe data source.
  ///   - sensorCard: The sensor card for the changed sensor.
  func observeDataSource(_ observeDataSource: ObserveDataSource,
                         sensorStateDidChangeForCard sensorCard: SensorCard)
}

/// Manages the sensor cards displayed by ObserveViewController.
class ObserveDataSource: SensorDelegate {

  // MARK: - Public properties

  /// Whether or not the footer add button should be shown. There must be more sensors available,
  /// even if this property is true, for the button to show.
  var shouldShowFooterAddButton = true

  /// Total number of sections (1 if no footer, 2 if there is a footer) in the datasource.
  var numberOfSections: Int {
    return 1 + (shouldShowFooterAddButton && !availableSensors().isEmpty ? 1 : 0)
  }

  /// Total number of items (plus optional footer) in the datasource.
  func numberOfItemsInSection(_ section: Int) -> Int {
    switch section {
    case 0:
      return items.count
    case 1:
      return shouldShowFooterAddButton && !availableSensors().isEmpty ? 1 : 0
    default:
      return 0
    }
  }

  /// The indexPath of the footer cell. If `nil`, the footer is not in use.
  var footerIndexPath: IndexPath? {
    guard shouldShowFooterAddButton && !availableSensors().isEmpty else {
      return nil
    }
    return IndexPath(item: 0, section: 1)
  }

  /// The indexPath of the last SensorCard in `items` (section 0).
  var lastCardIndexPath: IndexPath {
    return IndexPath(item: items.count - 1, section: 0)
  }

  /// Whether or not card should be deletable, which requires at least two cards.
  var shouldAllowCardDeletion: Bool {
    return items.count > 1
  }

  /// The available sensors for the current experiment.
  var availableSensorIDs = [String]()

  weak var delegate: ObserveDataSourceDelegate?

  // MARK: - Private properties

  private var sensorsInUse: [Sensor] = []
  private(set) var items: [SensorCard] = []
  let sensorController: SensorController

  // MARK: - Public methods

  /// Designated initializer.
  ///
  /// - Parameter sensorController: The sensor controller.
  init(sensorController: SensorController) {
    self.sensorController = sensorController
  }

  /// Returns the sensor card associated with a sensor.
  ///
  /// - Parameter sensor: The sensor.
  /// - Returns: The sensor card.
  func sensorCard(for sensor: Sensor) -> SensorCard? {
    guard let index = items.index(where: { $0.sensor == sensor }) else { return nil }
    return items[index]
  }

  /// Returns the index path for the sensor card associated with a sensor.
  ///
  /// - Parameter sensor: The sensor.
  /// - Returns: The index path for the sensor card associated with the sensor.
  func indexPath(ofSensor sensor: Sensor) -> IndexPath? {
    guard let sensorCard = sensorCard(for: sensor) else { return nil }
    return indexPathForItem(sensorCard)
  }

  // MARK: Adding, removing and fetching items and index paths

  /// Add a `SensorCard` item to the current `items` array. Equates to a row in the Observe
  /// collectionView.
  ///
  /// - Parameter sensorCard: A `SensorCard` object to add.
  func addItem(_ sensorCard: SensorCard) {
    items.append(sensorCard)
  }

  /// Remove a `SensorCard` item from the current `items` array. Removes a row from the Observe
  /// collectionView.
  ///
  /// - Parameter sensorCard: A `SensorCard` object to remove.
  func removeItem(_ sensorCard: SensorCard) {
    if let index = items.index(of: sensorCard) {
      items.remove(at: index)
    }
  }

  /// Removes all sensor cards from the current items array.
  func removeAllItems() {
    items.removeAll()
  }

  /// Fetch a `SensorCard` item at a given index.
  ///
  /// - Parameter index: An integer index for the item in `items`, equal to the `SensorCard`
  ///                    card in the Observe collectionView.
  /// - Returns: The `SensorCard` object from `items` with the given `index`.
  func item(at index: Int) -> SensorCard {
    return items[index]
  }

  /// Returns a sensor card with a matching sensor ID.
  ///
  /// - Parameter sensorID: A sensor ID.
  /// - Returns: A sensor card.
  func item(withSensorID sensorID: String) -> SensorCard? {
    guard let index = items.index(where: { $0.sensor.sensorId == sensorID }) else {
      return nil
    }
    return items[index]
  }

  /// The first `SensorCard` item.
  var firstItem: SensorCard? {
    return items.first
  }

  /// Fetch an `IndexPath` for a given `SensorCard`.
  ///
  /// - Parameter sensorCard: A sensor card in `items`.
  /// - Returns: The `IndexPath` for the given sensor card.
  func indexPathForItem(_ sensorCard: SensorCard) -> IndexPath? {
    guard let index = items.index(of: sensorCard) else { return nil }
    return IndexPath(item: index, section: 0)
  }

  // MARK: Tracking sensor usage

  /// An array of index paths for any sensor cards displaying a sensor picker. Currently, this
  /// should only return an array with a single item since only one sensor card at a time may be
  /// displaying its sensor picker.
  ///
  /// - Returns: An array of index paths of all sensor cards displaying its sensor picker.
  func indexPathsForCardsShowingSensorPicker() -> [IndexPath] {
    return items.enumerated()
                .filter { (_, element) in element.cellState.options.contains(.sensorPickerVisible) }
                .map { (index, _) in IndexPath(item: index, section: 0) }
  }

  /// Mark a `Sensor` as in use. Sensors can only be used by one card at a time.
  ///
  /// - Parameter sensor: A `Sensor` object.
  func beginUsingSensor(_ sensor: Sensor) {
    sensorsInUse.append(sensor)
    sensor.delegate = self
  }

  /// Mark a `Sensor` as no longer in use.
  ///
  /// - Parameter sensor: A `Sensor` object.
  func endUsingSensor(_ sensor: Sensor) {
    if let index = sensorsInUse.index(of: sensor) {
      sensorsInUse.remove(at: index)
      sensor.delegate = nil
    }
  }

  /// All supported sensors, minus the ones in use by other cards, sorted by name alphabetically.
  /// If this returns an empty array, no attempts to add new cards should be allowed.
  ///
  /// - Parameter sensor: A sensor to leave in the array even if it is in use, in order to retain
  ///   its sort order for display.
  /// - Returns: An array of `Sensor` objects.
  func availableSensors(withSelectedSensor selectedSensor: Sensor? = nil) -> [Sensor] {
    let sensorsAvailable = sensorController.availableSensors
    let usableSensors = sensorsAvailable.filter {
        !sensorsInUse.contains($0) || $0.sensorId == selectedSensor?.sensorId }
    if availableSensorIDs.isEmpty {
      return usableSensors
    } else {
      return usableSensors.filter { availableSensorIDs.contains($0.sensorId) }
    }
  }

  /// Create a sensor card, add it to the data source and return it. Useful when you want to create
  /// a new row in the Observe collectionView.
  ///
  /// - Parameter cellStateOptions: The cell state options for this card. Defaults to
  ///             `[.sensorPickerVisible]`.
  /// - Returns: A `SensorCard` object that has been added to the dataSource's underlying array.
  func sensorCardWithNextSensor(
      cellStateOptions: SensorCardCell.State.Options = .showingSensorPicker) -> SensorCard? {
    guard let sensor = availableSensors().first else { return nil }
    let nextCardColor =
        MDCPalette.nextSensorCardColorPalette(withUsedPalettes: items.map { $0.colorPalette })
    return sensorCardWithSensor(sensor,
                                cardColorPalette: nextCardColor,
                                cellStateOptions: cellStateOptions)
  }

  /// Create a sensor card, add it to the data source and return it. Useful when you want to create
  /// a new row in the Observe collectionView.
  ///
  /// - Parameters:
  ///   - sensor: The sensor to create the sensor card for.
  ///   - cardColorPalette: The color palette of the sensor card.
  /// - Returns: A `SensorCard` object that has been added to the dataSource's underlying array.
  ///   - cellStateOptions: The cell state options for this card.
  func sensorCardWithSensor(_ sensor: Sensor,
                            cardColorPalette: MDCPalette,
                            cellStateOptions: SensorCardCell.State.Options) -> SensorCard {
    let sensorCard = SensorCard(cellStateOptions: cellStateOptions,
                                sensor: sensor,
                                colorPalette: cardColorPalette)
    addItem(sensorCard)
    return sensorCard
  }

  func enumerateChartControllers(_ block: (ChartController) -> Void) {
    for sensorCard in items {
      block(sensorCard.chartController)
    }
  }

  // MARK: - SensorDelegate

  func sensorStateDidChange(_ sensor: Sensor) {
    guard let sensorCard = sensorCard(for: sensor) else {
      return
    }
    delegate?.observeDataSource(self, sensorStateDidChangeForCard: sensorCard)
  }

}
