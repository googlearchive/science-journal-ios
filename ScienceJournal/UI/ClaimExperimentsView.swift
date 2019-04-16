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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

protocol ClaimExperimentsViewDelegate: class {
  /// Tells the delegate the user pressed the claim experiments button.
  func claimExperimentsViewDidPressClaimExperiments()
}

/// A view used to show a button that allows a user to claim experiments that don't belong to an
/// account.
class ClaimExperimentsView: UIView {

  // MARK: - Properties

  weak var delegate: ClaimExperimentsViewDelegate?

  enum Metrics {
    /// The height of the claim experiments view.
    static let height: CGFloat = 180

    /// The maximum width to use for the claim experiments view.
    static let maxWidth: CGFloat = 400

    fileprivate static let backgroundColor = UIColor.white

    fileprivate static let shadowInsets = UIEdgeInsets(top: -2, left: -4, bottom: -6, right: -4)
    fileprivate static let cornerRadius: CGFloat = 2
    fileprivate static let imageViewDimension: CGFloat = 96
    fileprivate static let contentOuterSideBuffer: CGFloat = 16
    fileprivate static let imageViewTopBuffer: CGFloat = 16
    fileprivate static let titleLabelTopBuffer: CGFloat = 32
    fileprivate static let descriptionLabelTopBuffer: CGFloat = 16
    fileprivate static let claimButtonSideBuffer: CGFloat = 8
    fileprivate static let claimButtonTopBuffer: CGFloat = 16
  }

  private let imageView = UIImageView(image: UIImage(named: "claim_header"))
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
  private let claimButton = MDCFlatButton()
  private let shadow = UIImageView(image: UIImage(named: "shadow_layer_white"))

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

    // Shadow
    shadow.frame =
        CGRect(x: Metrics.shadowInsets.left,
               y: Metrics.shadowInsets.top,
               width: bounds.width - Metrics.shadowInsets.left - Metrics.shadowInsets.right,
               height: bounds.height - Metrics.shadowInsets.top - Metrics.shadowInsets.bottom)

    // Image view
    imageView.frame = CGRect(x: Metrics.contentOuterSideBuffer,
                             y: Metrics.imageViewTopBuffer,
                             width: Metrics.imageViewDimension,
                             height: Metrics.imageViewDimension)

    // Labels
    let labelWidth = bounds.maxX - imageView.frame.maxX - Metrics.contentOuterSideBuffer * 2

    // Title
    titleLabel.frame = CGRect(x: imageView.frame.maxX + Metrics.contentOuterSideBuffer,
                              y: Metrics.titleLabelTopBuffer,
                              width: labelWidth,
                              height: 0)
    titleLabel.sizeToFit()

    // Description
    descriptionLabel.frame = CGRect(x: titleLabel.frame.minX,
                                    y: titleLabel.frame.maxY + Metrics.descriptionLabelTopBuffer,
                                    width: labelWidth,
                                    height: 0)
    descriptionLabel.sizeToFit()

    // Claim button
    claimButton.sizeToFit()
    claimButton.frame = CGRect(x: Metrics.claimButtonSideBuffer,
                               y: imageView.frame.maxY + Metrics.claimButtonTopBuffer,
                               width: claimButton.frame.width,
                               height: claimButton.frame.height)

    [imageView, titleLabel, descriptionLabel, claimButton].forEach {
      $0.adjustFrameForLayoutDirection()
    }
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: Metrics.height)
  }

  /// Sets the number of unclaimed experiments to display.
  ///
  /// - Parameter number: The number of unclaimed experiments.
  func setNumberOfUnclaimedExperiments(_ number: Int) {
    if number == 1 {
      descriptionLabel.text = String.claimExperimentsDescriptionWithCountOne
    } else {
      descriptionLabel.text = String(format: String.claimExperimentsDescriptionWithCount, number)
    }
    setNeedsLayout()
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = Metrics.backgroundColor
    layer.cornerRadius = Metrics.cornerRadius

    // Shadow
    addSubview(shadow)

    // Image view
    addSubview(imageView)

    // Title label
    titleLabel.font = MDCTypography.body2Font()
    titleLabel.numberOfLines = 2
    titleLabel.text = String.claimExperimentsTitle
    addSubview(titleLabel)

    // Description label
    descriptionLabel.font = MDCTypography.captionFont()
    descriptionLabel.numberOfLines = 3
    addSubview(descriptionLabel)

    // Claim button
    claimButton.addTarget(self,
                          action: #selector(claimButtonPressed),
                          for: .touchUpInside)
    claimButton.setTitle(String.claimExperimentsButtonTitle, for: .normal)
    claimButton.setTitleColor(MDCPalette.blue.tint500, for: .normal)
    addSubview(claimButton)
  }

  // MARK: - User actions

  @objc func claimButtonPressed() {
    delegate?.claimExperimentsViewDidPressClaimExperiments()
  }

}

/// The claim experiments view wrapped in a UICollectionReusableView, so it can be displayed as a
/// collection view header without being full width.
class ClaimExperimentsHeaderView: UICollectionReusableView {

  // MARK: - Properties

  /// The claim experiments view.
  let claimExperimentsView = ClaimExperimentsView()

  enum Metrics {
    /// The height of the claim experiments header view.
    static let height = ClaimExperimentsView.Metrics.height + topBuffer

    fileprivate static let sideBuffer: CGFloat = 16
    fileprivate static let topBuffer: CGFloat = 16
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

  override func layoutSubviews() {
    super.layoutSubviews()

    let width = min(bounds.width - Metrics.sideBuffer * 2, ClaimExperimentsView.Metrics.maxWidth)
    claimExperimentsView.frame = CGRect(x: ceil((bounds.width - width) / 2),
                                        y: Metrics.topBuffer,
                                        width: width,
                                        height: ClaimExperimentsView.Metrics.height)
  }

  // MARK: - Private

  private func configureView() {
    addSubview(claimExperimentsView)
  }

}
