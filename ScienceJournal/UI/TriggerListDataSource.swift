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

import UIKit

/// A data source for a list of triggers for a sensor. They can be modified, deleted or added to.
class TriggerListDataSource {

  // MARK: - Properties

  /// The number of items in the data source.
  var numberOfItems: Int {
    return triggers.count
  }

  /// Whether or not the data source has items.
  var hasItems: Bool {
    return numberOfItems != 0
  }

  /// The triggers.
  var triggers: [SensorTrigger]

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter: sensorTriggers: The triggers.
  init(sensorTriggers: [SensorTrigger]) {
    triggers = sensorTriggers
  }

  /// Returns the sensor trigger for an index path.
  func item(at indexPath: IndexPath) -> SensorTrigger {
    return triggers[indexPath.item]
  }

  /// Returns the index path of an item.
  func indexPathOfItem(_ item: SensorTrigger) -> IndexPath? {
    guard let index =
        triggers.firstIndex(where: { $0.triggerID == item.triggerID }) else { return nil }
    return IndexPath(item: index, section: 0)
  }

  /// Returns the index path of the last item.
  var indexPathOfLastItem: IndexPath {
    return IndexPath(item: numberOfItems - 1, section: 0)
  }

  /// Adds a sensor trigger to the end of the list.
  func addItem(_ item: SensorTrigger) {
    insertItem(item, atIndex: triggers.endIndex)
  }

  /// Inserts a sensor trigger at the given index.
  func insertItem(_ item: SensorTrigger, atIndex index: Int) {
    triggers.insert(item, at: index)
  }

  /// Removes a trigger.
  @discardableResult func removeItem(at indexPath: IndexPath) -> SensorTrigger? {
    return triggers.remove(at: indexPath.item)
  }

}
