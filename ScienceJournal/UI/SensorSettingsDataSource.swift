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

import CoreBluetooth
import UIKit

import MaterialComponents

protocol SensorSettingsDataSourceDelegate: class {
  /// Called when the data source has changed and collection view needs a refresh.
  ///
  /// - Parameter dataSource: The data source that is requesting a refresh.
  func sensorSettingsDataSourceNeedsRefresh(_ dataSource: SensorSettingsDataSource)

  /// Called when a sensor should show configuration options.
  ///
  /// - Parameters:
  ///   - dataSource: The sensor settings data source.
  ///   - sensorInterface: A sensor interface.
  func sensorSettingsDataSource(_ dataSource: SensorSettingsDataSource,
                                sensorShouldShowOptions sensorInterface: BLESensorInterface)
}

/// Manages the sensor data displayed by SensorSettingsViewController.
class SensorSettingsDataSource: BLEServiceScannerDelegate {

  weak var delegate: SensorSettingsDataSourceDelegate?

  var sensors = [CBPeripheral]()

  let numberOfSections = 3

  enum Section: Int {
    case instructions = 0
    case myDevices
    case availableDevices

    var sectionTitle: String? {
      switch self {
      case .instructions:
        return nil
      case .myDevices:
        return String.myDevices
      case .availableDevices:
        return String.availableDevices
      }
    }
  }

  class SubSection {
    var collapsed = false
    let name: String
    let iconName: String
    var rowCount: Int { return 0 }

    init(name: String, iconName: String) {
      self.name = name
      self.iconName = iconName
    }
  }

  class DeviceSection: SubSection {
    var isInternalSensors = false
    var sensors = [Sensor]()
    override var rowCount: Int {
      return collapsed ? 1 : sensors.count + 1
    }
  }

  class ServiceSection: SubSection {
    var peripherals = [BLESensorInterface]()
    var serviceInterface: BLEServiceInterface
    override var rowCount: Int {
      return collapsed ? 1 : peripherals.count + 1
    }

    init(serviceInterface: BLEServiceInterface, name: String, iconName: String) {
      self.serviceInterface = serviceInterface
      super.init(name: name, iconName: iconName)
    }
  }

  var deviceSections = [DeviceSection]()

  // There is only one supported service for now. When other bluetooth services are supported this
  // will become an array of service sections.
  var serviceSections = [ServiceSection]()

  let serviceScanner: BLEServiceScanner

  /// The IDs of the sensors that are enabled.
  var enabledSensorIDs: [String]

  private var numberOfEnabledInternalSensorIDs: Int {
    // If there are no enabled sensor IDs, treat it as if all are enabled.
    guard !enabledSensorIDs.isEmpty else { return internalSensorIDs.count }

    return enabledSensorIDs.filter({ internalSensorIDs.contains($0) }).count
  }

  private var internalSensorIDs: [String]

  private let metadataManager: MetadataManager
  private let sensorController: SensorController

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - enabledSensorIDs: The IDs of sensors that are enabled.
  ///   - metadataManager: A metadata manager.
  ///   - sensorController: The sensor controller.
  init(enabledSensorIDs: [String],
       metadataManager: MetadataManager,
       sensorController: SensorController) {
    self.enabledSensorIDs = enabledSensorIDs
    self.metadataManager = metadataManager
    self.sensorController = sensorController

    // Devices section is a list of the current device's internal sensors as well as any
    // selected bluetooth devices.
    let internalTitle = String.phoneSensors
    let internalSensors = DeviceSection(name: internalTitle, iconName: "ic_phone_iphone")
    internalSensors.isInternalSensors = true

    internalSensors.sensors = sensorController.supportedInternalSensors
    deviceSections.append(internalSensors)

    internalSensorIDs = sensorController.supportedInternalSensors.map { $0.sensorId }

    if sensorController.bluetoothSensors.count > 0 {
      for (serviceId, sensors) in sensorController.bluetoothSensors {
        guard let service = sensorController.service(forId: serviceId) else {
          continue
        }
        let deviceSection = DeviceSection(name: service.name,
                                          iconName: "ic_sensor_bluetooth")
        deviceSection.sensors = sensors
        deviceSections.append(deviceSection)
      }
    }

    // Available devices listed bluetooth devices that have been discovered. Currently only the
    // Science Journal BLE service is available.
    for serviceInterface in sensorController.bleServices {
      let section = ServiceSection(serviceInterface: serviceInterface,
                                   name: serviceInterface.name,
                                   iconName: serviceInterface.iconName)
      serviceSections.append(section)
    }

    // Listen for available BLE devices.
    let supportedServicesIds = sensorController.bleServices.map { $0.serviceId }
    serviceScanner = BLEServiceScanner(services: supportedServicesIds)
    serviceScanner.delegate = self
    serviceScanner.startScanning()
  }

  func numberOfItems(inSection section: Int) -> Int {
    guard let sensorSection = Section(rawValue: section) else {
      return 0
    }

    switch sensorSection {
    case .instructions:
      return 1
    case .myDevices:
      return deviceSections.reduce(0, { total, section in total + section.rowCount })
    case .availableDevices:
      return serviceSections.reduce(0, { total, section in total + section.rowCount })
    }
  }

  func didSelectItem(atIndexPath indexPath: IndexPath) {
    guard let sensorSection = Section(rawValue: indexPath.section) else {
      return
    }

    switch sensorSection {
    case .instructions:
      break
    case .myDevices:
      var currentCount = 0
      for section in deviceSections {
        if indexPath.item < currentCount + section.rowCount {
          let sectionIndex = indexPath.item - currentCount
          if sectionIndex == 0 {
            section.collapsed = !section.collapsed
          } else {
            let sensor = section.sensors[sectionIndex - 1]
            toggleSensorEnabled(sensor)
          }
          delegate?.sensorSettingsDataSourceNeedsRefresh(self)
          break
        }
        currentCount += section.rowCount
      }
    case .availableDevices:
      var currentCount = 0
      for section in serviceSections {
        if indexPath.item < currentCount + section.rowCount {
          let sectionIndex = indexPath.item - currentCount
          if sectionIndex == 0 {
            section.collapsed = !section.collapsed
          } else {
            let sensorInterface = section.peripherals.remove(at: sectionIndex - 1)
            let bluetoothSensor = metadataManager.saveAndUpdateBluetoothSensor(sensorInterface)

            // When 3rd party sensors are added, this will need to be added to the correct
            // device section.
            let section = DeviceSection(name: sensorInterface.name, iconName: "ic_sensor_bluetooth")
            section.sensors.append(bluetoothSensor)
            deviceSections.append(section)

            delegate?.sensorSettingsDataSource(self, sensorShouldShowOptions: sensorInterface)
          }
          delegate?.sensorSettingsDataSourceNeedsRefresh(self)
          break
        }
        currentCount += section.rowCount
      }
    }
  }

  func configureCell(_ cell: SensorSettingsCell, atIndexPath indexPath: IndexPath) {
    guard let sensorSection = Section(rawValue: indexPath.section) else {
      return
    }

    switch sensorSection {
    case .instructions:
      cell.controlType = .none
      cell.textLabel.text = String.sensorHelpSelectSensors
      cell.textLabel.textColor = MDCPalette.grey.tint400
    case .myDevices:
      // Device sections are sub sections of the collection view sections so we need to keep track
      // of the positioning ourselves.
      var sectionOffset = 0
      for section in deviceSections {
        if indexPath.item < sectionOffset + section.rowCount {
          let sectionIndex = indexPath.item - sectionOffset
          if sectionIndex == 0 {
            cell.controlType = .rotatingButton
            cell.rotatingButton.direction = section.collapsed ? .up : .down
            cell.textLabel.text = section.name
            cell.image = UIImage(named: section.iconName)
            cell.tintColor = MDCPalette.blue.tint500

            if !section.isInternalSensors {
              cell.setButtonImage(UIImage(named: "ic_more_horiz"))
            }
          } else {
            let sensor = section.sensors[sectionIndex - 1]
            cell.controlType = .checkBox
            cell.isCheckBoxChecked = isSensorEnabled(sensor)
            cell.textLabel.text = sensor.name
            cell.image = UIImage(named: sensor.iconName)
            cell.textLabel.textColor = .black
            cell.tintColor = MDCPalette.grey.tint500
            cell.isCheckBoxDisabled = section.isInternalSensors &&
                numberOfEnabledInternalSensorIDs <= 1 && isSensorEnabled(sensor)
          }
          break
        }
        sectionOffset += section.rowCount
      }
    case .availableDevices:
      var currentCount = 0
      for section in serviceSections {
        if indexPath.item < currentCount + section.rowCount {
          let sectionIndex = indexPath.item - currentCount
          if indexPath.item == 0 {
            cell.controlType = .rotatingButton
            cell.rotatingButton.direction = section.collapsed ? .up : .down
            cell.textLabel.text = section.name
            cell.image = UIImage(named: section.iconName)
            cell.tintColor = MDCPalette.blue.tint500
          } else {
            cell.controlType = .checkBox
            let sensorInterface = section.peripherals[sectionIndex - 1]
            cell.textLabel.text = sensorInterface.name
            cell.image = nil
            cell.tintColor = MDCPalette.grey.tint500
          }
          break
        }
        currentCount += section.rowCount
      }
    }
  }

  /// Whether or not to highlight or select the item at an index path.
  func shouldSelectItemAt( indexPath: IndexPath) -> Bool {
    guard let sensorSection = Section(rawValue: indexPath.section) else { return false }

    switch sensorSection {
    case .instructions:
      return false
    case .myDevices:
      if numberOfEnabledInternalSensorIDs > 1 {
        // Allow selection for enabling and disabling, because there are more than one internal
        // sensors enabled.
        return true
      } else {
        // Only one internal sensor is enabled.
        var currentCount = 0
        for section in deviceSections {
          if !section.isInternalSensors {
            // This is not the internal sensors section, allow selection since it's ok to disable
            // all non-internal sensors.
            return true
          } else if indexPath.item < currentCount + section.rowCount {
            let sectionIndex = indexPath.item - currentCount
            if sectionIndex == 0 {
              // If this is a header cell, allow selection for collapsing and expanding.
              return true
            } else {
              // If this is the internal sensors section allow selection for enabling only, because
              // at least one internal sensor needs to be enabled.
              let sensor = section.sensors[sectionIndex - 1]
              return !isSensorEnabled(sensor)
            }
          }
          currentCount += section.rowCount
        }
        return true
      }
    case .availableDevices:
      return true
    }
  }

  /// Returns the device section that contains the given index path. The index path can identify
  /// any item within the desired device section.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: A device section, if found.
  func deviceSection(atIndexPath indexPath: IndexPath) -> DeviceSection? {
    guard indexPath.section == Section.myDevices.rawValue else {
      return nil
    }

    var indexCount = 0
    for section in deviceSections {
      indexCount += section.rowCount
      if indexPath.item < indexCount {
        return section
      }
    }
    return nil
  }

  /// Returns the header item index of the device section identified by the index path. The given
  /// index path can identify any item within the desired device section.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: An item index.
  func headerIndexOfDeviceSection(atIndexPath indexPath: IndexPath) -> Int? {
    var indexCount = 0
    for section in deviceSections {
      indexCount += section.rowCount
      if indexPath.item < indexCount {
        return indexCount - section.rowCount
      }
    }
    return nil
  }

  /// Removes a device section that contains the given index path. The index path can identify any
  /// item within the desired device section.
  ///
  /// - Parameter indexPath: An index path.
  func removeSection(atIndexPath indexPath: IndexPath) {
    guard let section = deviceSection(atIndexPath: indexPath),
        let sectionIndex = deviceSections.index(where: { $0.name == section.name }) else {
      return
    }

    deviceSections.remove(at: sectionIndex)
    delegate?.sensorSettingsDataSourceNeedsRefresh(self)
  }

  // MARK: - Private

  private func isSensorEnabled(_ sensor: Sensor) -> Bool {
    // If there are no enabled sensor IDs, enable all sensors.
    guard enabledSensorIDs.count != 0 else { return true }
    return enabledSensorIDs.contains(sensor.sensorId)
  }

  private func toggleSensorEnabled(_ sensor: Sensor) {
    // If no sensors are enabled, this is the first time disabling a sensor. Enable all internal
    // sensors.
    if enabledSensorIDs.isEmpty {
      enabledSensorIDs =
          sensorController.supportedInternalSensors.map { $0.sensorId }
    }

    if isSensorEnabled(sensor) {
      guard let index = enabledSensorIDs.index(where: { $0 == sensor.sensorId }) else { return }
      enabledSensorIDs.remove(at: index)
    } else {
      enabledSensorIDs.append(sensor.sensorId)
    }
  }

  // MARK: - BLEServiceScannerDelegate

  func serviceScannerDiscoveredNewPeripherals(_ serviceScanner: BLEServiceScanner) {
    let bluetoothSensors = sensorController.bluetoothSensors.values.reduce([], +)
    let addresses = bluetoothSensors.map { $0.sensorInterafce.identifier }
    let unpairedPeripherals = serviceScanner.discoveredPeripherals.filter { (discovered) -> Bool in
      !addresses.contains(discovered.peripheral.identifier.uuidString)
    }

    for section in serviceSections {
      var sensors = [BLESensorInterface]()
      for discoveredPeripheral in unpairedPeripherals {
        guard let serviceIds = discoveredPeripheral.serviceIds else { continue }
        if serviceIds.contains(section.serviceInterface.serviceId) {
          let discoveredSensors =
              section.serviceInterface.devicesForPeripheral(discoveredPeripheral.peripheral)
          sensors.append(contentsOf: discoveredSensors)
        }
      }
      section.peripherals = sensors
    }

    delegate?.sensorSettingsDataSourceNeedsRefresh(self)
  }

  func serviceScannerBluetoothAvailabilityChanged(_ serviceScanner: BLEServiceScanner) {
    // TODO: Display message if Bluetooth is unavailable.
  }

}
