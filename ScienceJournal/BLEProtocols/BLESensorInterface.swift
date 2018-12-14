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

/// Represents a single sensor as represented in the Science Journal interface. A sensor provides
/// a two dimensional (time and value) data point. A single Bluetooth peripheral can have multiple
/// sensors.
protocol BLESensorInterface {
  /// A unique identifier for this sensor.
  var identifier: String { get }

  /// The service ID associated with this sensor.
  var serviceId: CBUUID { get set }

  /// A unique identifier used to associate a saved sensor with its corresponding BLESensorInferface
  /// implementation.
  var providerId: String { get }

  /// The name of the sensor as it will appear in the UI.
  var name: String { get }

  /// The name of the icon image to display in the UI.
  var iconName: String { get }

  /// The name of the image to display when viewing the current value view.
  var animatingIconName: String { get }

  /// A data representation of the sensor (e.g. a protobuf) that can be saved and used to restore
  /// this sensor.
  var config: Data? { get }

  /// The Core Bluetooth peripheral for the sensor, used to disconnect the device if necessary.
  var peripheral: CBPeripheral? { get set }

  /// A string representation of the unit of measurement for the value the sensor provides. (i.e.
  /// mph, lux, dB).
  var unitDescription: String? { get }

  /// A text description of the sensor displayed in the UI.
  var textDescription: String { get }

  /// True if the sensor can be configured via a UI with options, otherwise false.
  var hasOptions: Bool { get }

  /// The information to display on the learn more screen for this sensor.
  var learnMoreInformation: Sensor.LearnMore { get }

  /// Presents a user interface of options to configure the sensor from the given view controller.
  /// Configuration of the peripheral to refect these options should be handled by the sensor
  /// interface.
  ///
  /// - Parameters:
  ///   - viewController: A view controller.
  ///   - completion: A completion closure called when the options have finished presenting.
  func presentOptions(from viewController: UIViewController, completion: @escaping () -> Void)

  /// Connects to the bluetooth peripheral associated with this sensor.
  ///
  /// - Parameter completion: Called when the connection is complete with a Bool indicating success
  ///                         or failure.
  func connect(_ completion: @escaping (Bool) -> Void)

  /// Requests that the sensor starts observing data.
  ///
  /// - Parameter listener: A block that should be called repeatedly every time a new `DataPoint`
  ///                       is observed.
  func startObserving(_ listener: @escaping (DataPoint) -> Void)

  /// The sensor should stop observing data and any relevant functionality can be shut down until
  /// startObserving() is called again.
  func stopObserving()
}
