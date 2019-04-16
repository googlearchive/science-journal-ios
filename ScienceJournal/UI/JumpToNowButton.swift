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

import Foundation

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// A floating jump-to-now button.
class JumpToNowButton: MDCFloatingButton {

  private var diameter: CGFloat = 48

  convenience init() {
    self.init(frame: .zero, shape: .default)
  }

  override init(frame: CGRect, shape: MDCFloatingButtonShape) {
    super.init(frame: frame, shape: shape)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  private func configureView() {
    accessibilityLabel = String.btnResetDescription
    tintColor = .white
    setImage(UIImage(named: "ic_last_page"), for: .normal)
    setBackgroundColor(MDCPalette.purple.tint900, for: .normal)
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: diameter, height: diameter)
  }

}
