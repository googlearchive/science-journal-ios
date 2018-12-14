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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view with a dark background and white text for showing an error message next to a text field.
class ErrorDialog: UIView {

  // MARK: - Properties

  let textLabel = UILabel()

  private let transformForHidden = CGAffineTransform(scaleX: 0.5, y: 0.5)
  private let transformForVisible = CGAffineTransform.identity

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  // MARK: - Public

  /// Shows the error dialog, animated.
  func show() {
    transform = transformForHidden
    UIView.animate(withDuration: 0.2) {
      self.alpha = 1
      self.transform = self.transformForVisible
    }
  }

  /// Hides the error dialog, animated.
  func hide() {
    UIView.animate(withDuration: 0.2) {
      self.alpha = 0
      self.transform = self.transformForHidden
    }
  }

  // MARK: - Private

  private func configureView() {
    alpha = 0
    backgroundColor = UIColor(white: 0, alpha: 0.9)

    textLabel.font = MDCTypography.captionFont()
    textLabel.numberOfLines = 2
    textLabel.textColor = .white
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.adjustsFontSizeToFitWidth = true
    addSubview(textLabel)
    textLabel.pinToEdgesOfView(self,
                               withInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
  }

}
