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
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// Shows the current value of the sensor in a label, and an icon.
class CurrentValueView: UIView {

  // MARK: - Properties

  var animatingIconWrapperView = UIView()
  let textLabel = UILabel()
  let infoButton = MDCFlatButton()

  var animatingIconView = SensorAnimationView() {
    didSet {
      oldValue.removeFromSuperview()

      animatingIconWrapperView.addSubview(animatingIconView)
      animatingIconView.translatesAutoresizingMaskIntoConstraints = false
      animatingIconView.pinToEdgesOfView(animatingIconWrapperView)
    }
  }

  static let animatingIconViewSize = CGSize(width: 50, height: 50)
  static let margins = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)

  // MARK: - UIView

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: CurrentValueView.height)
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Sets the animating icon's value which changes the image appropriately.
  ///
  /// - Parameters:
  ///   - value: A sensor value.
  ///   - minValue: A minimum used to scale the value.
  ///   - maxValue: A maximum used to scale the value.
  func setAnimatingIconValue(_ value: Double, minValue: Double, maxValue: Double) {
    animatingIconView.setValue(value, minValue: minValue, maxValue: maxValue)
  }

  /// The height of the current value view.
  static var height: CGFloat {
    return animatingIconViewSize.height + margins.top + margins.bottom
  }

  // MARK: - Private

  private func configureView() {
    let stackView = UIStackView()
    stackView.alignment = .center
    stackView.axis = .horizontal
    stackView.spacing = 10
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.layoutMargins = CurrentValueView.margins
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.pinToEdgesOfView(self)

    // Animating icon wrapper view.
    animatingIconWrapperView.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(animatingIconWrapperView)
    animatingIconWrapperView.heightAnchor.constraint(
        equalToConstant: CurrentValueView.animatingIconViewSize.height).isActive = true
    animatingIconWrapperView.widthAnchor.constraint(
        equalToConstant: CurrentValueView.animatingIconViewSize.width).isActive = true

    // Text label.
    textLabel.textAlignment = .right
    textLabel.font = MDCTypography.headlineFont()
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    stackView.addArrangedSubview(textLabel)

    // Info button.
    infoButton.setImage(UIImage(named: "ic_info"), for: .normal)
    infoButton.tintColor = .darkGray
    infoButton.inkColor = .clear
    infoButton.contentEdgeInsets = .zero
    infoButton.imageEdgeInsets = .zero
    infoButton.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(infoButton)
    infoButton.widthAnchor.constraint(
        equalToConstant: SensorCardHeaderView.iconDimension).isActive = true
    infoButton.heightAnchor.constraint(
        equalToConstant: SensorCardHeaderView.iconDimension).isActive = true
    infoButton.accessibilityLabel = String.learnMoreBtnContentDescription
  }

}
