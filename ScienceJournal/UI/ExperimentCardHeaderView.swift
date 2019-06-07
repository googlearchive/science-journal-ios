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

/// The timestamp, caption and menu options view for all cells in an experiment or Trial Detail
/// view.
class ExperimentCardHeaderView: UIView {

  // MARK: - Constants

  let innerHorizontalSpacing: CGFloat = 8.0
  static let iconDimension: CGFloat = 24.0
  private let innerButtonSpacing: CGFloat = 14.0

  // MARK: - Properties

  /// The timestamp label.
  let headerTimestampLabel = UILabel()

  /// The invisible button wrapping the timestamp and timestamp dot, only tappable if
  /// `isRelativeTimestamp` is true.
  let timestampButton = UIButton()

  /// The comment button for the header.
  let commentButton = MDCFlatButton()

  /// The menu button for the header.
  let menuButton = MenuButton()

  /// Override the accessibility label to set the inner wrapper instead.
  override var accessibilityLabel: String? {
    didSet {
      accessibilityWrappingView.accessibilityLabel = accessibilityLabel
    }
  }

  // A dot icon placed on the leading side of the timestamp in relative timestamp situations like
  // Trial detail.
  private let timestampDot = UIImageView(image: UIImage(named: "ic_lens_18pt"))

  // The outer containing stack view for this header.
  private let outerStack = UIStackView()

  // The accessibility wrapping view that reads the timestamp and allows for selection in any open
  // region of the view.
  private let accessibilityWrappingView = UIView()

  /// Show or hide the caption creation icon. Caption icons are hidden when there is a caption set
  /// on the owner or when the owner doesn't support captions (e.g. text notes).
  var showCaptionButton: Bool = true {
    didSet {
      commentButton.isHidden = !showCaptionButton
    }
  }

  /// Show or hide the menu icon.
  var showMenuButton: Bool = true {
    didSet {
      menuButton.isHidden = !showMenuButton
    }
  }

  /// If the timestamp for this view is relative, show the leading dot.
  var isTimestampRelative: Bool = false {
    didSet {
      timestampDot.isHidden = !isTimestampRelative
      // We use an invisible button on top of the timestamp to allow a user to tap the timestamp
      // to move the chart to that time. But when we are not in relative timestamp mode, we need to
      // remove that button entirely because it should not be an accessible element in VoiceOver.
      if isTimestampRelative {
        outerStack.addSubview(timestampButton)
        timestampButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        timestampButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        timestampButton.trailingAnchor.constraint(
            equalTo: headerTimestampLabel.trailingAnchor, constant: -20).isActive = true
        timestampButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
      } else {
        timestampButton.removeFromSuperview()
      }
    }
  }

  static let height: CGFloat = {
    // Calculate the header stack view's height, which is either the label's height or the icon
    // (whichever is bigger) + padding.
    let headerHeight = String.runReviewActivityLabel.labelHeight(
        withConstrainedWidth: 0,
        font: MDCTypography.fontLoader().regularFont(ofSize: ExperimentCardView.timestampFontSize))
    return max(headerHeight, ExperimentCardHeaderView.iconDimension) +
        (ExperimentCardView.headerFooterVerticalPadding * 2)
  }()

  // MARK: - Public

  override required init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: ExperimentCardHeaderView.height)
  }

  // MARK: - Private

  private func configureView() {
    autoresizingMask = [.flexibleWidth, .flexibleHeight]

    // Relative timestamp dot, for use in Trial detail timelines.
    timestampDot.tintColor = .appBarReviewBackgroundColor
    timestampDot.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    timestampDot.isHidden = true
    timestampDot.translatesAutoresizingMaskIntoConstraints = false
    outerStack.addArrangedSubview(timestampDot)

    // Timestamp label.
    headerTimestampLabel.textColor = MDCPalette.grey.tint500
    headerTimestampLabel.font = MDCTypography.fontLoader().regularFont(
        ofSize: ExperimentCardView.timestampFontSize)
    headerTimestampLabel.translatesAutoresizingMaskIntoConstraints = false
    headerTimestampLabel.isAccessibilityElement = false
    outerStack.addArrangedSubview(headerTimestampLabel)

    // The comment button.
    commentButton.setImage(UIImage(named: "ic_comment"), for: .normal)
    commentButton.tintColor = MDCPalette.grey.tint500
    commentButton.inkColor = .clear
    commentButton.autoresizesSubviews = false
    commentButton.contentEdgeInsets = .zero
    commentButton.imageEdgeInsets = .zero
    commentButton.translatesAutoresizingMaskIntoConstraints = false
    commentButton.setContentHuggingPriority(.required, for: .horizontal)
    commentButton.accessibilityLabel = String.noteCaptionHint

    // The menu button.
    menuButton.tintColor = commentButton.tintColor
    menuButton.translatesAutoresizingMaskIntoConstraints = false

    // Button wrapper to give extra padding between the two buttons.
    let buttonWrapper = UIStackView(arrangedSubviews: [commentButton, menuButton])
    buttonWrapper.axis = .horizontal
    buttonWrapper.alignment = .center
    buttonWrapper.spacing = innerButtonSpacing
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false
    outerStack.addArrangedSubview(buttonWrapper)

    // The wrapping stackView for the header.
    addSubview(outerStack)
    outerStack.axis = .horizontal
    outerStack.alignment = .center
    outerStack.spacing = innerHorizontalSpacing
    outerStack.translatesAutoresizingMaskIntoConstraints = false
    outerStack.layoutMargins = UIEdgeInsets(top: ExperimentCardView.headerFooterVerticalPadding,
                                            left: ExperimentCardView.innerHorizontalPadding,
                                            bottom: ExperimentCardView.headerFooterVerticalPadding,
                                            right: ExperimentCardView.innerHorizontalPadding)
    outerStack.isLayoutMarginsRelativeArrangement = true
    outerStack.pinToEdgesOfView(self)

    // The invisible timestamp button.
    timestampButton.translatesAutoresizingMaskIntoConstraints = false
    timestampButton.accessibilityLabel = String.selectTimestampContentDescription

    // Accessibility wrapping view, which sits behind all other elements to allow a user to "grab"
    // anywhere in this view to read the timestamp.
    configureAccessibilityWrappingView(accessibilityWrappingView, traits: .staticText)
  }

}
