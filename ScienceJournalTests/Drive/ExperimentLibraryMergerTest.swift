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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class ExperimentLibraryMergerTest: XCTestCase {

  var experimentLibraryMerger: ExperimentLibraryMerger!
  let localLibrary = ExperimentLibrary()
  let localSyncStatus = LocalSyncStatus()

  override func setUp() {
    super.setUp()
    experimentLibraryMerger = ExperimentLibraryMerger(localLibrary: localLibrary,
                                                      localSyncStatus: localSyncStatus)
  }

  func testUpdateWithNewExperiment() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.folderID = "foo"

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID2", fileID: "FILEID2")
    externalLibrary.folderID = "bar"

    XCTAssertNil(localLibrary.syncExperiment(forID: "ID2"),
                 "The local library does not yet contain ID2")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertNotNil(localLibrary.syncExperiment(forID: "ID"))
    XCTAssertNotNil(localLibrary.syncExperiment(forID: "ID2"))
    XCTAssertEqual("bar", localLibrary.folderID)
  }


  func testUpdateTimesWithExistingExperiment() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.setExperimentLastModified(atTimestamp: 100, withExperimentID: "ID")
    localLibrary.setExperimentLastOpened(atTimestamp: 100, experimentID: "ID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    externalLibrary.setExperimentLastModified(atTimestamp: 200, withExperimentID: "ID")
    externalLibrary.setExperimentLastOpened(atTimestamp: 300, experimentID: "ID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertEqual(200, localLibrary.experimentLastModified(withID: "ID"))
    XCTAssertEqual(300, localLibrary.experimentLastOpened(withID: "ID"))
  }


  func testUpdateSomeTimesWithExistingExperiment() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.setExperimentLastModified(atTimestamp: 100, withExperimentID: "ID")
    localLibrary.setExperimentLastOpened(atTimestamp: 100, experimentID: "ID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    externalLibrary.setExperimentLastModified(atTimestamp: 200, withExperimentID: "ID")
    externalLibrary.setExperimentLastOpened(atTimestamp: 50, experimentID: "ID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertEqual(200, localLibrary.experimentLastModified(withID: "ID"))
    XCTAssertEqual(100, localLibrary.experimentLastOpened(withID: "ID"))
  }


  func testUpdateDeleteWithExistingExperiment() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.setExperimentDeleted(false, experimentID: "ID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    externalLibrary.setExperimentDeleted(true, experimentID: "ID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertTrue(localLibrary.isExperimentDeleted(withID: "ID")!)
  }


  func testDontUpdateDeleteIfExistingAlreadyDeleted() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.setExperimentDeleted(true, experimentID: "ID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    externalLibrary.setExperimentDeleted(false, experimentID: "ID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertTrue(localLibrary.isExperimentDeleted(withID: "ID")!)
  }

  func testUpdateArchivedIfMergeSourceChanged() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.setExperimentArchived(false, experimentID: "ID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    externalLibrary.setExperimentArchived(true, experimentID: "ID")

    localSyncStatus.addExperiment(withID: "ID")
    localSyncStatus.setExperimentServerArchived(false, withID: "ID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertTrue(localLibrary.isExperimentArchived(withID: "ID")!)
  }

  func testDontUpdateArchivedIfMergeSourceUnchanged() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    localLibrary.setExperimentArchived(true, experimentID: "ID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")
    externalLibrary.setExperimentArchived(false, experimentID: "ID")

    localSyncStatus.addExperiment(withID: "ID")
    localSyncStatus.setExperimentServerArchived(false, withID: "ID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertTrue(localLibrary.isExperimentArchived(withID: "ID")!)
  }

  func testExperimentUpdatesNilFileID() {
    localLibrary.addExperiment(withID: "ID", fileID: nil)

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "FILEID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertEqual(localLibrary.fileID(forExperimentID: "ID"), "FILEID")
  }

  func testExperimentDoesNotOverwriteFileID() {
    localLibrary.addExperiment(withID: "ID", fileID: "FILEID")

    let externalLibrary = ExperimentLibrary()
    externalLibrary.addExperiment(withID: "ID", fileID: "OTHERFILEID")

    experimentLibraryMerger.merge(fromLibrary: externalLibrary)

    XCTAssertEqual(localLibrary.fileID(forExperimentID: "ID"), "FILEID")
  }

}
