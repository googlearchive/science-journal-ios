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

class DisplayPictureNoteTest: XCTestCase {

  func testImageFileExists() {
    // Create a display picture note with a picture path, and assert the image file does not exist.
    let pictureNoteID = "testPictureID"
    let experimentID = "testExperimentID"
    let metadataManager = MetadataManager.testingInstance
    let picturePath = metadataManager.relativePicturePath(for: pictureNoteID)
    let pictureURL = metadataManager.pictureFileURL(for: picturePath, experimentID: experimentID)
    let displayPictureNote: DisplayPictureNote =
        DisplayPictureNoteViewData(ID: pictureNoteID,
                                   trialID: nil,
                                   imagePath: pictureURL.path,
                                   timestamp: Timestamp(123),
                                   caption: nil)

    XCTAssertFalse(displayPictureNote.imageFileExists, "The image file shouldn't exist.")

    // Now actually save an image to the path.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    metadataManager.saveImage(image, atPicturePath: picturePath, experimentID: experimentID)
    XCTAssertTrue(displayPictureNote.imageFileExists, "The image file should exist.")
  }

}
