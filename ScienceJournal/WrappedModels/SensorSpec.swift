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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJSensorSpec. Describes a sensor that can be associated with trials or snapshots.
/// Can describe sensors no longer available or sensors from other devices.
class SensorSpec {

  /// Stores information about the sensor device like provider, address, hostid, etc.
  var gadgetInfo: GadgetInfo

  /// Opaque to Science Journal, used by external sensors for configuration data.
  var config: Data {
    get {
      return proto.config
    }
    set {
      proto.config = newValue
    }
  }

  /// The display attributes of the sensor at the time the sensor spec was created.
  var rememberedAppearance: BasicSensorAppearance

  /// The underlying proto.
  var proto: GSJSensorSpec {
    backingProto.info = gadgetInfo.proto
    backingProto.rememberedAppearance = rememberedAppearance.proto
    return backingProto
  }

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: A sensor spec proto.
  init(proto: GSJSensorSpec) {
    rememberedAppearance = BasicSensorAppearance(proto: proto.rememberedAppearance)
    gadgetInfo = GadgetInfo(proto: proto.info)
    backingProto = proto
  }

  /// Initializes a sensor spec with a sensor.
  convenience init(sensor: Sensor) {
    if let sensor = sensor as? BluetoothSensor {
      self.init(bleSensorInterface: sensor.sensorInterafce)
    } else {
      let proto = GSJSensorSpec()
      self.init(proto: proto)
      rememberedAppearance = BasicSensorAppearance(sensor: sensor)
      gadgetInfo.providerID = "com.google.android.apps.forscience.whistlepunk.hardware"
      gadgetInfo.address = sensor.sensorId
    }
    if let deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString {
      gadgetInfo.hostID = deviceIdentifier
    }
    gadgetInfo.hostDescription = UIDevice.deviceType
    proto.info.platform = .ios
  }

  // MARK: - Private

  /// The private backing proto.
  private let backingProto: GSJSensorSpec

}
