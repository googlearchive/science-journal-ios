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

import CoreBluetooth
import UIKit

/// Represents a bluetooth service that ScienceJournal will scan for when searching for bluetooth
/// devices. When the app finds peripherals it will call `devicesForPeripheral(_)` and will display
/// these devices to the user. Once the user picks a device, the corresponding BLESensorInterface
/// object handles all communication and user interaction.
protocol BLEServiceInterface {
  /// The ID of the service.
  var serviceId: CBUUID { get }

  /// The name of the service as it appears in the UI.
  var name: String { get }

  /// The name of the icon image to dispaly in the UI.
  var iconName: String { get }

  /// Returns an array of objects conforming to BLESensorInterface for the given bluetooth
  /// peripheral. For a single function device like a barometer there will likely be one interface
  /// returned for a peripheral. But an accelerometer might return three interfaces.
  ///
  /// - Parameter peripheral: The bluetooth peripheral.
  /// - Returns: An array of objects conforming to BLESensorInterface.
  func devicesForPeripheral(_ peripheral: CBPeripheral) -> [BLESensorInterface]
}
