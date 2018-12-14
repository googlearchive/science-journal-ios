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

import third_party_objective_c_material_components_ios_components_ActivityIndicator_ActivityIndicator
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view that displays an activity indicator and a loading message. Used as a subview of
/// a sensor card cell to indicate the sensor is loading.
class SensorLoadingView: UIView {

  private enum Metrics {
    static let activityRadius: CGFloat = 38
    static let activityStroke: CGFloat = 8
    static let stackSpacing: CGFloat = 20
  }

  /// The activity indicator.
  let activityView = MDCActivityIndicator()
  private let messageLabel = UILabel()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = .white

    // Label
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.font = MDCTypography.body1Font()
    messageLabel.text = String.sensorCardLoadingText
    messageLabel.numberOfLines = 0

    // Activity indicator
    activityView.translatesAutoresizingMaskIntoConstraints = false
    activityView.radius = Metrics.activityRadius
    activityView.strokeWidth = Metrics.activityStroke

    let stackView = UIStackView(arrangedSubviews: [activityView, messageLabel])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.spacing = Metrics.stackSpacing
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }

}
