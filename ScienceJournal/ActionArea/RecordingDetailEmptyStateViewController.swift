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
// This VC represents the empty state detail view controller when the user is viewing the trial
// detail view controller in landscape orientation.
final class RecordingDetailEmptyStateViewController: UIViewController {

  private enum Metrics {
    static let stackSpacing: CGFloat = 10
    static let labelTextColor: UIColor = .trialHeaderDefaultBackgroundColor
    static let labelFont = MDCTypography.fontLoader().boldFont?(ofSize: 16)
  }

  let label: UILabel = {
    let label = UILabel()
    label.font = Metrics.labelFont
    label.textColor = Metrics.labelTextColor
    return label
  }()

  var timestampString: String? {
    didSet {
      updateLabel()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let backgroundImageView =
      UIImageView(image: UIImage(named: "action_area_add_note_placeholder"))
    view.addSubview(backgroundImageView)
    backgroundImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-40)
    }

    let imageView = UIImageView(image: UIImage(named: "ic_access_time"))
    updateLabel()
    let stackView = UIStackView(arrangedSubviews: [imageView, label])
    stackView.spacing = Metrics.stackSpacing
    view.addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.top.equalTo(backgroundImageView.snp.bottom)
    }
  }

  override var description: String {
    return "\(type(of: self))"
  }

  private func updateLabel() {
    label.text = String.localizedAddNoteTo(with: timestampString ?? "0:00")
  }

}
