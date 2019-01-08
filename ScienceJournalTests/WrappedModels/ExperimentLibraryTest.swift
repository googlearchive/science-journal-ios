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

class ExperimentLibraryTest: XCTestCase {

  let experimentLibrary = ExperimentLibrary()

  func testExperimentArchived() {
    experimentLibrary.setExperimentArchived(true, experimentID: "123")
    XCTAssertNil(experimentLibrary.isExperimentArchived(withID: "123"))
    experimentLibrary.addExperiment(withID: "123", fileID: "456")
    XCTAssertFalse(experimentLibrary.isExperimentArchived(withID: "123")!)
    experimentLibrary.setExperimentArchived(true, experimentID: "123")
    XCTAssertTrue(experimentLibrary.isExperimentArchived(withID: "123")!)
    experimentLibrary.setExperimentArchived(false, experimentID: "123")
    XCTAssertFalse(experimentLibrary.isExperimentArchived(withID: "123")!)
  }

  func testExperimentDeleted() {
    experimentLibrary.setExperimentDeleted(true, experimentID: "123")
    XCTAssertNil(experimentLibrary.isExperimentDeleted(withID: "123"))
    experimentLibrary.addExperiment(withID: "123", fileID: "456")
    XCTAssertFalse(experimentLibrary.isExperimentDeleted(withID: "123")!)
    experimentLibrary.setExperimentDeleted(true, experimentID: "123")
    XCTAssertTrue(experimentLibrary.isExperimentDeleted(withID: "123")!)
    experimentLibrary.setExperimentDeleted(false, experimentID: "123")
    XCTAssertFalse(experimentLibrary.isExperimentDeleted(withID: "123")!)
  }

  func testExperimentLastOpened() {
    experimentLibrary.setExperimentLastOpened(atTimestamp: 1098919555, experimentID: "123")
    XCTAssertNil(experimentLibrary.experimentLastOpened(withID: "123"))
    experimentLibrary.addExperiment(withID: "123", fileID: "456")
    experimentLibrary.setExperimentLastOpened(atTimestamp: 1098919555, experimentID: "123")
    XCTAssertEqual(1098919555, experimentLibrary.experimentLastOpened(withID: "123"))
    experimentLibrary.setExperimentLastOpened(atTimestamp: 1526499485, experimentID: "123")
    XCTAssertEqual(1526499485, experimentLibrary.experimentLastOpened(withID: "123"))
  }

  func testExperimentModified() {
    experimentLibrary.setExperimentLastModified(atTimestamp: 1098919555, withExperimentID: "123")
    XCTAssertNil(experimentLibrary.experimentLastModified(withID: "123"))
    experimentLibrary.addExperiment(withID: "123", fileID: "456")
    experimentLibrary.setExperimentLastModified(atTimestamp: 1098919555, withExperimentID: "123")
    XCTAssertEqual(1098919555, experimentLibrary.experimentLastModified(withID: "123"))
    experimentLibrary.setExperimentLastModified(atTimestamp: 1526499485, withExperimentID: "123")
    XCTAssertEqual(1526499485, experimentLibrary.experimentLastModified(withID: "123"))
  }

  func testHasFileIDForExperiment() {
    let experimentID = "789"
    XCTAssertFalse(experimentLibrary.hasFileIDForExperiment(withID: experimentID),
                   "An experiment that has not been added should not have a file ID.")
    experimentLibrary.addExperiment(withID: experimentID)
    XCTAssertFalse(experimentLibrary.hasFileIDForExperiment(withID: experimentID),
                   "An experiment that has not set a file ID should not have a file ID.")
    experimentLibrary.setFileID("100", forExperimentID: experimentID)
    XCTAssertTrue(experimentLibrary.hasFileIDForExperiment(withID: experimentID),
                  "Once an experiment's file ID has been set, it should not a file ID.")
  }

  func testExperimentLibraryFromProto() {
    let syncExperimentProto1 = GSJSyncExperiment()
    syncExperimentProto1.experimentId = "apple"
    let syncExperimentProto2 = GSJSyncExperiment()
    syncExperimentProto2.experimentId = "banana"

    let proto = GSJExperimentLibrary()
    proto.folderId = "abc_id"
    proto.syncExperimentArray = NSMutableArray(array: [syncExperimentProto1, syncExperimentProto2])

    let experimentLibrary = ExperimentLibrary(proto: proto)
    XCTAssertEqual("abc_id", experimentLibrary.folderID)
    XCTAssertEqual(2, experimentLibrary.syncExperiments.count)
    XCTAssertEqual("apple", experimentLibrary.syncExperiments[0].experimentID)
    XCTAssertEqual("banana", experimentLibrary.syncExperiments[1].experimentID)
  }

  func testProtoFromExperimentLibrary() {
    let clock = SettableClock(now: 1000)
    let syncExperiment1 = SyncExperiment(experimentID: "cantaloupe", clock: clock)
    let syncExperiment2 = SyncExperiment(experimentID: "date", clock: clock)
    experimentLibrary.folderID = "def_id"
    experimentLibrary.syncExperiments = [syncExperiment1, syncExperiment2]

    let proto = experimentLibrary.proto
    XCTAssertEqual("def_id", proto.folderId)
    XCTAssertEqual(2, proto.syncExperimentArray_Count)
    XCTAssertEqual(2, proto.syncExperimentArray.count)
    let protoArray: [SyncExperiment] =
        proto.syncExperimentArray.map { SyncExperiment(proto: $0 as! GSJSyncExperiment) }
    XCTAssertEqual("cantaloupe", protoArray[0].experimentID)
    XCTAssertEqual("date", protoArray[1].experimentID)

    let proto2 = experimentLibrary.proto
    XCTAssertEqual(proto, proto2)
    XCTAssertFalse(proto === proto2)
  }

}
