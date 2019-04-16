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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A UILabel subclass for the relative timestamp in an ExperimentCardView, which can have an
/// optional shadow enabled.
class ExperimentTimestampLabel: UILabel {
  init() {
    super.init(frame: .zero)
    self.layer.shadowColor = UIColor(white: 0, alpha: 0.5).cgColor
    self.layer.shadowRadius = 2.0
    self.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
    self.layer.shouldRasterize = true
    self.layer.rasterizationScale = UIScreen.main.scale
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  var isShadowEnabled: Bool = false {
    didSet {
      self.layer.shadowOpacity = isShadowEnabled ? 1 : 0
    }
  }
}

/// The base card view class for Experiment-related data card views. Establishes shared metrics for
/// padding and spacing, creates a shared timestamp UILabel and configures it. Various Experiment
/// detail view cards should subclass this (see SnapshotCardView for example).
class ExperimentCardView: UIView {

  // MARK: - Constants

  /// The vertical padding for the header and footer.
  static let headerFooterVerticalPadding: CGFloat = 10.0
  /// The vertical padding of a card view, added to the top and bottom edges.
  static let innerVerticalPadding: CGFloat = 12.0
  /// The spacing between labels, vertically, in stackViews.
  static let innerLabelsSpacing: CGFloat = 2.0
  /// The horizontal padding of a card view, added to the leading and trailing edges.
  static let innerHorizontalPadding: CGFloat = 16.0
  /// The font size for the timestamp label, used in view height calculation.
  static let timestampFontSize: CGFloat = 12.0
  /// A combined value of the total horizontal padding, used in view width calculation.
  static let horizontalPaddingTotal: CGFloat = (ExperimentCardView.innerHorizontalPadding * 2)

  // MARK: - Shared properties

  /// The relative timestamp label.
  let timestampLabel = ExperimentTimestampLabel()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureSharedViews()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureSharedViews()
  }

  /// Resets the data in the view. Subclasses should implement.
  func reset() {
    // Base implementation does nothing.
  }

  // MARK: - Private

  private func configureSharedViews() {
    // Timestamp label.
    timestampLabel.textAlignment = .right
    timestampLabel.textColor = MDCPalette.grey.tint500
    timestampLabel.font = MDCTypography.fontLoader().regularFont(
        ofSize: ExperimentCardView.timestampFontSize)
    timestampLabel.translatesAutoresizingMaskIntoConstraints = false
    // Timestamp label should stay as narrow as necessary.
    timestampLabel.setContentHuggingPriority(.required, for: .horizontal)
    // Turn off the shadow by default.
    timestampLabel.isShadowEnabled = false
  }

}
