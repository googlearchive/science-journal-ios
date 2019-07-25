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

class ExperimentDataParserTest: XCTestCase {

  // MARK: - Properties

  let trial = Trial()

  var experimentDataParser: ExperimentDataParser!

  var sensor1: Sensor!
  var sensor2: Sensor!

  let sensorTrialStat1Minimum = 5.0
  let sensorTrialStat1Maximum = 6.0
  let sensorTrialStat1Average = 5.5
  let sensorTrialStat2Minimum = 7.0
  let sensorTrialStat2Maximum = 9.0
  let sensorTrialStat2Average = 8.0

  // MARK: - XCTest

  override func setUp() {
    super.setUp()

    let metadataManager = createMetadataManager()
    experimentDataParser = ExperimentDataParser(experimentID: "TEST",
                                                metadataManager: metadataManager,
                                                sensorController: MockSensorController())

    sensor1 = Sensor.mock(sensorId: "TestSensorID1",
                          name: "TestSensorName1",
                          textDescription: "Test description 1.",
                          iconName: "test icon 1",
                          unitDescription: "sin")
    sensor2 = Sensor.mock(sensorId: "TestSensorID2",
                          name: "TestSensorName2",
                          textDescription: "Test description 2.",
                          iconName: "test icon 2")

    setupTrial()
  }

  // MARK: - Test cases

  func testParsedTrials() {
    let trials = [Trial(), Trial(), Trial(), Trial()]
    let parsedTrials = experimentDataParser.parsedTrials(trials)
    XCTAssertEqual(parsedTrials.count, trials.count,
                   "The number of parsed trials should equal the number of trials.")
  }

  func testParsedTrialSensorCount() {
    let displayTrial = experimentDataParser.parseTrial(trial)
    let trialSensors = displayTrial.sensors
    XCTAssertEqual(trialSensors.count, 2, "There should be a trial sensor for each sensor.")
  }

  func testParsedTrialSensorTitles() {
    let experimentTrialData = experimentDataParser.parseTrial(trial)
    let trialSensors = experimentTrialData.sensors
    XCTAssertEqual(trialSensors[0].title, "\(sensor1.name) (\(sensor1.unitDescription!))",
                   "The trial sensor title should be the sensor name.")
    XCTAssertEqual(trialSensors[1].title, sensor2.name,
                   "The trial sensor title should be the sensor name.")
  }

  func testParsedTrialSensorTimestamp() {
    Timestamp.dateFormatter.timeZone = TimeZone(abbreviation: "EDT")
    let experimentTrialData = experimentDataParser.parseTrial(trial)
    var expectedDateString: String
    if #available(iOS 11.0, *) {
      expectedDateString = "May 18, 2017 at 10:37 AM"
    } else {
      expectedDateString = "May 18, 2017, 10:37 AM"
    }
    XCTAssertEqual(expectedDateString, experimentTrialData.timestamp.string,
                   "The timestamp should be properly parsed.")
  }

  func testParsedTrialSensorDataStats() {
    let experimentTrialData = experimentDataParser.parseTrial(trial)

    let trialSensor1 = experimentTrialData.sensors[0]
    XCTAssertEqual(trialSensor1.minValueString, sensor1.string(for: sensorTrialStat1Minimum),
                   "The `minValueString` should be the same as the sensor's string(for:) string " +
                       "for the minimum data point.")
    XCTAssertEqual(trialSensor1.maxValueString, sensor1.string(for: sensorTrialStat1Maximum),
                   "The `maxValueString` should be the same as the sensor's string(for:) string " +
                       "for the maximum data point.")
    XCTAssertEqual(trialSensor1.averageValueString, sensor1.string(for: sensorTrialStat1Average),
                   "The `averageValueString` should be the same as the sensor's string(for:) " +
                       "string for the maximum data point.")

    let trialSensor2 = experimentTrialData.sensors[1]
    XCTAssertEqual(trialSensor2.minValueString, sensor1.string(for: sensorTrialStat2Minimum),
                   "The `minValueString` should be the same as the sensor's string(for:) string " +
                       "for the minimum data point.")
    XCTAssertEqual(trialSensor2.maxValueString, sensor1.string(for: sensorTrialStat2Maximum),
                   "The `maxValueString` should be the same as the sensor's string(for:) string " +
                       "for the maximum data point.")
    XCTAssertEqual(trialSensor2.averageValueString, sensor1.string(for: sensorTrialStat2Average),
                   "The `averageValueString` should be the same as the sensor's string(for:) " +
                       "string for the maximum data point.")
  }

  func testParsedTrialNotesSortOrder() {
    let note1 = TextNote(text: "First")
    note1.timestamp = 1000
    let note2 = TextNote(text: "Second")
    note1.timestamp = 2000
    let note3 = TextNote(text: "Third")
    note1.timestamp = 3000

    // Trial notes are added in non-chronological order.
    trial.notes = [note2, note3, note1]

    let displayTrial = experimentDataParser.parseTrial(trial)

    XCTAssertEqual(3, displayTrial.notes.count)
    XCTAssertEqual("First", (displayTrial.notes[0] as! DisplayTextNote).text)
    XCTAssertEqual("Second", (displayTrial.notes[1] as! DisplayTextNote).text)
    XCTAssertEqual("Third", (displayTrial.notes[2] as! DisplayTextNote).text)
  }

  func testParsedTextNote() {
    Timestamp.dateFormatter.timeZone = TimeZone(abbreviation: "EDT")
    let textNote = TextNote(text: "A text note")
    textNote.timestamp = 1496369345626

    let experimentData = experimentDataParser.parseNote(textNote) as! DisplayTextNote
    XCTAssertEqual("A text note", experimentData.text)
    var expectedDateString: String
    if #available(iOS 11.0, *) {
      expectedDateString = "Jun 1, 2017 at 10:09 PM"
    } else {
      expectedDateString = "Jun 1, 2017, 10:09 PM"
    }
    XCTAssertEqual(expectedDateString, experimentData.timestamp.string)
  }

  func testParsedPictureNote() {
    Timestamp.dateFormatter.timeZone = TimeZone(abbreviation: "EDT")
    let pictureNote = PictureNote()
    pictureNote.timestamp = 1496369345626
    pictureNote.filePath = "some_image_path"

    let experimentData = experimentDataParser.parseNote(pictureNote) as! DisplayPictureNote
    XCTAssertTrue(experimentData.imagePath!.hasSuffix(pictureNote.filePath!))
    var expectedDateString: String
    if #available(iOS 11.0, *) {
      expectedDateString = "Jun 1, 2017 at 10:09 PM"
    } else {
      expectedDateString = "Jun 1, 2017, 10:09 PM"
    }
    XCTAssertEqual(expectedDateString, experimentData.timestamp.string)
  }

  func testParsedTrialNote() {
    let trial = Trial()
    let textNote = TextNote(text: "Some text here")
    let displayTextNote = experimentDataParser.parseNote(textNote,
                                                         forTrial: trial) as! DisplayTextNote

    XCTAssertEqual("Some text here", displayTextNote.text)
    XCTAssertEqual(trial.ID, displayTextNote.trialID)

    let textNote2 = TextNote(text: "Another note")
    let displayTextNote2 = experimentDataParser.parseNote(textNote2,
                                                          forTrial: nil) as! DisplayTextNote
    XCTAssertEqual("Another note", displayTextNote2.text)
    XCTAssertNil(displayTextNote2.trialID)
  }

  func testUnknownNoteType() {
    // Unknown subclass of Note.
    class OtherNote: Note {}

    let otherNote = OtherNote()
    let experimentData = experimentDataParser.parseNote(otherNote)
    XCTAssertNil(experimentData, "Unknown note types should return nil.")
  }

  func testAlternateTitle() {
    let experimentTrialData = experimentDataParser.parseTrial(trial)
    XCTAssertNil(experimentTrialData.title, "Trial title should be nil.")
    XCTAssertEqual("\(String.runDefaultTitle) 5", experimentTrialData.alternateTitle,
                   "Alternate title should match default plus index+1.")
  }

  func testSnapshotTrialNoteTimestamp() {
    // Create a snapshot note with a sensor snapshot that has a given timestamp.
    let sensorSnapshot = SensorSnapshot()
    sensorSnapshot.timestamp = 10000
    let snapshotNote = SnapshotNote(snapshots: [sensorSnapshot])

    // Create a trial without a crop.
    let trial = Trial()
    trial.recordingRange.min = 5000

    // Parse it into a display note for the trial.
    let displaySnapshotNote =
        experimentDataParser.parseNote(snapshotNote, forTrial: trial) as! DisplaySnapshotNote
    XCTAssertEqual(
        "0:05",
        displaySnapshotNote.snapshots[0].timestamp.string,
        "The display note timestamp should be the duration after the min recording range.")
  }

  func testSnapshotTrialNoteTimestampWithCrop() {
    // Create a snapshot note with a sensor snapshot that has a given timestamp.
    let sensorSnapshot = SensorSnapshot()
    sensorSnapshot.timestamp = 10000
    let snapshotNote = SnapshotNote(snapshots: [sensorSnapshot])

    // Create a trial with a crop.
    let trial = Trial()
    trial.recordingRange.min = 5000
    trial.cropRange = ChartAxis(min: 7000, max: 15000)

    // Parse it into a display note for the trial.
    let displaySnapshotNote =
        experimentDataParser.parseNote(snapshotNote, forTrial: trial) as! DisplaySnapshotNote
    XCTAssertEqual(
        "0:03",
        displaySnapshotNote.snapshots[0].timestamp.string,
        "The display note timestamp should be the duration after the min crop range.")
  }

  // MARK: - Setup trial

  func setupTrial() {
    // ID, experiment index, creation time, recording range.
    trial.ID = "TrialId"
    trial.trialNumberInExperiment = 5
    trial.creationDate = Date(milliseconds: 1495118240287)
    trial.recordingRange.min = 1234
    trial.recordingRange.max = 5678

    // Stats.
    let statsCalculator1 = StatCalculator()
    statsCalculator1.addDataPoint(DataPoint(x: 0, y: sensorTrialStat1Minimum))
    statsCalculator1.addDataPoint(DataPoint(x: 1, y: sensorTrialStat1Maximum))
    let sensorTrialStats1 = TrialStats(sensorID: sensor1.sensorId)
    sensorTrialStats1.addStatsFromStatCalculator(statsCalculator1)
    trial.trialStats.append(sensorTrialStats1)

    let statsCalculator2 = StatCalculator()
    statsCalculator2.addDataPoint(DataPoint(x: 0, y: sensorTrialStat2Minimum))
    statsCalculator2.addDataPoint(DataPoint(x: 1, y: sensorTrialStat2Maximum))
    let sensorTrialStats2 = TrialStats(sensorID: sensor2.sensorId)
    sensorTrialStats2.addStatsFromStatCalculator(statsCalculator2)
    trial.trialStats.append(sensorTrialStats2)

    // Layouts.
    let sensorLayout1 = SensorLayout(sensorID: sensor1.sensorId, colorPalette: .blue)
    trial.sensorLayouts.append(sensorLayout1)

    let sensorLayout2 = SensorLayout(sensorID: sensor2.sensorId, colorPalette: .blue)
    trial.sensorLayouts.append(sensorLayout2)

    // Appearance.
    trial.addSensorAppearance(BasicSensorAppearance(sensor: sensor1), for: sensor1.sensorId)
    trial.addSensorAppearance(BasicSensorAppearance(sensor: sensor2), for: sensor2.sensorId)
  }

}
