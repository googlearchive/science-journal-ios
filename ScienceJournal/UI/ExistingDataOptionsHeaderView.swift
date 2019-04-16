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

/// The header view for the existing data options screen, explaining that the user can now sync
/// experiments.
class ExistingDataOptionsHeaderView: UICollectionReusableView {

  // MARK: - Properties

  private enum Metrics {
    static let sideBuffer: CGFloat = 20
    static let topBuffer: CGFloat = 50
    static let bottomBuffer: CGFloat = 50
    static let labelVerticalBuffer: CGFloat = 20

    static let titleFont = MDCTypography.body2Font()
    static let countFont = MDCTypography.body1Font()
  }

  private let titleLabel = UILabel()
  private let countLabel = UILabel()

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

    let labelWidth = bounds.width - Metrics.sideBuffer * 2

    titleLabel.frame = CGRect(x: Metrics.sideBuffer,
                              y: Metrics.topBuffer,
                              width: labelWidth,
                              height: 0)
    titleLabel.sizeToFit()

    countLabel.frame = CGRect(x: titleLabel.frame.minX,
                              y: titleLabel.frame.maxY + Metrics.labelVerticalBuffer,
                              width: labelWidth,
                              height: 0)
    countLabel.sizeToFit()

    [titleLabel, countLabel].forEach { $0.adjustFrameForLayoutDirection() }
  }

  /// Returns the height of this view in a given width.
  ///
  /// - Parameter width: The width the view will be displayed in.
  /// - Returns: The height of the view.
  static func height(inWidth width: CGFloat, numberOfExperiments: Int) -> CGFloat {
    let labelWidth = width - Metrics.sideBuffer * 2
    let titleLabelHeight =
        String.existingDataOptionsTitle.labelHeight(withConstrainedWidth: labelWidth,
                                                    font: Metrics.titleFont)
    let countString = numberOfExperiments > 1 ?
        String(format: String.existingDataOptionsExperimentCountTextMultiple, numberOfExperiments) :
        String.existingDataOptionsExperimentCountTextSingle
    let countLabelHeight = countString.labelHeight(withConstrainedWidth: labelWidth,
                                                   font: Metrics.countFont)
    return titleLabelHeight + countLabelHeight + Metrics.labelVerticalBuffer * 2 +
        Metrics.topBuffer + Metrics.bottomBuffer
  }

  /// Sets the number of experiments to display.
  ///
  /// - Parameter number: The number of experiments.
  func setNumberOfExperiments(_ number: Int) {
    if number == 1 {
      countLabel.text = String.existingDataOptionsExperimentCountTextSingle
    } else {
      countLabel.text = String(format: String.existingDataOptionsExperimentCountTextMultiple,
                               number)
    }
    setNeedsLayout()
  }

  // MARK: - Private

  private func configureView() {
    titleLabel.font = Metrics.titleFont
    titleLabel.numberOfLines = 0
    titleLabel.text = String.existingDataOptionsTitle
    addSubview(titleLabel)

    countLabel.font = Metrics.countFont
    countLabel.numberOfLines = 0
    addSubview(countLabel)
  }

}
