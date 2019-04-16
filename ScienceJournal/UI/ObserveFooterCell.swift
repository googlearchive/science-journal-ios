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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons

protocol ObserveFooterCellDelegate: class {
  func observeFooterAddButtonPressed()
}

/// A cell with a plus button for adding more sensors.
class ObserveFooterCell: UICollectionViewCell {

  static let cellHeight: CGFloat = 58.0

  var addButton = MDCFlatButton()
  weak var delegate: ObserveFooterCellDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureCell()
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)!
    configureCell()
  }

  // MARK: - View

  private func configureCell() {
    // Menu button
    addButton.setImage(UIImage(named: "ic_add_circle"), for: .normal)
    addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
    addButton.tintColor = .lightGray
    addButton.inkColor = .clear
    addButton.autoresizesSubviews = false
    addButton.contentEdgeInsets = .zero
    addButton.imageEdgeInsets = .zero
    addButton.translatesAutoresizingMaskIntoConstraints = false
    addButton.accessibilityLabel = String.btnAddSensorCardDescription
    addSubview(addButton)
    configureConstraints()
  }

  private func configureConstraints() {
    addButton.widthAnchor.constraint(equalToConstant: ObserveFooterCell.cellHeight).isActive = true
    addButton.heightAnchor.constraint(equalToConstant: ObserveFooterCell.cellHeight).isActive = true
    addButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    addButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
  }

  // MARK: - User actions

  @objc func addButtonPressed() {
    delegate?.observeFooterAddButtonPressed()
  }

}
