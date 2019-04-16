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

import third_party_sciencejournal_ios_ScienceJournalProtos

extension GSJBleSensorConfig {

  /// The type of sensor data returned by the Science Journal BLE device.
  enum SensorType: Int {
    case rotation = 1
    case custom
    case raw

    /// Returns the string representation of the enum value. Type is a string in GSJBleSensorConfig.
    var string: String {
      return String(rawValue)
    }

    var name: String {
      switch self {
      case .rotation: return String.sensorRotationRpm
      case .custom: return String.sensorCustom
      case .raw: return String.sensorRaw
      }
    }

    var unitDescription: String? {
      switch self {
      case .rotation: return String.rpmUnits
      case .custom: return nil
      case .raw: return String.rawUnits
      }
    }

    var textDescription: String {
      switch self {
      case .rotation: return String.sensorDescShortRotation
      case .custom: return String.sensorDescShortBluetooth
      case .raw: return String.sensorDescShortRaw
      }
    }

    var iconName: String {
      // TODO: Return the proper unique icon for each type.
      switch self {
      case .rotation: return "ic_sensor_rotation"
      case .custom: return "ic_sensor_bluetooth"
      case .raw: return "ic_sensor_raw"
      }
    }

    var animatingIconName: String {
      // TODO: Return the proper unique icon for each type.
      switch self {
      case .rotation: return "sensor_rotation"
      case .custom: return "sensor_bluetooth"
      case .raw: return "sensor_raw"
      }
    }
  }

  var sensorTypeEnum: SensorType? {
    if hasSensorType,
      let intValue = Int(sensorType),
      let enumType = SensorType(rawValue: intValue) {
      return enumType
    }

    return nil
  }
}
