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

protocol VerifyAgeDelegate: class {
  /// Informs the delegate age verification was completed and should be closed.
  func ageVerificationDidComplete(_ viewController: VerifyAgeViewController)
}

/// A required COPPA-age-verifying view controller, presented to the user upon first-time use of the
/// app to confirm this user is at least 13 years old for certain features to be active.
class VerifyAgeViewController: ScienceJournalViewController {

  // MARK: - Properties

  private let contentView = UIView()
  private var contentViewLeadingConstraint: NSLayoutConstraint?
  private var contentViewTopConstraint: NSLayoutConstraint?
  private var contentViewTrailingConstraint: NSLayoutConstraint?
  private weak var delegate: VerifyAgeDelegate?
  private let header = UIView()
  private var headerHeightConstraint: NSLayoutConstraint?
  private var selectedAge = Date()
  private let preferenceManager: PreferenceManager

  // MARK: - Constants

  let birthdayLabelFontSize: CGFloat = 18.0
  let birthdayLabelTopPadding: CGFloat = 20.0
  let getStartedButtonElevation: CGFloat = 2.0
  let getStartedButtonTopPadding: CGFloat = 16.0
  let headerHeight: CGFloat = 140.0
  let headerHeightSmallestScreen: CGFloat = 100.0
  let headerImageWidth: CGFloat = 168.0
  let headerImageHeight: CGFloat = 80.0
  let labelsLeftPadding: CGFloat = 16.0
  let outerPaddingPad: CGFloat = 100
  let outerPaddingPhone: CGFloat = 0
  let topPaddingPad: CGFloat = 140
  let topPaddingPhone: CGFloat = 0
  let verifyBarPadding: CGFloat = 60.0
  let verifyLabelFontSize: CGFloat = 22.0

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: The analytics reporter.
  ///   - delegate: The verify age delegate.
  ///   - preferenceManager: The preference manager.
  init(analyticsReporter: AnalyticsReporter,
       delegate: VerifyAgeDelegate,
       preferenceManager: PreferenceManager) {
    self.delegate = delegate
    self.preferenceManager = preferenceManager
    super.init(analyticsReporter: analyticsReporter)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    // Content view.
    view.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentViewTopConstraint = contentView.topAnchor.constraint(equalTo: view.topAnchor)
    contentViewTopConstraint?.isActive = true
    contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    contentViewLeadingConstraint = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    contentViewLeadingConstraint?.isActive = true
    contentViewTrailingConstraint =
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    contentViewTrailingConstraint?.isActive = true

    // Header.
    contentView.addSubview(header)
    header.backgroundColor = UIColor(red: 0.682, green: 0.839, blue: 0.980, alpha: 1.0)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

    // Header image.
    let verifyHeaderImage = UIImageView(image: UIImage(named: "verify_age_header"))
    header.addSubview(verifyHeaderImage)
    verifyHeaderImage.translatesAutoresizingMaskIntoConstraints = false
    verifyHeaderImage.centerXAnchor.constraint(equalTo: header.centerXAnchor).isActive = true
    verifyHeaderImage.bottomAnchor.constraint(equalTo: header.bottomAnchor).isActive = true
    verifyHeaderImage.widthAnchor.constraint(equalToConstant: headerImageWidth).isActive = true
    verifyHeaderImage.heightAnchor.constraint(equalToConstant: headerImageHeight).isActive = true

    // Blue bar with verify title.
    let verifyBar = UIView()
    contentView.addSubview(verifyBar)
    verifyBar.backgroundColor = MDCPalette.blue.tint500
    verifyBar.translatesAutoresizingMaskIntoConstraints = false
    verifyBar.topAnchor.constraint(equalTo: header.bottomAnchor).isActive = true
    verifyBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    verifyBar.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true

    // Verify title.
    let verifyLabel = UILabel()
    verifyBar.addSubview(verifyLabel)
    verifyLabel.font = MDCTypography.fontLoader().regularFont(ofSize: verifyLabelFontSize)
    verifyLabel.textColor = .white
    verifyLabel.text = String.ageVerifierHeader
    verifyLabel.translatesAutoresizingMaskIntoConstraints = false
    verifyLabel.centerYAnchor.constraint(equalTo: verifyBar.centerYAnchor).isActive = true
    verifyLabel.leadingAnchor.constraint(equalTo: verifyBar.leadingAnchor,
                                         constant: labelsLeftPadding).isActive = true
    verifyBar.heightAnchor.constraint(equalTo: verifyLabel.heightAnchor,
                                      multiplier: 0,
                                      constant: verifyBarPadding).isActive = true

    // Birthday label.
    let birthdayLabel = UILabel()
    contentView.addSubview(birthdayLabel)
    birthdayLabel.font = MDCTypography.fontLoader().regularFont(ofSize: birthdayLabelFontSize)
    birthdayLabel.textColor = MDCPalette.grey.tint700
    birthdayLabel.text = String.ageVerifierBirthday
    birthdayLabel.translatesAutoresizingMaskIntoConstraints = false
    birthdayLabel.topAnchor.constraint(equalTo: verifyBar.bottomAnchor,
                                       constant: birthdayLabelTopPadding).isActive = true
    birthdayLabel.leadingAnchor.constraint(equalTo: verifyLabel.leadingAnchor).isActive = true

    // Age picker.
    let agePicker = UIDatePicker()
    contentView.addSubview(agePicker)
    agePicker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
    agePicker.datePickerMode = .date
    agePicker.translatesAutoresizingMaskIntoConstraints = false
    agePicker.minimumDate = Date(timeInterval: -(60*60*24*365*100), since: Date())  // 100 years ago
    agePicker.maximumDate = Date()
    agePicker.topAnchor.constraint(equalTo: birthdayLabel.bottomAnchor).isActive = true
    agePicker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    agePicker.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true

    // Get started button.
    let startButton = MDCButton()
    contentView.addSubview(startButton)
    let buttonTitle = String.ageVerifierGetStarted
    startButton.setBackgroundColor(MDCPalette.blue.tint500, for: .normal)
    startButton.setTitleColor(.white, for: .normal)
    startButton.setElevation(ShadowElevation(rawValue: getStartedButtonElevation), for: .normal)
    startButton.setElevation(.raisedButtonPressed, for: .highlighted)
    startButton.setTitle(buttonTitle, for: .normal)
    startButton.sizeToFit()
    startButton.addTarget(self, action: #selector(getStartedPressed), for: .touchUpInside)
    startButton.translatesAutoresizingMaskIntoConstraints = false
    startButton.topAnchor.constraint(equalTo: agePicker.bottomAnchor,
                                     constant: getStartedButtonTopPadding).isActive = true
    startButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateHeaderConstraintsForSize(view.bounds.size)
    configureVariableConstraints(forTraitCollection: traitCollection)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    updateHeaderConstraintsForSize(size)
  }

  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    configureVariableConstraints(forTraitCollection: newCollection)
  }

  // MARK: - Private

  private func updateHeaderConstraintsForSize(_ size: CGSize) {
    if let existingConstraint = headerHeightConstraint {
      existingConstraint.isActive = false
    }

    var usableHeaderHeight: CGFloat
    if size.height <= 480 {
      usableHeaderHeight = headerHeightSmallestScreen
    } else {
      usableHeaderHeight = headerHeight
    }
    let constant = size.isWiderThanTall ? 0 : usableHeaderHeight
    headerHeightConstraint = header.heightAnchor.constraint(equalToConstant: constant)
    headerHeightConstraint?.isActive = true
  }

  private func configureVariableConstraints(
      forTraitCollection newTraitCollection: UITraitCollection) {
    // Add extra margins on full screen iPad.
    let isRegular = newTraitCollection.horizontalSizeClass == .regular &&
        newTraitCollection.verticalSizeClass == .regular
    contentViewTopConstraint?.constant = isRegular ? topPaddingPad : topPaddingPhone
    contentViewLeadingConstraint?.constant =
        isRegular ? outerPaddingPad : outerPaddingPhone
    contentViewTrailingConstraint?.constant =
        isRegular ? -outerPaddingPad : -outerPaddingPhone
  }

  // MARK: - User actions

  @objc func pickerChanged(sender: UIDatePicker) {
    selectedAge = sender.date
  }

  @objc func getStartedPressed(sender: MDCButton) {
    preferenceManager.isUser13OrOlder = selectedAge.isBirthdateAge13OrOlder
    delegate?.ageVerificationDidComplete(self)
  }

}
