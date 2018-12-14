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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class NoteTest: XCTestCase {

  func testNoteCopying() {
    let proto = GSJLabel()
    proto.timestampMs = 123456
    let textValue = GSJTextLabelValue()
    textValue.text = "foo text"
    proto.protoData = textValue.data()!
    let note = Note(proto: proto)
    let copy = note.copy()
    XCTAssertTrue(note.ID == copy.ID)
    XCTAssertFalse(note === copy)
    XCTAssertEqual(note.timestamp, copy.timestamp)
    XCTAssertEqual(note.proto.protoData, copy.proto.protoData)
    XCTAssertEqual(123456, note.timestamp)
  }

  func testNoteCopyingWithNewID() {
    let proto = GSJLabel()
    proto.timestampMs = 123456
    let textValue = GSJTextLabelValue()
    textValue.text = "foo text"
    proto.protoData = textValue.data()!
    let note = Note(proto: proto)
    let copy = note.copyWithNewID()
    XCTAssertFalse(note.ID == copy.ID)
    XCTAssertFalse(note === copy)
    XCTAssertEqual(note.timestamp, copy.timestamp)
    XCTAssertEqual(note.proto.protoData, copy.proto.protoData)
    XCTAssertEqual(123456, note.timestamp)
  }

}
