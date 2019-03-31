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

import ScienceJournalProtos

/// A wrapper for a GSJBasicSensorAppearance that represents a sensor's display attributes.
class BasicSensorAppearance {

  /// The locale of the sensor's host device.
  var locale: String {
    get {
      return backingProto.locale
    }
    set {
      backingProto.locale = newValue
    }
  }

  /// Display name.
  var name: String {
    get {
      return backingProto.name
    }
    set {
      backingProto.name = newValue
    }
  }

  /// Displayed string representing the units of the value.
  var units: String {
    get {
      return backingProto.units
    }
    set {
      backingProto.units = newValue
    }
  }

  /// Asset path to the small icon (for tab display).
  var iconPath: IconPath?

  /// Asset path to the large icon (for snapshot or trigger note display).
  var largeIconPath: IconPath?

  /// Short description of the sensor.
  var shortDescription: String {
    get {
      return backingProto.shortDescription
    }
    set {
      backingProto.shortDescription = newValue
    }
  }

  /// Allows a sensor to specify that it should be rounded in a particular way.
  var pointsAfterDecimal: Int32 {
    get {
      return backingProto.pointsAfterDecimal
    }
    set {
      backingProto.pointsAfterDecimal = newValue
    }
  }

  /// A proto representation of the basic sensor appearance.
  var proto: GSJBasicSensorAppearance {
    backingProto.iconPath = iconPath?.proto
    backingProto.largeIconPath = largeIconPath?.proto
    return backingProto
  }

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: A basic sensor appearance proto.
  init(proto: GSJBasicSensorAppearance) {
    backingProto = proto
    iconPath = proto.hasIconPath ? IconPath(proto: proto.iconPath) : nil
    largeIconPath = proto.hasLargeIconPath ? IconPath(proto: proto.largeIconPath) : nil
  }

  /// Initializes a basic sensor appearance from a sensor.
  convenience init(sensor: Sensor) {
    let proto = GSJBasicSensorAppearance()
    proto.locale = Locale.current.identifier
    proto.name = sensor.name
    proto.units = sensor.unitDescription
    proto.shortDescription = sensor.textDescription
    proto.pointsAfterDecimal = sensor.pointsAfterDecimal
    // For built-in sensors, the same icon path can describe both small and large icons.
    let iconPathProto = IconPath(type: .builtin, pathString: sensor.sensorId).proto
    proto.iconPath = iconPathProto
    proto.largeIconPath = iconPathProto
    self.init(proto: proto)
  }

  // MARK: - Private

  // The private backing proto.
  let backingProto: GSJBasicSensorAppearance

}
