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
import Foundation

import third_party_sciencejournal_ios_ScienceJournalProtos

extension Array where Element:Sensor {

  /// Sorts an array of sensors by name.
  var sortedByName: [Sensor] {
    return sorted { $0.name < $1.name }
  }
}

/// The controller object that manages and vends sensors.
open class SensorController {

  // MARK: - Properties

  /// An array of all sensors the sensor controller knows about.
  var allSensors: [Sensor] {
    return internalSensors + bluetoothSensors.values.reduce([]) { (result, array) -> [Sensor] in
      return result + array
    }.sortedByName
  }

  /// The sensors internal to the current device.
  lazy var internalSensors =
      [SoundIntensitySensor(audioCapture: audioCapture, sensorTimer: unifiedSensorTimer),
       AccelerometerXSensor(sensorTimer: unifiedSensorTimer),
       AccelerometerYSensor(sensorTimer: unifiedSensorTimer),
       AccelerometerZSensor(sensorTimer: unifiedSensorTimer),
       LinearAccelerometerSensor(sensorTimer: unifiedSensorTimer),
       BarometerSensor(sensorTimer: unifiedSensorTimer),
       CompassSensor(sensorTimer: unifiedSensorTimer),
       BrightnessSensor(sensorTimer: unifiedSensorTimer),
       MagnetometerSensor(sensorTimer: unifiedSensorTimer),
       PitchSensor(audioCapture: audioCapture, sensorTimer: unifiedSensorTimer)].sortedByName

  /// The sensors internal to the current device that are supported.
  lazy var supportedInternalSensors: [Sensor] = {
    return self.internalSensors.filter { $0.isSupported }.sortedByName
  }()

  /// Look up dictionary for sensors, keyed by sensor ID.
  private var sensorIDLookup = [String: Sensor]()

  /// Supported BLE Services.
  var bleServices: [BLEServiceInterface] {
    return [MakingScienceServiceInterface()]
  }

  /// Known bluetooth sensors keyed by service ID.
  var bluetoothSensors = [CBUUID: [BluetoothSensor]]()

  /// An array of all available sensors, based on each sensor's isSupported value.
  var availableSensors: [Sensor] {
    return allSensors.filter { $0.isSupported }.sortedByName
  }

  private let audioCapture = AudioCapture()
  let unifiedSensorTimer = UnifiedSensorTimer()

  // MARK: - Public

  init() {
    #if SCIENCEJOURNAL_DEV_BUILD
      internalSensors.append(SineWaveSensor(sensorTimer: unifiedSensorTimer))
      internalSensors.append(SingleValueSensor(sensorTimer: unifiedSensorTimer))
    #endif

    for sensor in internalSensors {
      sensorIDLookup[sensor.sensorId] = sensor
    }
  }

  /// Returns the sensor with an ID.
  ///
  /// - Parameter sensorID: The sensor ID.
  /// - Returns: The sensor with matching ID.
  func sensor(for sensorID: String) -> Sensor? {
    return sensorIDLookup[sensorID]
  }

  func addOrUpdateBluetoothSensor(_ bluetoothSensor: BluetoothSensor) {
    addBluetoothSensorToLookup(bluetoothSensor)
    sensorIDLookup[bluetoothSensor.sensorId] = bluetoothSensor
  }

  func removeBluetoothSensor(_ bluetoothSensor: BluetoothSensor) {
    removeBluetoothSensorFromLookup(bluetoothSensor,
                                    serviceID: bluetoothSensor.sensorInterafce.serviceId)
    sensorIDLookup[bluetoothSensor.sensorId] = nil
  }

  func removeAllBluetoothSensors() {
    for (_, sensors) in bluetoothSensors {
      for sensor in sensors {
        removeBluetoothSensor(sensor)
      }
    }
    bluetoothSensors.removeAll()
  }

  func addBluetoothSensors(_ sensors: [BluetoothSensor]) {
    for sensor in sensors {
      addOrUpdateBluetoothSensor(sensor)
    }
  }

  /// Returns the bluetooth service for a service id.
  ///
  /// - Parameter serviceId: A service CBUUID.
  /// - Returns: A BLE service interface.
  func service(forId serviceId: CBUUID) -> BLEServiceInterface? {
    guard let index = bleServices.index(where: { $0.serviceId == serviceId }) else {
      return nil
    }
    return bleServices[index]
  }

  // MARK: - Private

  /// Adds the bluetooth sensor to the lookup dict. If a sensor with this ID exists it will
  /// be replaced.
  private func addBluetoothSensorToLookup(_ bluetoothSensor: BluetoothSensor) {
    let serviceID = bluetoothSensor.sensorInterafce.serviceId
    var serviceSensors = bluetoothSensors[serviceID] ?? [BluetoothSensor]()

    // If a sensor with this ID already exists, replace it.
    if let index = serviceSensors.index(where: { $0.sensorId == bluetoothSensor.sensorId }) {
      serviceSensors[index] = bluetoothSensor
    } else {
      serviceSensors.append(bluetoothSensor)
    }

    bluetoothSensors[serviceID] = serviceSensors
  }

  private func removeBluetoothSensorFromLookup(_ bluetoothSensor: BluetoothSensor,
                                               serviceID: CBUUID) {
    guard var serviceSensors = bluetoothSensors[serviceID],
        let index = serviceSensors.index(of: bluetoothSensor) else {
      return
    }
    serviceSensors.remove(at: index)
    if serviceSensors.count == 0 {
      bluetoothSensors[serviceID] = nil
    } else {
      bluetoothSensors[serviceID] = serviceSensors
    }
  }

}
