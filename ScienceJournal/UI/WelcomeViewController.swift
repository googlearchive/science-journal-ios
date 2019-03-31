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

protocol WelcomeViewControllerDelegate: class {
  /// Informs the delegate the user tapped the get started button.
  func welcomeViewControllerDidGetStarted()
}

/// A view controller that displays a splash image and a get started button.
class WelcomeViewController: OnboardingViewController {

  enum Metrics {
    static let googleLogoTopPadding: CGFloat = 30.0
    static let headerTopPaddingWide: CGFloat = 20.0
    static let logoTopPadding: CGFloat = 50.0
  }

  // MARK: - Properties

  /// The delegate.
  weak var delegate: WelcomeViewControllerDelegate?

  let headerTitle = UILabel()
  let primaryMessage = UILabel()

  // Constraints that will be modified on rotation.
  private var googleLogoBottomConstraint: NSLayoutConstraint?
  private var headerTopConstraint: NSLayoutConstraint?
  private var primaryMessageLeadingConstraint: NSLayoutConstraint?
  private var primaryMessageTrailingConstraint: NSLayoutConstraint?

  // MARK: - Public

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateConstraintsForSize(view.bounds.size)
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { (context) in
      self.updateConstraintsForSize(size)
      self.view.layoutIfNeeded()
    })
  }

  // MARK: - Private

  override func configureView() {
    super.configureView()

    shouldCenterWrappingViewVertically = true
    configureSplashImagesRelativeToLogo()

    headerTitle.text = String.exploreYourWorld
    primaryMessage.text = String.useScienceJournal

    // Header label.
    wrappingView.addSubview(headerTitle)
    headerTitle.translatesAutoresizingMaskIntoConstraints = false
    headerTopConstraint = headerTitle.topAnchor.constraint(equalTo: wrappingView.topAnchor)
    headerTopConstraint?.isActive = true
    headerTitle.textColor = .white
    headerTitle.font = MDCTypography.headlineFont()
    headerTitle.textAlignment = .center
    headerTitle.adjustsFontSizeToFitWidth = true
    headerTitle.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor).isActive = true
    headerTitle.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor).isActive = true

    // Primary message label.
    primaryMessage.translatesAutoresizingMaskIntoConstraints = false
    primaryMessage.font = Metrics.bodyFont
    primaryMessage.textColor = UIColor(red: 0.816, green: 0.714, blue: 0.980, alpha: 1.0)
    primaryMessage.alpha = 1
    primaryMessage.numberOfLines = 0

    // Configure constraints for the primary message.
    wrappingView.addSubview(primaryMessage)
    primaryMessage.textAlignment = .center
    primaryMessageLeadingConstraint =
        primaryMessage.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor)
    primaryMessageLeadingConstraint?.isActive = true
    primaryMessageTrailingConstraint =
        primaryMessage.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor)
    primaryMessageTrailingConstraint?.isActive = true
    primaryMessage.topAnchor.constraint(equalTo: headerTitle.bottomAnchor,
                                        constant: Metrics.innerSpacing).isActive = true

    // Button config.
    let startButton = MDCFlatButton()
    wrappingView.addSubview(startButton)
    startButton.translatesAutoresizingMaskIntoConstraints = false
    startButton.setBackgroundColor(.white, for: .normal)
    startButton.setTitleColor(MDCPalette.blue.tint500, for: .normal)
    startButton.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
    startButton.setElevation(ShadowElevation.raisedButtonPressed, for: [.selected, .highlighted])
    startButton.setTitle(String.getStarted.uppercased(), for: .normal)
    startButton.centerXAnchor.constraint(equalTo: wrappingView.centerXAnchor).isActive = true
    startButton.topAnchor.constraint(equalTo: primaryMessage.bottomAnchor,
                                     constant: Metrics.buttonSpacing).isActive = true
    startButton.addTarget(self, action: #selector(getStartedButtonPressed), for: .touchUpInside)

    NSLayoutConstraint.activate([
      logoImage.centerXAnchor.constraint(equalTo: wrappingView.centerXAnchor),
      logoImage.topAnchor.constraint(equalTo: startButton.bottomAnchor,
                                     constant: Metrics.logoTopPadding)
    ])

    // Google logo.
    let googleLogoImageView = UIImageView(image: UIImage(named: "logo_google_splash"))
    googleLogoImageView.translatesAutoresizingMaskIntoConstraints = false
    wrappingView.addSubview(googleLogoImageView)
    googleLogoImageView.centerXAnchor.constraint(equalTo: logoImage.centerXAnchor).isActive = true
    googleLogoImageView.topAnchor.constraint(equalTo: logoImage.bottomAnchor,
                                             constant: Metrics.googleLogoTopPadding).isActive = true
    googleLogoBottomConstraint =
        googleLogoImageView.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor)
  }

  // Updates constraints for labels. Used in rotation to ensure the best fit for various screen
  // sizes.
  func updateConstraintsForSize(_ size: CGSize) {
    func setCenterWrappingViewVertically(_ shouldCenter: Bool) {
      // When centered, add the Google logo bottom constraint and remove the header top padding.
      shouldCenterWrappingViewVertically = shouldCenter
      headerTopConstraint?.constant = shouldCenter ? 0 : Metrics.headerTopPaddingWide
      googleLogoBottomConstraint?.isActive = shouldCenter
    }

    guard UIDevice.current.userInterfaceIdiom != .pad else {
      setCenterWrappingViewVertically(true)
      return
    }

    setCenterWrappingViewVertically(!size.isWiderThanTall)

    let outerLeadingPadding =
        size.isWiderThanTall ? Metrics.outerPaddingWide : Metrics.outerPaddingNarrow
    let outerTrailingPadding =
        size.isWiderThanTall ? -Metrics.outerPaddingWide : -Metrics.outerPaddingNarrow

    primaryMessageLeadingConstraint?.constant = outerLeadingPadding
    primaryMessageTrailingConstraint?.constant = outerTrailingPadding
  }

  // MARK: - User actions

  @objc private func getStartedButtonPressed() {
    delegate?.welcomeViewControllerDidGetStarted()
  }

}
