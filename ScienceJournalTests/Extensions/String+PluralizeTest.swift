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

class String_PluralizeTest: XCTestCase {
  let email = "hello@example.com"

  func testClaimExperimentsClaimAllConfirmationMessage() {
    var count = 1
    var message = String.claimExperimentsClaimAllConfirmationMessage(withItemCount: count,
                                                                     email: email)
    var expected = "Add 1 remaining experiment to Google Drive for \(email)?"
    XCTAssertEqual(message, expected)

    count = 42
    message = String.claimExperimentsClaimAllConfirmationMessage(withItemCount: count, email: email)
    expected = "Add \(count) remaining experiments to Google Drive for \(email)?"
    XCTAssertEqual(message, expected)
  }

  func testClaimExperimentsDeleteAllConfirmationMessage() {
    var count = 1
    var message = String.claimExperimentsDeleteAllConfirmationMessage(withItemCount: count)
    var expected = "Delete 1 remaining experiment?"
    XCTAssertEqual(message, expected)

    count = 42
    message = String.claimExperimentsDeleteAllConfirmationMessage(withItemCount: count)
    expected = "Delete \(count) remaining experiments?"
    XCTAssertEqual(message, expected)
  }

  func testClaimExperimentConfirmationMessage() {
    let message = String.claimExperimentConfirmationMessage(withEmail: email)
    let expected = "Add this experiment to Google Drive for \(email)?"
    XCTAssertEqual(message, expected)
  }

  func testNotesDescription() {
    var count = 0
    XCTAssertEqual("", String.notesDescription(withCount: count))
    count = 1
    XCTAssertEqual("1 note", String.notesDescription(withCount: count))
    count = 42
    XCTAssertEqual("42 notes", String.notesDescription(withCount: count))
  }

  func testTrialsDescription() {
    var count = 0
    XCTAssertEqual("", String.trialsDescription(withCount: count))
    count = 1
    XCTAssertEqual("1 recording", String.trialsDescription(withCount: count))
    count = 42
    XCTAssertEqual("42 recordings", String.trialsDescription(withCount: count))
  }

}

