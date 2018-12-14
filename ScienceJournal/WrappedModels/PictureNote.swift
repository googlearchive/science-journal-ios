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

import UIKit

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for a GSJLabel that contains a picture.
public class PictureNote: Note {

  /// The file path of the image.
  public var filePath: String? {
    get {
      do {
        let value = try GSJPictureLabelValue(data: proto.protoData)
        return value.filePath
      } catch {
        print("[PictureNote] Error when parsing protoData: \(error.localizedDescription)")
        return nil
      }
    }
    set {
      let value = GSJPictureLabelValue()
      value.filePath = newValue
      proto.protoData = value.data()
    }
  }

  /// Initializes a picture note with an empty proto.
  convenience init() {
    let proto = GSJLabel()
    proto.type = .picture
    self.init(proto: proto)
    ID = UUID().uuidString
    timestamp = Date().millisecondsSince1970
  }

}
