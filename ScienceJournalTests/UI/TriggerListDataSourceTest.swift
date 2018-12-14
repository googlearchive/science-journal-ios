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

class TriggerListDataSourceTest: XCTestCase {

  let sensorTriggers = [SensorTrigger(sensorID: "Test Sensor ID"),
                        SensorTrigger(sensorID: "Test Sensor ID"),
                        SensorTrigger(sensorID: "Test Sensor ID"),
                        SensorTrigger(sensorID: "Test Sensor ID")]

  func testNumberOfItems() {
    // Create a trigger list data source that has 4 triggers.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    XCTAssertEqual(4, triggerListDataSource.numberOfItems, "The data source should have 4 items.")
    XCTAssertTrue(triggerListDataSource.hasItems, "Should be true when there are 4 items.")

    // Create a trigger list data source that has no triggers.
    let triggerListDataSource2 = TriggerListDataSource(sensorTriggers: [])
    XCTAssertEqual(0, triggerListDataSource2.numberOfItems, "The data source should have 0 items.")
    XCTAssertFalse(triggerListDataSource2.hasItems, "Should be false when there are 0 items.")
  }

  func testItemAtIndexPath() {
    // Create a trigger list data source and compare each against its original object.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    XCTAssertEqual(triggerListDataSource.item(at: IndexPath(item: 0, section: 0)).triggerID,
                   sensorTriggers[0].triggerID,
                   "The triggers should be equal.")
    XCTAssertEqual(triggerListDataSource.item(at: IndexPath(item: 1, section: 0)).triggerID,
                   sensorTriggers[1].triggerID,
                   "The triggers should be equal.")
    XCTAssertEqual(triggerListDataSource.item(at: IndexPath(item: 2, section: 0)).triggerID,
                   sensorTriggers[2].triggerID,
                   "The triggers should be equal.")
    XCTAssertEqual(triggerListDataSource.item(at: IndexPath(item: 3, section: 0)).triggerID,
                   sensorTriggers[3].triggerID,
                   "The triggers should be equal.")

    // Compare a trigger against a different one than itself.
    XCTAssertNotEqual(triggerListDataSource.item(at: IndexPath(item: 3, section: 0)).triggerID,
                      SensorTrigger(sensorID: "Test Sensor ID").triggerID,
                      "The triggers should not be equal.")
  }

  func testIndexPathOfItem() {
    // Create a trigger list data source and check each items index path.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    XCTAssertEqual(IndexPath(item: 0, section: 0),
                   triggerListDataSource.indexPathOfItem(sensorTriggers[0]),
                   "The index paths should match.")
    XCTAssertEqual(IndexPath(item: 1, section: 0),
                   triggerListDataSource.indexPathOfItem(sensorTriggers[1]),
                   "The index paths should match.")
    XCTAssertEqual(IndexPath(item: 2, section: 0),
                   triggerListDataSource.indexPathOfItem(sensorTriggers[2]),
                   "The index paths should match.")
    XCTAssertEqual(IndexPath(item: 3, section: 0),
                   triggerListDataSource.indexPathOfItem(sensorTriggers[3]),
                   "The index paths should match.")
  }

  func testIndexPathOfLastItem() {
    // Create a trigger list data source and check the index path of the last item.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    XCTAssertEqual(IndexPath(item: 3, section: 0),
                   triggerListDataSource.indexPathOfLastItem,
                   "The index paths should match.")
  }

  func testAddItem() {
    // Create a trigger list data source and add an item. It should add to the number of items, and
    // should also have an index path. Its index path should be the index path of the last item.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    XCTAssertEqual(4, triggerListDataSource.numberOfItems, "The data source should have 4 items.")

    let newTrigger = SensorTrigger(sensorID: "Test Sensor ID")
    triggerListDataSource.addItem(newTrigger)
    XCTAssertEqual(5,
                   triggerListDataSource.numberOfItems,
                   "The data source should now have 5 items.")
    XCTAssertEqual(IndexPath(item: 4, section: 0),
                   triggerListDataSource.indexPathOfItem(newTrigger)!,
                   "The index path should match.")
    XCTAssertEqual(triggerListDataSource.indexPathOfItem(newTrigger)!,
                   triggerListDataSource.indexPathOfLastItem,
                   "The index paths should match.")
  }

  func testInsertItem() {
    // Create a trigger list data source and insert an item. It should add to the number of items,
    // and should also have an index path. Its index path should be the index path where it was
    // inserted.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    XCTAssertEqual(4, triggerListDataSource.numberOfItems, "The data source should have 4 items.")

    let newTrigger = SensorTrigger(sensorID: "Test Sensor ID")
    triggerListDataSource.insertItem(newTrigger, atIndex: 2)
    XCTAssertEqual(5,
                   triggerListDataSource.numberOfItems,
                   "The data source should now have 5 items.")
    XCTAssertEqual(IndexPath(item: 2, section: 0),
                   triggerListDataSource.indexPathOfItem(newTrigger)!,
                   "The index path should match.")
  }

  func testRemoveItem() {
    // Create a trigger list data source and remove an item. It should remove from the number of
    // items. The removed trigger should match the trigger at the index path.
    let triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)
    let triggerToRemove = triggerListDataSource.item(at: IndexPath(item: 2, section: 0))

    XCTAssertEqual(4, triggerListDataSource.numberOfItems, "The data source should have 4 items.")
    XCTAssertTrue(triggerListDataSource.triggers.contains(where: {
      $0.triggerID == triggerToRemove.triggerID
    }),
                  "Triggers should contain the trigger to remove.")

    let removedTrigger = triggerListDataSource.removeItem(at: IndexPath(item: 2, section: 0))
    XCTAssertEqual(3,
                   triggerListDataSource.numberOfItems,
                   "The data source should now have 3 items.")
    XCTAssertFalse(triggerListDataSource.triggers.contains(where: {
      $0.triggerID == triggerToRemove.triggerID
    }),
                  "Triggers should not contain the trigger to remove.")
    XCTAssertEqual(triggerToRemove.triggerID,
                   removedTrigger!.triggerID,
                   "The removed trigger and trigger to remove should match.")
  }

}
