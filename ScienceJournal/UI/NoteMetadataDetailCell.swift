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

/// A cell that displays the description, value and icon for metadata about a note.
class NoteMetadataDetailCell: UICollectionViewCell {

  // MARK: - Constants

  static let edgeInsets = UIEdgeInsets(top: 10.0, left: 0, bottom: 6.0, right: 0)
  static let iconDimension: CGFloat = 24.0
  static let iconSpacing: CGFloat = 20.0

  // MARK: - Property

  /// The secondary description label, displayed beneath the text label and in a lighter color.
  let descriptionLabel = UILabel()
  /// The icon to display to the leading side of the labels.
  let iconView = UIImageView()
  /// The primary value text label.
  let textLabel = UILabel()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Calculates the height required to display this view, given the data provided.
  ///
  /// - Parameters:
  ///   - text: The primary text for this metadata.
  ///   - description: The secondary text for this metadata.
  ///   - width: The width this view will be constrained to.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func heightWithText(_ text: String,
                             description: String?,
                             inWidth width: CGFloat) -> CGFloat {
    // Constrained width based on icon.
    let constrainedWidth = width - NoteMetadataDetailCell.iconDimension -
        NoteMetadataDetailCell.iconSpacing
    // Add the top and bottom padding.
    var totalHeight =
        NoteMetadataDetailCell.edgeInsets.top + NoteMetadataDetailCell.edgeInsets.bottom
    // Measure the text label.
    totalHeight += text.labelHeight(withConstrainedWidth: constrainedWidth,
                                       font: MDCTypography.body1Font())
    if let description = description {
      // Measure the description
      totalHeight += description.labelHeight(withConstrainedWidth: constrainedWidth,
                                             font: MDCTypography.body1Font())
    }
    return totalHeight
  }

  // MARK: - Private

  private func configureView() {
    // The icon.
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.widthAnchor.constraint(
        equalToConstant: NoteMetadataDetailCell.iconDimension).isActive = true
    iconView.heightAnchor.constraint(
        equalToConstant: NoteMetadataDetailCell.iconDimension).isActive = true
    iconView.tintColor = MDCPalette.grey.tint600
    iconView.image = UIImage(named: "ic_info")  // Default icon.

    // The primary text label.
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.font = MDCTypography.body1Font()
    textLabel.numberOfLines = 0
    textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

    // The secondary description label.
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.font = MDCTypography.body1Font()
    descriptionLabel.textColor = MDCPalette.grey.tint500
    descriptionLabel.numberOfLines = 0
    descriptionLabel.setContentCompressionResistancePriority(.defaultHigh,
                                                             for: .vertical)

    // Labels vertical stack view.
    let labelsStack = UIStackView(arrangedSubviews: [textLabel, descriptionLabel])
    labelsStack.axis = .vertical
    labelsStack.alignment = .leading
    labelsStack.translatesAutoresizingMaskIntoConstraints = false
    labelsStack.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

    // Outer stack view.
    let outerStack = UIStackView(arrangedSubviews: [iconView, labelsStack])
    contentView.addSubview(outerStack)
    outerStack.spacing = NoteMetadataDetailCell.iconSpacing
    outerStack.alignment = .center
    outerStack.translatesAutoresizingMaskIntoConstraints = false
    outerStack.layoutMargins = NoteMetadataDetailCell.edgeInsets
    outerStack.isLayoutMarginsRelativeArrangement = true
    outerStack.pinToEdgesOfView(contentView)
  }

}
