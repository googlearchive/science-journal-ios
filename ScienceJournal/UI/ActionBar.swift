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

/// A toolbar that has an action button.
open class ActionBar: UIView {

  /// The button types for the action bar.
  public enum ButtonType {

    /// A check mark button.
    case check

    /// A send button.
    case send

    /// The image for the button type.
    var image: UIImage? {
      switch self {
      case .check:
        return UIImage(named: "select_item_button")
      case .send:
        return UIImage(named: "send_note_button")?.imageFlippedForRightToLeftLayoutDirection()
      }
    }
  }

  /// The button.
  let button = MDCFlatButton(type: .custom)

  /// Designated initializer.
  ///
  /// - Parameter buttonType: The button type for the action bar.
  public init(buttonType: ButtonType) {
    super.init(frame: .zero)
    configureView(with: buttonType)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override open var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: ViewConstants.toolbarHeight)
  }

  private func configureView(with buttonType: ButtonType) {
    addSubview(button)
    button.inkColor = .clear
    button.disabledAlpha = 0.4
    button.setImage(buttonType.image, for: .normal)
    button.tintColor = .white
    button.translatesAutoresizingMaskIntoConstraints = false
    button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }

}
