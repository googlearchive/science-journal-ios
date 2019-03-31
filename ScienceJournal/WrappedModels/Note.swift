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

// TODO: Update comments once label proto refactor is complete. There might be other
// note types.
/// A wrapper for GSJLabel. A note represents a piece of data that can be attached to either an
/// experiment or a trial. A note can be text, a photo or a snapshot of data. (The proto name
/// "Label" is the legacy term).
public class Note {

  /// The ID is unique within an experiment, but cannot be assumed to be unique across
  /// experiments, as users may "copy" entire experiments from Drive.
  /// This ID should probably be a unique GUID.
  var ID: String {
    get {
      return proto.labelId
    }
    set {
      proto.labelId = newValue
    }
  }

  /// The time in ms since the epoch which represents this label in time.
  /// This may be the time at which the label was created, but some labels
  /// have editable timestamps.
  var timestamp: Int64 {
    get {
      return proto.timestampMs
    }
    set {
      proto.timestampMs = newValue
    }
  }

  // TODO: parse proto.valuesArray for each note type.

  /// The date the label was created.
  var creationDate: Date {
    get {
      return Date(milliseconds: proto.creationTimeMs)
    }
    set {
      proto.creationTimeMs = newValue.millisecondsSince1970
    }
  }

  /// An optional user-added caption. Not all labels will make use of this field.
  /// Currently text labels will not use this, but picture, trigger, and snapshot will.
  var caption: Caption?

  /// The private backing proto.
  private let backingProto: GSJLabel

  // MARK: - Public

  /// A proto representation of a trial.
  var proto: GSJLabel {
    backingProto.caption = caption?.proto
    return backingProto
  }

  /// Returns a copy of the note with a new unique ID.
  func copyWithNewID() -> Self {
    return createNoteCopy(note: self, ID: UUID().uuidString)
  }

  /// Returns a copy of the note.
  func copy() -> Self {
    return createNoteCopy(note: self)
  }

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: A note proto.
  public required init(proto: GSJLabel) {
    let protoCopy = proto.copy() as! GSJLabel
    caption = protoCopy.hasCaption ? Caption(proto: protoCopy.caption) : nil
    backingProto = protoCopy
  }

  /// Convenience initializer that creates a new note from a given note. The new note is a true
  /// copy with the same ID.
  ///
  /// - Parameter note: A note.
  convenience init(note: Note) {
    self.init(proto: note.proto.copy() as! GSJLabel)
  }

  /// Initializes a note with an empty proto.
  convenience init() {
    let proto = GSJLabel()
    self.init(proto: proto)
    ID = UUID().uuidString
    timestamp = Date().millisecondsSince1970
  }

  /// Returns a subclass of `Note` depending on the proto's type. If the type is not known it will
  /// return the base class `Note`.
  ///
  /// - Parameter labelProto: A label proto.
  /// - Returns: A note.
  class func from(_ labelProto: GSJLabel) -> Note {
    switch labelProto.type {
    case .text:
      return TextNote(proto: labelProto)
    case .picture:
      return PictureNote(proto: labelProto)
    case .snapshot:
      return SnapshotNote(proto: labelProto)
    case .sensorTrigger:
      return TriggerNote(proto: labelProto)
    default:
        fatalError("Impossible case")
    }
  }

  // MARK: - Private

  /// Helper method that creates a copy of a note.
  ///
  /// - Parameters:
  ///   - note: The note to copy.
  ///   - ID: An optional ID to assign the note copy.
  /// - Returns: A copy of the note.
  private func createNoteCopy<T: Note>(note: Note, ID: String? = nil) -> T {
    let noteCopy = T(proto: self.proto.copy() as! GSJLabel)
    if let ID = ID {
      noteCopy.ID = ID
    }
    return noteCopy
  }

}
