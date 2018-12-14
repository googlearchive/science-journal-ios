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

/// The base class which configures the title and description for a settings cell. This should be
/// subclassed to create unique settings cell types.
class SettingsCell: UICollectionViewCell {

  enum Metrics {
    static let cellInsets = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
    static let innerHorizontalSpacing: CGFloat = 10.0
    static let innerVerticalSpacing: CGFloat = 4.0
    static let textLabelFont = MDCTypography.subheadFont()
    static let descriptionLabelFont = MDCTypography.body1Font()
  }

  // MARK: - Properties

  /// The primary title label. Ideally one line, but not limited.
  let titleLabel = UILabel()
  /// The description text label. Optional, can be many lines.
  let descriptionLabel = UILabel()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  func configureView() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(descriptionLabel)

    // The title label.
    titleLabel.numberOfLines = 0
    titleLabel.font = Metrics.textLabelFont
    titleLabel.alpha = MDCTypography.subheadFontOpacity()

    // The description label.
    descriptionLabel.numberOfLines = 0
    descriptionLabel.font = Metrics.descriptionLabelFont
    descriptionLabel.alpha = MDCTypography.body1FontOpacity()
  }

}
