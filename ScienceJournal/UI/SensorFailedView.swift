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

/// A view that displays an activity indicator and a loading message. Used as a subview of
/// a sensor card cell to indicate the sensor is loading.
class SensorFailedView: UIView {

  private enum Metrics {
    static let stackSpacing: CGFloat = 10
    static let viewInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
  }

  let actionButton = MDCFlatButton()
  let imageView = UIImageView()
  let messageLabel = UILabel()
  private let stackView = UIStackView()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  func showActionButton(withTitle title: String) {
    actionButton.isHidden = false
    actionButton.setTitle(title, for: .normal)
    stackView.insertArrangedSubview(actionButton, at: 2)
  }

  func hideActionButton() {
    actionButton.isHidden = true
    stackView.removeArrangedSubview(actionButton)
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = .white

    // Image view
    imageView.tintColor = MDCPalette.grey.tint800
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage(named: "sensor_error")
    imageView.contentMode = .scaleAspectFit
    imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    // Action button
    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.setTitle(String.actionRetry, for: .normal)

    // Label
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.font = MDCTypography.body1Font()
    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center

    // Stack view
    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(messageLabel)
    stackView.addArrangedSubview(actionButton)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.spacing = Metrics.stackSpacing
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.alignment = .center
    stackView.layoutMargins = Metrics.viewInsets
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.pinToEdgesOfView(self)
  }

}
