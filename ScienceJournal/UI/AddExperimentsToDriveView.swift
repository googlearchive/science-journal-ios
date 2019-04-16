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

/// A view shown above the claim experiments view, explaining that a user can add unclaimed
/// experiments to Drive.
class AddExperimentsToDriveView: UIView {

  // MARK: - Properties

  enum Metrics {
    /// The maximum width to use for the add experiments to Drive view.
    static let maxWidth: CGFloat = 400

    fileprivate static let backgroundColor = UIColor.white

    fileprivate static let shadowInsets = UIEdgeInsets(top: -2, left: -4, bottom: -6, right: -4)
    fileprivate static let cornerRadius: CGFloat = 2
    fileprivate static let imageViewDimension: CGFloat = 32
    fileprivate static let outerPadding: CGFloat = 16
    fileprivate static let innerSpacing: CGFloat = 16
    fileprivate static let titleLabelOriginX = outerPadding * 2 + imageViewDimension

    fileprivate static let titleLabelText = String.claimExperimentsAddToDriveTitle
    fileprivate static let descriptionLabelText = String.claimExperimentsAddToDriveSubtitle

    fileprivate static let titleLabelFont = MDCTypography.body2Font()
    fileprivate static let descriptionLabelFont = MDCTypography.captionFont()
  }

  private let imageView = UIImageView(image: UIImage(named: "ic_claim_drive"))
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
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
    imageView.frame = CGRect(x: Metrics.outerPadding,
                             y: Metrics.outerPadding,
                             width: Metrics.imageViewDimension,
                             height: Metrics.imageViewDimension)

    // Title label
    let titleLabelHeight = AddExperimentsToDriveView.titleHeight(inWidth: bounds.width)
    titleLabel.frame =
        CGRect(x: Metrics.titleLabelOriginX,
               y: floor(imageView.frame.midY - (titleLabelHeight / 2)),
               width: AddExperimentsToDriveView.titleLabelWidth(inBoundingWidth: bounds.width),
               height: titleLabelHeight)

    // Description label
    descriptionLabel.frame = CGRect(
        x: Metrics.outerPadding,
        y: imageView.frame.maxY + Metrics.innerSpacing,
        width: AddExperimentsToDriveView.descriptionLabelWidth(inBoundingWidth: bounds.width),
        height: 0)
    descriptionLabel.sizeToFit()

    [imageView, titleLabel, descriptionLabel].forEach {
      $0.adjustFrameForLayoutDirection()
    }
  }

  static func titleHeight(inWidth width: CGFloat) -> CGFloat {
    let titleLabelConstrainedWidth = width - Metrics.titleLabelOriginX -
        Metrics.innerSpacing
    return Metrics.titleLabelText.labelHeight(withConstrainedWidth: titleLabelConstrainedWidth,
                                              font: Metrics.titleLabelFont)
  }

  static func height(inWidth width: CGFloat) -> CGFloat {
    let constrainedWidth = width - Metrics.outerPadding * 2
    let descriptionLabelHeight =
        Metrics.descriptionLabelText.labelHeight(withConstrainedWidth: constrainedWidth,
                                                 font: Metrics.descriptionLabelFont)
    let titleOrImageHeight = max(AddExperimentsToDriveView.titleHeight(inWidth: width),
                                 Metrics.imageViewDimension)
    return Metrics.outerPadding + titleOrImageHeight + Metrics.innerSpacing +
        descriptionLabelHeight + Metrics.outerPadding
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
    titleLabel.font = Metrics.titleLabelFont
    titleLabel.numberOfLines = 0
    titleLabel.text = Metrics.titleLabelText
    addSubview(titleLabel)

    // Description label
    descriptionLabel.font = Metrics.descriptionLabelFont
    descriptionLabel.numberOfLines = 0
    descriptionLabel.text = Metrics.descriptionLabelText
    addSubview(descriptionLabel)
  }

  private static func titleLabelWidth(inBoundingWidth boundingWidth: CGFloat) -> CGFloat {
    return boundingWidth - Metrics.titleLabelOriginX - Metrics.outerPadding
  }

  private static func descriptionLabelWidth(inBoundingWidth boundingWidth: CGFloat) -> CGFloat {
    return boundingWidth - Metrics.outerPadding * 2
  }

}

/// The add experiments to Drive view wrapped in a UICollectionReusableView, so it can be
/// displayed as a collection view header without being full width.
class AddExperimentsToDriveHeaderView: UICollectionReusableView {

  // MARK: - Properties

  private enum Metrics {
    static let outerPadding: CGFloat = 16
  }

  private let addExperimentsToDriveView = AddExperimentsToDriveView()

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

    let viewSize = AddExperimentsToDriveHeaderView.viewSize(inWidth: bounds.width)
    addExperimentsToDriveView.frame = CGRect(x: ceil((bounds.width - viewSize.width) / 2),
                                             y: Metrics.outerPadding,
                                             width: viewSize.width,
                                             height: viewSize.height)
  }

  static func viewSize(inWidth width: CGFloat) -> CGSize {
    let width = min(width - Metrics.outerPadding * 2,
                    AddExperimentsToDriveView.Metrics.maxWidth)
    let height = AddExperimentsToDriveView.height(inWidth: width)
    return CGSize(width: width, height: height)
  }

  // MARK: - Private

  private func configureView() {
    addSubview(addExperimentsToDriveView)
  }

}
