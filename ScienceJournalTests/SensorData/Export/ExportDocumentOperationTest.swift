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

class ExportDocumentOperationTest: XCTestCase {

  let metadataManager = MetadataManager.testingInstance
  var documentManager: DocumentManager!
  let operationQueue = GSJOperationQueue()

  override func setUp() {
    super.setUp()
    let sensorDataManager = SensorDataManager.testStore
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "MockUser",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                      metadataManager: metadataManager,
                                      sensorDataManager: sensorDataManager)
  }

  func testExportedExperiment() {
    let sensorDataManager = SensorDataManager.testStore

    let (experiment, _) = metadataManager.createExperiment()
    let exportExperimentID = experiment.ID
    experiment.notes = [PictureNote(), TextNote(text: "note")]
    experiment.trials = [Trial(), Trial(), Trial()]

    XCTAssertEqual(1, metadataManager.experimentOverviews.count)

    let coverImage = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    metadataManager.saveImage(coverImage, atPicturePath: "assets/123_cover_image.jpg",
                              experimentID: experiment.ID)
    experiment.imagePath = "assets/123_cover_image.jpg"

    metadataManager.saveExperiment(experiment)

    let experimentURL = metadataManager.experimentDirectoryURL(for: experiment.ID)
    let coverImageURL = metadataManager.pictureFileURL(for: "assets/123_cover_image.jpg",
                                                       experimentID: experiment.ID)

    let exportDocument = ExportDocumentOperation(coverImageURL: coverImageURL,
                                                 experiment: experiment,
                                                 experimentURL: experimentURL,
                                                 sensorDataManager: sensorDataManager)

    let expectation = self.expectation(description: "operation finished")
    exportDocument.addObserver(BlockObserver { [unowned self] op, errors in
      let documentURL = (op as! ExportDocumentOperation).documentURL

      // The best way to test the exported experiment is to import it.
      _ = self.documentManager.handleImportURL(documentURL)

      NotificationCenter.default.addObserver(forName: .documentManagerDidImportExperiment,
                                             object: nil,
                                             queue: nil,
                                             using: { [weak self] notification in
        guard let self = self else { return }
        XCTAssertEqual(2, self.metadataManager.experimentOverviews.count)

        let importExperimentID = self.metadataManager.experimentOverviews[1].experimentID

        XCTAssertNotEqual(importExperimentID,
                          exportExperimentID,
                          "Imported experiment is a different experiment than the exported one.")

        let importedExperiment = self.metadataManager.experiment(withID: importExperimentID)!

        XCTAssertEqual(2, importedExperiment.notes.count)
        XCTAssertEqual(3, importedExperiment.trials.count)
        XCTAssertEqual("/assets/ExperimentCoverImage.jpg", importedExperiment.imagePath)

        let importedExperimentURL =
            self.metadataManager.experimentDirectoryURL(for: importExperimentID)
        let coverImageURL =
            importedExperimentURL.appendingPathComponent("assets/ExperimentCoverImage.jpg")

        XCTAssertTrue(FileManager.default.fileExists(atPath: coverImageURL.path))

        expectation.fulfill()
      })
    })

    operationQueue.addOperation(exportDocument)

    waitForExpectations(timeout: 0.5)
  }

}
