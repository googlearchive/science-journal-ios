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

struct MakingScienceIds {
  static let serviceUUID = CBUUID(string: "555a0001-0aaa-467a-9538-01f0652c74e8")
  static let valueCharacteristic = CBUUID(string: "555a0003-0aaa-467a-9538-01f0652c74e8")
  static let settingCharacteristic = CBUUID(string: "555a0010-0aaa-467a-9538-01f0652c74e8")
  static let versionCharacteristic = CBUUID(string: "555a0011-0aaa-467a-9538-01f0652c74e8")
}

/// Interface for the Making Science Arduino service.
class MakingScienceServiceInterface: BLEServiceInterface {

  var serviceId: CBUUID {
    return MakingScienceIds.serviceUUID
  }

  var name: String {
    return String.bluetoothSensorScienceJournalTitle
  }

  var iconName: String {
    return "ic_sensor_bluetooth_1"
  }

  var characteristicIds: [CBUUID] {
    return [MakingScienceIds.valueCharacteristic,
            MakingScienceIds.versionCharacteristic,
            MakingScienceIds.settingCharacteristic]
  }

  func devicesForPeripheral(_ peripheral: CBPeripheral) -> [BLESensorInterface] {
    return [MakingScienceSensorInterface(name: peripheral.name,
                                         identifier: peripheral.identifier.uuidString)]
  }

}
