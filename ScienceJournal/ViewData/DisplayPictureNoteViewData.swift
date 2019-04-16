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

/// Protocol for a picture note view data.
protocol DisplayPictureNote: CaptionableNote {
  var imagePath: String? { get set }

  /// Whether the image file exists on disk.
  var imageFileExists: Bool { get }
}

/// View data for a picture note.
struct DisplayPictureNoteViewData: DisplayPictureNote {
  var ID: String
  var trialID: String?
  var imagePath: String?
  var timestamp: Timestamp
  var caption: String?
  var noteType: DisplayNoteType { return .pictureNote(self) }
  var itemType: DisplayItemType { return .pictureNote(self) }

  var imageFileExists: Bool {
    guard let imagePath = imagePath else {
      return false
    }

    return FileManager.default.fileExists(atPath: imagePath)
  }
}
