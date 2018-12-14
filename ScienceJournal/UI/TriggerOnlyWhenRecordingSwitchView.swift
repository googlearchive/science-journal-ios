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

/// A view for switching whether or not to trigger only when recording, in the trigger edit view.
class TriggerOnlyWhenRecordingSwitchView: TriggerOptionSwitchView {

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var verticalPadding: CGFloat {
    return 59
  }

  // MARK: - Private

  private func configureView() {
    titleText = String.triggerOnlyWhenRecording

    let topBorder = SeparatorView(direction: .horizontal, style: .dark)
    topBorder.translatesAutoresizingMaskIntoConstraints = false
    addSubview(topBorder)
    topBorder.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
    topBorder.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    topBorder.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

    let bottomBorder = SeparatorView(direction: .horizontal, style: .dark)
    bottomBorder.translatesAutoresizingMaskIntoConstraints = false
    addSubview(bottomBorder)
    bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
  }

}
