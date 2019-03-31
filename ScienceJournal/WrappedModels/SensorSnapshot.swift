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

/// A wrapper for a GSJSnapshotLabelValue_SensorSnapshot that represents a snapshot of a sensor's
/// data at one point in time.
class SensorSnapshot {

  /// The spec for the sensor that recorded the value.
  var sensorSpec: SensorSpec

  /// The timestamp the value was recorded.
  var timestamp: Int64 {
    get {
      return proto.timestampMs
    }
    set {
      proto.timestampMs = newValue
    }
  }

  /// The sensor value recorded.
  var value: Double {
    get {
      return proto.value
    }
    set {
      proto.value = newValue
    }
  }

  /// The underlying proto.
  var proto: GSJSnapshotLabelValue_SensorSnapshot {
    backingProto.sensor = sensorSpec.proto
    return backingProto
  }

  /// Designated initializer.
  ///
  /// - Parameter proto: A sensor snapshot proto.
  init(proto: GSJSnapshotLabelValue_SensorSnapshot) {
    sensorSpec = SensorSpec(proto: proto.sensor)
    backingProto = proto
  }

  /// Initializes a sensor snapshot with an empty proto.
  convenience init() {
    let proto = GSJSnapshotLabelValue_SensorSnapshot()
    self.init(proto: proto)
  }

  // MARK: - Private

  /// The private backing proto.
  private let backingProto: GSJSnapshotLabelValue_SensorSnapshot

}
