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

import third_party_objective_c_material_components_ios_components_Typography_Typography

// TODO: This VC still needs a final image.
final class ExperimentDetailEmptyStateViewController: UIViewController {

  private enum Metrics {
    static let labelTextColor: UIColor = .lightGray
    static let labelFont = MDCTypography.fontLoader().boldFont?(ofSize: 16)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let backgroundImageView =
      UIImageView(image: UIImage(named: "action_area_add_notes"))
    view.addSubview(backgroundImageView)
    backgroundImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-40)
    }

    let label = UILabel()
    label.font = Metrics.labelFont
    label.text = String.actionAreaAddMoreNotes
    label.textColor = Metrics.labelTextColor
    view.addSubview(label)
    label.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.top.equalTo(backgroundImageView.snp.bottom)
    }
  }

  override var description: String {
    return "\(type(of: self))"
  }

}
