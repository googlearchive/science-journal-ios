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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// The cell that shows each option for the existing data options screen.
class ExistingDataOptionsCell: UICollectionViewCell {

  // MARK: - Properties

  private enum Metrics {
    static let imageViewDimension: CGFloat = 42
    static let labelSideBuffer: CGFloat = 16
    static let labelVerticalBuffer: CGFloat = 8
    static let outerVerticalBuffer: CGFloat = 20

    static let titleLabelFont = MDCTypography.body2Font()
    static let descriptionLabelFont = MDCTypography.captionFont()
  }

  /// Whether or not to show a bottom separator.
  var shouldShowBottomSeparator = false {
    didSet {
      bottomSeparator.isHidden = !shouldShowBottomSeparator
    }
  }

  /// The image view.
  let imageView = UIImageView()

  /// The title label.
  let titleLabel = UILabel()

  /// The description label.
  let descriptionLabel = UILabel()

  private let topSeparator = SeparatorView(direction: .horizontal, style: .dark)
  private let bottomSeparator = SeparatorView(direction: .horizontal, style: .dark)

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    topSeparator.frame = CGRect(x: 0,
                                y: 0,
                                width: bounds.width,
                                height: SeparatorView.Metrics.dimension)
    bottomSeparator.frame = CGRect(x: 0,
                                   y: bounds.height - SeparatorView.Metrics.dimension,
                                   width: bounds.width,
                                   height: SeparatorView.Metrics.dimension)

    imageView.frame = CGRect(x: 0,
                             y: ceil((bounds.height - Metrics.imageViewDimension) / 2),
                             width: Metrics.imageViewDimension,
                             height: Metrics.imageViewDimension)

    let labelOriginX = imageView.frame.maxX + Metrics.labelSideBuffer
    let labelWidth = bounds.maxX - labelOriginX - Metrics.labelSideBuffer
    let titleLabelHeight = titleLabel.text?.labelHeight(withConstrainedWidth: labelWidth,
                                                        font: titleLabel.font) ?? 0
    let descriptionLabelHeight =
      descriptionLabel.text?.labelHeight(withConstrainedWidth: labelWidth,
                                         font: descriptionLabel.font) ?? 0

    let totalLabelHeight = titleLabelHeight + descriptionLabelHeight + Metrics.labelVerticalBuffer
    titleLabel.frame = CGRect(x: labelOriginX,
                              y: ceil((bounds.height - totalLabelHeight) / 2),
                              width: labelWidth,
                              height: titleLabelHeight)

    descriptionLabel.frame = CGRect(x: titleLabel.frame.minX,
                                    y: titleLabel.frame.maxY + Metrics.labelVerticalBuffer,
                                    width: labelWidth,
                                    height: descriptionLabelHeight)

    [topSeparator, bottomSeparator, imageView, titleLabel, descriptionLabel].forEach {
      $0.adjustFrameForLayoutDirection()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    shouldShowBottomSeparator = false
  }

  /// The height of the cell, in a width, with a given title and description.
  ///
  /// - Parameters:
  ///   - title: The title.
  ///   - description: The description.
  ///   - width: The constrained width.
  /// - Returns: The height for the cell.
  static func height(withTitle title: String,
                     description: String,
                     inWidth width: CGFloat) -> CGFloat {
    let labelWidth = width - Metrics.imageViewDimension - Metrics.labelSideBuffer * 2
    let titleLabelHeight = title.labelHeight(withConstrainedWidth: labelWidth,
                                             font: Metrics.titleLabelFont)
    let descriptionLabelHeight = description.labelHeight(withConstrainedWidth: labelWidth,
                                                         font: Metrics.descriptionLabelFont)
    return titleLabelHeight + descriptionLabelHeight + Metrics.outerVerticalBuffer * 2 +
        Metrics.labelVerticalBuffer
  }

  // MARK: - Private

  private func configureView() {
    addSubview(topSeparator)

    bottomSeparator.isHidden = true
    addSubview(bottomSeparator)

    addSubview(imageView)

    titleLabel.font = Metrics.titleLabelFont
    titleLabel.numberOfLines = 0
    addSubview(titleLabel)

    descriptionLabel.font = Metrics.descriptionLabelFont
    descriptionLabel.numberOfLines = 0
    addSubview(descriptionLabel)
  }

}
