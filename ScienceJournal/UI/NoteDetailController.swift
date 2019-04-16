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

/// A protocol for grouping and identifying note detail view controllers.
protocol NoteDetailController: class {
  /// The display note associated with the controller.
  var displayNote: DisplayNote { get set }
}

/// A note detail controller that supports captions.
protocol CaptionableNoteDetailController: NoteDetailController {
  /// The current caption as displayed in a text field for controllers that support captions. May
  /// be different than the display note.
  var currentCaption: String? { get set }
}

extension CaptionableNoteDetailController {

  /// Updates the current caption from the current display note. If the captions are different they
  /// will be concatenated so the current caption is not lost due to an incoming change. Display
  /// notes can change via Drive sync while a user is editing the version on device.
  func updateCaptionFromDisplayNote() {
    guard let captionNote = displayNote as? CaptionableNote else {
      return
    }

    var newCaption = captionNote.caption
    if currentCaption?.trimmedOrNil != captionNote.caption {
      let versions = [currentCaption, captionNote.caption].compactMap { $0?.trimmedOrNil }
      newCaption = versions.joined(separator: String.concatenationSeparator)
    }
    currentCaption = newCaption
  }

}
