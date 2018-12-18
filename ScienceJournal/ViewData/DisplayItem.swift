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

/// Root protocol for view data types. All trials and notes inherit from this.
protocol DisplayItem {
  var ID: String { get }
  /// The timestamp associated with the item.
  var timestamp: Timestamp { get set }
  var itemType: DisplayItemType { get }
}

/// Designates a display item as being able to have a caption.
protocol Captionable {
  var caption: String? { get set }
}

/// Protocol for note types.
protocol DisplayNote: DisplayItem {
  var noteType: DisplayNoteType { get }
  var trialID: String? { get }
}

/// Protocol for captionable notes.
protocol CaptionableNote: DisplayNote, Captionable {}

/// The types of notes that can belong to a trial. Useful when iterating types for
/// displaying a trail.
enum DisplayNoteType {
  case textNote(DisplayTextNote)
  case pictureNote(DisplayPictureNote)
  case snapshotNote(DisplaySnapshotNote)
  case triggerNote(DisplayTriggerNote)
}

/// The types of items that can belong to an experiment. Useful when iterating types for displaying
/// an experiment.
enum DisplayItemType {
  case trial(DisplayTrial)
  case textNote(DisplayTextNote)
  case pictureNote(DisplayPictureNote)
  case snapshotNote(DisplaySnapshotNote)
  case triggerNote(DisplayTriggerNote)

  var deleteActionAccessibilityLabel: String {
    switch self {
    case .trial:
      return String.actionDeleteRecordingContentDescription
    case .pictureNote:
      return String.actionDeleteRecordingPictureNoteContentDescription
    case .snapshotNote:
      return String.actionDeleteRecordingSnapshotContentDescription
    case .textNote:
      return String.actionDeleteRecordingTextNoteContentDescription
    case .triggerNote:
      return String.actionDeleteRecordingTriggerNoteContentDescription
    }
  }
}
