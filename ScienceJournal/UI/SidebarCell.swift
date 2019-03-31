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

/// Cell used in the sidebar to display a menu option with a title and icon.
class SidebarCell: UICollectionViewCell {

  // MARK: - Constants

  let iconDimension: CGFloat = 24.0
  let iconPadding: CGFloat = 16.0
  let titlePadding: CGFloat = 72.0

  // MARK: - Properties

  let iconView = UIImageView()
  let titleLabel = UILabel()
  private let inkView = MDCInkView()
  private let statusBarCoverView = UIView()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureCell()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureCell()
  }

  // MARK: - Private

  private func configureCell() {
    isAccessibilityElement = true
    accessibilityTraits = .button

    inkView.inkColor = UIColor(white: 0, alpha: 0.1)
    inkView.frame = contentView.bounds
    contentView.addSubview(inkView)

    // Icon
    contentView.addSubview(iconView)
    iconView.tintColor = UIColor(red: 0.451, green: 0.451, blue: 0.451, alpha: 1.0)
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: iconPadding).isActive = true
    iconView.widthAnchor.constraint(equalToConstant: iconDimension).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: iconDimension).isActive = true

    // Title label
    contentView.addSubview(titleLabel)
    titleLabel.textColor = .black
    titleLabel.font = MDCTypography.body2Font()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor).isActive = true
    titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor,
                                        constant: titlePadding).isActive = true
  }

  // MARK: Ink

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if let touch = touches.first {
      inkView.startTouchBeganAnimation(at: touch.location(in: contentView), completion: nil)
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    if let touch = touches.first {
      inkView.startTouchEndedAnimation(at: touch.location(in: contentView), completion: nil)
    }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    inkView.cancelAllAnimations(animated: true)
  }

}
