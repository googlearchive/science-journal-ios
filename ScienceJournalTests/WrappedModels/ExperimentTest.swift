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
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class ExperimentTest: XCTestCase {

  func testProtoInput() {
    let proto = GSJExperiment()
    proto.creationTimeMs = 517518713723
    proto.title = "Test Title"
    proto.imagePath = "some/path/image.jpg"
    proto.trialsArray = NSMutableArray(array: [GSJTrial(), GSJTrial()])
    proto.labelsArray = NSMutableArray(array: [GSJLabel(), GSJLabel(), GSJLabel()])
    proto.sensorTriggersArray = NSMutableArray(array: [GSJSensorTrigger()])

    let experiment = Experiment(proto: proto, ID: UUID().uuidString)

    XCTAssertTrue(experiment.ID.count > 0)
    XCTAssertEqual(517518713723, experiment.creationDate.millisecondsSince1970)
    XCTAssertEqual("Test Title", experiment.title)
    XCTAssertEqual("some/path/image.jpg", experiment.imagePath)
    // TODO: Add deeper test of trials, notes, sensorTriggers similar to sensor layouts.
    XCTAssertEqual(2, experiment.trials.count)
    XCTAssertEqual(3, experiment.notes.count)
    XCTAssertEqual(1, experiment.sensorTriggers.count)
  }

  func testProtoOutput() {
    let experiment = Experiment(ID: UUID().uuidString)
    experiment.creationDate = Date(milliseconds: 517518713723)
    experiment.setTitle("Test Title")
    experiment.imagePath = "some/path/image.jpg"
    experiment.trials = [Trial(), Trial(), Trial()]
    experiment.notes = [Note(), Note()]
    experiment.sensorTriggers = [SensorTrigger(sensorID: ""), SensorTrigger(sensorID: "")]

    XCTAssertTrue(experiment.ID.count > 0)
    XCTAssertEqual(517518713723, experiment.proto.creationTimeMs)
    XCTAssertEqual("Test Title", experiment.proto.title)
    XCTAssertEqual("some/path/image.jpg", experiment.proto.imagePath)
    // TODO: Add deeper test of trials, notes, sensorTriggers similar to sensor layouts.
    XCTAssertEqual(3, experiment.proto.trialsArray.count)
    XCTAssertEqual(2, experiment.proto.labelsArray.count)
    XCTAssertEqual(2, experiment.proto.sensorTriggersArray.count)
  }

  func testSensorLayouts() {
    let proto = GSJExperiment()

    let layout1 = GSJSensorLayout()
    layout1.sensorId = "12345"
    let layout2 = GSJSensorLayout()
    layout2.sensorId = "ABCDEF"
    proto.sensorLayoutsArray.add(layout1)
    proto.sensorLayoutsArray.add(layout2)

    let experiment = Experiment(proto: proto, ID: UUID().uuidString)

    XCTAssertEqual(2, experiment.sensorLayouts.count)
    XCTAssertEqual("12345", experiment.sensorLayouts[0].sensorID)
    XCTAssertEqual("ABCDEF", experiment.sensorLayouts[1].sensorID)
  }

  func testEnabledSensors() {
    // Create an experiment from an empty proto.
    let proto = GSJExperiment()
    var experiment = Experiment(proto: proto, ID: "Experiment_Test_ID")

    // No sensor IDs should be enabled.
    XCTAssertFalse(experiment.isSensorEnabled("test_id_1"))
    XCTAssertFalse(experiment.isSensorEnabled("test_id_2"))
    XCTAssertFalse(experiment.isSensorEnabled("test_id_3"))

    // Add some sensor entries.
    let sensor1 = GSJExperiment_SensorEntry()
    sensor1.sensorId = "test_id_1"

    let sensor2 = GSJExperiment_SensorEntry()
    sensor2.sensorId = "test_id_2"

    let availableSensors = [sensor1, sensor2]
    proto.availableSensorsArray = NSMutableArray(array: availableSensors)

    // Only the available sensors should be enabled.
    experiment = Experiment(proto: proto, ID: "Experiment_Test_ID")
    XCTAssertTrue(experiment.isSensorEnabled("test_id_1"))
    XCTAssertTrue(experiment.isSensorEnabled("test_id_2"))
    XCTAssertFalse(experiment.isSensorEnabled("test_id_3"))
  }

  func testUpdatingTrial() {
    let experiment = Experiment(ID: "")

    // Create a trial with an ID and a title.
    let trial = Trial()
    trial.ID = "trial"
    trial.setTitle("title", experiment: experiment)

    // Add the trial to an experiment.
    experiment.trials.append(trial)

    XCTAssertEqual(1, experiment.trials.count, "The experiment should have one trial.")
    XCTAssertEqual(trial.title,
                   experiment.trials.first!.title,
                   "The title of the first trial in the experiment should be 'title'.")

    // Change the title of the trial and update it in the experiment.
    trial.setTitle("new title", experiment: experiment)

    XCTAssertEqual(1, experiment.trials.count, "The experiment should still have one trial.")
    XCTAssertEqual(trial.title,
                   experiment.trials.first!.title,
                   "The title of the first trial in the experiment should be 'new title'.")
  }

  func testRemoveTrial() {
    // Create an experiment.
    let experiment = Experiment(ID: "test experiment")

    // Add a trial to the experiment.
    let trial = Trial()
    trial.ID = "test trial"
    experiment.trials.append(trial)

    // Assert the experiment contains the trial.
    XCTAssertTrue(experiment.trials.contains(where: { $0.ID == trial.ID }),
                  "The experiment should contain the trial.")

    // Remove the trial.
    experiment.removeTrial(withID: trial.ID)

    // Assert that it is removed from the experiment.
    XCTAssertFalse(experiment.trials.contains(where: { $0.ID == trial.ID }),
                   "The experiment should not contain the trial.")
  }

  func testTriggersForSensor() {
    // Create a sensor and some triggers for it, and also some triggers for another sensor.
    let sensor = Sensor.mock(sensorId: "test sensor")
    let trigger1 = SensorTrigger(sensorID: sensor.sensorId)
    let trigger2 = SensorTrigger(sensorID: "another sensor")
    let trigger3 = SensorTrigger(sensorID: sensor.sensorId)
    let trigger4 = SensorTrigger(sensorID: sensor.sensorId)
    let trigger5 = SensorTrigger(sensorID: "another sensor")

    // Add the triggers to an experiment.
    let experiment = Experiment(ID: "")
    experiment.sensorTriggers = [trigger1, trigger2, trigger3, trigger4, trigger5]

    // Get the triggers for the sensor from the experiment.
    XCTAssertEqual([trigger1.triggerID, trigger3.triggerID, trigger4.triggerID],
                   experiment.triggersForSensor(sensor).map({ $0.triggerID }))
  }

  func testSensorLayoutForSensorID() {
    // Create sensor layouts.
    let sensorID = "test sensor"
    let sensorLayout1 = SensorLayout(sensorID: sensorID, colorPalette: .blue)
    let sensorLayout2 = SensorLayout(sensorID: "another sensor", colorPalette: .blue)

    // Add the sensor layouts to an experiment.
    let experiment = Experiment(ID: "")
    experiment.sensorLayouts = [sensorLayout1, sensorLayout2]

    // Get the sensor layout for the sensor from the experiment.
    XCTAssertEqual(sensorLayout1.sensorID, experiment.sensorLayoutForSensorID(sensorID)!.sensorID)
  }

  func testChangeCounts() {
    let experiment = Experiment(ID: "TEST_1")
    XCTAssertEqual(0, experiment.changes.count)

    experiment.trackChange(ExperimentChange.addChange(forElement: .note, withID: "NOTE_ID"))
    experiment.trackChange(ExperimentChange.addChange(forElement: .trial, withID: "TRIAL_ID"))

    XCTAssertEqual(2, experiment.changes.count)

    let experiment2 = Experiment(proto: experiment.proto, ID: "TEST_2")
    XCTAssertEqual(2, experiment2.changes.count)
  }

  func testTrackChanges() {
    let experiment = Experiment(ID: "CHANGE_TEST")
    XCTAssertEqual(0, experiment.changes.count)

    experiment.setTitle("foo")
    XCTAssertEqual(1, experiment.changes.count)
    experiment.changes[0].assert(isElement: .experiment, changeType: .modify, ID: experiment.ID)

    let note = TextNote(text: "text")
    experiment.insertNote(note, atIndex: 0, isUndo: false)
    XCTAssertEqual(2, experiment.changes.count)
    experiment.changes[1].assert(isElement: .note, changeType: .add, ID: note.ID)

    experiment.noteUpdated(withID: note.ID)
    XCTAssertEqual(3, experiment.changes.count)
    experiment.changes[2].assert(isElement: .note, changeType: .modify, ID: note.ID)

    let trial = Trial()
    experiment.addTrial(trial, isUndo: false)
    XCTAssertEqual(4, experiment.changes.count)
    experiment.changes[3].assert(isElement: .trial, changeType: .add, ID: trial.ID)

    experiment.trialUpdated(withID: trial.ID)
    XCTAssertEqual(5, experiment.changes.count)
    experiment.changes[4].assert(isElement: .trial, changeType: .modify, ID: trial.ID)

    let trialNote = TextNote(text: "text")
    trial.insertNote(trialNote, atIndex: 0, experiment: experiment, isUndo: false)
    XCTAssertEqual(6, experiment.changes.count)
    experiment.changes[5].assert(isElement: .note, changeType: .add, ID: trialNote.ID)

    experiment.noteUpdated(withID: trialNote.ID)
    XCTAssertEqual(7, experiment.changes.count)
    experiment.changes[6].assert(isElement: .note, changeType: .modify, ID: trialNote.ID)
  }

  func testRemoveAvailableSensors() {
    // Create an experiment and available sensors.
    let experiment = Experiment(ID: "REMOVE_AVAILABLE_SENSORS_TEST")

    let sensor1 = Sensor.mock(sensorId: "AVAILABLE_SENSOR_1")
    let sensor2 = Sensor.mock(sensorId: "AVAILABLE_SENSOR_2")
    let sensor3 = Sensor.mock(sensorId: "AVAILABLE_SENSOR_3")

    let sensorEntry1 = SensorEntry(sensor: sensor1)
    let sensorEntry2 = SensorEntry(sensor: sensor2)
    let sensorEntry3 = SensorEntry(sensor: sensor3)

    // Give the available sensors to the experiment and assert they are there.
    experiment.availableSensors = [sensorEntry1, sensorEntry2, sensorEntry3]
    XCTAssertEqual(3, experiment.availableSensors.count)

    // Remove the available sensors and assert they are gone from the experiment.
    experiment.removeAvailableSensors()
    XCTAssertTrue(experiment.availableSensors.isEmpty)
  }

  func testRemoveSensorTriggers() {
    // Create an experiment and sensor triggers.
    let experiment = Experiment(ID: "REMOVE_SENSOR_TRIGGERS_TEST")

    let sensorTrigger1 = SensorTrigger(sensorID: "SENSOR_TRIGGER_1")
    let sensorTrigger2 = SensorTrigger(sensorID: "SENSOR_TRIGGER_2")
    let sensorTrigger3 = SensorTrigger(sensorID: "SENSOR_TRIGGER_3")

    // Give the sensor triggers to the experiment and assert they are there.
    experiment.sensorTriggers = [sensorTrigger1, sensorTrigger2, sensorTrigger3]
    XCTAssertEqual(3, experiment.sensorTriggers.count)

    // Remove the sensor triggers and assert they are gone from the experiment.
    experiment.removeSensorTriggers()
    XCTAssertTrue(experiment.sensorTriggers.isEmpty)
  }

  func testRemoveSensorLayouts() {
    // Create an experiment and some sensor layouts.
    let experiment = Experiment(ID: "REMOVE_SENSOR_LAYOUTS_TEST")

    let sensorLayout1 = SensorLayout(sensorID: "SENSOR_LAYOUT_1", colorPalette: .blue)
    let sensorLayout2 = SensorLayout(sensorID: "SENSOR_LAYOUT_2", colorPalette: .green)
    let sensorLayout3 = SensorLayout(sensorID: "SENSOR_LAYOUT_3", colorPalette: .orange)

    // Give the sensor layouts containing to the experiment and assert they are there.
    experiment.sensorLayouts = [sensorLayout1, sensorLayout2, sensorLayout3]
    XCTAssertEqual(3, experiment.sensorLayouts.count)
    XCTAssertEqual("SENSOR_LAYOUT_1", experiment.sensorLayouts[0].sensorID)
    XCTAssertEqual("SENSOR_LAYOUT_2", experiment.sensorLayouts[1].sensorID)
    XCTAssertEqual("SENSOR_LAYOUT_3", experiment.sensorLayouts[2].sensorID)

    // Remove the sensor layouts from the experiment and assert they are gone.
    experiment.removeSensorLayouts()
    XCTAssertTrue(experiment.sensorLayouts.isEmpty)
  }

  func testHasAssetReferences() {
    let experiment1 = Experiment(ID: "testHasAssetReferences1")
    XCTAssertFalse(experiment1.hasAssetReferences)

    let experiment2 = Experiment(ID: "testHasAssetReferences2")
    experiment2.trials = [Trial(), Trial(), Trial()]
    XCTAssertTrue(experiment2.hasAssetReferences)

    let experiment3 = Experiment(ID: "testHasAssetReferences3")
    experiment3.addNote(PictureNote())
    experiment3.addNote(PictureNote())
    XCTAssertTrue(experiment3.hasAssetReferences)

    let experiment4 = Experiment(ID: "testHasAssetReferences4")
    experiment4.addNote(TextNote())
    experiment4.addNote(TextNote())
    XCTAssertFalse(experiment4.hasAssetReferences)

    let experiment5 = Experiment(ID: "testHasAssetReferences5")
    experiment5.imagePath = "path/to/image.jpg"
    XCTAssertTrue(experiment5.hasAssetReferences)

    let experiment6 = Experiment(ID: "testHasAssetReferences6")
    experiment6.trials = [Trial(), Trial(), Trial()]
    experiment6.addNote(PictureNote())
    experiment6.addNote(PictureNote())
    experiment6.imagePath = "path/to/image.jpg"
    XCTAssertTrue(experiment6.hasAssetReferences)
  }

}
