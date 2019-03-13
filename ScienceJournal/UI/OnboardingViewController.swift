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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// The base class for onboarding view controllers that contains the Science Journal colors,
/// iconography and layout. Permissions and welcome screens should subclass this to adhere to the
/// designed look for initial flows.
class OnboardingViewController: ScienceJournalViewController {

  // MARK: - Properties

  enum Metrics {
    static let outerPaddingNarrow: CGFloat = 24.0
    static let outerPaddingWide: CGFloat = 100.0
    static let maxLabelWidth: CGFloat = 400.0
    static let compassXOffset: CGFloat = -10.0
    static let compassYOffset: CGFloat = 8.0
    static let logoYOffset: CGFloat = 40.0
    static let magGlassXOffset: CGFloat = 26.0
    static let magGlassYOffset: CGFloat = 10.0
    static let pencilXOffset: CGFloat = 28.0
    static let pencilYOffset: CGFloat = -120.0
    static let rulerXOffset: CGFloat = -40.0
    static let rulerYOffset: CGFloat = -140.0
    static let innerSpacing: CGFloat = 20.0
    static let buttonSpacing: CGFloat = 40.0
    static let buttonSpacingInner: CGFloat = 8.0
    static let buttonSpacingWide: CGFloat = 30.0
    static let padWidth: CGFloat = 540.0
    static let padHeight: CGFloat = 620.0
    static let compassImageOffsetX: CGFloat = 145
    static let compassImageOffsetY: CGFloat = 34
    static let magGlassImageOffsetX: CGFloat = -145
    static let magGlassImageOffsetY: CGFloat = 63
    static let pencilImageOffsetX: CGFloat = -145
    static let pencilImageOffsetY: CGFloat = -102
    static let rulerImageOffsetX: CGFloat = 145
    static let rulerImageOffsetY: CGFloat = -100
    static let backgroundColor = UIColor(red: 0.290, green: 0.078, blue: 0.549, alpha: 1.0)
    static let backgroundTransparent = UIColor(red: 0.290, green: 0.078, blue: 0.549, alpha: 0.0)
    static let gradientHeight: CGFloat = 200.0
    static let bodyFont = MDCTypography.fontLoader().regularFont(ofSize: 16.0)
  }

  /// A compass image, part of the splash montage.
  let compassImage = UIImageView(image: UIImage(named: "guide_footer_compass"))
  /// The Science Journal logo image, part of the splash montage.
  let logoImage = UIImageView(image: UIImage(named: "guide_footer_logo"))
  /// A magnifying glass image, part of the splash montage.
  let magGlassImage = UIImageView(image: UIImage(named: "guide_footer_mag_glass"))
  /// A pencil image, part of the splash montage.
  let pencilImage = UIImageView(image: UIImage(named: "guide_footer_pencil"))
  /// A ruler image, part of the splash montage.
  let rulerImage = UIImageView(image: UIImage(named: "guide_footer_ruler"))

  // MARK: Public

  /// A wrapping view used to constrain the view to a specific size on iPad. On other devices, this
  /// will be the same size as `view`. All subviews should be added to this view.
  let wrappingView = UIView()

  /// When laying out the wrapping view, it will be centered vertically when true. Otherwise, it is
  /// full screen on iPhone and a standard height on iPad. The wrapping view height must be properly
  /// sized for this to work. Defaults to false.
  var shouldCenterWrappingViewVertically = false {
    didSet {
      configureVariableConstraints(forTraitCollection: traitCollection)
    }
  }

  private var wrappingViewConstraints = [NSLayoutConstraint]()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: - Public

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureVariableConstraints(forTraitCollection: traitCollection)
  }

  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    configureVariableConstraints(forTraitCollection: newCollection)
  }

  func configureView() {
    view.backgroundColor = Metrics.backgroundColor

    // Configure the wrapping view.
    view.addSubview(wrappingView)
    wrappingView.translatesAutoresizingMaskIntoConstraints = false

    // Various parts of the splash montage.
    [compassImage, logoImage, magGlassImage, pencilImage, rulerImage].forEach {
      wrappingView.addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
      if #available(iOS 11.0, *) {
        $0.accessibilityIgnoresInvertColors = true
      }
    }
  }

  // Configures constraints to position the splash images at the bottom of the view.
  func configureSplashImagesPinnedToBottom() {
    // Lay out the footer.
    NSLayoutConstraint.activate([
      compassImage.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor,
                                             constant: Metrics.compassXOffset),
      compassImage.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor,
                                           constant: Metrics.compassYOffset),
      logoImage.centerXAnchor.constraint(equalTo: wrappingView.centerXAnchor),
      logoImage.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor,
                                        constant: Metrics.logoYOffset),
      magGlassImage.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor,
                                             constant: Metrics.magGlassXOffset),
      magGlassImage.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor,
                                            constant: Metrics.magGlassYOffset),
      pencilImage.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor,
                                           constant: Metrics.pencilXOffset),
      pencilImage.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor,
                                          constant: Metrics.pencilYOffset),
      rulerImage.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor,
                                           constant: Metrics.rulerXOffset),
      rulerImage.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor,
                                         constant: Metrics.rulerYOffset)
    ])
  }

  // Configures constraints to position all splash images relative to the Science Journal logo
  // image. This requires configuring constraints for the logo as it will not have a default
  // position.
  func configureSplashImagesRelativeToLogo() {
    NSLayoutConstraint.activate([
      compassImage.centerXAnchor.constraint(equalTo: logoImage.centerXAnchor,
                                            constant: Metrics.compassImageOffsetX),
      compassImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor,
                                            constant: Metrics.compassImageOffsetY),
      magGlassImage.centerXAnchor.constraint(equalTo: logoImage.centerXAnchor,
                                             constant: Metrics.magGlassImageOffsetX),
      magGlassImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor,
                                             constant: Metrics.magGlassImageOffsetY),
      pencilImage.centerXAnchor.constraint(equalTo: logoImage.centerXAnchor,
                                           constant: Metrics.pencilImageOffsetX),
      pencilImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor,
                                           constant: Metrics.pencilImageOffsetY),
      rulerImage.centerXAnchor.constraint(equalTo: logoImage.centerXAnchor,
                                          constant: Metrics.rulerImageOffsetX),
      rulerImage.centerYAnchor.constraint(equalTo: logoImage.centerYAnchor,
                                          constant: Metrics.rulerImageOffsetY)
    ])
  }

  // MARK: - Private

  private func configureVariableConstraints(
      forTraitCollection newTraitCollection: UITraitCollection) {
    view.removeConstraints(wrappingViewConstraints)
    wrappingViewConstraints.removeAll()

    if shouldCenterWrappingViewVertically {
      wrappingViewConstraints.append(
          wrappingView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
      wrappingViewConstraints.append(
          wrappingView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
      wrappingViewConstraints.append(
          wrappingView.trailingAnchor.constraint(equalTo: view.trailingAnchor))
    } else if newTraitCollection.verticalSizeClass == .regular &&
        newTraitCollection.horizontalSizeClass == .regular {
      wrappingViewConstraints.append(
          wrappingView.widthAnchor.constraint(equalToConstant: Metrics.padWidth))
      wrappingViewConstraints.append(
          wrappingView.heightAnchor.constraint(equalToConstant: Metrics.padHeight))
      wrappingViewConstraints.append(
          wrappingView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
      wrappingViewConstraints.append(
          wrappingView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
    } else {
      wrappingViewConstraints.append(
          wrappingView.topAnchor.constraint(equalTo: view.topAnchor))
      wrappingViewConstraints.append(
          wrappingView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
      wrappingViewConstraints.append(
          wrappingView.trailingAnchor.constraint(equalTo: view.trailingAnchor))
      wrappingViewConstraints.append(
          wrappingView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
    }

    NSLayoutConstraint.activate(wrappingViewConstraints)
  }

}
