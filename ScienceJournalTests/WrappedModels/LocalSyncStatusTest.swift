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
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class LocalSyncStatusTest: XCTestCase {

  let localSyncStatus = LocalSyncStatus()

  func testDirty() {
    localSyncStatus.addExperiment(withID: "123")
    XCTAssertFalse(localSyncStatus.isExperimentDirty(withID: "123")!)
    localSyncStatus.setExperimentDirty(true, withID: "123")
    XCTAssertTrue(localSyncStatus.isExperimentDirty(withID: "123")!)
    localSyncStatus.setExperimentDirty(false, withID: "123")
    XCTAssertFalse(localSyncStatus.isExperimentDirty(withID: "123")!)
  }

  func testLastSyncedVersion() {
    localSyncStatus.addExperiment(withID: "123")
    XCTAssertNil(localSyncStatus.experimentLastSyncedVersion(withID: "123"))
    localSyncStatus.setExperimentLastSyncedVersion(1000, withID: "123")
    XCTAssertEqual(1000, localSyncStatus.experimentLastSyncedVersion(withID: "123")!)
    localSyncStatus.setExperimentLastSyncedVersion(2000, withID: "123")
    XCTAssertEqual(2000, localSyncStatus.experimentLastSyncedVersion(withID: "123")!)
  }

  func testServerArchived() {
    localSyncStatus.addExperiment(withID: "123")
    XCTAssertFalse(localSyncStatus.isExperimentServerArchived(withID: "123")!)
    localSyncStatus.setExperimentServerArchived(true, withID: "123")
    XCTAssertTrue(localSyncStatus.isExperimentServerArchived(withID: "123")!)
    localSyncStatus.setExperimentServerArchived(false, withID: "123")
    XCTAssertFalse(localSyncStatus.isExperimentServerArchived(withID: "123")!)
  }

  func testExperimentDownloaded() {
    XCTAssertFalse(localSyncStatus.isExperimentDownloaded(withID: "123"))
    localSyncStatus.addExperiment(withID: "123")
    XCTAssertFalse(localSyncStatus.isExperimentDownloaded(withID: "123"))
    localSyncStatus.setExperimentDownloaded(true, withID: "123")
    XCTAssertTrue(localSyncStatus.isExperimentDownloaded(withID: "123"))
    localSyncStatus.setExperimentDownloaded(false, withID: "123")
    XCTAssertFalse(localSyncStatus.isExperimentDownloaded(withID: "123"))
  }

}
