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

/// A wrapper for GSJGadgetInfo. Represents information about one "gadget" (can be a sensor or a
/// host device like a phone).
class GadgetInfo {

  /// Platform on which this device was instantiated. Read-only, set during init.
  var platform: GSJGadgetInfo_Platform {
    return proto.platform
  }

  /// The provider ID for external sensors.
  var providerID: String {
    get {
      return proto.providerId
    }
    set {
      proto.providerId = newValue
    }
  }

  /// Opaque to Science Journal, used by external sensors. Two sensor specs with the same address
  /// refer to the same sensor.
  var address: String {
    get {
      return proto.address
    }
    set {
      proto.address = newValue
    }
  }

  /// A unique identifier for the sensor's host device.
  var hostID: String {
    get {
      return proto.hostId
    }
    set {
      proto.hostId = newValue
    }
  }

  /// A human-readable string describing which host device hosted this sensor.
  var hostDescription: String {
    get {
      return proto.hostDescription
    }
    set {
      proto.hostDescription = newValue
    }
  }

  // MARK: - Public

  /// A proto representation of gadget info.
  let proto: GSJGadgetInfo

  /// Designated initializer.
  ///
  /// - Parameter proto: A gadget info proto.
  init(proto: GSJGadgetInfo) {
    self.proto = proto
  }

  /// Initializes gadget info with an empty proto.
  convenience init() {
    let proto = GSJGadgetInfo()
    proto.platform = .ios
    self.init(proto: proto)
  }

}
