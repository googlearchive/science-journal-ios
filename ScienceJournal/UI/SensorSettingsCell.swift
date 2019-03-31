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

protocol SensorSettingsCellDelegate: class {
  /// Tells the delegate the button was pressed.
  ///
  /// - Parameter cell: The cell whose button was pressed.
  func sensorSettingsCell(_ cell: SensorSettingsCell, buttonPressed button: UIButton)
}

/// A cell for displaying sensor settings. Each has a single line text label, and optional rotating
/// buttons, check boxes and image views.
class SensorSettingsCell: MDCCollectionViewCell {

  /// The control types a sensor settings cell can have.
  enum ControlType {
    /// No control.
    case none
    /// A rotating button.
    case rotatingButton
    /// A check box.
    case checkBox
  }

  // MARK: - Properties

  weak var delegate: SensorSettingsCellDelegate?

  /// The cell height.
  static let height: CGFloat = 48

  /// The control type.
  var controlType = ControlType.none {
    didSet {
      switch controlType {
      case .none:
        checkBox.isHidden = true
        rotatingButton.isHidden = true
      case .rotatingButton:
        checkBox.isHidden = true
        rotatingButton.isHidden = false
      case .checkBox:
        checkBox.isHidden = false
        rotatingButton.isHidden = true
      }
    }
  }

  /// The image to show in the image view.
  var image: UIImage? {
    didSet {
      guard let image = image else {
        imageView.image = nil
        imageView.isHidden = true
        return
      }

      imageView.image = image
      imageView.isHidden = false
    }
  }

  /// The text label.
  let textLabel = UILabel()

  /// The rotating button.
  let rotatingButton = RotatingExpandButton(arrowDirection: .down)

  /// Whether or not the check box is checked.
  var isCheckBoxChecked: Bool = false {
    didSet {
      guard isCheckBoxChecked != oldValue else { return }

      if isCheckBoxChecked {
        checkBox.image = UIImage(named: "ic_check_box")
      } else {
        checkBox.image = UIImage(named: "ic_check_box_outline_blank")
      }
      checkBox.tintColor = checkBoxTintColor
    }
  }

  /// Whether or not the check box is disabled.
  var isCheckBoxDisabled: Bool = false {
    didSet {
      guard isCheckBoxDisabled != oldValue else { return }
      checkBox.tintColor = checkBoxTintColor
    }
  }

  private let checkBox = UIImageView()
  private let imageView = UIImageView()
  private let button = MDCFlatButton()

  private var checkBoxTintColor: UIColor {
    if isCheckBoxDisabled {
      return MDCPalette.grey.tint300
    } else {
      if isCheckBoxChecked {
        return MDCPalette.blue.tint500
      } else {
        return MDCPalette.grey.tint500
      }
    }
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

  override func prepareForReuse() {
    super.prepareForReuse()
    controlType = .none
    tintColor = nil
    image = nil
    textLabel.textColor = .black
    button.isHidden = true
  }

  /// Sets the button image.
  ///
  /// - Parameter image: An image.
  func setButtonImage(_ image: UIImage?) {
    button.setImage(image, for: .normal)
    button.isHidden = image == nil
  }

  // MARK: - Private

  private func configureView() {
    rotatingButton.isHidden = true
    rotatingButton.setContentHuggingPriority(.required, for: .horizontal)
    rotatingButton.tintColor = MDCPalette.grey.tint500
    rotatingButton.translatesAutoresizingMaskIntoConstraints = false
    rotatingButton.isUserInteractionEnabled = false

    isCheckBoxChecked = true
    checkBox.isHidden = true
    checkBox.contentMode = .center
    checkBox.translatesAutoresizingMaskIntoConstraints = false
    checkBox.heightAnchor.constraint(equalToConstant: 24).isActive = true
    checkBox.widthAnchor.constraint(equalToConstant: 58).isActive = true

    imageView.isHidden = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
    imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true

    let spacingView = UIView()
    spacingView.translatesAutoresizingMaskIntoConstraints = false
    spacingView.widthAnchor.constraint(equalToConstant: 18).isActive = true

    button.isHidden = true
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)

    textLabel.alpha = MDCTypography.subheadFontOpacity()
    textLabel.font = MDCTypography.subheadFont()
    textLabel.translatesAutoresizingMaskIntoConstraints = false

    let views = [rotatingButton, checkBox, imageView, spacingView, textLabel, button]
    let stackView = UIStackView(arrangedSubviews: views)
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stackView)
    stackView.pinToEdgesOfView(contentView)
  }

  @objc private func buttonPressed(_ button: UIButton) {
    delegate?.sensorSettingsCell(self, buttonPressed: button)
  }

}
