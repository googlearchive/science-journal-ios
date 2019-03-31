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

import Foundation
import CoreBluetooth

/// Gets and sets characteristic data for a single bluetooth peripheral.
class BLEPeripheralInterface: NSObject, CBPeripheralDelegate {
  var peripheral: CBPeripheral
  var serviceUUID: CBUUID
  var service: CBService?
  var characteristicUUIDs: [CBUUID]
  var characteristicNotifyBlocks = [CBUUID: (Data) -> Void]()

  init(peripheral: CBPeripheral, serviceUUID: CBUUID, characteristicUUIDs: [CBUUID]) {
    self.peripheral = peripheral
    self.serviceUUID = serviceUUID
    self.characteristicUUIDs = characteristicUUIDs

    super.init()

    self.peripheral.delegate = self
    self.peripheral.discoverServices([serviceUUID])
  }

  func updatesForCharacteristic(_ characteristicUUID: CBUUID, block: @escaping (Data) -> Void) {
    characteristicNotifyBlocks[characteristicUUID] = block

    guard let characteristics = service?.characteristics else { return }

    for characteristic in characteristics {
      if characteristic.uuid == characteristicUUID {
        peripheral.setNotifyValue(true, for: characteristic)
      }
    }
  }

  func stopUpdatesForCharacteristic(_ characteristicUUID: CBUUID) {
    guard let characteristics = service?.characteristics else { return }

    for characteristic in characteristics {
      if characteristic.uuid == characteristicUUID {
        peripheral.setNotifyValue(false, for: characteristic)
      }
    }
  }

  // MARK: - CBPeripheralDelegate

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      print("Error discovering services: \(error)")
      return
    }

    guard let services = peripheral.services else {
      print("Peripheral has no services.")
      return
    }

    // Search services for the target service.
    for service in services {
      if service.uuid == serviceUUID {
        self.service = service
        // Discover characteristics for this service.
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        break
      }
    }
  }

  func peripheral(_ peripheral: CBPeripheral,
                  didDiscoverCharacteristicsFor service: CBService,
                  error: Error?) {
    if let error = error {
      print("Error discovering characteristics: \(error)")
      return
    }

    guard let characteristics = service.characteristics else {
      print("Service has no characteristics.")
      return
    }

    for characterstic in characteristics {
      // If there is an existing notify block for the characteristic, start notifying.
      if characteristicNotifyBlocks.keys.firstIndex(of: characterstic.uuid) != nil {
        peripheral.setNotifyValue(true, for: characterstic)
      }
    }
  }

  func peripheral(_ peripheral: CBPeripheral,
                  didUpdateValueFor characteristic: CBCharacteristic,
                  error: Error?) {
    if let error = error {
      print("Error discovering characteristics: \(error)")
      return
    }

    guard let data = characteristic.value else {
      print("Characteristic had no value.")
      return
    }

    characteristicNotifyBlocks[characteristic.uuid]?(data)
  }
}
