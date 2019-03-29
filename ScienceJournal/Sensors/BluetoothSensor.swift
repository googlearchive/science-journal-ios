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
import Foundation

/// A sensor that fetches data from any BLE device with a corresponding implementation
/// of BLESensorInterface.
class BluetoothSensor: Sensor, BLEServiceScannerDelegate {

  var peripheralInterface: BLEPeripheralInterface?

  let sensorInterafce: BLESensorInterface

  let serviceScanner = BLEServiceScanner()

  private var currentValue: Double?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorInterface: The sensor interface.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(sensorInterface: BLESensorInterface, sensorTimer: SensorTimer) {
    self.sensorInterafce = sensorInterface

    let animatingIconView = RelativeScaleAnimationView(iconName: sensorInterface.animatingIconName)
    super.init(sensorId: sensorInterface.identifier,
               name: sensorInterface.name,
               textDescription: sensorInterface.textDescription,
               iconName: sensorInterface.iconName,
               animatingIconView: animatingIconView,
               unitDescription: sensorInterface.unitDescription,
               learnMore: sensorInterafce.learnMoreInformation,
               sensorTimer: sensorTimer)
    displaysLoadingState = true
    // There is a delay in receiving bluetooth state. Optimistically assume it is supported.
    isSupported = true
  }

  override func start() {
    state = .loading
    sensorInterafce.connect { (success) in
      guard success else {
        self.state = .failed(.unavailableHardware)
        return
      }
      self.state = .ready
      self.sensorInterafce.startObserving({ [weak self] (dataPoint) in
        self?.currentValue = dataPoint.y
      })
    }
  }

  override func retry() {
    start()
  }

  override func pause() {
    sensorInterafce.stopObserving()
    state = .paused
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    guard let currentValue = currentValue else { return }
    callListenerBlocksWithDataPoint(DataPoint(x: milliseconds, y: currentValue))
  }

  // MARK: - BLEServiceScannerDelegate

  func serviceScannerDiscoveredNewPeripherals(_ serviceScanner: BLEServiceScanner) {}

  func serviceScannerBluetoothAvailabilityChanged(_ serviceScanner: BLEServiceScanner) {
    isSupported = serviceScanner.isBluetoothAvailable
  }

}
