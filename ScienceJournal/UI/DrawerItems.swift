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

import UIKit

/// The drawer items and their view controllers.
open class DrawerItems {

  // MARK: - Properties

  /// All drawer items, ordered. Classes should use this to fetch all drawer items.
  var allItems: [DrawerItem]

  /// All view controllers belonging to drawer items.
  var viewControllers: [DrawerItemViewController] {
    return keyedDrawerItems.values.compactMap { $0.viewController as? DrawerItemViewController }
  }

  /// All view controllers which require position tracking in the drawer.
  var drawerPositionListeners: [DrawerPositionListener] {
    return keyedDrawerItems.values.compactMap { $0.viewController as? DrawerPositionListener }
  }

  /// All drawer items, keyed and unordered.
  private var keyedDrawerItems: [String: DrawerItem]

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: The analytics reporter.
  ///   - drawerConfig: The drawer config.
  ///   - preferenceManager: A preference manager.
  ///   - sensorController: The sensor controller.
  ///   - sensorDataManager: A sensor data manager.
  init(analyticsReporter: AnalyticsReporter,
       drawerConfig: DrawerConfig,
       preferenceManager: PreferenceManager,
       sensorController: SensorController,
       sensorDataManager: SensorDataManager) {
    let drawerConfigItems = drawerConfig.configuredDrawerItems(analyticsReporter: analyticsReporter,
                                                               preferenceManager: preferenceManager,
                                                               sensorController: sensorController,
                                                               sensorDataManager: sensorDataManager)
    keyedDrawerItems = drawerConfigItems.keyedDrawerItems
    allItems = drawerConfigItems.drawerItems
  }

  /// A drawer item for the given key.
  ///
  /// - Parameter: A key.
  /// - Returns: The drawer item.
  func drawerItemForKey(_ key: String) -> DrawerItem {
    return keyedDrawerItems[key]!
  }

  /// The view controller for a drawer item with a given key.
  ///
  /// - Parameter: A key.
  /// - Returns: The view controller.
  public func viewControllerForKey(_ key: String) -> DrawerItemViewController {
    return (keyedDrawerItems[key]?.viewController as? DrawerItemViewController)!
  }

}
