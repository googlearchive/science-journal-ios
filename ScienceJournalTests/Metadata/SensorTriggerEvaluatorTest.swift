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

class SensorTriggerEvaluatorTest: XCTestCase {

  func testShouldTriggerWithNoPreviousValue() {
    // Create a sensor trigger` with a value to trigger, and a sensor trigger evaluator with no
    // previous value.
    let sensorTrigger = SensorTrigger(sensorID: "sensorTriggerId")
    sensorTrigger.triggerInformation.valueToTrigger = 10
    let sensorTriggerEvaluator = SensorTriggerEvaluator(sensorTrigger: sensorTrigger)

    // Set up a fake clock.
    let fakeLastUsed: Int64 = 12345
    sensorTriggerEvaluator.clock = SettableClock(now: fakeLastUsed)
    XCTAssertNil(sensorTriggerEvaluator.previousValue,
                 "The sensor trigger evaluator's previous value should be nil before calling " +
                     "`shouldTrigger(withValue:)` for the first time.")
    let value = 10.0000000000001
    XCTAssertFalse(sensorTriggerEvaluator.shouldTrigger(withValue: value),
                  "If the sensor trigger evaluator has no previous value, this should be false.")
    XCTAssertEqual(sensorTriggerEvaluator.previousValue, value,
                   "The sensor trigger evaluator's previous value should be equal to `value`.")
    XCTAssertEqual(sensorTriggerEvaluator.sensorTrigger.lastUsedDate.millisecondsSince1970,
                   fakeLastUsed,
                   "The sensor trigger's `lastUsedMs` should be equal to `fakeLastUsed`.")
 }

  func testShouldTriggerWhenAt() {
    // Create a sensor trigger to trigger when at a value.
    let sensorTrigger = SensorTrigger(sensorID: "sensorTriggerId")
    sensorTrigger.triggerInformation.triggerWhen = .triggerWhenAt
    sensorTrigger.triggerInformation.valueToTrigger = 10
    let sensorTriggerEvaluator = SensorTriggerEvaluator(sensorTrigger: sensorTrigger)
    sensorTriggerEvaluator.previousValue = 11
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 10.0000000000001),
                  "If `value` is nearly equal to the `valueToTrigger`, this should be true.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 9),
                  "If `value` crossed the threshold, this should be true.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 12),
                  "If `value` crossed the threshold in the other direction, this should be true.")
  }

  func testShouldTriggerWhenDropsBelow() {
    // Create a sensor trigger to trigger when dropping below a value.
    let sensorTrigger = SensorTrigger(sensorID: "sensorTriggerId")
    sensorTrigger.triggerInformation.triggerWhen = .triggerWhenDropsBelow
    sensorTrigger.triggerInformation.valueToTrigger = 10
    let sensorTriggerEvaluator = SensorTriggerEvaluator(sensorTrigger: sensorTrigger)
    sensorTriggerEvaluator.previousValue = 11
    XCTAssertFalse(sensorTriggerEvaluator.shouldTrigger(withValue: 12),
                   "If `value` is above `valueToTrigger`, this should be false.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 9),
                  "If `value` drops below `valueToTrigger`, this should be true.")
  }

  func testShouldTriggerWhenRisesAbove() {
    // Create a sensor trigger to trigger when rising above `valueToTrigger`.
    let sensorTrigger = SensorTrigger(sensorID: "sensorTriggerId")
    sensorTrigger.triggerInformation.triggerWhen = .triggerWhenRisesAbove
    sensorTrigger.triggerInformation.valueToTrigger = 10
    let sensorTriggerEvaluator = SensorTriggerEvaluator(sensorTrigger: sensorTrigger)
    sensorTriggerEvaluator.previousValue = 9
    XCTAssertFalse(sensorTriggerEvaluator.shouldTrigger(withValue: 8),
                   "If `value` is below `valueToTrigger`, this should be false.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 11),
                  "If `value` rises above `valueToTrigger`, this should be true.")
  }

  func testShouldTriggerWhenBelow() {
    // Create a sensor trigger to trigger when below `valueToTrigger`.
    let sensorTrigger = SensorTrigger(sensorID: "sensorTriggerId")
    sensorTrigger.triggerInformation.triggerWhen = .triggerWhenBelow
    sensorTrigger.triggerInformation.valueToTrigger = 10
    let sensorTriggerEvaluator = SensorTriggerEvaluator(sensorTrigger: sensorTrigger)
    sensorTriggerEvaluator.previousValue = 9
    XCTAssertFalse(sensorTriggerEvaluator.shouldTrigger(withValue: 11),
                  "If `value` is above `valueToTrigger`, this should be false.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 8),
                  "If `value` is below `valueToTrigger`, this should be true.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 7),
                  "Even when previous value is below `valueToTrigger`, if `value` is below " +
                      "`valueToTrigger`, this should be true.")
  }

  func testShouldTriggerWhenAbove() {
    // Create a sensor trigger to trigger when above `valueToTrigger`.
    let sensorTrigger = SensorTrigger(sensorID: "sensorTriggerId")
    sensorTrigger.triggerInformation.triggerWhen = .triggerWhenAbove
    sensorTrigger.triggerInformation.valueToTrigger = 10
    let sensorTriggerEvaluator = SensorTriggerEvaluator(sensorTrigger: sensorTrigger)
    sensorTriggerEvaluator.previousValue = 11
    XCTAssertFalse(sensorTriggerEvaluator.shouldTrigger(withValue: 9),
                  "If `value` is above `valueToTrigger`, this should be true.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 12),
                  "If `value` is above `valueToTrigger`, this should be true.")
    XCTAssertTrue(sensorTriggerEvaluator.shouldTrigger(withValue: 14),
                  "Even when previous value is above `valueToTrigger`, if `value` is above " +
                      "`valueToTrigger`, this should be true.")

  }

  func testSensorTriggerEvaluatorsForSensorTriggers() {
    // Create some sensor triggers.
    let sensorTrigger1 = SensorTrigger(sensorID: "sensorTrigger1Id")
    let sensorTrigger2 = SensorTrigger(sensorID: "sensorTrigger2Id")
    let sensorTrigger3 = SensorTrigger(sensorID: "sensorTrigger3Id")
    let sensorTriggers = [sensorTrigger1, sensorTrigger2, sensorTrigger3]

    // Get sensor trigger evaluators for the `SensorTriggers`.
    let sensorTriggerEvaluators =
        SensorTriggerEvaluator.sensorTriggerEvaluators(for: sensorTriggers)

    XCTAssertEqual(sensorTriggers.count, sensorTriggerEvaluators.count,
                   "There should be an equal `count` in `sensorTriggers` and " +
                       "`sensorTriggerEvaluators`")
    // There should be a sensor trigger evaluator for each sensor trigger.
    for index in 0..<sensorTriggerEvaluators.endIndex {
      XCTAssertTrue(sensorTriggers[index] === sensorTriggerEvaluators[index].sensorTrigger,
                    "The sensor trigger evaluator's sensor trigger should be equal to the " +
                        "corresponding sensor trigger.")
    }
  }

}
