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

/// A cell used to display an action in a pop up menu view controller. It has a text label and
/// optional leading image view.
class PopUpMenuCell: UICollectionViewCell {

  // MARK: - Properties

  /// The text label.
  let textLabel = UILabel()

  /// The icon.
  var icon: UIImage? {
    didSet{
      guard let icon = icon else {
        if oldValue != nil {
          stackView.removeArrangedSubview(imageView)
          imageView.removeFromSuperview()
        }
        return
      }

      imageView.image = icon
      imageView.tintColor = MDCPalette.grey.tint700

      if oldValue == nil {
        stackView.insertArrangedSubview(imageView, at: 0)
      }
    }
  }

  /// Is cell enabled? If not, the text and icon have a disabled appearance.
  var isEnabled: Bool = true {
    didSet {
      guard oldValue != isEnabled else { return }
      [textLabel, imageView].forEach { $0.alpha = isEnabled ? 1 : 0.5 }

      if isEnabled {
        accessibilityTraits = .button
      } else {
        accessibilityTraits = UIAccessibilityTraits(rawValue:
            UIAccessibilityTraits.button.rawValue | UIAccessibilityTraits.notEnabled.rawValue)
      }
    }
  }

  /// The inset margins.
  static let margins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

  /// The text label font.
  static let textLabelFont = MDCTypography.subheadFont()

  /// The image view size.
  static let imageViewSize = CGSize(width: 24, height: 24)

  /// The spacing between the image view and text label.
  static let textToImageSpacing: CGFloat = 10

  /// The cell height.
  static let height: CGFloat = 48

  private let imageView = UIImageView()
  private let stackView = UIStackView()

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
    imageView.image = nil
    textLabel.text = nil
    isEnabled = true
  }

  // MARK: - Private

  private func configureView() {
    isAccessibilityElement = true
    accessibilityTraits = .button

    // Stack view.
    stackView.alignment = .center
    stackView.axis = .horizontal
    stackView.spacing = PopUpMenuCell.textToImageSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stackView)
    stackView.layoutMargins = PopUpMenuCell.margins
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.pinToEdgesOfView(self)

    // Image view. Will be added to the stack view when an icon is set.
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.heightAnchor.constraint(
        equalToConstant: PopUpMenuCell.imageViewSize.height).isActive = true
    imageView.widthAnchor.constraint(
        equalToConstant: PopUpMenuCell.imageViewSize.width).isActive = true

    // Text label.
    textLabel.font = PopUpMenuCell.textLabelFont
    textLabel.textColor = UIColor(white: 0, alpha: MDCTypography.subheadFontOpacity())
    textLabel.lineBreakMode = .byTruncatingTail
    textLabel.adjustsFontSizeToFitWidth = true
    stackView.addArrangedSubview(textLabel)
  }

}
