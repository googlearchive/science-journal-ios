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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A header view for the Experiments list. The view contains a single label, whose text will
/// contain the month name for a group of experiments (example: "May").
class ExperimentsListHeaderView: UICollectionReusableView {

  // MARK: - Constants

  static let headerFontSize: CGFloat = 16.0
  static let headerInsets = UIEdgeInsets(top: 16, left: 0, bottom: 12, right: 16)

  // MARK: - Properties

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

  /// Calculates the height required to display this view, given the string `text`.
  ///
  /// - Parameters:
  ///   - text: The text of this header view.
  ///   - width: Maximum width for this view, used to constrain measurements.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func viewHeightWithString(_ text: String, inWidth width: CGFloat) -> CGFloat {
    let constrainedWidth = width - ExperimentsListHeaderView.headerInsets.left -
        ExperimentsListHeaderView.headerInsets.right
    let headerFont =
        MDCTypography.fontLoader().boldFont!(ofSize: ExperimentsListHeaderView.headerFontSize)
    return text.labelHeight(withConstrainedWidth: constrainedWidth, font: headerFont) +
        ExperimentsListHeaderView.headerInsets.top + ExperimentsListHeaderView.headerInsets.bottom
  }

  // MARK: - Private

  private func configureView() {
    addSubview(textLabel)
    textLabel.font =
        MDCTypography.fontLoader().boldFont?(ofSize: ExperimentsListHeaderView.headerFontSize)
    textLabel.textColor = MDCPalette.grey.tint600
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.pinToEdgesOfView(self, withInsets: ExperimentsListHeaderView.headerInsets)
  }

}
