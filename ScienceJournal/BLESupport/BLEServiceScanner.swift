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

import Foundation
import CoreBluetooth

/// A closure type for the completion of peripheral connections.
typealias ConnectionClosure = (CBPeripheral?, BLEFailedToConnectError?) -> Void

struct BLEFailedToConnectError: Error {
  let peripheral: CBPeripheral
}

struct DiscoveredPeripheral: Equatable {
  let peripheral: CBPeripheral
  let serviceIds: [CBUUID]?

  static func ==(lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
    let serviceIdsEqual = { () -> Bool in
      if let lhsServiceIds = lhs.serviceIds, let rhsServiceIds = rhs.serviceIds {
        return lhsServiceIds == rhsServiceIds
      } else if lhs.serviceIds == nil && rhs.serviceIds == nil {
        return true
      }
      return false
    }()
    return lhs.peripheral == rhs.peripheral && serviceIdsEqual
  }
}

protocol BLEServiceScannerDelegate: class {
  func serviceScannerBluetoothAvailabilityChanged(_ serviceScanner: BLEServiceScanner)
  func serviceScannerDiscoveredNewPeripherals(_ serviceScanner: BLEServiceScanner)
}

/// Scans for peripherals that match a particular service uuid. Also connects to discovered
/// peripherals, either by a direct reference to a peripheral or by a known peripheral identifier.
class BLEServiceScanner: NSObject, CBCentralManagerDelegate {

  weak var delegate: BLEServiceScannerDelegate?

  var isBluetoothAvailable = true

  fileprivate var centralManager: CBCentralManager!

  fileprivate(set) var serviceUUIDs: [CBUUID]?
  fileprivate(set) var discoveredPeripherals = [DiscoveredPeripheral]()

  fileprivate let scanInterval: TimeInterval = 2.0
  fileprivate let pauseInterval: TimeInterval = 10.0
  fileprivate var shouldScan = false

  fileprivate var peripheralConnectionBlocks = [UUID: ConnectionClosure]()

  fileprivate(set) var requestedPeripheralId: UUID?
  fileprivate(set) var requestedPeripheralConnectionBlock: ConnectionClosure?

  init(services: [CBUUID]? = nil) {
    serviceUUIDs = services
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  deinit {
    // The central manager continues to send delegate calls after deinit in iOS 9 only, so we have
    // to nil the delegate here. This was surfacing when running unit tests.
    centralManager.delegate = nil
  }

  /// Tells the device to scan for peripherals. Scans for 2 seconds then pauses for 10, repeating
  /// until stopped.
  func startScanning() {
    guard !shouldScan else { return }
    shouldScan = true
    resumeScanning()
  }

  /// Stops scanning for peripherals.
  func stopScanning() {
    guard shouldScan else { return }
    shouldScan = false
    centralManager.stopScan()
  }

  func connectToPeripheral(withIdentifier identifier: String,
                           completion: @escaping ConnectionClosure) {
    guard let uuid = UUID(uuidString: identifier) else {
      completion(nil, nil)
      return
    }

    for discovered in discoveredPeripherals {
      if discovered.peripheral.identifier == uuid {
        connectTo(discovered.peripheral, completion: completion)
        return
      }
    }

    // If there isn't already a peripheral with this id, store it for later.
    requestedPeripheralId = uuid
    requestedPeripheralConnectionBlock = completion

    // Start scanning in case we're not already scanning.
    startScanning()
  }

  func connectTo(_ peripheral: CBPeripheral, completion: ConnectionClosure? = nil) {
    if let completion = completion {
      peripheralConnectionBlocks[peripheral.identifier] = completion
    }
    centralManager.connect(peripheral, options: nil)
  }

  /// Disconnects from a peripheral.
  ///
  /// - Parameter peripheral: The peripheral to disconnect from.
  func disconnectFromPeripheral(_ peripheral: CBPeripheral) {
    centralManager.cancelPeripheralConnection(peripheral)
  }

  @objc fileprivate func resumeScanning() {
    guard shouldScan, let serviceUUIDs = serviceUUIDs else { return }

    centralManager.scanForPeripherals(withServices: serviceUUIDs, options: nil)
    Timer.scheduledTimer(timeInterval: scanInterval,
                         target: self,
                         selector: #selector(delayScanning),
                         userInfo: nil,
                         repeats: false)
  }

  @objc fileprivate func delayScanning() {
    centralManager.stopScan()
    Timer.scheduledTimer(timeInterval: pauseInterval,
                         target: self,
                         selector: #selector(resumeScanning),
                         userInfo: nil,
                         repeats: false)
  }

  // MARK: - CBCentralManagerDelegate

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let previouslyAvailable = isBluetoothAvailable
    switch central.state {
    case .poweredOff:
      print("Bluetooth powered off.")
      isBluetoothAvailable = false
    case .unsupported:
      print("Bluetooth not supported on this device.")
      isBluetoothAvailable = false
    case .unauthorized:
      print("Bluetooth not authorized.")
      isBluetoothAvailable = false
    case .resetting:
      print("Bluetooth is resetting.")
      isBluetoothAvailable = false
    case .unknown:
      print("Bluetooth unknown state.")
      isBluetoothAvailable = false
    case .poweredOn:
      print("Bluetooth is powered on.")
      isBluetoothAvailable = true
      resumeScanning()
    }

    if previouslyAvailable != isBluetoothAvailable {
      delegate?.serviceScannerBluetoothAvailabilityChanged(self)
    }
  }

  func centralManager(_ central: CBCentralManager,
                      didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any],
                      rssi RSSI: NSNumber) {
    // Append this peripheral if it is not already in the array.
    let serviceIds = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? Array<CBUUID>
    let discovered =
        DiscoveredPeripheral(peripheral: peripheral,
                             serviceIds: serviceIds)
    if discoveredPeripherals.index(of: discovered) == nil {
      discoveredPeripherals.append(discovered)
    }
    delegate?.serviceScannerDiscoveredNewPeripherals(self)

    if peripheral.identifier == requestedPeripheralId {
      connectTo(peripheral, completion: requestedPeripheralConnectionBlock)
      requestedPeripheralId = nil
      requestedPeripheralConnectionBlock = nil
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    // Remove then fire a connection block, if it exists.
    if let block = peripheralConnectionBlocks.removeValue(forKey: peripheral.identifier) {
      block(peripheral, nil)
    }
  }

  func centralManager(_ central: CBCentralManager,
                      didDisconnectPeripheral peripheral: CBPeripheral,
                      error: Error?) {
    print("Disconnected peripheral: \(String(describing: peripheral.name)), " +
        "Error: \(String(describing: error))")
  }

  func centralManager(_ central: CBCentralManager,
                      didFailToConnect peripheral: CBPeripheral,
                      error: Error?) {
    print("Failed to connect to peripheral: \(String(describing: peripheral.name)), " +
        "Error: \(String(describing: error))")

    if let block = peripheralConnectionBlocks.removeValue(forKey: peripheral.identifier) {
      block(nil, BLEFailedToConnectError(peripheral: peripheral))
    }
  }
}
