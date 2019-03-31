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

import MaterialComponents

/// A bar button item that can be used throughout Science Journal navigation bars. Can have popup
/// menus attached to the `button` subview.
class MaterialBarButtonItem: UIBarButtonItem {

  // MARK: - Constants

  /// The width and height dimension of the icon, which includes padding.
  static let barButtonIconDimension: CGFloat = 56.0

  // MARK: - Properties

  /// The button to add actions to and to attach menus to.
  let button = MDCFlatButton()

  // MARK: - Public

  override init() {
    super.init()
    configureButton()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureButton()
  }

  // MARK: - Private

  fileprivate func configureButton() {
    button.inkStyle = .unbounded
    button.inkMaxRippleRadius = 28.0
    button.tintColor = .white
    button.autoresizesSubviews = false
    button.contentEdgeInsets = .zero
    button.imageEdgeInsets = .zero
    button.translatesAutoresizingMaskIntoConstraints = false
    button.widthAnchor.constraint(
        equalToConstant: MaterialBarButtonItem.barButtonIconDimension).isActive = true
    customView = button
    width = MaterialBarButtonItem.barButtonIconDimension
  }

}

/// Subclass of MaterialBarButtonItem for menu buttons, for accessibility purposes.
class MaterialMenuBarButtonItem: MaterialBarButtonItem {

  override func configureButton() {
    super.configureButton()
    button.accessibilityLabel = String.menuBtnContentDescription
    button.accessibilityHint = String.menuBtnContentDetails
  }

}
