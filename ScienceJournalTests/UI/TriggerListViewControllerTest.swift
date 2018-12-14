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

class TriggerListViewControllerTest: XCTestCase {

  class MockDelegate: TriggerListDelegate {
    func triggerListViewController(_ triggerListViewController: TriggerListViewController,
                                   didUpdateTriggers sensorTriggers: [SensorTrigger],
                                   withActiveTriggerIDs activeTriggerIDs: [String],
                                   forSensor sensor: Sensor) {}
  }

  class MockCollectionView: UICollectionView {

    var mockIndexPath: IndexPath?

    override func indexPath(for cell: UICollectionViewCell) -> IndexPath? {
      return mockIndexPath
    }
  }

  func testActiveTriggerIDsUpdateForSwitchValueChanged() {
    // Create a sensor and some triggers.
    let sensor = Sensor.mock(sensorId: "test sensor ID")
    let trigger1 = SensorTrigger(sensorID: sensor.sensorId)
    let trigger2 = SensorTrigger(sensorID: sensor.sensorId)

    // Create a mock collection view and trigger list view controller with the triggers.
    let mockCollectionView = MockCollectionView(frame: .zero,
                                                collectionViewLayout: UICollectionViewLayout())
    let triggerListViewController =
        TriggerListViewController(sensorTriggers: [trigger1, trigger2],
                                  activeTriggerIDs: [trigger1.triggerID],
                                  sensor: sensor,
                                  delegate: MockDelegate(),
                                  analyticsReporter: AnalyticsReporterOpen())
    triggerListViewController.collectionView = mockCollectionView

    // Set the mock to return the index path of trigger 1.
    mockCollectionView.mockIndexPath = IndexPath(item: 0, section: 0)

    // Trigger 1 should be active.
    XCTAssertTrue(triggerListViewController.isTriggerActive(trigger1))

    // Create a trigger list cell and set its switch to off.
    let triggerListCell = TriggerListCell()
    triggerListCell.aSwitch.isOn = false

    // Call switch value changed and check that trigger 1 is no longer active.
    triggerListViewController.triggerListCellSwitchValueChanged(triggerListCell)
    XCTAssertFalse(triggerListViewController.isTriggerActive(trigger1))

    // Set the switch to on and call value changed again to check that trigger 1 is active again.
    triggerListCell.aSwitch.isOn = true
    triggerListViewController.triggerListCellSwitchValueChanged(triggerListCell)
    XCTAssertTrue(triggerListViewController.isTriggerActive(trigger1))

    // Do the same for trigger 2, but starting from disabled.
    mockCollectionView.mockIndexPath = IndexPath(item: 1, section: 0)
    XCTAssertFalse(triggerListViewController.isTriggerActive(trigger2))

    triggerListCell.aSwitch.isOn = true
    triggerListViewController.triggerListCellSwitchValueChanged(triggerListCell)
    XCTAssertTrue(triggerListViewController.isTriggerActive(trigger2))

    triggerListCell.aSwitch.isOn = false
    triggerListViewController.triggerListCellSwitchValueChanged(triggerListCell)
    XCTAssertFalse(triggerListViewController.isTriggerActive(trigger2))
 }

}
