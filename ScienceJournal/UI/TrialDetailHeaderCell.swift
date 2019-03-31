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

/// The cell describing a trial, used above the pinned sensor info in TrialDetailViewController.
/// This cell contains a title, timestamp and duration.
class TrialDetailHeaderCell: UICollectionViewCell {

  // MARK: - Constants

  static let valueFontSize: CGFloat = 22.0
  static let descriptionFontSize: CGFloat = 14.0
  static let edgeInsets = UIEdgeInsets(top: 8.0, left: 16.0, bottom: 10.0, right: 16.0)
  let innerHorizontalSpacing: CGFloat = 10.0

  // MARK: - Properties

  let durationLabel = UILabel()
  let timestampLabel = UILabel()
  let titleLabel = UILabel()

  /// The total height of this view. Ideally, controllers would cache this value as it will not
  /// change for different instances of this view type.
  static var height: CGFloat {
    var totalHeight = TrialDetailHeaderCell.edgeInsets.top +
        TrialDetailHeaderCell.edgeInsets.bottom
    let valueFont =
        MDCTypography.fontLoader().mediumFont(ofSize: TrialDetailHeaderCell.valueFontSize) ??
        UIFont.boldSystemFont(ofSize: TrialDetailHeaderCell.valueFontSize)
    totalHeight +=
        String.runReviewActivityLabel.labelHeight(withConstrainedWidth: 0, font: valueFont) * 2
    totalHeight += SeparatorView.Metrics.dimension
    return ceil(totalHeight)
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
    backgroundColor = .white

    // The title of this trial.
    titleLabel.font =
        MDCTypography.fontLoader().mediumFont(ofSize: TrialDetailHeaderCell.valueFontSize) ??
        UIFont.boldSystemFont(ofSize: TrialDetailHeaderCell.valueFontSize)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    // The duration header.
    let durationHeaderLabel = UILabel()
    durationHeaderLabel.text = String.runReviewDuration
    durationHeaderLabel.font =
        MDCTypography.fontLoader().regularFont(ofSize: TrialDetailHeaderCell.descriptionFontSize)
    durationHeaderLabel.textAlignment = .right
    durationHeaderLabel.textColor = MDCPalette.grey.tint700
    durationHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
    durationHeaderLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    durationHeaderLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    // The stack view that holds the title on the left and duration header label on the right.
    let topStack = UIStackView(arrangedSubviews: [titleLabel, durationHeaderLabel])
    topStack.alignment = .center
    topStack.spacing = innerHorizontalSpacing
    topStack.translatesAutoresizingMaskIntoConstraints = false

    // The timestamp for this trial.
    timestampLabel.font =
        MDCTypography.fontLoader().regularFont(ofSize: TrialDetailHeaderCell.descriptionFontSize)
    timestampLabel.textColor = MDCPalette.grey.tint700
    timestampLabel.translatesAutoresizingMaskIntoConstraints = false
    timestampLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    // The duration of this trial.
    durationLabel.font =
        MDCTypography.fontLoader().mediumFont(ofSize: TrialDetailHeaderCell.valueFontSize)
    durationLabel.textAlignment = .right
    durationLabel.textColor = UIColor.appBarReviewBackgroundColor
    durationLabel.translatesAutoresizingMaskIntoConstraints = false

    // The stack view that holds the timestamp on the left and the duration on the right.
    let bottomStack = UIStackView(arrangedSubviews: [timestampLabel, durationLabel])
    bottomStack.alignment = .lastBaseline
    bottomStack.spacing = innerHorizontalSpacing
    bottomStack.translatesAutoresizingMaskIntoConstraints = false

    // The outer stack view that vertically stacks the two rows and pins to the edges of the cell.
    let stackView = UIStackView(arrangedSubviews: [topStack, bottomStack])
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.layoutMargins = TrialDetailHeaderCell.edgeInsets
    stackView.isLayoutMarginsRelativeArrangement = true

    let separator = SeparatorView(direction: .horizontal, style: .dark)
    separator.translatesAutoresizingMaskIntoConstraints = false

    let outerStackView = UIStackView(arrangedSubviews: [stackView, separator])
    contentView.addSubview(outerStackView)
    outerStackView.axis = .vertical
    outerStackView.translatesAutoresizingMaskIntoConstraints = false
    outerStackView.pinToEdgesOfView(contentView)
  }

}
