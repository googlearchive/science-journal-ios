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

extension GSJTriggerInformation_TriggerWhen {

  /// Lower case, past tense of trigger when, to be used in a label string.
  var triggerWhenText: String {
    switch self {
    case .triggerWhenAt: return String.triggerWhenAt.lowercased()
    case .triggerWhenRisesAbove: return String.triggerWhenRoseAbove.lowercased()
    case .triggerWhenDropsBelow: return String.triggerWhenDroppedBelow.lowercased()
    case .triggerWhenAbove: return String.triggerWhenIsAbove.lowercased()
    case .triggerWhenBelow: return String.triggerWhenIsBelow.lowercased()
    }
  }

  /// Whether or not the trigger when should only allow an alert trigger action.
  var shouldOnlyAllowTriggerActionAlert: Bool {
    switch self {
    case .triggerWhenAbove, .triggerWhenBelow:
      return true
    case .triggerWhenAt, .triggerWhenDropsBelow, .triggerWhenRisesAbove:
      return false
    }
  }

}
