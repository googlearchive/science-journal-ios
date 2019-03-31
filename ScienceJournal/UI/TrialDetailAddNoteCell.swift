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

protocol TrialDetailAddNoteCellDelegate: class {
  /// Informs the delegate that the add note button was pressed.
  func trialDetailAddNoteCellButtonPressed()
}

/// The cell with a button used to add a new Trial note to an existing Trial.
class TrialDetailAddNoteCell: UICollectionViewCell {

  // MARK: - Constants

  static let buttonInsets = UIEdgeInsets(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0)
  static let verticalPadding: CGFloat = 12.0

  // MARK: - Properties

  weak var delegate: TrialDetailAddNoteCellDelegate?

  let addButton = MDCFlatButton()

  static let height: CGFloat = {
    var totalHeight = String.addNoteButtonText.uppercased().labelHeight(
        withConstrainedWidth: 0,
        font: MDCTypography.buttonFont())
    return ceil(totalHeight + buttonInsets.top + buttonInsets.bottom) +
        TrialDetailAddNoteCell.verticalPadding
  }()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: TrialDetailAddNoteCell.height)
  }

  // MARK: - Private

  private func configureView() {
    contentView.addSubview(addButton)
    addButton.setTitle(String.addNoteButtonText.uppercased(), for: .normal)
    addButton.accessibilityLabel = String.addNoteButtonText
    addButton.setTitleColor(.appBarReviewBackgroundColor, for: .normal)
    addButton.translatesAutoresizingMaskIntoConstraints = false
    addButton.contentEdgeInsets = TrialDetailAddNoteCell.buttonInsets
    addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
  }

  @objc private func addButtonPressed() {
    delegate?.trialDetailAddNoteCellButtonPressed()
  }

}
