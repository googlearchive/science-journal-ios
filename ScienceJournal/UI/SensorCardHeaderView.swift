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

/// The header view for the sensor card cell. It contains a button to show/hide the sensor picker, a
/// title, button to show the sensor description, and a button to show options.
class SensorCardHeaderView: UIView {

  // MARK: - Properties

  let expandButton = RotatingExpandButton(arrowDirection: .down)
  let menuButton = MenuButton()
  let stackView = UIStackView()
  let titleLabel = UILabel()

  private lazy var audioImageView: UIImageView = {
    let audioImageView = UIImageView(image: UIImage(named: "ic_music_note"))
    audioImageView.tintColor = .white
    audioImageView.translatesAutoresizingMaskIntoConstraints = false
    audioImageView.widthAnchor.constraint(
        equalToConstant: SensorCardHeaderView.audioImageViewDimension).isActive = true
    audioImageView.heightAnchor.constraint(
        equalToConstant: SensorCardHeaderView.audioImageViewDimension).isActive = true
    return audioImageView
  }()

  static let audioImageViewDimension: CGFloat = 24
  static let iconDimension: CGFloat = 24
  static let margins = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
  let stackViewSpacing: CGFloat = 12

  // MARK: - UIView

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: SensorCardHeaderView.height)
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Whether or not to show the audio icon.
  ///
  /// - Parameter show: Whether or not the audio icon should show.
  func setShowAudioIcon(_ show: Bool) {
    if show {
      audioImageView.alpha = 0
      stackView.insertArrangedSubview(self.audioImageView, at: 2)
    }
    UIView.animate(withDuration: 0.2,
                   animations: { self.audioImageView.alpha = show ? 1 : 0 },
                   completion: { (_) in
      if !show {
        self.stackView.removeArrangedSubview(self.audioImageView)
        self.audioImageView.removeFromSuperview()
      }
    })
  }

  /// The height of the header view.
  static var height: CGFloat {
    return iconDimension + margins.top + margins.bottom
  }

  // MARK: - Private

  private func configureView() {
    stackView.alignment = .center
    stackView.axis = .horizontal
    stackView.spacing = stackViewSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.layoutMargins = SensorCardHeaderView.margins
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.pinToEdgesOfView(self)

    // Expand button.
    expandButton.tintColor = .white
    expandButton.inkColor = .clear
    expandButton.contentEdgeInsets = .zero
    expandButton.imageEdgeInsets = .zero
    expandButton.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(expandButton)
    expandButton.setContentHuggingPriority(.required, for: .horizontal)
    expandButton.hitAreaInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)

    // Title label.
    titleLabel.textColor = .white
    titleLabel.font = MDCTypography.body2Font()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    stackView.addArrangedSubview(titleLabel)

    // Menu button
    stackView.addArrangedSubview(menuButton)
  }

}
