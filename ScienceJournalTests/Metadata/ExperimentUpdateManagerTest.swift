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

class ExperimentUpdateManagerTest: XCTestCase, ExperimentUpdateListener {

  var experiment: Experiment!
  var overview: ExperimentOverview!
  var experimentUpdateManager: ExperimentUpdateManager!
  let metadataManager = MetadataManager.testingInstance

  var experimentUpdateTrialNoteAddedCalled = false
  var experimentUpdateExperimentNoteAddedCalled = false
  var experimentUpdateExperimentNoteDeletedCalled = false
  var experimentUpdateTrialNoteDeletedCalled = false
  var experimentUpdateNoteUpdatedCalled = false
  var experimentUpdateTrialUpdatedCalled = false
  var experimentUpdateTrialAddedCalled = false
  var experimentUpdateTrialDeletedCalled = false
  var experimentUpdateTrialArchiveStateChangedCalled = false

  var undoBlock: (() -> Void)?

  override func setUp() {
    super.setUp()
    let (experiment, overview) = metadataManager.createExperiment()
    self.experiment = experiment
    self.overview = overview
    let sensorDataManager = SensorDataManager.testStore
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "TestAccountID",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    experimentUpdateManager =
        ExperimentUpdateManager(experiment: experiment,
                                experimentDataDeleter: experimentDataDeleter,
                                metadataManager: metadataManager,
                                sensorDataManager: sensorDataManager)
    experimentUpdateManager.addListener(self)
  }

  override func tearDown() {
    // Delete test directory.
    metadataManager.deleteRootDirectory()

    experimentUpdateManager.removeListener(self)
    super.tearDown()
  }

  func testAddTrialNote() {
    let trial = Trial()
    experiment.trials.append(trial)

    XCTAssertEqual(0, trial.notes.count)
    XCTAssertFalse(experimentUpdateTrialNoteAddedCalled)

    let note = TextNote(text: "Making science is fun.")
    experimentUpdateManager.addTrialNote(note, trialID: trial.ID)

    XCTAssertEqual(1, trial.notes.count)
    XCTAssertEqual(note.ID, trial.notes[0].ID)
    XCTAssertTrue(experimentUpdateTrialNoteAddedCalled)
  }

  func testInsertTrialNote() {
    // Set up a trial with 2 notes.
    let trial = Trial()
    experiment.trials.append(trial)
    let note1 = TextNote(text: "Making science is fun.")
    let note2 = TextNote(text: "And educational.")
    trial.notes = [note1, note2]

    XCTAssertEqual(2, trial.notes.count)
    XCTAssertFalse(experimentUpdateTrialNoteAddedCalled)

    let note3 = TextNote(text: "And exciting")

    experimentUpdateManager.insertTrialNote(note3, trialID: trial.ID, atIndex: 1)

    XCTAssertEqual(3, trial.notes.count)
    XCTAssertEqual(note3.ID, trial.notes[1].ID)
    XCTAssertTrue(experimentUpdateTrialNoteAddedCalled)
  }

  func testAddExperimentNote() {
    XCTAssertEqual(0, experiment.notes.count)
    XCTAssertFalse(experimentUpdateExperimentNoteAddedCalled)

    let note = TextNote(text: "An experiment note.")

    experimentUpdateManager.addExperimentNote(note)

    XCTAssertEqual(1, experiment.notes.count)
    XCTAssertEqual(note.ID, experiment.notes[0].ID)
    XCTAssertTrue(experimentUpdateExperimentNoteAddedCalled)
  }

  func testInsertExperimentNote() {
    let note2 = TextNote(text: "Second experiment note.")
    let note3 = TextNote(text: "Third experiment note.")
    experiment.notes = [note2, note3]

    XCTAssertEqual(2, experiment.notes.count)
    XCTAssertFalse(experimentUpdateExperimentNoteAddedCalled)

    let note1 = TextNote(text: "First experiment note.")
    experimentUpdateManager.insertExperimentNote(note1, atIndex: 0, isUndo: false)

    XCTAssertEqual(3, experiment.notes.count)
    XCTAssertEqual(note1.ID, experiment.notes[0].ID)
    XCTAssertTrue(experimentUpdateExperimentNoteAddedCalled)
  }

  func testDeleteExperimentNote() {
    XCTAssertEqual(0, experiment.notes.count)

    let note1 = TextNote(text: "Test note 1.")
    let note2 = TextNote(text: "Test note 2.")
    experimentUpdateManager.addExperimentNote(note1)
    experimentUpdateManager.addExperimentNote(note2)
    XCTAssertEqual(2, experiment.notes.count)

    experimentUpdateManager.deleteExperimentNote(withID: note1.ID)

    XCTAssertEqual(1, experiment.notes.count)
    XCTAssertTrue(experimentUpdateExperimentNoteDeletedCalled)

    // Reset the delegate Bool.
    experimentUpdateExperimentNoteAddedCalled = false

    XCTAssertNotNil(undoBlock)
    undoBlock!()

    XCTAssertEqual(2, experiment.notes.count)
    XCTAssertTrue(experimentUpdateExperimentNoteAddedCalled)
    XCTAssertEqual(note1.ID, experiment.notes[0].ID)
  }

  func testDeleteTrialNote() {
    let note1 = TextNote(text: "Test note 1.")
    let note2 = TextNote(text: "Test note 2.")
    let trial = Trial()
    trial.notes = [note1, note2]
    experiment.trials.append(trial)

    XCTAssertEqual(2, trial.notes.count)
    XCTAssertFalse(experimentUpdateTrialNoteDeletedCalled)

    experimentUpdateManager.deleteTrialNote(withID: note1.ID, trialID: trial.ID)

    XCTAssertEqual(1, trial.notes.count)
    XCTAssertEqual(note2.ID, trial.notes[0].ID)
    XCTAssertTrue(experimentUpdateTrialNoteDeletedCalled)

    XCTAssertNotNil(undoBlock)
    undoBlock!()

    XCTAssertEqual(2, trial.notes.count)
    XCTAssertTrue(experimentUpdateTrialNoteAddedCalled)
    XCTAssertEqual(note1.ID, trial.notes[0].ID)
  }

  func testUpdateNoteCaption() {
    // Make two notes with the same ID.
    let experimentNote = PictureNote()
    let trialNote = PictureNote()
    trialNote.ID = experimentNote.ID

    let trial = Trial()
    experiment.trials = [trial]
    experimentUpdateManager.addExperimentNote(experimentNote)
    experimentUpdateManager.addTrialNote(trialNote, trialID: trial.ID)

    XCTAssertNil(trial.notes[0].caption)
    XCTAssertNil(experiment.notes[0].caption)
    XCTAssertFalse(experimentUpdateNoteUpdatedCalled)

    experimentUpdateManager.updateNoteCaption("Experiment note caption",
                                              forNoteWithID: experimentNote.ID,
                                              trialID: nil)

    XCTAssertNil(trial.notes[0].caption)
    XCTAssertEqual("Experiment note caption", experiment.notes[0].caption!.text)
    XCTAssertTrue(experimentUpdateNoteUpdatedCalled)

    // Reset the delegate Bool.
    experimentUpdateNoteUpdatedCalled = false

    experimentUpdateManager.updateNoteCaption("Trial note caption",
                                              forNoteWithID: trialNote.ID,
                                              trialID: trial.ID)

    XCTAssertEqual("Trial note caption", trial.notes[0].caption!.text)
    XCTAssertEqual("Experiment note caption", experiment.notes[0].caption!.text)
    XCTAssertTrue(experimentUpdateNoteUpdatedCalled)
  }

  func testUpdateTextNoteCaption() {
    let textNote = TextNote(text: "A note")
    experimentUpdateManager.addExperimentNote(textNote)

    XCTAssertNil(textNote.caption)

    experimentUpdateManager.updateNoteCaption("A caption", forNoteWithID: textNote.ID, trialID: nil)

    XCTAssertNil(textNote.caption)
    XCTAssertFalse(experimentUpdateNoteUpdatedCalled)
  }

  func testUpdateText() {
    // Make two notes with the same ID.
    let experimentNote = TextNote(text: "Experiment text note.")
    let trialNote = TextNote(text: "Trial text note.")
    trialNote.ID = experimentNote.ID

    let trial = Trial()
    experiment.trials = [trial]
    experimentUpdateManager.addExperimentNote(experimentNote)
    experimentUpdateManager.addTrialNote(trialNote, trialID: trial.ID)

    XCTAssertEqual("Trial text note.", (trial.notes[0] as! TextNote).text)
    XCTAssertEqual("Experiment text note.", (experiment.notes[0] as! TextNote).text)
    XCTAssertFalse(experimentUpdateNoteUpdatedCalled)

    experimentUpdateManager.updateText("Experiment Replaced.",
                                       forNoteWithID: experimentNote.ID,
                                       trialID: nil)

    XCTAssertEqual("Trial text note.", (trial.notes[0] as! TextNote).text)
    XCTAssertEqual("Experiment Replaced.", (experiment.notes[0] as! TextNote).text)
    XCTAssertTrue(experimentUpdateNoteUpdatedCalled)

    // Reset the delegate Bool.
    experimentUpdateNoteUpdatedCalled = false

    experimentUpdateManager.updateText("Trial Replaced.",
                                       forNoteWithID: trialNote.ID,
                                       trialID: trial.ID)

    XCTAssertEqual("Trial Replaced.", (trial.notes[0] as! TextNote).text)
    XCTAssertEqual("Experiment Replaced.", (experiment.notes[0] as! TextNote).text)
    XCTAssertTrue(experimentUpdateNoteUpdatedCalled)
  }

  func testUpdateNonTextNoteText() {
    let snapshotNote = SnapshotNote()
    experimentUpdateManager.addExperimentNote(snapshotNote)

    experimentUpdateManager.updateText("Into the void.",
                                       forNoteWithID: snapshotNote.ID,
                                       trialID: nil)

    XCTAssertFalse(experimentUpdateNoteUpdatedCalled)
  }

  func testUpdateTrial() {
    let trial = Trial()
    experiment.trials = [trial]

    experimentUpdateManager.updateTrial(cropRange: ChartAxis(min: 10, max: 20),
                                        name: nil,
                                        captionString: nil,
                                        forTrialID: trial.ID)

    XCTAssertEqual(ChartAxis(min: 10, max: 20), trial.cropRange)
    XCTAssertTrue(experimentUpdateTrialUpdatedCalled)

    // Reset the delegate Bool.
    experimentUpdateTrialUpdatedCalled = false

    experimentUpdateManager.updateTrial(cropRange: nil,
                                        name: "A great recording.",
                                        captionString: nil,
                                        forTrialID: trial.ID)

    XCTAssertEqual(ChartAxis(min: 10, max: 20), trial.cropRange)
    XCTAssertEqual("A great recording.", trial.title)
    XCTAssertTrue(experimentUpdateTrialUpdatedCalled)

    // Reset the delegate Bool.
    experimentUpdateTrialUpdatedCalled = false

    experimentUpdateManager.updateTrial(cropRange: nil,
                                        name: nil,
                                        captionString: "This is a caption.",
                                        forTrialID: trial.ID)

    XCTAssertEqual(ChartAxis(min: 10, max: 20), trial.cropRange)
    XCTAssertEqual("A great recording.", trial.title)
    XCTAssertEqual("This is a caption.", trial.caption?.text)
    XCTAssertTrue(experimentUpdateTrialUpdatedCalled)
  }

  func testUpdateTrialNoChanges() {
    let trial = Trial()
    experiment.trials = [trial]
    experimentUpdateManager.updateTrial(cropRange: nil,
                                        name: nil,
                                        captionString: nil,
                                        forTrialID: trial.ID)
    XCTAssertFalse(experimentUpdateTrialUpdatedCalled)
  }

  func testAddTrial() {
    XCTAssertEqual(0, experiment.trials.count)
    XCTAssertFalse(experimentUpdateTrialAddedCalled)
    XCTAssertEqual(0, experiment.totalTrials)

    let trial = Trial()
    experimentUpdateManager.addTrial(trial, recording: true)

    XCTAssertEqual(1, experiment.trials.count)
    XCTAssertEqual(trial.ID, experiment.trials[0].ID)
    XCTAssertTrue(experimentUpdateTrialAddedCalled)
    XCTAssertEqual(1, experiment.totalTrials)

    let trial2 = Trial()
    experimentUpdateManager.addTrial(trial2, recording: false)
    XCTAssertEqual(2, experiment.trials.count)
    XCTAssertEqual(1, experiment.totalTrials, "Non-recording trials don't increment counters.")

    let trial3 = Trial()
    experimentUpdateManager.addTrial(trial3, recording: true)
    XCTAssertEqual(3, experiment.trials.count)
    XCTAssertEqual(2, experiment.totalTrials, "Recording trials increment counters.")
  }

  func testDeleteTrial() {
    XCTAssertEqual(0, experiment.trials.count)
    XCTAssertEqual(0, experiment.totalTrials)

    let trial = Trial()
    experimentUpdateManager.addTrial(trial, recording: true)

    XCTAssertEqual(1, experiment.trials.count)
    XCTAssertEqual(1, experiment.totalTrials)

    experimentUpdateManager.deleteTrial(withID: trial.ID)

    XCTAssertEqual(0, experiment.trials.count)
    XCTAssertEqual(1, experiment.totalTrials)
    XCTAssertNotNil(undoBlock)
    XCTAssertTrue(experimentUpdateTrialDeletedCalled)

    // Reset the delegate Bool.
    experimentUpdateTrialAddedCalled = false

    undoBlock!()

    XCTAssertEqual(1, experiment.trials.count)
    XCTAssertEqual(1, experiment.totalTrials)
    XCTAssertEqual(trial.ID, experiment.trials[0].ID)
    XCTAssertTrue(experimentUpdateTrialAddedCalled)
  }

  func testArchiveTrial() {
    let trial = Trial()
    experimentUpdateManager.addTrial(trial, recording: true)
    XCTAssertFalse(trial.isArchived)
    XCTAssertFalse(experimentUpdateTrialArchiveStateChangedCalled)

    experimentUpdateManager.toggleArchivedState(forTrialID: trial.ID)

    XCTAssertTrue(trial.isArchived)
    XCTAssertTrue(experimentUpdateTrialArchiveStateChangedCalled)

    // Reset the delegate Bool.
    experimentUpdateTrialArchiveStateChangedCalled = false

    XCTAssertNotNil(undoBlock)
    undoBlock!()

    XCTAssertFalse(trial.isArchived)
    XCTAssertTrue(experimentUpdateTrialArchiveStateChangedCalled)
  }

  func testExperimentChangesWithExperimentNoteDeleteUndo() {
    let experiment = experimentUpdateManager.experiment
    XCTAssertEqual(0, experiment.changes.count)

    let note = TextNote(text: "text")
    experimentUpdateManager.addExperimentNote(note)
    XCTAssertEqual(1, experiment.changes.count)
    experiment.changes[0].assert(isElement: .note, changeType: .add, ID: note.ID)

    experimentUpdateManager.deleteExperimentNote(withID: note.ID)
    XCTAssertEqual(2, experiment.changes.count)
    experiment.changes[1].assert(isElement: .note, changeType: .delete, ID: note.ID)

    XCTAssertNotNil(undoBlock)
    undoBlock!()

    XCTAssertEqual(3, experiment.changes.count)
    experiment.changes[2].assert(isElement: .note, changeType: .modify, ID: note.ID)
  }

  func testExperimentChangesWithTrialNoteDeleteUndo() {
    let experiment = experimentUpdateManager.experiment
    XCTAssertEqual(0, experiment.changes.count)

    let trial = Trial()
    experimentUpdateManager.addTrial(trial, recording: false)
    experiment.changes[0].assert(isElement: .trial, changeType: .add, ID: trial.ID)
    XCTAssertEqual(1, experiment.changes.count)

    let note = TextNote(text: "text")
    experimentUpdateManager.addTrialNote(note, trialID: trial.ID)
    XCTAssertEqual(2, experiment.changes.count)
    experiment.changes[1].assert(isElement: .note, changeType: .add, ID: note.ID)

    experimentUpdateManager.deleteTrialNote(withID: note.ID, trialID: trial.ID)
    XCTAssertEqual(3, experiment.changes.count)
    experiment.changes[2].assert(isElement: .note, changeType: .delete, ID: note.ID)

    XCTAssertNotNil(undoBlock)
    undoBlock!()

    XCTAssertEqual(4, experiment.changes.count)
    experiment.changes[3].assert(isElement: .note, changeType: .modify, ID: note.ID)
  }

  func testExperimentChangesWithTrialDeleteUndo() {
    let experiment = experimentUpdateManager.experiment
    XCTAssertEqual(0, experiment.changes.count)

    let trial = Trial()
    experimentUpdateManager.addTrial(trial, recording: false)
    XCTAssertEqual(1, experiment.changes.count)

    experimentUpdateManager.deleteTrial(withID: trial.ID)
    XCTAssertEqual(2, experiment.changes.count)
    experiment.changes[1].assert(isElement: .trial, changeType: .delete, ID: trial.ID)

    XCTAssertNotNil(undoBlock)
    undoBlock!()

    XCTAssertEqual(3, experiment.changes.count)
    experiment.changes[2].assert(isElement: .trial, changeType: .modify, ID: trial.ID)
  }

  func testRemovingUsedCoverImage() {
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!

    XCTAssertNil(experiment.imagePath)
    XCTAssertNil(overview.imagePath)

    let imagePath = "assets/note_image.jpg"
    metadataManager.saveImage(image,
                              atPicturePath: imagePath,
                              experimentID: experiment.ID)
    let pictureNote = PictureNote()
    pictureNote.filePath = imagePath
    experiment.addNote(pictureNote)

    let noteImageURL = metadataManager.pictureFileURL(for: imagePath,
                                                      experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: noteImageURL.path), "Note image exists")

    metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: imagePath,
                                                          experiment: experiment)

    XCTAssertEqual(imagePath, experiment.imagePath)
    XCTAssertEqual(imagePath, overview.imagePath)

    let image2 = UIImage(named: "select_item_button",
                         in: Bundle.currentBundle,
                         compatibleWith: nil)!
    let imageData = image2.jpegData(compressionQuality: 0.8)
    experimentUpdateManager.setCoverImageData(imageData, metadata: nil)

    XCTAssertTrue(FileManager.default.fileExists(atPath: noteImageURL.path),
                  "Note image still exists")
  }

  func testRemovingUnusedCoverImage() {
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    let imageData = image.jpegData(compressionQuality: 0.8)

    XCTAssertNil(experiment.imagePath)
    XCTAssertNil(overview.imagePath)

    metadataManager.saveCoverImageData(imageData, metadata: nil, forExperiment: experiment)

    XCTAssertNotNil(experiment.imagePath)
    XCTAssertNotNil(overview.imagePath)

    let coverImageURL1 = metadataManager.pictureFileURL(for: experiment.imagePath!,
                                                        experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: coverImageURL1.path))

    experimentUpdateManager.setCoverImageData(imageData, metadata: nil)

    XCTAssertNotNil(experiment.imagePath)
    XCTAssertNotNil(overview.imagePath)

    let coverImageURL2 = metadataManager.pictureFileURL(for: experiment.imagePath!,
                                                        experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: coverImageURL2.path),
                  "New cover image exists.")
    XCTAssertFalse(FileManager.default.fileExists(atPath: coverImageURL1.path),
                   "Original cover image doesn't exist.")
  }

  // MARK: - ExperimentUpdateListener

  func experimentUpdateTrialNoteAdded(_ note: Note, toTrial trial: Trial) {
    experimentUpdateTrialNoteAddedCalled = true
  }

  func experimentUpdateExperimentNoteAdded(_ note: Note, toExperiment experiment: Experiment) {
    experimentUpdateExperimentNoteAddedCalled = true
  }

  func experimentUpdateExperimentNoteDeleted(_ note: Note,
                                             experiment: Experiment,
                                             undoBlock: @escaping () -> Void) {
    experimentUpdateExperimentNoteDeletedCalled = true
    self.undoBlock = undoBlock
  }

  func experimentUpdateTrialNoteDeleted(_ note: Note,
                                        trial: Trial,
                                        experiment: Experiment,
                                        undoBlock: @escaping () -> Void) {
    experimentUpdateTrialNoteDeletedCalled = true
    self.undoBlock = undoBlock
  }

  func experimentUpdateNoteUpdated(_ note: Note, trial: Trial?, experiment: Experiment) {
    experimentUpdateNoteUpdatedCalled = true
  }

  func experimentUpdateTrialUpdated(_ trial: Trial, experiment: Experiment, updatedStats: Bool) {
    experimentUpdateTrialUpdatedCalled = true
  }

  func experimentUpdateTrialAdded(_ trial: Trial,
                                  toExperiment experiment: Experiment,
                                  recording isRecording: Bool) {
    experimentUpdateTrialAddedCalled = true
  }

  func experimentUpdateTrialDeleted(_ trial: Trial,
                                    fromExperiment experiment: Experiment,
                                    undoBlock: (() -> Void)?) {
    experimentUpdateTrialDeletedCalled = true
    self.undoBlock = undoBlock
  }

  func experimentUpdateTrialArchiveStateChanged(_ trial: Trial,
                                                experiment: Experiment,
                                                undoBlock: @escaping () -> Void) {
    experimentUpdateTrialArchiveStateChangedCalled = true
    self.undoBlock = undoBlock
  }

}
