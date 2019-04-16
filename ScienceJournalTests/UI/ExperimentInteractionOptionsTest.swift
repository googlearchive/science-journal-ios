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

class ExperimentInteractionOptionsTest: XCTestCase {

  func testNormal() {
    let experimentInteractionOptions = ExperimentInteractionOptions.normal
    XCTAssertTrue(experimentInteractionOptions.contains(.canAdd))
    XCTAssertTrue(experimentInteractionOptions.contains(.canEdit))
    XCTAssertTrue(experimentInteractionOptions.contains(.canDelete))
  }

  func testArchived() {
    let experimentInteractionOptions = ExperimentInteractionOptions.archived
    XCTAssertFalse(experimentInteractionOptions.contains(.canAdd))
    XCTAssertTrue(experimentInteractionOptions.contains(.canEdit))
    XCTAssertTrue(experimentInteractionOptions.contains(.canDelete))
  }

  func testReadOnlyWithItemDelete() {
    let experimentInteractionOptions = ExperimentInteractionOptions.readOnlyWithItemDelete
    XCTAssertFalse(experimentInteractionOptions.contains(.canAdd))
    XCTAssertFalse(experimentInteractionOptions.contains(.canEdit))
    XCTAssertTrue(experimentInteractionOptions.contains(.canDelete))
  }

  func testReadOnly() {
    let experimentInteractionOptions = ExperimentInteractionOptions.readOnly
    XCTAssertFalse(experimentInteractionOptions.contains(.canAdd))
    XCTAssertFalse(experimentInteractionOptions.contains(.canEdit))
    XCTAssertFalse(experimentInteractionOptions.contains(.canDelete))
  }

  func testShouldShowDrawer() {
    var experimentInteractionOptions = ExperimentInteractionOptions.normal
    XCTAssertTrue(experimentInteractionOptions.shouldShowDrawer)
    experimentInteractionOptions.remove(.canAdd)
    XCTAssertFalse(experimentInteractionOptions.shouldShowDrawer)

    experimentInteractionOptions = ExperimentInteractionOptions.archived
    XCTAssertFalse(experimentInteractionOptions.shouldShowDrawer)
    experimentInteractionOptions.insert(.canAdd)
    XCTAssertTrue(experimentInteractionOptions.shouldShowDrawer)

    experimentInteractionOptions = ExperimentInteractionOptions.readOnlyWithItemDelete
    XCTAssertFalse(experimentInteractionOptions.shouldShowDrawer)
    experimentInteractionOptions.insert(.canAdd)
    XCTAssertTrue(experimentInteractionOptions.shouldShowDrawer)

    experimentInteractionOptions = ExperimentInteractionOptions.readOnly
    XCTAssertFalse(experimentInteractionOptions.shouldShowDrawer)
    experimentInteractionOptions.insert(.canAdd)
    XCTAssertTrue(experimentInteractionOptions.shouldShowDrawer)
  }

  func testShouldAllowEdits() {
    var experimentInteractionOptions = ExperimentInteractionOptions.normal
    XCTAssertTrue(experimentInteractionOptions.shouldAllowEdits)
    experimentInteractionOptions.remove(.canEdit)
    XCTAssertFalse(experimentInteractionOptions.shouldAllowEdits)

    experimentInteractionOptions = ExperimentInteractionOptions.archived
    XCTAssertTrue(experimentInteractionOptions.shouldAllowEdits)
    experimentInteractionOptions.remove(.canEdit)
    XCTAssertFalse(experimentInteractionOptions.shouldAllowEdits)

    experimentInteractionOptions = ExperimentInteractionOptions.readOnlyWithItemDelete
    XCTAssertFalse(experimentInteractionOptions.shouldAllowEdits)
    experimentInteractionOptions.insert(.canEdit)
    XCTAssertTrue(experimentInteractionOptions.shouldAllowEdits)

    experimentInteractionOptions = ExperimentInteractionOptions.readOnly
    XCTAssertFalse(experimentInteractionOptions.shouldAllowEdits)
    experimentInteractionOptions.insert(.canEdit)
    XCTAssertTrue(experimentInteractionOptions.shouldAllowEdits)
  }

  func testShouldAllowDeletes() {
    var experimentInteractionOptions = ExperimentInteractionOptions.normal
    XCTAssertTrue(experimentInteractionOptions.shouldAllowDeletes)
    experimentInteractionOptions.remove(.canDelete)
    XCTAssertFalse(experimentInteractionOptions.shouldAllowDeletes)

    experimentInteractionOptions = ExperimentInteractionOptions.archived
    XCTAssertTrue(experimentInteractionOptions.shouldAllowDeletes)
    experimentInteractionOptions.remove(.canDelete)
    XCTAssertFalse(experimentInteractionOptions.shouldAllowDeletes)

    experimentInteractionOptions = ExperimentInteractionOptions.readOnlyWithItemDelete
    XCTAssertTrue(experimentInteractionOptions.shouldAllowDeletes)
    experimentInteractionOptions.remove(.canDelete)
    XCTAssertFalse(experimentInteractionOptions.shouldAllowDeletes)

    experimentInteractionOptions = ExperimentInteractionOptions.readOnly
    XCTAssertFalse(experimentInteractionOptions.shouldAllowDeletes)
    experimentInteractionOptions.insert(.canDelete)
    XCTAssertTrue(experimentInteractionOptions.shouldAllowDeletes)
  }

}
