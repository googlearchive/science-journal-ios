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

class DrawerConfigOpen: DrawerConfig {

  func configuredDrawerItems(analyticsReporter: AnalyticsReporter,
                             preferenceManager: PreferenceManager,
                             sensorController: SensorController,
                             sensorDataManager: SensorDataManager) ->
      (keyedDrawerItems: [String: DrawerItem], drawerItems: [DrawerItem]) {
    var keyedDrawerItems = [String: DrawerItem]()
    var drawerItems = [DrawerItem]()

    let notesViewController = NotesViewController(analyticsReporter: analyticsReporter)
    let observeViewController = ObserveViewController(analyticsReporter: analyticsReporter,
                                                      preferenceManager: preferenceManager,
                                                      sensorController: sensorController,
                                                      sensorDataManager: sensorDataManager)
    let cameraViewController = CameraViewController(analyticsReporter: analyticsReporter)
    let photoLibraryViewController = PhotoLibraryViewController(
        actionBarButtonType: .send,
        analyticsReporter: analyticsReporter)

    let notesItem = DrawerItem(tabBarImage: UIImage(named: "ic_comment"),
                               accessibilityLabel: String.notesTabContentDescription,
                               viewController: notesViewController)
    keyedDrawerItems[DrawerItemKeys.notesViewControllerKey] = notesItem
    drawerItems.append(notesItem)

    let observeItem = DrawerItem(tabBarImage: UIImage(named: "ic_sensors"),
                                 accessibilityLabel: String.observeTabContentDescription,
                                 viewController: observeViewController)
    keyedDrawerItems[DrawerItemKeys.observeViewControllerKey] = observeItem
    drawerItems.append(observeItem)

    let cameraItem = DrawerItem(tabBarImage: UIImage(named: "ic_camera_alt"),
                                accessibilityLabel: String.cameraTabContentDescription,
                                viewController: cameraViewController)
    keyedDrawerItems[DrawerItemKeys.cameraViewControllerKey] = cameraItem
    drawerItems.append(cameraItem)

    let photoItem = DrawerItem(tabBarImage: UIImage(named: "ic_image"),
                               accessibilityLabel: String.photosTabContentDescription,
                               viewController: photoLibraryViewController)
    keyedDrawerItems[DrawerItemKeys.photoLibraryViewControllerKey] = photoItem
    drawerItems.append(photoItem)

    return (keyedDrawerItems, drawerItems)
  }

}
