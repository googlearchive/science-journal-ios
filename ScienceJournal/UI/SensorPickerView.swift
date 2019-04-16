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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_Tabs_Tabs

/// A view with the sensor settings button and a picker view for selecting sensors.
class SensorPickerView: UIView {

  // MARK: - Properties

  let settingsButton = MDCFlatButton()
  let tabBar = MDCTabBar()
  var isAccessible: Bool = true {
    didSet {
      tabBar.accessibilityElementsHidden = !isAccessible
      tabBar.items.forEach { $0.isAccessibilityElement = isAccessible }
      settingsButton.isAccessibilityElement = isAccessible
    }
  }

  /// The height of the sensor picker view.
  static let height: CGFloat = 48

  // MARK: - UIView

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: SensorPickerView.height)
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  // MARK: - Private

  private func configureView() {
    clipsToBounds = true

    let stackView = UIStackView()
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.pinToEdgesOfView(self)

    // Tab bar.
    tabBar.itemAppearance = .images
    tabBar.tintColor = .yellow
    tabBar.selectedItemTintColor = .white
    tabBar.unselectedItemTintColor = .white
    tabBar.barTintColor = .clear
    tabBar.inkColor = UIColor(white: 0, alpha: 0.2)
    tabBar.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
    tabBar.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(tabBar)
    // If the tab bar width is set smaller than its item size (this can happen during rotation), the
    // item sizes compress and are never re-sized, causing a layout bug. Temporary fix until the MDC
    // bug is fixed. https://github.com/material-components/material-components-ios/issues/2727
    tabBar.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

    // Settings button.
    settingsButton.accessibilityLabel = String.titleActivitySensorSettings
    settingsButton.setImage(UIImage(named: "ic_settings"), for: .normal)
    settingsButton.tintColor = .white
    settingsButton.translatesAutoresizingMaskIntoConstraints = false
    settingsButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    settingsButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
    stackView.addArrangedSubview(settingsButton)
  }

}
