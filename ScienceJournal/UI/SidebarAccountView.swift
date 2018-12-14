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

protocol SidebarAccountViewDelegate: class {
  /// Informs the delegate the user tapped on the account view.
  func sidebarAccountViewTapped()
}

/// A view that lives at the bottom of the sidebar and shows the user's currently-logged-in Google
/// account information (avatar, name and email), which acts as a button allowing the user to change
/// accounts or log out.
class SidebarAccountView: UIView {

  private enum Metrics {
    static let arrowDimension: CGFloat = 14.0
    static let imageDimension: CGFloat = 50.0
    static let imageRadius: CGFloat = ceil(Metrics.imageDimension / 2)
    static let imageSpacing: CGFloat = 10.0
    static let viewInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
  }

  // MARK: - Properties

  /// The sidebar account view delegate.
  weak var delegate: SidebarAccountViewDelegate?

  /// The first line of text (when displaying an account it's the user's display name).
  private var firstLine: String? {
    didSet {
      guard firstLine != oldValue else { return }
      firstLineLabel.text = firstLine
    }
  }

  /// The second line of text (when displaying an account it's the user's email address).
  private var secondLine: String? {
    didSet {
      guard secondLine != oldValue else { return }
      secondLineLabel.text = secondLine
      if secondLine == nil {
        labelStack.removeArrangedSubview(secondLineLabel)
        secondLineLabel.removeFromSuperview()
      } else {
        labelStack.insertArrangedSubview(secondLineLabel, at: 1)
      }
    }
  }

  /// The users's profile image.
  private var profileImage: UIImage? {
    didSet {
      guard profileImage != oldValue else { return }
      profileImageView.image = profileImage
    }
  }

  private let firstLineLabel = UILabel()
  private let secondLineLabel = UILabel()
  private let profileImageView = UIImageView()
  private let labelStack = UIStackView()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Displays account details.
  ///
  /// - Parameters:
  ///   - name: An account name.
  ///   - email: An account email.
  ///   - profileImage: An account profile image.
  func showAccount(withName name: String, email: String, profileImage: UIImage?) {
    firstLine = name
    secondLine = email
    self.profileImage = profileImage
    profileImageView.tintColor = nil
  }

  /// Displays the signed out state with a generic icon.
  func showNoAccount() {
    firstLine = String.signIn
    secondLine = nil
    profileImage = UIImage(named: "ic_account_placeholder")
    profileImageView.tintColor = MDCPalette.grey.tint700
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = .white

    let separator = SeparatorView(direction: .horizontal, style: .dark)
    addSubview(separator)
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.topAnchor.constraint(equalTo: topAnchor).isActive = true
    separator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    separator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

    firstLineLabel.font = MDCTypography.body2Font()
    secondLineLabel.font = MDCTypography.body1Font()

    [firstLineLabel, secondLineLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.textColor = .black
      $0.allowsDefaultTighteningForTruncation = true
      $0.adjustsFontSizeToFitWidth = true
    }

    labelStack.addArrangedSubview(firstLineLabel)
    labelStack.addArrangedSubview(secondLineLabel)
    labelStack.translatesAutoresizingMaskIntoConstraints = false
    labelStack.axis = .vertical
    labelStack.alignment = .leading
    labelStack.setContentCompressionResistancePriority(.required, for: .horizontal)

    let arrow = UIImageView(image: UIImage(named: "ic_login_arrow"))
    arrow.tintColor = MDCPalette.grey.tint500
    arrow.translatesAutoresizingMaskIntoConstraints = false
    arrow.setContentHuggingPriority(.required, for: .horizontal)
    arrow.contentMode = .center
    arrow.widthAnchor.constraint(equalToConstant: Metrics.arrowDimension).isActive = true
    arrow.heightAnchor.constraint(equalToConstant: Metrics.arrowDimension).isActive = true

    let labelsAndArrowStack = UIStackView(arrangedSubviews: [labelStack, arrow])
    labelsAndArrowStack.translatesAutoresizingMaskIntoConstraints = false
    labelsAndArrowStack.alignment = .top

    profileImageView.translatesAutoresizingMaskIntoConstraints = false
    if #available(iOS 11.0, *) {
      profileImageView.accessibilityIgnoresInvertColors = true
    }
    profileImageView.layer.cornerRadius = Metrics.imageRadius
    profileImageView.clipsToBounds = true
    profileImageView.widthAnchor.constraint(equalToConstant: Metrics.imageDimension).isActive = true
    profileImageView.heightAnchor.constraint(
        equalToConstant: Metrics.imageDimension).isActive = true

    let outerStack = UIStackView(arrangedSubviews: [profileImageView, labelsAndArrowStack])
    addSubview(outerStack)
    outerStack.translatesAutoresizingMaskIntoConstraints = false
    outerStack.alignment = .center
    outerStack.spacing = Metrics.imageSpacing
    outerStack.layoutMargins = Metrics.viewInsets
    outerStack.isLayoutMarginsRelativeArrangement = true
    outerStack.pinToEdgesOfView(self)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(accountViewTapped))
    addGestureRecognizer(tapGesture)
  }

  // MARK: - User actions

  @objc private func accountViewTapped() {
    delegate?.sidebarAccountViewTapped()
  }

}
