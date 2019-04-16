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

class ExperimentCoordinatorViewControllerTest: XCTestCase {

  let sensorDataManager = SensorDataManager.testStore
  var drawerVC: DrawerViewController!
  let metadataManager = MetadataManager.testingInstance
  var documentManager: DocumentManager!

  class MockDelegate: TriggerListDelegate {
    func triggerListViewController(_ triggerListViewController: TriggerListViewController,
                                   didUpdateTriggers sensorTriggers: [SensorTrigger],
                                   withActiveTriggerIDs activeTriggerIDs: [String],
                                   forSensor sensor: Sensor) {}
  }

  override func setUp() {
    super.setUp()
    let analyticsReporter = AnalyticsReporterOpen()
    let sensorDataManager = SensorDataManager.testStore
    let metadataManager = MetadataManager.testingInstance
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "MockUser",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                      metadataManager: metadataManager,
                                      sensorDataManager: sensorDataManager)
    drawerVC = DrawerViewController(analyticsReporter: analyticsReporter,
                                    drawerConfig: DrawerConfigOpen(),
                                    preferenceManager: PreferenceManager(),
                                    sensorController: MockSensorController(),
                                    sensorDataManager: sensorDataManager)
  }

  // TODO: Re-enable these tests once photo permission alert bug is addressed. http://b/63697236
  func disableTestTriggerReplace() {
    // Create some triggers.
    let trigger1 = SensorTrigger(sensorID: "test sensor ID")
    trigger1.triggerInformation.triggerWhen = .triggerWhenAbove
    trigger1.triggerInformation.valueToTrigger = 1
    let trigger2 = SensorTrigger(sensorID: "test sensor ID")
    trigger2.triggerInformation.triggerWhen = .triggerWhenAt
    trigger2.triggerInformation.valueToTrigger = 2
    let trigger3 = SensorTrigger(sensorID: "test sensor ID")
    trigger3.triggerInformation.triggerWhen = .triggerWhenBelow
    trigger3.triggerInformation.valueToTrigger = 3

    // Give the triggers to an experiment.
    let experiment = Experiment(ID: "test experiment ID")
    experiment.sensorTriggers = [trigger1, trigger2, trigger3]
    XCTAssertEqual(experiment.sensorTriggers.count, 3)

    // Create an array of updated triggers with IDs matching the originals.
    let trigger4 = SensorTrigger(sensorID: "test sensor ID")
    trigger4.triggerID = trigger1.triggerID
    trigger4.triggerInformation.valueToTrigger = 4
    let trigger5 = SensorTrigger(sensorID: "test sensor ID")
    trigger5.triggerID = trigger2.triggerID
    trigger5.triggerInformation.valueToTrigger = 5
    let trigger6 = SensorTrigger(sensorID: "test sensor ID")
    trigger6.triggerID = trigger3.triggerID
    trigger6.triggerInformation.valueToTrigger = 6

    // Call to update the experiment's triggers and check that they have been replaced in the
    // triggers array.
    let experimentViewController =
        ExperimentCoordinatorViewController(experiment: experiment,
                                            experimentInteractionOptions: .normal,
                                            shouldAllowSharing: true,
                                            drawerViewController: drawerVC,
                                            analyticsReporter: AnalyticsReporterOpen(),
                                            metadataManager: metadataManager,
                                            preferenceManager: PreferenceManager(),
                                            sensorController: MockSensorController(),
                                            sensorDataManager: sensorDataManager,
                                            documentManager: documentManager)
    let sensor = Sensor.mock(sensorId: "test sensor ID")
    let triggerListViewController =
        TriggerListViewController(sensorTriggers: [],
                                  activeTriggerIDs: [],
                                  sensor: sensor,
                                  delegate: MockDelegate(),
                                  analyticsReporter: AnalyticsReporterOpen())
    experimentViewController.triggerListViewController(
        triggerListViewController,
        didUpdateTriggers: [trigger4, trigger5, trigger6],
        withActiveTriggerIDs: [],
        forSensor: sensor)
    XCTAssertEqual(experiment.sensorTriggers[0].triggerInformation.valueToTrigger,
                   trigger4.triggerInformation.valueToTrigger)
    XCTAssertEqual(experiment.sensorTriggers[1].triggerInformation.valueToTrigger,
                   trigger5.triggerInformation.valueToTrigger)
    XCTAssertEqual(experiment.sensorTriggers[2].triggerInformation.valueToTrigger,
                   trigger6.triggerInformation.valueToTrigger)
    XCTAssertEqual(experiment.sensorTriggers.count, 3)
  }

  func disableTestTriggerDelete() {
    // Create some triggers.
    let trigger1 = SensorTrigger(sensorID: "test sensor ID")
    trigger1.triggerInformation.triggerWhen = .triggerWhenAbove
    trigger1.triggerInformation.valueToTrigger = 1
    let trigger2 = SensorTrigger(sensorID: "test sensor ID")
    trigger2.triggerInformation.triggerWhen = .triggerWhenAt
    trigger2.triggerInformation.valueToTrigger = 2
    let trigger3 = SensorTrigger(sensorID: "test sensor ID")
    trigger3.triggerInformation.triggerWhen = .triggerWhenBelow
    trigger3.triggerInformation.valueToTrigger = 3

    // Give the triggers to an experiment.
    let experiment = Experiment(ID: "test experiment ID")
    experiment.sensorTriggers = [trigger1, trigger2, trigger3]
    XCTAssertEqual(experiment.sensorTriggers.count, 3)

    // Call to update the experiment's triggers and check that the ones not passed have been removed
    // in the triggers array.
    let experimentViewController =
        ExperimentCoordinatorViewController(experiment: experiment,
                                            experimentInteractionOptions: .normal,
                                            shouldAllowSharing: true,
                                            drawerViewController: drawerVC,
                                            analyticsReporter: AnalyticsReporterOpen(),
                                            metadataManager: metadataManager,
                                            preferenceManager: PreferenceManager(),
                                            sensorController: MockSensorController(),
                                            sensorDataManager: sensorDataManager,
                                            documentManager: documentManager)
    let sensor = Sensor.mock(sensorId: "test sensor ID")
    let triggerListViewController =
        TriggerListViewController(sensorTriggers: [],
                                  activeTriggerIDs: [],
                                  sensor: sensor,
                                  delegate: MockDelegate(),
                                  analyticsReporter: AnalyticsReporterOpen())
    experimentViewController.triggerListViewController(triggerListViewController,
                                                       didUpdateTriggers: [trigger1, trigger3],
                                                       withActiveTriggerIDs: [],
                                                       forSensor: sensor)
    var foundTrigger1 = false
    var foundTrigger2 = false
    var foundTrigger3 = false
    for trigger in experiment.sensorTriggers {
      if trigger.triggerID ==  trigger1.triggerID {
        foundTrigger1 = true
      } else if trigger.triggerID ==  trigger2.triggerID {
        foundTrigger2 = true
      } else if trigger.triggerID ==  trigger3.triggerID {
        foundTrigger3 = true
      }
    }
    XCTAssertTrue(foundTrigger1)
    XCTAssertFalse(foundTrigger2)
    XCTAssertTrue(foundTrigger3)
    XCTAssertEqual(experiment.sensorTriggers.count, 2)
  }

  func disableTestTriggerAddition() {
    // Create some triggers.
    let trigger1 = SensorTrigger(sensorID: "test sensor ID")
    trigger1.triggerInformation.triggerWhen = .triggerWhenAbove
    trigger1.triggerInformation.valueToTrigger = 1
    let trigger2 = SensorTrigger(sensorID: "test sensor ID")
    trigger2.triggerInformation.triggerWhen = .triggerWhenAt
    trigger2.triggerInformation.valueToTrigger = 2
    let trigger3 = SensorTrigger(sensorID: "test sensor ID")
    trigger3.triggerInformation.triggerWhen = .triggerWhenBelow
    trigger3.triggerInformation.valueToTrigger = 3

    // Give the triggers to an experiment.
    let experiment = Experiment(ID: "test experiment ID")
    experiment.sensorTriggers = [trigger1, trigger2, trigger3]
    XCTAssertEqual(experiment.sensorTriggers.count, 3)

    // Call to update the experiment's triggers and check that the new ones passed have been added
    // in the triggers array.
    let experimentViewController =
        ExperimentCoordinatorViewController(experiment: experiment,
                                            experimentInteractionOptions: .normal,
                                            shouldAllowSharing: true,
                                            drawerViewController: drawerVC,
                                            analyticsReporter: AnalyticsReporterOpen(),
                                            metadataManager: metadataManager,
                                            preferenceManager: PreferenceManager(),
                                            sensorController: MockSensorController(),
                                            sensorDataManager: sensorDataManager,
                                            documentManager: documentManager)
    let sensor = Sensor.mock(sensorId: "test sensor ID")
    let triggerListViewController =
        TriggerListViewController(sensorTriggers: [],
                                  activeTriggerIDs: [],
                                  sensor: sensor,
                                  delegate: MockDelegate(),
                                  analyticsReporter: AnalyticsReporterOpen())
    let trigger4 = SensorTrigger(sensorID: "test sensor ID")
    trigger4.triggerInformation.triggerWhen = .triggerWhenRisesAbove
    trigger4.triggerInformation.valueToTrigger = 4
    experimentViewController.triggerListViewController(
        triggerListViewController,
        didUpdateTriggers: [trigger1, trigger2, trigger3, trigger4],
        withActiveTriggerIDs: [],
        forSensor: sensor)
    var foundTrigger1 = false
    var foundTrigger2 = false
    var foundTrigger3 = false
    var foundTrigger4 = false
    for trigger in experiment.sensorTriggers {
      if trigger.triggerID ==  trigger1.triggerID {
        foundTrigger1 = true
      } else if trigger.triggerID ==  trigger2.triggerID {
        foundTrigger2 = true
      } else if trigger.triggerID ==  trigger3.triggerID {
        foundTrigger3 = true
      } else if trigger.triggerID ==  trigger4.triggerID {
        foundTrigger4 = true
      }
    }
    XCTAssertTrue(foundTrigger1)
    XCTAssertTrue(foundTrigger2)
    XCTAssertTrue(foundTrigger3)
    XCTAssertTrue(foundTrigger4)
    XCTAssertEqual(experiment.sensorTriggers.count, 4)
  }

  func disableTestIsSensorTriggerActive() {
    // Create some triggers, all for the same sensor ID.
    let sensorID = "test sensor ID"
    let trigger1 = SensorTrigger(sensorID: sensorID)
    let trigger2 = SensorTrigger(sensorID: sensorID)
    let trigger3 = SensorTrigger(sensorID: sensorID)
    let trigger4 = SensorTrigger(sensorID: sensorID)

    // Create a sensor layout for the same sensor ID as the triggers. Add two of the trigger IDs to
    // the layout's active sensor trigger IDs.
    let sensorLayout = SensorLayout(sensorID: sensorID, colorPalette: .blue)
    sensorLayout.activeSensorTriggerIDs = [trigger1.triggerID, trigger2.triggerID]

    // Create an experiment and add the sensor layout to it.
    let experiment = Experiment(ID: "test experiment ID")
    experiment.sensorLayouts.append(sensorLayout)

    // Create an experiment view controller to test whether or not the triggers are active.
    let experimentViewController =
        ExperimentCoordinatorViewController(experiment: experiment,
                                            experimentInteractionOptions: .normal,
                                            shouldAllowSharing: true,
                                            drawerViewController: drawerVC,
                                            analyticsReporter: AnalyticsReporterOpen(),
                                            metadataManager: metadataManager,
                                            preferenceManager: PreferenceManager(),
                                            sensorController: MockSensorController(),
                                            sensorDataManager: sensorDataManager,
                                            documentManager: documentManager)
    XCTAssertTrue(experimentViewController.observeViewController(
        ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                              preferenceManager: PreferenceManager(),
                              sensorController: MockSensorController(),
                              sensorDataManager: sensorDataManager),
        isSensorTriggerActive: trigger1))
    XCTAssertTrue(experimentViewController.observeViewController(
        ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                              preferenceManager: PreferenceManager(),
                              sensorController: MockSensorController(),
                              sensorDataManager: sensorDataManager),
        isSensorTriggerActive: trigger2))
    XCTAssertFalse(experimentViewController.observeViewController(
        ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                              preferenceManager: PreferenceManager(),
                              sensorController: MockSensorController(),
                              sensorDataManager: sensorDataManager),
        isSensorTriggerActive: trigger3))
    XCTAssertFalse(experimentViewController.observeViewController(
        ObserveViewController(analyticsReporter: AnalyticsReporterOpen(),
                              preferenceManager: PreferenceManager(),
                              sensorController: MockSensorController(),
                              sensorDataManager: sensorDataManager),
        isSensorTriggerActive: trigger4))
  }

  func testRightBarButtonItemsWithDrawer() {
    let experiment = Experiment(ID: "test experiment ID")
    let experimentViewController =
        ExperimentCoordinatorViewController(experiment: experiment,
                                            experimentInteractionOptions: .normal,
                                            shouldAllowSharing: true,
                                            drawerViewController: drawerVC,
                                            analyticsReporter: AnalyticsReporterOpen(),
                                            metadataManager: metadataManager,
                                            preferenceManager: PreferenceManager(),
                                            sensorController: MockSensorController(),
                                            sensorDataManager: sensorDataManager,
                                            documentManager: documentManager)

    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.experimentInteractionOptions.remove(.canAdd)
    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.experimentInteractionOptions.remove(.canEdit)
    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.experimentInteractionOptions.insert(.canAdd)
    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))
  }

  func testRightBarButtonItemsNoDrawer() {
    let experiment = Experiment(ID: "test experiment ID")
    let experimentViewController =
        ExperimentCoordinatorViewController(experiment: experiment,
                                            experimentInteractionOptions: .normal,
                                            shouldAllowSharing: true,
                                            drawerViewController: nil,
                                            analyticsReporter: AnalyticsReporterOpen(),
                                            metadataManager: metadataManager,
                                            preferenceManager: PreferenceManager(),
                                            sensorController: MockSensorController(),
                                            sensorDataManager: sensorDataManager,
                                            documentManager: documentManager)

    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.experimentInteractionOptions.remove(.canAdd)
    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.experimentInteractionOptions.remove(.canEdit)
    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.experimentInteractionOptions.insert(.canAdd)
    experimentViewController.updateRightBarButtonItems(for: .compact)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))

    experimentViewController.updateRightBarButtonItems(for: .regularWide)
    XCTAssertTrue(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.menuBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.editBarButton))
    XCTAssertFalse(experimentViewController.navigationItem.rightBarButtonItems!.contains(
        experimentViewController.fixedSpaceBarItem))
  }

}
