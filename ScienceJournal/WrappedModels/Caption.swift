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

/// A wrapper for GSJCaption. A caption is text that can be appended to a trial or a note.
class Caption {

  /// The text of the caption.
  var text: String? {
    get {
      return proto.hasText ? proto.text : nil
    }
    set {
      proto.text = newValue
    }
  }

  /// The date the caption was last edited.
  var lastEditedDate: Date {
    get {
      return Date(milliseconds: proto.lastEditedTimestamp)
    }
    set {
      proto.lastEditedTimestamp = newValue.millisecondsSince1970
    }
  }

  /// The underlying proto.
  let proto: GSJCaption

  /// Designated initializer.
  ///
  /// - Parameter proto: A caption proto.
  init(proto: GSJCaption) {
    self.proto = proto
  }

  /// Convenience initializer that creates an empty proto and optionally sets the text of the
  /// caption.
  ///
  /// - Parameter text: The text of the caption. Optional.
  convenience init(text: String? = nil) {
    let proto = GSJCaption()
    self.init(proto: proto)
    if let text = text {
      self.text = text
    }
  }

}
