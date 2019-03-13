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

protocol SignInViewControllerDelegate: class {
  /// Informs the delegate the user will continue without signing in.
  func signInViewControllerContinueWithoutSigningIn()
}

/// A view controller that displays a splash image and a sign in button.
class SignInViewController: OnboardingViewController {

  enum Metrics {
    static let driveMessageTopPaddingNarrow: CGFloat = 80.0
    static let driveMessageTopPaddingNarrowSmallScreen: CGFloat = 60.0
    static let driveMessageTopPaddingWide: CGFloat = 40.0
    static let driveMessageTopPaddingWideSmallScreen: CGFloat = 20.0
    static let textColor = UIColor(red: 0.816, green: 0.714, blue: 0.980, alpha: 1.0)
    static let separatorViewColor = UIColor(red: 0.45, green: 0.18, blue: 0.77, alpha: 1.0)
  }

  // MARK: - Properties

  /// The delegate.
  weak var delegate: SignInViewControllerDelegate?

  private let driveMessage = UILabel()
  private let driveScrollView = UIScrollView()
  private let stackView = UIStackView()
  private let noSignInButton = MDCFlatButton()
  private let noSignInFloatingButton = ButtonViewController()

  private let accountsManager: AccountsManager
  private let driveSyncInfoURL =
      URL(string: "https://support.google.com/sciencejournal/answer/9176370")!

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - accountsManager: The accounts manager.
  ///   - analyticsReporter: The analytics reporter.
  init(accountsManager: AccountsManager, analyticsReporter: AnalyticsReporter) {
    self.accountsManager = accountsManager
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateViewForSize(view.bounds.size)
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { (context) in
      self.updateViewForSize(size)
      self.view.layoutIfNeeded()
    })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let isFloatingButtonVisible = noSignInFloatingButton.view.alpha == 1
    let bottomInset = isFloatingButtonVisible ? noSignInFloatingButton.view.frame.height : 0
    driveScrollView.contentInset.bottom = bottomInset
    driveScrollView.scrollIndicatorInsets.bottom = bottomInset
    driveScrollView.scrollIndicatorInsets.left = view.safeAreaInsetsOrZero.left
    driveScrollView.scrollIndicatorInsets.right = view.safeAreaInsetsOrZero.right
  }

  // MARK: - Private

  override func configureView() {
    super.configureView()

    configureSplashImagesRelativeToLogo()

    driveMessage.text = String.driveSyncInformation
    driveMessage.translatesAutoresizingMaskIntoConstraints = false
    driveMessage.font = Metrics.bodyFont
    driveMessage.textColor = Metrics.textColor
    driveMessage.alpha = 1
    driveMessage.numberOfLines = 0

    // Shared button config.
    let signInButton = MDCFlatButton()
    signInButton.translatesAutoresizingMaskIntoConstraints = false
    signInButton.setBackgroundColor(.white, for: .normal)
    signInButton.setTitleColor(MDCPalette.blue.tint500, for: .normal)
    signInButton.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
    signInButton.setElevation(ShadowElevation.raisedButtonPressed, for: [.selected, .highlighted])

    // A scrollview to hold the drive message label and buttons, since it will be taller than the
    // screen in landscape and on some smaller phones in portrait.
    wrappingView.addSubview(driveScrollView)
    driveScrollView.translatesAutoresizingMaskIntoConstraints = false
    if #available(iOS 11.0, *) {
      driveScrollView.contentInsetAdjustmentBehavior = .never
    }
    driveScrollView.pinToEdgesOfView(wrappingView)

    // Drive message config.
    stackView.addArrangedSubview(driveMessage)
    driveScrollView.addSubview(stackView)

    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.layoutMargins = UIEdgeInsets(top: Metrics.driveMessageTopPaddingNarrow,
                                           left: Metrics.outerPaddingNarrow,
                                           bottom: Metrics.outerPaddingNarrow,
                                           right: Metrics.outerPaddingNarrow)
    stackView.spacing = Metrics.buttonSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.pinToEdgesOfView(driveScrollView)
    stackView.widthAnchor.constraint(equalTo: wrappingView.widthAnchor).isActive = true

    signInButton.setTitle(String.signIn.uppercased(), for: .normal)
    signInButton.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)

    // Learn more button.
    let learnMoreButton = MDCFlatButton()
    learnMoreButton.setTitle(String.learnMore.uppercased(), for: .normal)
    learnMoreButton.translatesAutoresizingMaskIntoConstraints = false
    learnMoreButton.setBackgroundColor(.clear, for: .normal)
    learnMoreButton.setTitleColor(.white, for: .normal)
    learnMoreButton.addTarget(self, action: #selector(learnMoreButtonPressed), for: .touchUpInside)

    let buttonStack = UIStackView(arrangedSubviews: [signInButton, learnMoreButton])
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    buttonStack.axis = .vertical
    buttonStack.alignment = .center
    buttonStack.spacing = Metrics.buttonSpacingInner
    stackView.addArrangedSubview(buttonStack)

    stackView.addArrangedSubview(logoImage)

    // Continue without signing in button.
    noSignInButton.setTitle(String.continueWithoutSignin.uppercased(), for: .normal)
    noSignInButton.translatesAutoresizingMaskIntoConstraints = false
    noSignInButton.setBackgroundColor(.clear, for: .normal)
    noSignInButton.setTitleColor(.white, for: .normal)
    stackView.addArrangedSubview(noSignInButton)

    // Without this constraint the stack view is too wide. It doesn't seem like it should be
    // necessary so there is likely a bug elsewhere.
    buttonStack.centerXAnchor.constraint(equalTo: driveScrollView.centerXAnchor).isActive = true

    // Continue button floating version.
    noSignInFloatingButton.view.translatesAutoresizingMaskIntoConstraints = false
    wrappingView.addSubview(noSignInFloatingButton.view)
    noSignInFloatingButton.button.setTitle(String.continueWithoutSignin.uppercased(), for: .normal)
    noSignInFloatingButton.button.setTitleColor(Metrics.textColor, for: .normal)
    noSignInFloatingButton.topSeparatorView.backgroundColor = Metrics.separatorViewColor
    noSignInFloatingButton.view.backgroundColor = Metrics.backgroundColor
    noSignInFloatingButton.view.alpha = 0
    NSLayoutConstraint.activate([
      noSignInFloatingButton.view.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor),
      noSignInFloatingButton.view.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor),
      noSignInFloatingButton.view.bottomAnchor.constraint(equalTo: wrappingView.bottomAnchor)
    ])

    [noSignInButton, noSignInFloatingButton.button].forEach { button in
      button.addTarget(self,
                       action: #selector(continueWithoutSigningInButtonPressed),
                       for: .touchUpInside)
    }
  }

  // Updates the view, including constraints, for the a given screen size.
  private func updateViewForSize(_ size: CGSize) {
    let floatingButtonAlpha: CGFloat
    if size.height < 736 {
      noSignInButton.isHidden = true
      noSignInButton.alpha = 0
      floatingButtonAlpha = 1
    } else {
      noSignInButton.isHidden = false
      noSignInButton.alpha = 1
      floatingButtonAlpha = 0
    }
    noSignInFloatingButton.view.alpha = floatingButtonAlpha

    let stackViewTopPadding: CGFloat
    let buttonSpacing: CGFloat
    let outerLeadingPadding: CGFloat
    let outerTrailingPadding: CGFloat
    if traitCollection.horizontalSizeClass == .regular &&
        traitCollection.verticalSizeClass == .regular {
      stackViewTopPadding = 0
      buttonSpacing = Metrics.buttonSpacing
      outerLeadingPadding = Metrics.outerPaddingNarrow
      outerTrailingPadding = -Metrics.outerPaddingNarrow
    } else {
      if size.isWiderThanTall {
        if size.width <= 568 {
          stackViewTopPadding = Metrics.driveMessageTopPaddingWideSmallScreen
        } else {
          stackViewTopPadding = Metrics.driveMessageTopPaddingWide
        }
        buttonSpacing = Metrics.buttonSpacingWide
      } else {
        if size.width <= 320 {
          stackViewTopPadding = Metrics.driveMessageTopPaddingNarrowSmallScreen
        } else {
          stackViewTopPadding = Metrics.driveMessageTopPaddingNarrow
        }
        buttonSpacing = Metrics.buttonSpacing
      }

      outerLeadingPadding =
          size.isWiderThanTall ? Metrics.outerPaddingWide : Metrics.outerPaddingNarrow
      outerTrailingPadding =
          size.isWiderThanTall ? -Metrics.outerPaddingWide : -Metrics.outerPaddingNarrow
    }

    stackView.layoutMargins = UIEdgeInsets(top: stackViewTopPadding,
                                           left: outerLeadingPadding,
                                           bottom: Metrics.outerPaddingNarrow,
                                           right: outerTrailingPadding)
    stackView.spacing = buttonSpacing
  }

  // MARK: - User actions

  @objc private func signInButtonPressed() {
    accountsManager.presentSignIn(fromViewController: self)
    analyticsReporter.track(.signInFromWelcome)
  }

  @objc private func learnMoreButtonPressed() {
    UIApplication.shared.open(driveSyncInfoURL)
    analyticsReporter.track(.signInLearnMore)
  }

  @objc private func continueWithoutSigningInButtonPressed() {
    delegate?.signInViewControllerContinueWithoutSigningIn()
    analyticsReporter.track(.signInContinueWithoutAccount)
  }

}
