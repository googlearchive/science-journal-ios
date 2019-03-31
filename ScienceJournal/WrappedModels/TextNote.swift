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

/// A wrapper for a GSJLabel that contains a text note.
class TextNote: Note {

  /// The note text.
  var text: String {
    get {
      do {
        let value = try GSJTextLabelValue(data: proto.protoData)
        return value.text
      } catch {
        print("[TextNote] Error parsing protoData: \(error.localizedDescription)")
        return ""
      }
    }
    set {
      let value = GSJTextLabelValue()
      value.text = newValue
      proto.protoData = value.data()
    }
  }

  /// Initializes a text note with a proto containing the text.
  ///
  /// - Parameter text: The note text.
  convenience init(text: String) {
    let proto = GSJLabel()
    proto.type = .text
    self.init(proto: proto)
    ID = UUID().uuidString
    timestamp = Date().millisecondsSince1970
    self.text = text
  }

}
