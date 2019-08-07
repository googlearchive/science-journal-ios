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

// TODO: This VC still needs an image and final copy. We're also going to need an empty state
//       VC for recording details, which will need to update its label in response to user input.
//       We'll want to either enhance this one to support that or create a separate VC.
final class ExperimentDetailEmptyStateViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let label = UILabel()
    // TODO: Verify this string and localize the final version.
    label.text = "Add more observation notes"
    label.textColor = .lightGray
    view.addSubview(label)
    label.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
    }
  }

  override var description: String {
    return "\(type(of: self))"
  }

}
