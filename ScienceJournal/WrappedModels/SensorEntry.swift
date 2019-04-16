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

/// A wrapper for GSJExperiment_SensorEntry. Describes a sensor with its ID and spec.
class SensorEntry {

  /// The sensor ID associated with this entry.
  var sensorID: String {
    get {
      return proto.sensorId
    }
    set {
      proto.sensorId = newValue
    }
  }

  /// The spec for the sensor that recorded the value.
  var sensorSpec: SensorSpec

  /// The underlying proto.
  var proto: GSJExperiment_SensorEntry {
    backingProto.spec = sensorSpec.proto
    return backingProto
  }

  /// Designated initializer.
  ///
  /// - Parameter: proto: A sensor entry proto.
  init(proto: GSJExperiment_SensorEntry) {
    sensorSpec = SensorSpec(proto: proto.spec)
    backingProto = proto
  }

  /// Initializes a sensor entry with a sensor.
  ///
  /// - Parameter sensor: A sensor.
  convenience init(sensor: Sensor) {
    let proto = GSJExperiment_SensorEntry()
    self.init(proto: proto)
    sensorID = sensor.sensorId
    sensorSpec = SensorSpec(sensor: sensor)
  }

  // MARK: - Private

  /// The private backing proto.
  private let backingProto: GSJExperiment_SensorEntry

}
