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

class ObserveViewControllerTest: XCTestCase {

  class MockDelegate: ObserveViewControllerDelegate {

    var mockActiveTriggers = [SensorTrigger]()

    func observeViewControllerDidStartRecording(_ observeViewController: ObserveViewController) {}
    func observeViewControllerDidEndRecording(_ observeViewController: ObserveViewController) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didCreateSensorSnapshots sensorSnapshots: [SensorSnapshot]) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didReceiveNoteTrigger trigger: SensorTrigger,
                               forSensor sensor: Sensor,
                               atTimestamp timestamp: Int64) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didBeginTrial trial: Trial) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didUpdateTrial trial: Trial,
                               isFinishedRecording: Bool) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didCancelTrial trial: Trial) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didPressSetTriggersForSensor sensor: Sensor) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didUpdateSensorLayouts sensorLayouts: [SensorLayout]) {}
    func observeViewControllerDidPressSensorSettings(_
        observeViewController: ObserveViewController) {}
    func observeViewController(_ observeViewController: ObserveViewController,
                               didExceedTriggerFireLimitForSensor sensor: Sensor) {}

    func observeViewController(_ observeViewController: ObserveViewController,
                               isSensorTriggerActive sensorTrigger: SensorTrigger) -> Bool {
      return mockActiveTriggers.contains(where: { $0.triggerID == sensorTrigger.triggerID })
    }

  }

  func testActiveSensorTriggers() {
    // Create some triggers
    let trigger1 = SensorTrigger(sensorID: "test sensor ID")
    let trigger2 = SensorTrigger(sensorID: "test sensor ID")
    let trigger3 = SensorTrigger(sensorID: "test sensor ID")
    let trigger4 = SensorTrigger(sensorID: "test sensor ID")

    // Create a mock delegate and mock two triggers as active.
    let mockDelegate = MockDelegate()
    mockDelegate.mockActiveTriggers = [trigger1, trigger2]

    // Create an observe view controller, set the mock delegate and give it all of the triggers.
    let sensorDataManager = createSensorDataManager()
    let observeViewController =
        ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                              preferenceManager: PreferenceManager(),
                              sensorController: MockSensorController(),
                              sensorDataManager: sensorDataManager)
    observeViewController.delegate = mockDelegate
    observeViewController.sensorTriggers = [trigger1, trigger2, trigger3, trigger4]

    // Check active sensor IDs to ensure the proper ones are included.
    XCTAssertTrue(observeViewController.activeSensorTriggers.contains(where: {
      $0.triggerID == trigger1.triggerID
    }))
    XCTAssertTrue(observeViewController.activeSensorTriggers.contains(where: {
      $0.triggerID == trigger2.triggerID
    }))
    XCTAssertFalse(observeViewController.activeSensorTriggers.contains(where: {
      $0.triggerID == trigger3.triggerID
    }))
    XCTAssertFalse(observeViewController.activeSensorTriggers.contains(where: {
      $0.triggerID == trigger4.triggerID
    }))
  }

  func testSensorHasVisualTriggers() {
    // Create some visual triggers for a sensor, and some for another sensor. Give them to observe.
    let sensor = Sensor.mock(sensorId: "test sensor")
    let triggers = [SensorTrigger(sensorID: sensor.sensorId),
                    SensorTrigger(sensorID: sensor.sensorId),
                    SensorTrigger(sensorID: "another sensor"),
                    SensorTrigger(sensorID: "another sensor")]
    triggers.forEach {
      $0.triggerInformation.triggerActionType = .triggerActionAlert
      $0.triggerInformation.triggerAlertTypes = [.triggerAlertVisual]
    }
    let sensorDataManager = createSensorDataManager()
    let observe = ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                                        preferenceManager: PreferenceManager(),
                                        sensorController: MockSensorController(),
                                        sensorDataManager: sensorDataManager)
    observe.sensorTriggers = triggers

    XCTAssertFalse(observe.sensorHasVisualTriggers(sensor, forRecording: false),
                   "The sensor should not have visual triggers if they are not active.")

    // Mark the triggers as active.
    let mockDelegate = MockDelegate()
    mockDelegate.mockActiveTriggers = triggers
    observe.delegate = mockDelegate

    XCTAssertTrue(observe.sensorHasVisualTriggers(sensor, forRecording: false),
                  "The sensor should have visual triggers when they are active.")

    // Disable the test sensor's triggers.
    mockDelegate.mockActiveTriggers = [triggers[2], triggers[3]]

    XCTAssertFalse(observe.sensorHasVisualTriggers(sensor, forRecording: false),
                   "The sensor should not have visual triggers if they are not active.")

    // Re-enable all triggers, but mark them as fire only when recording.
    mockDelegate.mockActiveTriggers = triggers
    triggers.forEach { $0.triggerInformation.triggerOnlyWhenRecording = true }

    XCTAssertFalse(observe.sensorHasVisualTriggers(sensor, forRecording: false),
                   "The sensor should not have visual triggers while not recording if they are " +
                       "set to fire only when recording.")

    XCTAssertTrue(observe.sensorHasVisualTriggers(sensor, forRecording: true),
                   "The sensor should have visual triggers while recording.")

    // Mark the triggers to also fire when not recording.
    triggers.forEach { $0.triggerInformation.triggerOnlyWhenRecording = false }

    XCTAssertTrue(observe.sensorHasVisualTriggers(sensor, forRecording: false),
                   "The sensor should have visual triggers while not recording if they set to " +
                       "fire also when not recording.")
  }

  func testUpdateSensorCardsForVisualTriggers() {
    // Set up observe with a sensor card for one sensor in the data source.
    let sensor = Sensor.mock(sensorId: "test sensor")
    let sensorDataManager = createSensorDataManager()
    let observe = ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                                        preferenceManager: PreferenceManager(),
                                        sensorController: MockSensorController(),
                                        sensorDataManager: sensorDataManager)
    let sensorCard = observe.observeDataSource.sensorCardWithSensor(sensor,
                                                                    cardColorPalette: .blue,
                                                                    cellStateOptions: .normal)

    // Give the sensor a visual trigger.
    let trigger = SensorTrigger(sensorID: sensor.sensorId)
    trigger.triggerInformation.triggerActionType = .triggerActionAlert
    trigger.triggerInformation.triggerAlertTypes = [.triggerAlertVisual]
    observe.sensorTriggers = [trigger]

    // Mark the trigger as enabled.
    let mockDelegate = MockDelegate()
    mockDelegate.mockActiveTriggers = [trigger]
    observe.delegate = mockDelegate

    // Update sensor cards.
    observe.updateSensorCardsForVisualTriggers(whileRecording: false)

    XCTAssertTrue(sensorCard.cellState.options.contains(.visualTriggersVisible),
                  "Options should contain visual triggers visible when there is one.")

    // Set the trigger to fire only when recording.
    trigger.triggerInformation.triggerOnlyWhenRecording = true

    // Update sensor cards.
    observe.updateSensorCardsForVisualTriggers(whileRecording: false)

    XCTAssertFalse(sensorCard.cellState.options.contains(.visualTriggersVisible),
                  "Options should not contain visual triggers visible when it should fire only " +
                      "when recording, and observe is not recording.")

    // Update sensor cards for recording.
    observe.updateSensorCardsForVisualTriggers(whileRecording: true)

    XCTAssertTrue(sensorCard.cellState.options.contains(.visualTriggersVisible),
                  "Options should contain visual triggers visible when recording.")
  }

  func testSetAvailableSensorIDs() {
    // Add three sensors.
    let sensor1 = Sensor.mock(sensorId: "TEST_SENSOR_1")
    let sensor2 = Sensor.mock(sensorId: "TEST_SENSOR_2")
    let sensor3 = Sensor.mock(sensorId: "TEST_SENSOR_3")
    let sensorDataManager = createSensorDataManager()
    let observeVC = ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                                          preferenceManager: PreferenceManager(),
                                          sensorController: MockSensorController(),
                                          sensorDataManager: sensorDataManager)
    _ = observeVC.observeDataSource.sensorCardWithSensor(sensor1,
                                                         cardColorPalette: .blue,
                                                         cellStateOptions: .normal)
    _ = observeVC.observeDataSource.sensorCardWithSensor(sensor2,
                                                         cardColorPalette: .blue,
                                                         cellStateOptions: .normal)
    _ = observeVC.observeDataSource.sensorCardWithSensor(sensor3,
                                                         cardColorPalette: .blue,
                                                         cellStateOptions: .normal)

    XCTAssertEqual(3, observeVC.observeDataSource.items.count)
    XCTAssertEqual("TEST_SENSOR_1", observeVC.observeDataSource.items[0].sensor.sensorId)
    XCTAssertEqual("TEST_SENSOR_2", observeVC.observeDataSource.items[1].sensor.sensorId)
    XCTAssertEqual("TEST_SENSOR_3", observeVC.observeDataSource.items[2].sensor.sensorId)

    // Restrict available to sensors so only one active sensor is now available.
    observeVC.setAvailableSensorIDs(["TEST_SENSOR_2", "TEST_SENSOR_4"], andAddListeners: false)

    XCTAssertEqual(1, observeVC.observeDataSource.items.count)
    XCTAssertEqual("TEST_SENSOR_2", observeVC.observeDataSource.items[0].sensor.sensorId)
  }

  func testSensorsReceiveForegroundAndBackgroundCalls() {
    let mockSensor = MockSensor(sensorId: "test sensor ID")
    let mockSensorController = MockSensorController()
    mockSensorController.addSensorToReturn(mockSensor, forSensorId: mockSensor.sensorId)

    let sensorDataManager = createSensorDataManager()
    let observeViewController =
        ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                              preferenceManager: PreferenceManager(),
                              sensorController: mockSensorController,
                              sensorDataManager: sensorDataManager)
    observeViewController.addInitialSensorCardIfNeeded(andAddListener: false)

    observeViewController.applicationWillResignActive()
    XCTAssertTrue(mockSensor.didReceivePrepareForBackgroundCall)

    observeViewController.applicationDidBecomeActive()
    XCTAssertTrue(mockSensor.didReceivePrepareForForegroundCall)
  }

}
