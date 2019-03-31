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

/// A view that shows a more notes label, used in a trial card cell when there are more than two
/// notes for a trial.
class TrialCardMoreNotesView: UIView {

  // MARK: - Properties

  static var height: CGFloat = 56.0

  // MARK: - Public

  init() {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: TrialCardMoreNotesView.height)
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = MDCPalette.grey.tint100

    isAccessibilityElement = true
    accessibilityTraits = .button
    accessibilityLabel = String.loadMoreNotesBtn

    // View more notes button.
    let moreNotesLabel = UILabel()
    addSubview(moreNotesLabel)
    moreNotesLabel.translatesAutoresizingMaskIntoConstraints = false
    moreNotesLabel.textColor = MDCPalette.blue.tint500
    moreNotesLabel.font = MDCTypography.buttonFont()
    moreNotesLabel.text = String.loadMoreNotesBtn.uppercased()
    moreNotesLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0).isActive = true
    moreNotesLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }

}
