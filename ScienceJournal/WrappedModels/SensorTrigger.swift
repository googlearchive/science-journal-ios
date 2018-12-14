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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJSensorTrigger.
class SensorTrigger {

  /// The sensor ID associated with this trigger. This is not mutable.
  var sensorID: String {
    get {
      return proto.sensorId
    }
    set {
      proto.sensorId = newValue
    }
  }

  /// The date the trigger was last used.
  var lastUsedDate: Date {
    get {
      return Date(milliseconds: proto.lastUsedMs)
    }
    set {
      proto.lastUsedMs = newValue.millisecondsSince1970
    }
  }

  /// The Trigger Information describing this trigger.
  var triggerInformation: TriggerInformation {
    get {
      return TriggerInformation(proto: proto.triggerInformation)
    }
    set {
      proto.triggerInformation = newValue.proto
    }
  }

  /// The unique ID of this trigger.
  var triggerID: String {
    get {
      return proto.triggerId
    }
    set {
      proto.triggerId = newValue
    }
  }

  /// Whether or not the trigger is a visual trigger.
  var isVisualTrigger: Bool {
    return triggerInformation.triggerActionType == .triggerActionAlert &&
        triggerInformation.triggerAlertTypes.contains(.triggerAlertVisual)
  }

  /// The text description of a sensor trigger. Example: "Alert me when at 0dB".
  ///
  /// - Parameter sensor: The sensor the trigger is for.
  /// - Returns: The text description of the sensor trigger.
  func textDescription(for sensor: Sensor) -> String {
    // String for each action.
    var actionDescription: String {
      switch triggerInformation.triggerActionType {
      case .triggerActionAlert: return String.triggerTypeAlert
      case .triggerActionNote: return String.triggerTypeNote
      case .triggerActionStartRecording: return String.triggerTypeStartRecording
      case .triggerActionStopRecording: return String.triggerTypeStopRecording
      }
    }

    // String for when to trigger.
    var whenDescription: String {
      switch triggerInformation.triggerWhen {
      case .triggerWhenAbove: return String.triggerListWhenAbove
      case .triggerWhenAt: return String.triggerListWhenAt
      case .triggerWhenBelow: return String.triggerListWhenBelow
      case .triggerWhenDropsBelow: return String.triggerListWhenDroppingBelow
      case .triggerWhenRisesAbove: return String.triggerListWhenRisingAbove
      }
    }

    return "\(actionDescription) \(whenDescription) " +
        "\(sensor.string(for: triggerInformation.valueToTrigger, withUnits: true))"
  }

  /// The underlying proto.
  let proto: GSJSensorTrigger

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: A note proto.
  init(proto: GSJSensorTrigger) {
    self.proto = proto
  }

  /// Initializes a sensor trigger with an empty proto.
  ///
  /// - Parameter sensorID: The sensor ID.
  convenience init(sensorID: String) {
    let proto = GSJSensorTrigger()
    self.init(proto: proto)
    triggerID = UUID().uuidString
    self.sensorID = sensorID
  }

}
