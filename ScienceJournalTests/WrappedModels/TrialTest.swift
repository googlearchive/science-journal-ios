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
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class TrialTest: XCTestCase {

  func testTrialStatsForSensorId() {
    // Some sensor IDs.
    let testSensorIds = ["testSensorId1", "testSensorId2", "testSensorId3", "testSensorId4"]

    // Create a trial with sensor trial stats for each sensor ID.
    var trialStatsArray = [TrialStats]()
    for sensorId in testSensorIds {
      let trialStats = TrialStats()
      trialStats.sensorID = sensorId
      trialStatsArray.append(trialStats)
    }
    let trial = Trial()
    trial.trialStats = trialStatsArray

    for (index, sensorId) in testSensorIds.enumerated() {
      XCTAssertEqual(trial.sensorTrialStats(for: sensorId)!.proto,
                     trialStatsArray[index].proto,
                     "`sensorTrialStats(for:)` should return the correct sensor trial stats for " +
                         "the sensor ID.")
    }
  }

  func testTrialDuration() {
    let trial = Trial()
    let startTimestamp = Timestamp(4000)
    let endTimestamp = Timestamp(10000)
    trial.recordingRange.min = startTimestamp.milliseconds
    trial.recordingRange.max = endTimestamp.milliseconds
    XCTAssertEqual(trial.durationInterval, 6, "Trial duration should be 6 minutes.")
  }

  func testTrialCopying() {
    let trial = Trial()
    trial.isArchived = true
    let note1 = Note()
    let note2 = Note()
    trial.notes = [note1, note2]

    let copy = trial.copy

    XCTAssertTrue(trial.ID == trial.ID)
    XCTAssertFalse(trial === copy)
    XCTAssertTrue(copy.isArchived)
    XCTAssertEqual(2, copy.notes.count)
    XCTAssertEqual(note1.ID, copy.notes[0].ID)
    XCTAssertEqual(note2.ID, copy.notes[1].ID)
  }

}
