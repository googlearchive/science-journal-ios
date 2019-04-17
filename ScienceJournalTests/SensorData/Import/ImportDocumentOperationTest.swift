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

class ImportDocumentOperationTest: XCTestCase {

  let operationQueue = GSJOperationQueue()

  func testImportExperimentWithoutTrialsDoesNotFail() {
    let metadataManager = MetadataManager.testingInstance
    let sensorDataManager = SensorDataManager.testStore
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "MockUser",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    let documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                          metadataManager: metadataManager,
                                          sensorDataManager: sensorDataManager)

    // Create an experiment with no trials.
    let (experiment, _) = metadataManager.createExperiment()
    experiment.notes.append(TextNote(text: "test"))
    metadataManager.saveExperiment(experiment)

    // Create an sj file for it.
    let exportExpectation = expectation(description: "Export document finished.")
    var exportURL: URL!
    documentManager.createExportDocument(forExperimentWithID: experiment.ID) { url in
      exportURL = url
      exportExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)

    // Set up the import document operation.
    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let baseFilename = ProcessInfo.processInfo.globallyUniqueString + "_import"
    let filename = baseFilename + "." + "sj"
    let zipURL = tempDirectoryURL.appendingPathComponent(filename)

    let zipFilename = baseFilename + "_extracted"
    let extractionURL = tempDirectoryURL.appendingPathComponent(zipFilename)

    let experimentID = UUID().uuidString
    let experimentURL = metadataManager.experimentDirectoryURL(for: experimentID)

    let importDocumentOperation =
        ImportDocumentOperation(sourceURL: exportURL,
                                zipURL: zipURL,
                                extractionURL: extractionURL,
                                experimentURL: experimentURL,
                                sensorDataManager: SensorDataManager.testStore,
                                metadataManager: metadataManager)

    let finishedExpectation = expectation(description: "Import document finished.")
    importDocumentOperation.addObserver(BlockObserver { (_, errors) in
      XCTAssertEqual(
          errors.count,
          0,
          "There should not be any errors when importing an experiment that has no trials.")

      let experiment = metadataManager.experiment(withID: experimentID)
      XCTAssertEqual(experiment!.ID, experimentID, "The ID should match the imported experiment's.")
      XCTAssertEqual(experiment!.notes.count, 1, "There should be one note.")
      XCTAssertEqual((experiment!.notes[0] as! TextNote).text,
                     "test",
                     "The text of the note should match.")
      XCTAssertEqual(experiment!.trials.count, 0, "The experiment should not have any trials.")

      finishedExpectation.fulfill()
    })
    operationQueue.addOperation(importDocumentOperation)
    waitForExpectations(timeout: 1)
  }

}
