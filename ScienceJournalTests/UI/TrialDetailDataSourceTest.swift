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

class TrialDetailDataSourceTest: XCTestCase {

  var trialDetailDataSource: TrialDetailDataSource!

  override func setUp() {
    super.setUp()

    let note1 = TextNote()
    note1.ID = "TextNoteID"
    let note2 = PictureNote()
    note2.ID = "PictureNoteID"

    let trial = Trial()
    trial.trialNumberInExperiment = 1
    trial.notes = [note1, note2]

    let metadataManager = createMetadataManager()
    let experimentDataParser =
        ExperimentDataParser(experimentID: "TEST",
                             metadataManager: metadataManager,
                             sensorController: MockSensorController())
    trialDetailDataSource = TrialDetailDataSource(trial: trial,
                                                  experimentDataParser: experimentDataParser,
                                                  experimentInteractionOptions: .normal)
  }

  func testNumberOfSections() {
    let numberOfSections = TrialDetailDataSource.Section.numberOfSections

    // There should be a valid value for every index of the section count.
    for index in 0..<numberOfSections {
      XCTAssertNotNil(TrialDetailDataSource.Section(rawValue: index))
    }

    // There should not be a valid value beyond the section count.
    XCTAssertNil(TrialDetailDataSource.Section(rawValue: numberOfSections))
  }

  func testNoteForIndexPath() {
    if FeatureFlags.isActionAreaEnabled {
      let note = trialDetailDataSource.noteForIndexPath(IndexPath(item: 1, section: 1))
      XCTAssertEqual("PictureNoteID", note.ID, "ID should match the expected note.")
    } else {
      var note = trialDetailDataSource.noteForIndexPath(IndexPath(item: 1, section: 1))
      XCTAssertEqual("TextNoteID", note.ID, "ID should match the expected note.")

      note = trialDetailDataSource.noteForIndexPath(IndexPath(item: 2, section: 1))
      XCTAssertEqual("PictureNoteID", note.ID, "ID should match the expected note.")
    }
  }

  func testIsAddNoteIndexPath() {
    if FeatureFlags.isActionAreaEnabled {
      XCTAssertFalse(trialDetailDataSource.isAddNoteIndexPath(IndexPath(item: 0, section: 2)))
    } else {
      XCTAssertTrue(trialDetailDataSource.isAddNoteIndexPath(IndexPath(item: 0, section: 2)))
    }
  }

  func testIsTrialHeaderIndexPath(_ indexPath: IndexPath) {
    XCTAssertTrue(trialDetailDataSource.isTrialHeaderIndexPath(IndexPath(item: 0, section: 0)))
  }

  func testIsTrialNoteIndexPath(_ indexPath: IndexPath) {
    // Should be valid only for items corresponding to notes.
    XCTAssertTrue(trialDetailDataSource.isTrialNoteIndexPath(IndexPath(item: 0, section: 1)))
    XCTAssertTrue(trialDetailDataSource.isTrialNoteIndexPath(IndexPath(item: 1, section: 1)))
    XCTAssertFalse(trialDetailDataSource.isTrialNoteIndexPath(IndexPath(item: 2, section: 1)))
  }

  func testAddNote(_ note: Note) {
    XCTAssertEqual(2, trialDetailDataSource.numberOfItemsInSection(1))

    let newNote = TextNote()
    newNote.ID = "NewTextNoteID"
    trialDetailDataSource.addNote(newNote)

    XCTAssertEqual(3, trialDetailDataSource.numberOfItemsInSection(1))
    let note = trialDetailDataSource.noteWithID("NewTextNoteID")
    XCTAssertEqual("NewTextNoteID", note!.ID)
  }

  func testRemoveNote() {
    XCTAssertEqual(2, trialDetailDataSource.displayTrial.notes.count)

    trialDetailDataSource.removeNote(withID: "TextNoteID")
    XCTAssertEqual(1, trialDetailDataSource.displayTrial.notes.count)
    XCTAssertNil(trialDetailDataSource.displayTrial.notes.index(where: { $0.ID == "TextNoteID" }))
  }

}
