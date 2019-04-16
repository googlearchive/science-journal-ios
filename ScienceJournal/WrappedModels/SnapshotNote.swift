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

import Foundation

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for a GSJLabel that contains a snapshot note.
class SnapshotNote: Note {

  /// The note text.
  var snapshots: [SensorSnapshot]

  override var proto: GSJLabel {
    let proto = super.proto
    let snapshotValue = GSJSnapshotLabelValue()
    snapshotValue.snapshotsArray = NSMutableArray(array: snapshots.map { $0.proto })
    proto.protoData = snapshotValue.data()
    return proto
  }

  required init(proto: GSJLabel) {
    if let snapshotValue = try? GSJSnapshotLabelValue(data: proto.protoData) {
      snapshots = snapshotValue.snapshotsArray.map { snapshotProto in
        SensorSnapshot(proto: snapshotProto as! GSJSnapshotLabelValue_SensorSnapshot)
      }
    } else {
      snapshots = [SensorSnapshot]()
    }
    super.init(proto: proto)
  }

  /// Initializes a snapshot note with a proto containing the snapshots.
  ///
  /// - Parameter snapshots: Sensor snapshots.
  convenience init(snapshots: [SensorSnapshot]) {
    let proto = GSJLabel()
    proto.type = .snapshot
    self.init(proto: proto)
    self.snapshots = snapshots
    ID = UUID().uuidString
    timestamp = Date().millisecondsSince1970
  }

}
