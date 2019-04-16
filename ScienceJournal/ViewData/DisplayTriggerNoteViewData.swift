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

/// Protocol for a trigger note view data.
protocol DisplayTriggerNote: CaptionableNote {
  var descriptionText: String { get set }
  var noteText: String { get set }
  var valueText: String { get set }
  var icon: UIImage? { get set }
  var iconAccessibilityLabel: String? { get set }
}

/// View data for a trigger note.
struct DisplayTriggerNoteViewData: DisplayTriggerNote {
  var ID: String
  var trialID: String?
  var descriptionText: String
  var noteText: String
  var valueText: String
  var timestamp: Timestamp
  var icon: UIImage?
  var iconAccessibilityLabel: String?
  var caption: String?
  var noteType: DisplayNoteType { return .triggerNote(self) }
  var itemType: DisplayItemType { return .triggerNote(self) }
}
