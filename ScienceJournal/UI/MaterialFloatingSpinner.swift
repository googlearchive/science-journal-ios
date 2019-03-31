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

/// A circular spinner contained in a shadowed, circular view. Best placed on top of cells or views
/// to indicate loading after user interaction.
class MaterialFloatingSpinner: UIView {

  enum Metrics {
    static let spinnerDimension: CGFloat = 32.0
    static let spinnerPadding: CGFloat = 6.0
    static let spinnerBackgroundDimenion = Metrics.spinnerDimension + Metrics.spinnerPadding
  }

  // MARK: - Properties

  override var intrinsicContentSize: CGSize {
    return CGSize(width: Metrics.spinnerBackgroundDimenion,
                  height: Metrics.spinnerBackgroundDimenion)
  }

  /// The mode of the spinner.
  var indicatorMode: MDCActivityIndicatorMode {
    set {
      spinner.indicatorMode = newValue
    }
    get {
      return spinner.indicatorMode
    }
  }

  /// The progress for the spinner, when in determinate mode. The range is 0.0 to 1.0.
  var progress: Float {
    set {
      spinner.progress = newValue
    }
    get {
      return spinner.progress
    }
  }

  private let spinner = MDCActivityIndicator()
  private let spinnerBackground = ShadowedView()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  func startAnimating() {
    self.spinner.startAnimating()
    self.spinnerBackground.alpha = 1
  }

  func stopAnimating() {
    self.spinnerBackground.alpha = 0
    self.spinner.stopAnimating()
  }

  // MARK: - Private

  private func configureView() {
    addSubview(spinnerBackground)
    spinnerBackground.backgroundColor = .white
    spinnerBackground.translatesAutoresizingMaskIntoConstraints = false
    spinnerBackground.widthAnchor.constraint(
        equalToConstant: Metrics.spinnerBackgroundDimenion).isActive = true
    spinnerBackground.heightAnchor.constraint(
        equalToConstant: Metrics.spinnerBackgroundDimenion).isActive = true
    spinnerBackground.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    spinnerBackground.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    spinnerBackground.layer.cornerRadius = 19.0
    spinnerBackground.setElevation(points: ShadowElevation.refresh.rawValue)
    spinnerBackground.alpha = 0  // Hidden by default.

    spinnerBackground.addSubview(spinner)
    spinner.indicatorMode = .indeterminate
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.widthAnchor.constraint(equalToConstant: Metrics.spinnerDimension).isActive = true
    spinner.heightAnchor.constraint(equalToConstant: Metrics.spinnerDimension).isActive = true
    spinner.centerXAnchor.constraint(equalTo: spinnerBackground.centerXAnchor).isActive = true
    spinner.centerYAnchor.constraint(equalTo: spinnerBackground.centerYAnchor).isActive = true
  }

}
