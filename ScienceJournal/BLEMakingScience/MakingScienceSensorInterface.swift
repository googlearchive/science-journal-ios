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

import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs
import third_party_sciencejournal_ios_ScienceJournalProtos

/// Interface for the Making Science Arduino sensor.
class MakingScienceSensorInterface: BLESensorInterface {

  private let denominatorForRPMs = 60 * 1000.0
  private let defaultFrequencyWindow: Int64 = 2000
  private let defaultFrequencyFilter = 0.0

  private let packetAssembler = PacketAssembler()

  private var sensorConfigDialog: MakingScienceSensorConfigViewController?

  private var peripheralInterface: BLEPeripheralInterface?

  private var serviceScanner: BLEServiceScanner

  private var filter: ValueFilter?

  var identifier: String

  var serviceId: CBUUID

  var peripheral: CBPeripheral?

  var providerId: String {
    return "bluetooth_le"
  }

  var name: String

  var iconName: String {
    guard let sensorType = sensorConfig?.sensorTypeEnum else {
      // Default to the raw icon.
      return GSJBleSensorConfig.SensorType.raw.iconName
    }
    return sensorType.iconName
  }

  var animatingIconName: String {
    guard let sensorType = sensorConfig?.sensorTypeEnum else {
      // Default to the raw animating icon.
      return GSJBleSensorConfig.SensorType.raw.animatingIconName
    }
    return sensorType.animatingIconName
  }

  var unitDescription: String? {
    guard let sensorType = sensorConfig?.sensorTypeEnum else {
      // Default to the raw unit description.
      return GSJBleSensorConfig.SensorType.raw.unitDescription
    }
    return sensorType.unitDescription
  }

  var textDescription: String {
    guard let sensorType = sensorConfig?.sensorTypeEnum else {
      // Default to the raw text description.
      return GSJBleSensorConfig.SensorType.raw.textDescription
    }
    return sensorType.textDescription
  }

  /// The current filter to apply to received data points.
  private var currentFilter: ValueFilter {
    var filterToApply: ValueFilter
    if let filter = filter {
      filterToApply = filter
    } else if let sensorType = sensorConfig?.sensorTypeEnum {
      filterToApply = filter(forSensorType: sensorType)
      filter = filterToApply
    } else {
      filterToApply = IdentityFilter()
      filter = filterToApply
    }
    return filterToApply
  }

  var hasOptions: Bool { return false }

  var learnMoreInformation: Sensor.LearnMore {
    var sensorType: GSJBleSensorConfig.SensorType {
      guard let sensorConfig = sensorConfig, let sensorTypeEnum = sensorConfig.sensorTypeEnum else {
        return .custom
      }
      return sensorTypeEnum
    }

    var paragraphs: (first: String, second: String) {
      switch sensorType {
      case .rotation:
        return (String.sensorDescFirstParagraphRotation,
                String.sensorDescSecondParagraphRotation)
      case .custom:
        return (String.sensorDescFirstParagraphUnknownBluetooth,
                String.sensorDescSecondParagraphUnknownBluetooth)
      case .raw:
        return (String.sensorDescFirstParagraphRaw,
                String.sensorDescSecondParagraphRaw)
      }
    }

    var imageName: String {
      if sensorType == .rotation {
        return "learn_more_bluetooth_rotation"
      } else {
        return "learn_more_bluetooth_raw"
      }
    }

    return Sensor.LearnMore(firstParagraph: paragraphs.first,
                            secondParagraph: paragraphs.second,
                            imageName: imageName)
  }

  var sensorConfig: GSJBleSensorConfig?

  var config: Data? {
    guard let sensorConfig = sensorConfig else { return nil }
    return sensorConfig.data()
  }

  private var presentOptionsCompletionBlock: (() -> Void)?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - name: The name of the sensor.
  ///   - identifier: The sensor identifier.
  required init(name: String?, identifier: String) {
    self.name = name ?? identifier
    self.identifier = identifier
    self.serviceId = MakingScienceIds.serviceUUID
    serviceScanner = BLEServiceScanner(services: [serviceId])
  }

  func presentOptions(from viewController: UIViewController, completion: @escaping () -> Void) {
    presentOptionsCompletionBlock = completion
    let dialogController = MDCDialogTransitionController()
    // swiftlint:disable force_cast
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    // swiftlint:enable force_cast
    let dialog =
        MakingScienceSensorConfigViewController(analyticsReporter: appDelegate.analyticsReporter)

    dialog.okButton.addTarget(self,
                              action: #selector(sensorConfigOKButtonPressed),
                              for: .touchUpInside)
    dialog.modalPresentationStyle = .custom
    dialog.transitioningDelegate = dialogController
    dialog.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
    viewController.present(dialog, animated: true)

    sensorConfigDialog = dialog
  }

  @objc func sensorConfigOKButtonPressed() {
    sensorConfigDialog?.dismiss(animated: true)

    guard let sensorConfigDialog = sensorConfigDialog else {
      return
    }

    let config = GSJBleSensorConfig()
    config.address = identifier

    let sensorType = sensorConfigDialog.selectedType
    config.sensorType = sensorType.string
    if sensorType == .custom {
      config.customPin = sensorConfigDialog.selectedPin.string
      config.customFrequency = sensorConfigDialog.isFrequencyEnabled
    }

    sensorConfig = config

    presentOptionsCompletionBlock?()
    presentOptionsCompletionBlock = nil
  }

  func connect(_ completion: @escaping (Bool) -> Void) {
    serviceScanner.connectToPeripheral(withIdentifier: identifier) { (peripheral, error) in
      // Stop scanning.
      self.serviceScanner.stopScanning()

      guard peripheral != nil else {
        print("[BluetoothSensor] Error connecting to " +
              "peripheral: \(String(describing: error?.peripheral.name)) " +
              "address: \(String(describing: error?.peripheral.identifier))")
        // TODO: Pass along connection error http://b/64684813
        completion(false)
        return
      }

      self.peripheral = peripheral

      completion(true)
    }
  }

  func startObserving(_ listener: @escaping (DataPoint) -> Void) {
    guard let peripheral = peripheral else { return }

    let characteristics = [MakingScienceIds.valueCharacteristic,
                           MakingScienceIds.versionCharacteristic,
                           MakingScienceIds.settingCharacteristic]
    let interface = BLEPeripheralInterface(peripheral: peripheral,
                                           serviceUUID: MakingScienceIds.serviceUUID,
                                           characteristicUUIDs: characteristics)
    interface.updatesForCharacteristic(MakingScienceIds.valueCharacteristic, block: {
      [weak self] (data) in
      guard let weakSelf = self else { return }
      if let dataPoint = weakSelf.packetAssembler.append(data) {
        var filteredDataPoint = dataPoint
        filteredDataPoint.y =
            weakSelf.currentFilter.filterValue(timestamp: dataPoint.x, value: dataPoint.y)
        listener(filteredDataPoint)
      }
    })
    self.peripheralInterface = interface
  }

  func stopObserving() {
    self.peripheralInterface?.stopUpdatesForCharacteristic(MakingScienceIds.valueCharacteristic)
  }

  private func filter(forSensorType: GSJBleSensorConfig.SensorType) -> ValueFilter {
    guard let sensorType = sensorConfig?.sensorTypeEnum else {
      // Default to the raw icon.
      return IdentityFilter()
    }

    switch sensorType {
    case .rotation:
      return FrequencyBuffer(window: defaultFrequencyWindow,
                             denominatorInMillis: denominatorForRPMs,
                             filter: defaultFrequencyFilter)
    case .raw, .custom:
      let transform = GSJBleSensorConfig_ScaleTransform()
      transform.sourceBottom = 0
      transform.sourceTop = 1023
      transform.destBottom = 0
      transform.destTop = 100
      return ScaleFilter(transform: transform)

    }
  }

}
