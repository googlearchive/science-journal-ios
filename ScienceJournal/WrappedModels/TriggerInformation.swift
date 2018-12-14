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

/// A wrapper for GSJTriggerInformation.
class TriggerInformation {

  /// The value at which this trigger fires.
  var valueToTrigger: Double {
    get {
      return proto.valueToTrigger
    }
    set {
      proto.valueToTrigger = newValue
    }
  }

  /// When to fire the trigger.
  var triggerWhen: GSJTriggerInformation_TriggerWhen {
    get {
      return proto.triggerWhen
    }
    set {
      proto.triggerWhen = newValue
    }
  }

  /// The trigger action type.
  var triggerActionType: GSJTriggerInformation_TriggerActionType {
    get {
      return proto.triggerActionType
    }
    set {
      proto.triggerActionType = newValue
    }
  }

  /// The trigger alert types.
  var triggerAlertTypes: [GSJTriggerInformation_TriggerAlertType] {
    get {
      var types = [GSJTriggerInformation_TriggerAlertType]()
      proto.triggerAlertTypesArray.enumerateValues({ (value, index, stop) in
        types.append(GSJTriggerInformation_TriggerAlertType(rawValue: value)!)
      })
      return types
    }
    set {
      proto.triggerAlertTypesArray.removeAll()
      newValue.forEach { proto.triggerAlertTypesArray.addValue($0.rawValue) }
    }
  }

  /// The text for a note, if this is a trigger action note.
  var noteText: String {
    get {
      return proto.noteText
    }
    set {
      proto.noteText = newValue
    }
  }

  /// Whether the trigger should activate only when recording (or all the time).
  var triggerOnlyWhenRecording: Bool {
    get {
      return proto.triggerOnlyWhenRecording
    }
    set {
      proto.triggerOnlyWhenRecording = newValue
    }
  }

  /// The underlying proto.
  let proto: GSJTriggerInformation

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: A note proto.
  init(proto: GSJTriggerInformation) {
    self.proto = proto
  }

  /// Initializes a trigger information with an empty proto.
  convenience init() {
    let proto = GSJTriggerInformation()
    self.init(proto: proto)
  }

}
