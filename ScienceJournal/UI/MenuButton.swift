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

/// An MDCFlatButton with horizontal dots used as a menu button throughout Science Journal.
class MenuButton: MDCFlatButton {

  /// The width and height dimension of the icons used in the header and footer. Used in height
  /// calculation.
  static let menuIconDimension: CGFloat = 24.0

  // MARK: - Public

  init() {
    super.init(frame: .zero)
    configureButton()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureButton()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: MenuButton.menuIconDimension, height: MenuButton.menuIconDimension)
  }

  // MARK: - Private

  private func configureButton() {
    accessibilityLabel = String.menuBtnContentDescription
    accessibilityHint = String.menuBtnContentDetails
    inkColor = .clear
    setImage(UIImage(named: "ic_more_horiz"), for: .normal)
    tintColor = .white
    autoresizesSubviews = false
    contentEdgeInsets = .zero
    imageEdgeInsets = .zero
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.required, for: .horizontal)
  }

}
