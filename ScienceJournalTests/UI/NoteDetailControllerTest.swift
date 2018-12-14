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

import third_party_objective_c_material_components_ios_components_TextFields_TextFields

class NoteDetailControllerTest: XCTestCase {

  var noteDetailVC: TestCaptionableNoteDetailController!

  override func setUp() {
    super.setUp()

    let displayPictureNote = DisplayPictureNoteViewData(ID: "TESTID",
                                                        trialID: "TRIALID",
                                                        imagePath: "image/path",
                                                        timestamp: Timestamp(1000),
                                                        caption: "Foo")
    noteDetailVC = TestCaptionableNoteDetailController(displayNote: displayPictureNote)
  }

  func testUpdatingCaptionWithSameValue() {
    noteDetailVC.updateCaptionFromDisplayNote()
    XCTAssertEqual(noteDetailVC.currentCaption, "Foo")

    let newPictureNote = DisplayPictureNoteViewData(ID: "TESTID",
                                                    trialID: "TRIALID",
                                                    imagePath: "image/path/2",
                                                    timestamp: Timestamp(2000),
                                                    caption: "Foo")

    noteDetailVC.displayNote = newPictureNote
    noteDetailVC.updateCaptionFromDisplayNote()
    XCTAssertEqual(noteDetailVC.currentCaption, "Foo")
  }

  func testUpdatingCaptionWithNewValue() {
    noteDetailVC.updateCaptionFromDisplayNote()
    XCTAssertEqual(noteDetailVC.currentCaption, "Foo")

    let newPictureNote = DisplayPictureNoteViewData(ID: "TESTID",
                                                    trialID: "TRIALID",
                                                    imagePath: "image/path/2",
                                                    timestamp: Timestamp(2000),
                                                    caption: "Bar")

    noteDetailVC.displayNote = newPictureNote
    noteDetailVC.updateCaptionFromDisplayNote()
    XCTAssertEqual(noteDetailVC.currentCaption, "Foo / Bar")
  }

  func testUpdatingCaptionWithEmptyString() {
    let pictureNote = DisplayPictureNoteViewData(ID: "TESTID",
                                                 trialID: "TRIALID",
                                                 imagePath: "image/path/2",
                                                 timestamp: Timestamp(2000),
                                                 caption: "")
    noteDetailVC.displayNote = pictureNote
    noteDetailVC.updateCaptionFromDisplayNote()

    let newPictureNote = DisplayPictureNoteViewData(ID: "TESTID",
                                                    trialID: "TRIALID",
                                                    imagePath: "image/path/2",
                                                    timestamp: Timestamp(2000),
                                                    caption: "Foo")
    noteDetailVC.displayNote = newPictureNote
    noteDetailVC.updateCaptionFromDisplayNote()

    XCTAssertEqual(noteDetailVC.currentCaption, "Foo")
  }

  // MARK: - TestNoteDetailController

  class TestCaptionableNoteDetailController: CaptionableNoteDetailController {
    var displayNote: DisplayNote
    var currentCaption: String?

    init(displayNote: DisplayNote) {
      self.displayNote = displayNote
    }
  }

}
