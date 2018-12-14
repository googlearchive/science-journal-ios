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

class SensorTriggerFrequencyObserverTest: XCTestCase {

  /// Mock delegate that tracks when it receives the delegate call for a trigger exceeding its fire
  /// limit.
  class MockSensorTriggerFrequencyObserverDelegate: SensorTriggerFrequencyObserverDelegate {

    var didExceedFireLimitCalled = false

    func sensorTriggerFrequencyObserverDidExceedFireLimit(_
        sensorTriggerFrequencyObserver: SensorTriggerFrequencyObserver) {
      didExceedFireLimitCalled = true
    }

  }

  func testNoteTriggerOverLimit() {
    // Create a delegate to track that triggers exceeded their fire limit.
    let mockSensorTriggerFrequencyObserverDelegate = MockSensorTriggerFrequencyObserverDelegate()

    // Create a frequency observer and tell it a note trigger fired six times in a second.
    let sensorTriggerFrequencyObserver =
        SensorTriggerFrequencyObserver(delegate: mockSensorTriggerFrequencyObserverDelegate)
    let trigger = SensorTrigger(sensorID: "")
    trigger.triggerInformation.triggerActionType = .triggerActionNote
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123678)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123789)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123890)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123901)

    XCTAssertTrue(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)
  }

  func testNoteTriggerNotOverLimit() {
    // Create a delegate to track that triggers did not exceed their fire limit.
    let mockSensorTriggerFrequencyObserverDelegate = MockSensorTriggerFrequencyObserverDelegate()

    // Create a frequency observer and tell it a note trigger fired five times in a second, and then
    // one more time in the next second.
    let sensorTriggerFrequencyObserver =
        SensorTriggerFrequencyObserver(delegate: mockSensorTriggerFrequencyObserverDelegate)
    let trigger = SensorTrigger(sensorID: "")
    trigger.triggerInformation.triggerActionType = .triggerActionNote
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123678)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123789)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123890)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 124901)

    XCTAssertFalse(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)
  }

  func testRecordingTriggerOverLimit() {
    // Create a delegate to track that triggers exceeded their fire limit.
    let mockSensorTriggerFrequencyObserverDelegate = MockSensorTriggerFrequencyObserverDelegate()

    // Create a frequency observer and tell it a stop recording trigger fired three times in a
    // second.
    let sensorTriggerFrequencyObserver =
        SensorTriggerFrequencyObserver(delegate: mockSensorTriggerFrequencyObserverDelegate)
    let trigger = SensorTrigger(sensorID: "")
    trigger.triggerInformation.triggerActionType = .triggerActionStopRecording
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123678)

    XCTAssertTrue(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)
  }

  func testRecordingTriggerNotOverLimit() {
    // Create a delegate to track that triggers did not exceed their fire limit.
    let mockSensorTriggerFrequencyObserverDelegate = MockSensorTriggerFrequencyObserverDelegate()

    // Create a frequency observer and tell it a stop recording trigger fired three times in a
    // second, and then one more time in the next second.
    let sensorTriggerFrequencyObserver =
      SensorTriggerFrequencyObserver(delegate: mockSensorTriggerFrequencyObserverDelegate)
    let trigger = SensorTrigger(sensorID: "")
    trigger.triggerInformation.triggerActionType = .triggerActionStopRecording
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 124678)

    XCTAssertFalse(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)
  }

  func testMultipleRecordingTriggerOverLimit() {
    // Create a delegate to track that triggers exceeded their fire limit.
    let mockSensorTriggerFrequencyObserverDelegate = MockSensorTriggerFrequencyObserverDelegate()

    // Create a frequency observer and tell it a stop recording trigger fired three times in a
    // second.
    let sensorTriggerFrequencyObserver =
        SensorTriggerFrequencyObserver(delegate: mockSensorTriggerFrequencyObserverDelegate)
    let trigger = SensorTrigger(sensorID: "")
    trigger.triggerInformation.triggerActionType = .triggerActionStopRecording
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 123678)
    XCTAssertTrue(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)

    // Reset the tracking Bool.
    mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled = false

    // Exceed the trigger limit again.
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 133456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 133567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 133678)
    XCTAssertTrue(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)

    // Reset the tracking Bool.
    mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled = false

    // Exceed the trigger limit again.
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 143456)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 143567)
    sensorTriggerFrequencyObserver.triggerFired(trigger, at: 143678)
    XCTAssertTrue(mockSensorTriggerFrequencyObserverDelegate.didExceedFireLimitCalled)
  }

}
