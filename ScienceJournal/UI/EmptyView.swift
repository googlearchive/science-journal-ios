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

protocol EmptyViewDelegate: class {
  /// Tells the delegate the user pressed the claim experiments button.
  func emptyViewDidPressClaimExperiments()
}

/// A view with a title and icon describing the empty state of a view.
class EmptyView: UIScrollView {

  struct Metrics {
    static let imageViewDimensionMultiplierRegular: CGFloat = 1
    static let imageViewDimensionMultiplierCompact: CGFloat = 0.6
    static let innerSpacing: CGFloat = 30.0
    static let titleFontSize: CGFloat = 16.0
    static let verticalOffsetRegular: CGFloat = -58.0
    static let verticalOffsetCompact: CGFloat = -22.0
    static let claimExperimentsViewTopConstraintConstant: CGFloat = 16
    static let claimExperimentsViewWidthConstraintConstant: CGFloat = -32
    static let imageViewDimensionSmall: CGFloat = 200
    static let stackViewTopConstraintConstantRegular: CGFloat = 80
    static let stackViewTopConstraintConstantCompact: CGFloat  = 48
  }

  // MARK: - Properties

  /// The empty view delegate.
  weak var emptyViewDelegate: EmptyViewDelegate?

  /// An archived flag, used to show that the entity which is empty, is archived. Hidden by default.
  let archivedFlag = ArchivedFlagView()

  /// The insets for the archived flag. Only top and left are used. The default is zero insets,
  /// anchored to the top and leading anchors.
  var archivedFlagInsets = UIEdgeInsets.zero {
    didSet {
      archivedFlagTopConstraint?.constant = archivedFlagInsets.top
      archivedFlagLeadingConstraint?.constant = archivedFlagInsets.left
    }
  }

  /// The claim experiments view.
  lazy var claimExperimentsView: ClaimExperimentsView = {
    let claimExperimentsView = ClaimExperimentsView()
    claimExperimentsView.delegate = self
    claimExperimentsView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(claimExperimentsView)
    claimExperimentsView.topAnchor.constraint(
        equalTo: topAnchor,
        constant: Metrics.claimExperimentsViewTopConstraintConstant).isActive = true
    claimExperimentsView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    let claimExperimentsViewWidthConstraint = claimExperimentsView.widthAnchor.constraint(
        equalTo: widthAnchor, constant: Metrics.claimExperimentsViewWidthConstraintConstant)
    claimExperimentsViewWidthConstraint.priority = .defaultLow
    claimExperimentsViewWidthConstraint.isActive = true
    claimExperimentsView.widthAnchor.constraint(
        lessThanOrEqualToConstant: ClaimExperimentsView.Metrics.maxWidth).isActive = true

    stackViewTopConstraint =
        stackView.topAnchor.constraint(equalTo: claimExperimentsView.bottomAnchor)
    updateForVerticalSizeClass()

    return claimExperimentsView
  }()

  /// Whether or not the claim experiments view should be hidden.
  var isClaimExperimentsViewHidden = true {
    didSet {
      claimExperimentsView.isHidden = isClaimExperimentsViewHidden
      imageView.isHidden = !isClaimExperimentsViewHidden &&
          traitCollection.verticalSizeClass == .compact

      if isClaimExperimentsViewHidden {
        imageViewHeightConstraintForClaimExperimentsViewShowing?.isActive = false
        imageViewWidthConstraintForClaimExperimentsViewShowing?.isActive = false
        stackViewTopConstraint?.isActive = false
        stackViewCenterYConstraint?.isActive = true
        imageViewHeightConstraint?.isActive = true
        imageViewWidthConstraint?.isActive = true
      } else {
        imageViewHeightConstraint?.isActive = false
        imageViewWidthConstraint?.isActive = false
        stackViewCenterYConstraint?.isActive = false
        stackViewTopConstraint?.isActive = true
        imageViewHeightConstraintForClaimExperimentsViewShowing?.isActive = true
        imageViewWidthConstraintForClaimExperimentsViewShowing?.isActive = true
      }
    }
  }

  private var archivedFlagTopConstraint: NSLayoutConstraint?
  private var archivedFlagLeadingConstraint: NSLayoutConstraint?
  private let imageView = UIImageView()
  private let stackView = UIStackView()
  private var stackViewCenterYConstraint: NSLayoutConstraint?
  private var stackViewTopConstraint: NSLayoutConstraint?
  private var imageViewHeightConstraintForClaimExperimentsViewShowing: NSLayoutConstraint?
  private var imageViewWidthConstraintForClaimExperimentsViewShowing: NSLayoutConstraint?
  private let titleLabel = UILabel()

  // The image view height constraint. Its constant is set to be equal to the image height.
  private lazy var imageViewHeightConstraint: NSLayoutConstraint? = {
    guard let imageSize = self.imageView.image?.size else { return nil }
    let constraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
    constraint.isActive = true
    return constraint
  }()

  // The image view width constraint. Its constant is set to be equal to the image width.
  private lazy var imageViewWidthConstraint: NSLayoutConstraint? = {
    guard let imageSize = self.imageView.image?.size else { return nil }
    let constraint = imageView.widthAnchor.constraint(equalToConstant: imageSize.width)
    constraint.isActive = true
    return constraint
  }()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - title: The title.
  ///   - imageName: The name of the image.
  init(title: String, imageName: String) {
    super.init(frame: .zero)
    configureView(title: title, imageName: imageName)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateForVerticalSizeClass()
  }

  // MARK: - Private

  private func configureView(title: String, imageName: String) {
    backgroundColor = MDCPalette.grey.tint200

    // Stack view to hold everything else.
    addSubview(stackView)
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = Metrics.innerSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    stackViewCenterYConstraint =
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor,
                                           constant: Metrics.verticalOffsetRegular)
    stackViewCenterYConstraint?.isActive = true

    // The title label.
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = MDCTypography.fontLoader().boldFont?(ofSize: Metrics.titleFontSize)
    titleLabel.text = title
    titleLabel.textColor = MDCPalette.grey.tint500
    titleLabel.numberOfLines = 2
    stackView.addArrangedSubview(titleLabel)

    // The empty icon.
    imageView.image = UIImage(named: imageName)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(imageView)
    imageViewHeightConstraintForClaimExperimentsViewShowing =
        imageView.heightAnchor.constraint(equalToConstant: Metrics.imageViewDimensionSmall)
    imageViewWidthConstraintForClaimExperimentsViewShowing =
        imageView.widthAnchor.constraint(equalToConstant: Metrics.imageViewDimensionSmall)

    // The archived flag.
    addSubview(archivedFlag)
    archivedFlag.isHidden = true
    archivedFlag.translatesAutoresizingMaskIntoConstraints = false
    archivedFlagTopConstraint = archivedFlag.topAnchor.constraint(equalTo: topAnchor)
    archivedFlagTopConstraint?.isActive = true
    archivedFlagLeadingConstraint = archivedFlag.leadingAnchor.constraint(equalTo: leadingAnchor)
    archivedFlagLeadingConstraint?.isActive = true
  }

  private func updateForVerticalSizeClass() {
    let verticallyCompact = traitCollection.verticalSizeClass == .compact

    var imageViewDimensionMultiplier: CGFloat {
      return verticallyCompact ?
          Metrics.imageViewDimensionMultiplierCompact : Metrics.imageViewDimensionMultiplierRegular
    }

    var stackViewCenterYConstraintConstant: CGFloat {
      return verticallyCompact ? Metrics.verticalOffsetCompact : Metrics.verticalOffsetRegular
    }

    guard let imageSize = imageView.image?.size else { return }
    imageViewHeightConstraint?.constant = imageSize.height * imageViewDimensionMultiplier
    imageViewWidthConstraint?.constant = imageSize.width * imageViewDimensionMultiplier
    stackViewCenterYConstraint?.constant = stackViewCenterYConstraintConstant

    let regularVerticalAndHorizontal = traitCollection.verticalSizeClass == .regular &&
        traitCollection.horizontalSizeClass == .regular
    stackViewTopConstraint?.constant = regularVerticalAndHorizontal ?
        Metrics.stackViewTopConstraintConstantRegular: Metrics.stackViewTopConstraintConstantCompact
    imageViewHeightConstraintForClaimExperimentsViewShowing?.constant =
        regularVerticalAndHorizontal ? imageSize.height : Metrics.imageViewDimensionSmall
    imageViewWidthConstraintForClaimExperimentsViewShowing?.constant =
        regularVerticalAndHorizontal ? imageSize.width : Metrics.imageViewDimensionSmall

    imageView.isHidden = !isClaimExperimentsViewHidden && verticallyCompact
  }

}

extension EmptyView: ClaimExperimentsViewDelegate {
  // MARK: - ClaimExperimentsViewDelegate

  func claimExperimentsViewDidPressClaimExperiments() {
    emptyViewDelegate?.emptyViewDidPressClaimExperiments()
  }
}
