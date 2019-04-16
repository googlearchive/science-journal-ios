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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

extension VisualTriggerView {

  /// The view in the visual trigger view that shows that a trigger fired.
  class TriggerFiredView: UIView {

    // The title label. Must be layed out.
    let titleLabel = UILabel()

    override init(frame: CGRect) {
      super.init(frame: frame)
      configureView()
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      configureView()
    }

    private func configureView() {
      clipsToBounds = true

      backgroundColor = MDCPalette.red.tint500

      titleLabel.font = MDCTypography.body2Font()
      titleLabel.text = String.triggerFiredText
      titleLabel.textColor = .white
      addSubview(titleLabel)
    }

  }

}
