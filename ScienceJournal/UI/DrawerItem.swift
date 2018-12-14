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

/// Data object that represents a drawer tab, including its icon and the view controller that is
/// displayed when the tab is pressed.
open class DrawerItem {

  /// The image for the tab bar item.
  let tabBarImage: UIImage?

  /// The accessibility label for a tab bar item.
  let accessibilityLabel: String

  // The component's view controller.
  public let viewController: UIViewController

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - tabBarImage: The image for the tab bar item.
  ///   - accessibilityLabel: The localized string to read when the tab is selected.
  ///   - viewController: The view controller.
  public init(tabBarImage: UIImage?, accessibilityLabel: String, viewController: UIViewController) {
    self.tabBarImage = tabBarImage
    self.accessibilityLabel = accessibilityLabel
    self.viewController = viewController
  }

}
