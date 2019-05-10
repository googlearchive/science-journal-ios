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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// The header view for a trial, which contains the trial's title and a background color.
class TrialCardHeaderView: UIView {

  // MARK: - Properties

  let titleLabel = UILabel()

  static var height: CGFloat {
    // Padding at the top and bottom of the view.
    var totalHeight = ExperimentCardView.innerVerticalPadding * 2
    // Measure the title label's height and use it or the icon's height, whichever is bigger.
    totalHeight += ceil(String.runReviewActivityLabel.labelHeight(withConstrainedWidth: 0,
                                                                  font: MDCTypography.body2Font()))
    return totalHeight
  }

  /// Whether or not the view is dimmed and the archive state is visible. When showing, the view's
  /// alpha is set to 0.3, but the archived flag remains at full alpha.
  var isShowingArchiveFlag = false {
    didSet {
      updateViewForArchiveFlagState()
    }
  }

  private let archivedFlag = ArchivedFlagView()
  private let dimmedAlpha: CGFloat = 0.3

  // MARK: - Public

  init() {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  // MARK: - Private

  private func configureView() {
    autoresizingMask = [.flexibleWidth, .flexibleHeight]

    isAccessibilityElement = true
    accessibilityTraits = .staticText

    // Title label.
    addSubview(titleLabel)
    titleLabel.font = MDCTypography.body2Font()
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    let insets = UIEdgeInsets(top: ExperimentCardView.innerVerticalPadding,
                              left: ExperimentCardView.innerHorizontalPadding,
                              bottom: ExperimentCardView.innerVerticalPadding,
                              right: ExperimentCardView.innerHorizontalPadding)
    titleLabel.pinToEdgesOfView(self, withInsets: insets)

    // Archived flag view.
    addSubview(archivedFlag)
    archivedFlag.isShadowed = false
    archivedFlag.translatesAutoresizingMaskIntoConstraints = false
    archivedFlag.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    archivedFlag.trailingAnchor.constraint(equalTo: trailingAnchor,
                                           constant: -insets.right).isActive = true

    updateViewForArchiveFlagState()
  }

  private func updateViewForArchiveFlagState() {
    backgroundColor = isShowingArchiveFlag ?
        .trialHeaderArchivedBackgroundColor : .trialHeaderDefaultBackgroundColor
    titleLabel.alpha = isShowingArchiveFlag ? dimmedAlpha : 1
    archivedFlag.isHidden = !isShowingArchiveFlag
  }

}
