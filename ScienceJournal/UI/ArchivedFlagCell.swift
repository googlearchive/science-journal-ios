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

/// A cell that shows an archived flag, which can appear at the top of an archived experiment or
/// trial, above that experiment or trial's data.
class ArchivedFlagCell: UICollectionViewCell {

  // MARK: - Properties

  /// The insets for the label, inside the wrapping flag view.
  static let labelInsets = UIEdgeInsets(top: 4.0, left: 6.0, bottom: 4.0, right: 6.0)

  /// The calculated height of this view, not including layout margins.
  static var height: CGFloat = {
    var totalHeight = String.archivedBadge.labelHeight(withConstrainedWidth: 0,
                                                       font: MDCTypography.body2Font())
    totalHeight += ArchivedFlagCell.labelInsets.top + ArchivedFlagCell.labelInsets.bottom
    totalHeight +=
        MDCShadowMetrics(elevation: ShadowElevation.cardResting.rawValue).bottomShadowOffset.height
    return totalHeight
  }()

  private var archivedFlagLeadingConstraint: NSLayoutConstraint?
  private var archivedFlagTopConstraint: NSLayoutConstraint?

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func layoutMarginsDidChange() {
    // Only top and left layout margins are used.
    archivedFlagLeadingConstraint?.constant = layoutMargins.left
    archivedFlagTopConstraint?.constant = layoutMargins.top
  }

  // MARK: - Private

  private func configureView() {
    let archivedFlag = ShadowedView()
    contentView.addSubview(archivedFlag)
    archivedFlag.translatesAutoresizingMaskIntoConstraints = false
    archivedFlag.shadowLayer.elevation = ShadowElevation.cardResting
    archivedFlag.backgroundColor = UIColor(red: 0.286, green: 0.290, blue: 0.290, alpha: 1.0)
    archivedFlagTopConstraint = archivedFlag.topAnchor.constraint(equalTo: contentView.topAnchor)
    archivedFlagTopConstraint?.isActive = true
    archivedFlagLeadingConstraint =
        archivedFlag.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
    archivedFlagLeadingConstraint?.isActive = true
    archivedFlag.layer.cornerRadius = 2.0

    // Archived label.
    let archivedLabel = UILabel()
    archivedFlag.addSubview(archivedLabel)
    archivedLabel.translatesAutoresizingMaskIntoConstraints = false
    archivedLabel.text = String.archivedBadge.uppercased()
    archivedLabel.textColor = .white
    archivedLabel.font = MDCTypography.body2Font()
    archivedLabel.pinToEdgesOfView(archivedFlag, withInsets: ArchivedFlagCell.labelInsets)
  }

}
