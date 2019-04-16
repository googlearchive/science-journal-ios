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

import third_party_objective_c_material_components_ios_components_ShadowLayer_ShadowLayer
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view that shows an archived flag, which can appear in an archived experiment list cell or
/// trial card cell.
class ArchivedFlagView: ShadowedView {

  // MARK: - Properties

  /// The text color. Default is white.
  var textColor = UIColor.white {
    didSet {
      archivedLabel.textColor = textColor
    }
  }

  /// Whether or not the view has a shadow. Default is true.
  var isShadowed = true {
    didSet {
      updateViewForShadowedState()
    }
  }

  private let archivedLabel = UILabel()

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
    layer.cornerRadius = 2.0
    backgroundColor = UIColor(red: 0.286, green: 0.290, blue: 0.290, alpha: 1.0)

    isAccessibilityElement = true
    accessibilityTraits = .staticText
    accessibilityLabel = String.archivedBadge
    accessibilityHint = String.archivedContentDescription

    // Archived label.
    addSubview(archivedLabel)
    archivedLabel.translatesAutoresizingMaskIntoConstraints = false
    archivedLabel.text = String.archivedBadge.uppercased()
    archivedLabel.textColor = textColor
    archivedLabel.font = MDCTypography.body2Font()
    archivedLabel.pinToEdgesOfView(self, withInsets: ArchivedFlagCell.labelInsets)
    archivedLabel.isAccessibilityElement = false

    updateViewForShadowedState()
  }

  private func updateViewForShadowedState() {
    shadowLayer.elevation = isShadowed ? ShadowElevation.cardResting : ShadowElevation.none
  }

}
