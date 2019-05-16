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

class ExperimentStateManagerTest: XCTestCase, ExperimentStateListener {

  var experimentStateManager: ExperimentStateManager!
  var metadataManager: MetadataManager!
  var sensorDataManager: SensorDataManager!

  var experimentStateArchiveStateChangedCalled = false
  var experimentStateDeletedCalled = false
  var experimentStateRestoredCalled = false

  var undoBlock: (() -> Void)?

  override func setUp() {
    super.setUp()
    metadataManager = createMetadataManager()
    sensorDataManager = createSensorDataManager()
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "ExperimentStateManagerTest",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    experimentStateManager = ExperimentStateManager(experimentDataDeleter: experimentDataDeleter,
                                                    metadataManager: metadataManager,
                                                    sensorDataManager: sensorDataManager)
    experimentStateManager.addListener(self)
  }

  override func tearDown() {
    experimentStateManager.removeListener(self)
    super.tearDown()
  }

  func testToggleArchiveStateForExperiment() {
    let (experiment, _) = metadataManager.createExperiment()
    XCTAssertFalse(metadataManager.isExperimentArchived(withID: experiment.ID))

    experimentStateManager.toggleArchiveStateForExperiment(withID: experiment.ID)

    XCTAssertTrue(experimentStateArchiveStateChangedCalled)
    XCTAssertTrue(metadataManager.isExperimentArchived(withID: experiment.ID))
    XCTAssertNotNil(undoBlock)

    experimentStateArchiveStateChangedCalled = false

    undoBlock!()
    XCTAssertTrue(experimentStateArchiveStateChangedCalled)
    XCTAssertFalse(metadataManager.isExperimentArchived(withID: experiment.ID))
  }

  func testDeleteExperiment() {
    let (experiment, _) = metadataManager.createExperiment()
    experiment.notes = [TextNote(text: "Note text")]
    metadataManager.saveExperiment(experiment)
    XCTAssertNotNil(metadataManager.experiment(withID: experiment.ID))

    experimentStateManager.deleteExperiment(withID: experiment.ID)

    XCTAssertNil(metadataManager.experiment(withID: experiment.ID))
    XCTAssertTrue(experimentStateDeletedCalled)
    XCTAssertNotNil(undoBlock)

    undoBlock!()

    XCTAssertNotNil(metadataManager.experiment(withID: experiment.ID))
    XCTAssertTrue(experimentStateRestoredCalled)
  }

  func testDeleteEmptyExperiment() {
    let (experiment, _) = metadataManager.createExperiment()
    XCTAssertNotNil(metadataManager.experiment(withID: experiment.ID))

    experimentStateManager.deleteExperiment(withID: experiment.ID)

    XCTAssertNil(metadataManager.experiment(withID: experiment.ID))
    XCTAssertTrue(experimentStateDeletedCalled)
    XCTAssertNil(undoBlock)
  }

  // MARK: - ExperimentStateListener

  func experimentStateArchiveStateChanged(forExperiment experiment: Experiment,
                                          overview: ExperimentOverview,
                                          undoBlock: @escaping () -> Void) {
    experimentStateArchiveStateChangedCalled = true
    self.undoBlock = undoBlock
  }

  func experimentStateDeleted(_ deletedExperiment: DeletedExperiment, undoBlock: (() -> Void)?) {
    experimentStateDeletedCalled = true
    self.undoBlock = undoBlock
  }

  func experimentStateRestored(_ experiment: Experiment, overview: ExperimentOverview) {
    experimentStateRestoredCalled = true
  }

}
