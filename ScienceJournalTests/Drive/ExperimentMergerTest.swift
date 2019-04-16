/*
 *  Copyright 2019 Google LLC. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License")
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

class ExperimentMergerTest: XCTestCase {

  let experimentLocal = Experiment(ID: "experimentId")
  var experimentMerger: ExperimentMerger!

  override func setUp() {
    super.setUp()
    experimentMerger = ExperimentMerger(localExperiment: experimentLocal)
  }

  func testMergeIdenticalExperiments() {
    experimentLocal.setTitle("Title")

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual("Title", experimentLocal.title)
    XCTAssertEqual(1, experimentLocal.changes.count)
  }

  func testMergeIdenticalExperimentsWithTwoChanges() {
    experimentLocal.setTitle("Title")
    experimentLocal.setTitle("Title2")

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual("Title2", experimentLocal.title)
    XCTAssertEqual(2, experimentLocal.changes.count)
  }

  func testMergeChangedExperimentTitleChange() {
    experimentLocal.setTitle("Title")

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    experimentRemote.setTitle("Title2")
    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual("Title2", experimentLocal.title, "Local has the latest title.")
    XCTAssertEqual(2, experimentLocal.changes.count)
  }

  func testMergeChangedExperimentTitleChangeTwice() {
    experimentLocal.setTitle("Title")

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    experimentRemote.setTitle("Title2")
    experimentRemote.setTitle("Title3")
    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual("Title3", experimentLocal.title, "Local has the latest title.")
    XCTAssertEqual(3, experimentLocal.changes.count)
  }

  func testMergeChangedExperimentTitleChangeConflict() {
    experimentLocal.setTitle("Title")

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Both experiments alter the title.
    experimentLocal.setTitle("Title2")
    experimentRemote.setTitle("Title3")
    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual("Title2 / Title3", experimentLocal.title, "Local has a combined title.")
    XCTAssertEqual(3, experimentLocal.changes.count)
  }

  func testMergeExperimentsLabelAddOnly() {
    let note = newTextNoteWithCaption("caption")

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Remote adds a note.
    experimentRemote.addNote(note)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(0, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(0, experimentLocal.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count, "Local reflects added note.")
  }

  func testMergeExperimentsLabelAddAndEdit() {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Remote updates a note.
    let note2 = TextNote(proto: note.proto)
    let caption2 = Caption()
    caption2.text = "caption2"
    note2.caption = caption2
    experimentRemote.updateNote(note2)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    XCTAssertEqual(experimentRemote.notes[0].caption?.text,
                   experimentLocal.notes[0].caption?.text,
                   "Local reflects note update.")
  }

  func testMergeExperimentsLabelAddAndDelete() {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Remote removes the note.
    experimentRemote.removeNote(withID: note.ID)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(0, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(0, experimentRemote.notes.count)
    XCTAssertEqual(0, experimentLocal.notes.count, "Local reflects note deletion.")
  }

  func testMergeExperimentsLabelAddAndEditDelete() {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    let note2 = TextNote(proto: note.proto)
    let caption2 = Caption()
    caption2.text = "caption2"
    note2.caption = caption2

    // Remote updates a note.
    experimentRemote.updateNote(note2)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    // Remote removes a note.
    experimentRemote.removeNote(withID: note.ID)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(0, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(3, experimentLocal.changes.count)

    XCTAssertEqual(0, experimentRemote.notes.count)
    XCTAssertEqual(0, experimentLocal.notes.count, "Local reflects note deletion.")
  }

  func testMergeExperimentsTrialAddOnly() {
    let trial = Trial()

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Remote adds a trial.
    experimentRemote.addTrial(trial, isUndo: false)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(0, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(0, experimentLocal.trials.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(1, experimentLocal.trials.count, "Local reflects added trial.")
  }

  func testMergeExperimentsTrialNoteAdd() {
    let trial = Trial()

    experimentLocal.addTrial(trial, isUndo: false)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    let note = newTextNoteWithCaption("caption")

    let remoteTrial = experimentRemote.trial(withID: trial.ID)!

    // Remote adds a note.
    remoteTrial.addNote(note, experiment: experimentRemote, isUndo: false)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(1, remoteTrial.notes.count)
    XCTAssertEqual(0, trial.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(1, remoteTrial.notes.count)
    XCTAssertEqual(1, trial.notes.count, "Local reflects added note.")
  }

  func testMergeExperimentsTrialAddAndDeleteLocalAndEditRemotely() {
    let trial = Trial()
    experimentLocal.addTrial(trial, isUndo: false)
    trial.setTitle("Foo", experiment: experimentLocal)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    // Change remote trial title.
    trial.setTitle("Bar", experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(1, experimentLocal.trials.count)

    experimentLocal.removeTrial(withID: trial.ID)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(3, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(0, experimentLocal.trials.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(4, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(0, experimentLocal.trials.count, "Local trial is still deleted.")
  }

  func testMergeExperimentsTrialNoteUpdate() {
    let trial = Trial()
    experimentLocal.addTrial(trial, isUndo: false)

    let note = newTextNoteWithCaption("caption")
    trial.addNote(note, experiment: experimentLocal, isUndo: false)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    let note2 = TextNote(proto: note.proto)
    let caption2 = Caption()
    caption2.text = "caption2"
    note2.caption = caption2

    let remoteTrial = experimentRemote.trial(withID: trial.ID)!

    // Remote updates trial note.
    remoteTrial.updateNote(note2, experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(1, remoteTrial.notes.count)
    XCTAssertEqual(1, trial.notes.count)

    XCTAssertEqual("caption", experimentLocal.trials[0].note(withID: note.ID)!.caption!.text)
    XCTAssertEqual("caption2", experimentRemote.trials[0].note(withID: note.ID)!.caption!.text)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(3, experimentLocal.changes.count)

    XCTAssertEqual(1, remoteTrial.notes.count)
    XCTAssertEqual(1, trial.notes.count)

    XCTAssertEqual("caption2",
                   experimentLocal.trials[0].note(withID: note.ID)!.caption!.text,
                   "Local reflects remote update.")
    XCTAssertEqual("caption2", experimentRemote.trials[0].note(withID: note.ID)!.caption!.text)
  }

  func testMergeExperimentsTrialNoteDelete() {
    let trial = Trial()
    experimentLocal.addTrial(trial, isUndo: false)

    let note = newTextNoteWithCaption("caption")
    trial.addNote(note, experiment: experimentLocal, isUndo: false)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    let remoteTrial = experimentRemote.trial(withID: trial.ID)!

    // Remote removes trial note.
    remoteTrial.removeNote(withID: note.ID, experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(0, remoteTrial.notes.count)
    XCTAssertEqual(1, trial.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(3, experimentLocal.changes.count)

    XCTAssertEqual(0, remoteTrial.notes.count)
    XCTAssertEqual(0, trial.notes.count, "Local reflects the note deletion.")
  }

  func testMergeExperimentsAddTrialAndNoteAndDeleteTrial() {
    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Add a trial to remote with a note.
    let trial = Trial()
    experimentRemote.addTrial(trial, isUndo: false)

    let note = newTextNoteWithCaption("caption")
    trial.addNote(note, experiment: experimentRemote, isUndo: false)

    XCTAssertEqual(1, trial.notes.count)

    // Remove the trial note.
    trial.removeNote(withID: note.ID, experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(0, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(0, experimentLocal.trials.count)

    XCTAssertEqual(0, trial.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(3, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(1, experimentLocal.trials.count)

    XCTAssertEqual(0, experimentLocal.trial(withID: trial.ID)!.notes.count,
                   "Local trial does not have a note.")
  }

  func testMergeExperimentsNoteEditConflict() {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    let note2 = TextNote(proto: note.proto)
    let caption2 = Caption()
    caption2.text = "caption2"
    note2.caption = caption2

    // Remote updates note.
    experimentRemote.updateNote(note2)

    let note3 = TextNote(proto: note.proto)
    let caption3 = Caption()
    caption3.text = "caption3"
    note3.caption = caption3

    // Local updates note.
    experimentLocal.updateNote(note3)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(4, experimentLocal.changes.count,
                   "Local experiment now has 4 changes, the modify from remote and an 'add' from" +
                       " duplicating the note")
    XCTAssertEqual(2, experimentLocal.notes.count,
                   "Local now has 2 notes, the original note " +
                       "and a copy of the remote modified note.")

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentRemote.notes.count)
  }

  func testMergeExperimentsNoteEditLocallyDeletedExternalConflict() {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    // Delete remote note.
    experimentRemote.removeNote(withID: note.ID)

    let note2 = TextNote(proto: note.proto)
    let caption2 = Caption()
    caption2.text = "caption2"
    note2.caption = caption2

    // Update local note.
    experimentLocal.updateNote(note2)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(0, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(3, experimentLocal.changes.count)
    XCTAssertEqual(0, experimentLocal.notes.count)
  }

  func testMergeExperimentsNoteEditedExternallyDeletedLocallyConflict() {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    XCTAssertEqual(1, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    let note2 = TextNote(proto: note.proto)
    note2.timestamp = 2222

    // Update remote note.
    experimentRemote.updateNote(note2)

    // Delete local note.
    experimentLocal.removeNote(withID: note.ID)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(0, experimentLocal.notes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    // After merge, local has deleted note.
    XCTAssertEqual(3, experimentLocal.changes.count)
    XCTAssertEqual(0, experimentLocal.notes.count)
    XCTAssertNil(experimentLocal.note(withID: note.ID), "The deleted note is still deleted.")

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(1, experimentRemote.notes.count)
  }

  func testMergeChangedTrialTitleChangeConflict() {
    let trial = Trial()
    trial.setTitle("Recording", experiment: experimentLocal)
    experimentLocal.addTrial(trial, isUndo: false)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    let remoteTrial = experimentRemote.trial(withID: trial.ID)!
    remoteTrial.setTitle("Recording2", experiment: experimentRemote)

    trial.setTitle("Recording3", experiment: experimentLocal)

    XCTAssertEqual(3, experimentRemote.changes.count)
    XCTAssertEqual(3, experimentLocal.changes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual("Recording3 / Recording2",
                   experimentLocal.trial(withID: trial.ID)!.title,
                   "Local has a combined title.")
    XCTAssertEqual(4, experimentLocal.changes.count)
  }

  func testTakeMaxTotalTrials() {
    // Add a greater total trials value to the local experiemnt than the remote experiment.
    let experimentRemote = Experiment(ID: experimentLocal.ID)
    experimentRemote.totalTrials = 5
    experimentLocal.totalTrials = 7

    // Merge the experiments and assert the local experiment gets the max value between the two
    // experiments for total trials.
    experimentMerger.mergeFrom(experiment: experimentRemote)
    XCTAssertEqual(7, experimentLocal.totalTrials)

    // Now make the remote experiment get the greater total trials value.
    experimentRemote.totalTrials = 9
    experimentLocal.totalTrials = 8

    // Merge the experiments and assert the local experiment still gets the max value between the
    // two experiments for total trials.
    experimentMerger.mergeFrom(experiment: experimentRemote)
    XCTAssertEqual(9, experimentLocal.totalTrials)
  }

  func testReplaceExperimentWithExternalExperiment() {
    // Add some data that should stay local during a merge to the local experiment, and different
    // data to the external experiment.
    let experimentRemote = Experiment(ID: experimentLocal.ID)

    // Available sensors.
    let sensor1 = Sensor.mock(sensorId: "AVAILABLE_SENSOR_1")
    let sensor2 = Sensor.mock(sensorId: "AVAILABLE_SENSOR_2")
    let sensor3 = Sensor.mock(sensorId: "AVAILABLE_SENSOR_3")
    let sensorEntry1 = SensorEntry(sensor: sensor1)
    let sensorEntry2 = SensorEntry(sensor: sensor2)
    let sensorEntry3 = SensorEntry(sensor: sensor3)
    experimentLocal.availableSensors = [sensorEntry1, sensorEntry2]
    experimentRemote.availableSensors = [sensorEntry3]

    XCTAssertEqual(2, experimentLocal.availableSensors.count)
    XCTAssertEqual(experimentLocal.availableSensors[0].sensorID, sensorEntry1.sensorID)
    XCTAssertEqual(experimentLocal.availableSensors[1].sensorID, sensorEntry2.sensorID)
    XCTAssertEqual(1, experimentRemote.availableSensors.count)
    XCTAssertEqual(experimentRemote.availableSensors[0].sensorID, sensorEntry3.sensorID)

    // Sensor triggers.
    let sensorTrigger1 = SensorTrigger(sensorID: "SENSOR_TRIGGER_1")
    let sensorTrigger2 = SensorTrigger(sensorID: "SENSOR_TRIGGER_2")
    let sensorTrigger3 = SensorTrigger(sensorID: "SENSOR_TRIGGER_3")

    experimentLocal.sensorTriggers = [sensorTrigger1, sensorTrigger2]
    experimentRemote.sensorTriggers = [sensorTrigger3]

    XCTAssertEqual(2, experimentLocal.sensorTriggers.count)
    XCTAssertEqual(experimentLocal.sensorTriggers[0].sensorID, sensorTrigger1.sensorID)
    XCTAssertEqual(experimentLocal.sensorTriggers[1].sensorID, sensorTrigger2.sensorID)
    XCTAssertEqual(1, experimentRemote.sensorTriggers.count)
    XCTAssertEqual(experimentRemote.sensorTriggers[0].sensorID, sensorTrigger3.sensorID)

    // Active trigger IDs, in sensor layouts.
    let sensorLayout1 = SensorLayout(sensorID: "SENSOR_LAYOUT_1", colorPalette: .blue)
    let sensorLayout2 = SensorLayout(sensorID: "SENSOR_LAYOUT_2", colorPalette: .green)
    let sensorLayout3 = SensorLayout(sensorID: "SENSOR_LAYOUT_3", colorPalette: .orange)

    experimentLocal.sensorLayouts = [sensorLayout1, sensorLayout2]
    experimentRemote.sensorLayouts = [sensorLayout3]

    XCTAssertEqual(2, experimentLocal.sensorLayouts.count)
    XCTAssertEqual("SENSOR_LAYOUT_1", experimentLocal.sensorLayouts[0].sensorID)
    XCTAssertEqual("SENSOR_LAYOUT_2", experimentLocal.sensorLayouts[1].sensorID)
    XCTAssertEqual(1, experimentRemote.sensorLayouts.count)
    XCTAssertEqual("SENSOR_LAYOUT_3", experimentRemote.sensorLayouts[0].sensorID)

    // Copy the local data into the external experiment.
    experimentMerger.replaceExperiment(withExperiment: experimentRemote)

    // Available sensors.
    XCTAssertEqual(2, experimentRemote.availableSensors.count)
    XCTAssertEqual(experimentRemote.availableSensors[0].sensorID, sensorEntry1.sensorID)
    XCTAssertEqual(experimentRemote.availableSensors[1].sensorID, sensorEntry2.sensorID)

    // Sensor triggers.
    XCTAssertEqual(2, experimentRemote.sensorTriggers.count)
    XCTAssertEqual(experimentRemote.sensorTriggers[0].sensorID, sensorTrigger1.sensorID)
    XCTAssertEqual(experimentRemote.sensorTriggers[1].sensorID, sensorTrigger2.sensorID)

    // Active sensor trigger IDs, in sensor layouts.
    XCTAssertEqual(2, experimentRemote.sensorLayouts.count)
    XCTAssertEqual("SENSOR_LAYOUT_1", experimentRemote.sensorLayouts[0].sensorID)
    XCTAssertEqual("SENSOR_LAYOUT_2", experimentRemote.sensorLayouts[1].sensorID)
  }

  func testCaptionConflictTwoValues() {
    assertCaptionConflict(withClientCaption: "AAA",
                          serverCaption: "BBB",
                          expectedMergedCaption: "BBB / AAA")
  }

  func testCaptionConflictOneIsNil() {
    assertCaptionConflict(withClientCaption: "AAA",
                          serverCaption: nil,
                          expectedMergedCaption: "AAA")
  }

  func testCaptionConflictBothNil() {
    assertCaptionConflict(withClientCaption: nil,
                          serverCaption: nil,
                          expectedMergedCaption: nil)
  }

  func testDeletedImageAssets() {
    let pictureNote1 = PictureNote()
    let pictureNote2 = PictureNote()
    let pictureNote3 = PictureNote()
    pictureNote1.filePath = "path/to/image/1"
    pictureNote2.filePath = "path/to/image/2"
    pictureNote3.filePath = "path/to/image/3"

    experimentLocal.addNote(pictureNote1)
    experimentLocal.addNote(pictureNote2)
    experimentLocal.addNote(pictureNote3)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Remote removes two notes.
    experimentRemote.removeNote(withID: pictureNote1.ID)
    experimentRemote.removeNote(withID: pictureNote2.ID)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(3, experimentLocal.notes.count)

    XCTAssertNil(experimentMerger.deletedAssetPaths)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(1, experimentRemote.notes.count)
    XCTAssertEqual(1, experimentLocal.notes.count)

    XCTAssertNotNil(experimentMerger.deletedAssetPaths)
    XCTAssertEqual(2, experimentMerger.deletedAssetPaths!.count)
    XCTAssertTrue(experimentMerger.deletedAssetPaths!.contains("path/to/image/1"))
    XCTAssertTrue(experimentMerger.deletedAssetPaths!.contains("path/to/image/2"))
    XCTAssertFalse(experimentMerger.deletedAssetPaths!.contains("path/to/image/3"))
  }

  func testDeletedTrialIDs() {
    let trial1 = Trial()
    let trial2 = Trial()
    let trial3 = Trial()
    experimentLocal.addTrial(trial1, isUndo: false)
    experimentLocal.addTrial(trial2, isUndo: false)
    experimentLocal.addTrial(trial3, isUndo: false)

    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    XCTAssertEqual(3, experimentRemote.trials.count)
    XCTAssertEqual(3, experimentLocal.trials.count)

    experimentRemote.removeTrial(withID: trial2.ID)
    experimentRemote.removeTrial(withID: trial3.ID)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(3, experimentLocal.trials.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(1, experimentRemote.trials.count)
    XCTAssertEqual(1, experimentLocal.trials.count)

    XCTAssertNotNil(experimentMerger.deletedTrialIDs)
    XCTAssertEqual(2, experimentMerger.deletedTrialIDs!.count)
    XCTAssertTrue(experimentMerger.deletedTrialIDs!.contains(trial2.ID))
    XCTAssertTrue(experimentMerger.deletedTrialIDs!.contains(trial3.ID))
    XCTAssertFalse(experimentMerger.deletedTrialIDs!.contains(trial1.ID))
  }

  // MARK: - Helpers

  func assertCaptionConflict(withClientCaption clientCaption: String?,
                             serverCaption: String?,
                             expectedMergedCaption: String?) {
    let note = newTextNoteWithCaption("caption")

    experimentLocal.addNote(note)

    // Client experiment with the same note.
    let experimentRemote = Experiment(proto: experimentLocal.proto, ID: experimentLocal.ID)

    // Remote changes the caption.
    let caption1 = Caption()
    caption1.text = clientCaption
    let clientNote = experimentRemote.note(withID: note.ID)!
    clientNote.caption = caption1
    experimentRemote.noteCaptionUpdated(withID: note.ID)

    // Local changes the same caption.
    let caption2 = Caption()
    caption2.text = serverCaption
    note.caption = caption2
    experimentLocal.noteCaptionUpdated(withID: note.ID)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(2, experimentLocal.changes.count)

    experimentMerger.mergeFrom(experiment: experimentRemote)

    XCTAssertEqual(2, experimentRemote.changes.count)
    XCTAssertEqual(4, experimentLocal.changes.count)
    XCTAssertEqual(expectedMergedCaption, note.caption?.text)
  }

  func newTextNoteWithCaption(_ captionText: String) -> TextNote {
    let note = TextNote()
    let caption = Caption()
    caption.text = captionText
    note.caption = caption
    return note
  }

}
