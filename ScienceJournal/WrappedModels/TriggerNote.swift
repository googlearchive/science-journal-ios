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

/// A wrapper for a GSJLabel that contains a trigger note.
class TriggerNote: Note {

  /// The sensor that recorded the trigger.
  var sensorSpec: SensorSpec?

  /// The trigger information.
  var triggerInformation: TriggerInformation?

  override var proto: GSJLabel {
    let proto = super.proto
    let triggerValue = GSJSensorTriggerLabelValue()
    triggerValue.sensor = sensorSpec?.proto
    triggerValue.triggerInformation = triggerInformation?.proto
    proto.protoData = triggerValue.data()
    return proto
  }

  required init(proto: GSJLabel) {
    if let triggerValue = try? GSJSensorTriggerLabelValue(data: proto.protoData) {
      sensorSpec = triggerValue.hasSensor ? SensorSpec(proto: triggerValue.sensor) : nil
      triggerInformation =
          triggerValue.hasTriggerInformation ?
            TriggerInformation(proto: triggerValue.triggerInformation) : nil
    }
    super.init(proto: proto)
  }

  /// Initializes a trigger note with a sensor spec, trigger information and timestamp.
  ///
  /// - Parameters:
  ///   - sensorSpec: The sensor spec.
  ///   - triggerInformation: The trigger information.
  ///   - timestamp: The timestamp when the trigger fired.
  convenience init(sensorSpec: SensorSpec,
                   triggerInformation: TriggerInformation,
                   timestamp: Int64) {
    let proto = GSJLabel()
    proto.type = .sensorTrigger
    self.init(proto: proto)
    ID = UUID().uuidString
    self.sensorSpec = sensorSpec
    self.triggerInformation = triggerInformation
    self.timestamp = timestamp
    if !triggerInformation.noteText.isEmpty {
      caption = Caption(text: triggerInformation.noteText)
    }
  }

}
