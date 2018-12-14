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

/// The view containing a caption for an Experiment item, which is attached to the bottom of an
/// ExperimentCell. Can appear on TrialCardCell, PhotoCardCell and SnapshotCardCell. NoteCardCells
/// cannot have captions.
class ExperimentCardCaptionView: ExperimentCardView {

  // MARK: - Constants

  /// The font size for the caption.
  static let captionFontSize: CGFloat = 16.0
  static let captionVerticalPadding: CGFloat = 12.0

  // MARK: - Properties

  /// The timestamp label.
  let captionLabel = UILabel()

  // MARK: - Public

  override required init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let captionText = captionLabel.text else { return .zero }
    return CGSize(width: size.width,
                  height: ExperimentCardCaptionView.heightWithCaption(captionText,
                                                                      inWidth: size.width))
  }

  /// Calculates the height required to display this view, given the `caption`.
  ///
  /// - Parameters:
  ///   - caption: The string caption.
  ///   - width: Maximum width for this view, used to constrain measurements.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func heightWithCaption(_ caption: String, inWidth width: CGFloat) -> CGFloat {
    // Constrained width, including padding.
    let constrainedWidth = width - ExperimentCardView.horizontalPaddingTotal
    // The height of the label plus the padding on top and bottom.
    // Top separator.
    var totalHeight = SeparatorView.Metrics.dimension
    // The height of the label.
    totalHeight += caption.labelHeight(withConstrainedWidth: constrainedWidth,
                                       font: MDCTypography.fontLoader().regularFont(
                                           ofSize: ExperimentCardCaptionView.captionFontSize))
    // Top and bottom vertical padding.
    return totalHeight + (ExperimentCardCaptionView.captionVerticalPadding * 2)
  }

  override func reset() {
    captionLabel.text = nil
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = MDCPalette.grey.tint100

    // Create a wrapper view for the label so we can give it padding but not affect the padding
    // of the separator view which needs to fill the full width of the wrapping stack view.
    let labelWrapper = UIView()
    labelWrapper.translatesAutoresizingMaskIntoConstraints = false
    labelWrapper.addSubview(captionLabel)

    captionLabel.font = MDCTypography.fontLoader().regularFont(
        ofSize: ExperimentCardCaptionView.captionFontSize)
    captionLabel.textColor = MDCPalette.grey.tint600
    captionLabel.numberOfLines = 0
    captionLabel.translatesAutoresizingMaskIntoConstraints = false
    let insets = UIEdgeInsets(top: 0,
                              left: ExperimentCardView.innerHorizontalPadding,
                              bottom: ExperimentCardCaptionView.captionVerticalPadding,
                              right: ExperimentCardView.innerHorizontalPadding)
    captionLabel.pinToEdgesOfView(labelWrapper, withInsets: insets)

    let wrapperStack =
        UIStackView(arrangedSubviews: [SeparatorView(direction: .horizontal, style: .light),
                                       labelWrapper])
    addSubview(wrapperStack)
    wrapperStack.axis = .vertical
    wrapperStack.spacing = ExperimentCardCaptionView.captionVerticalPadding
    wrapperStack.translatesAutoresizingMaskIntoConstraints = false
    wrapperStack.pinToEdgesOfView(self)
  }

}
