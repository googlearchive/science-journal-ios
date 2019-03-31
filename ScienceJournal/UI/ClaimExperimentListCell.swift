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

protocol ClaimExperimentListCellDelegate: class {
  /// Tells the delegate the user tapped the add to Drive button for a cell.
  ///
  /// - Parameter cell: The claim experiment list cell.
  func claimExperimentListCellPresssedAddToDriveButton(_ cell: ClaimExperimentListCell)

  /// Tells the delegate the user tapped the share button for a cell.
  ///
  /// - Parameters:
  ///   - cell: The claim experiment list cell.
  ///   - shareButton: The share button.
  func claimExperimentListCell(_ cell: ClaimExperimentListCell,
                               presssedShareButton shareButton: UIButton)

  /// Tells the delegate the user tapped the delete button for a cell.
  ///
  /// - Parameter cell: The claim experiment list cell.
  func claimExperimentListCellPresssedDeleteButton(_ cell: ClaimExperimentListCell)
}

/// A cell displaying an experiment that needs to be claimed by a user. It also displays buttons for
/// adding the experiment to drive, sharing it or deleting it.
class ClaimExperimentListCell: ExperimentsListCellBase {

  // MARK: - Properties

  private weak var delegate: ClaimExperimentListCellDelegate?
  private let shareButton = MDCFlatButton()

  private enum Metrics {
    static let buttonEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    static let buttonHeight: CGFloat = 40
    static let iconDimension: CGFloat = 24 + Metrics.buttonEdgeInsets.left +
        Metrics.buttonEdgeInsets.right
  }

  override var titleAndButtonsHeight: CGFloat {
    return super.titleAndButtonsHeight + Metrics.buttonHeight
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// Configures a cell for a given experiment overview and background color.
  ///
  /// - Parameters:
  ///   - experimentOverview: The experiment overview to use for configuring the title.
  ///   - delegate: The delegate for this cell.
  ///   - image: The image for this experiment or nil.
  func configureForExperimentOverview(_ experimentOverview: ExperimentOverview,
                                      delegate: ClaimExperimentListCellDelegate,
                                      image: UIImage?,
                                      showShareOption: Bool) {
    self.delegate = delegate
    configureForExperimentOverview(experimentOverview, image: image)
    shareButton.isHidden = !showShareOption
  }

  /// The item size for the cell in a width.
  ///
  /// Parameter width: The width of the item.
  /// Returns: The size for the item.
  static func itemSize(inWidth width: CGFloat) -> CGSize {
    // The item should be 10% taller than its width, plus the height of the additional buttons.
    return CGSize(width: width, height: width * 1.1 + Metrics.buttonHeight)
  }

  // MARK: - Private

  private func configureView() {
    outerStack.addArrangedSubview(SeparatorView(direction: .horizontal, style: .dark))

    // Claim buttons.
    let addButton = MDCFlatButton()
    addButton.setImage(UIImage(named: "ic_add_to_drive"), for: .normal)
    addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
    addButton.accessibilityLabel = String.claimExperimentsAddToDriveContentDescription

    shareButton.setImage(UIImage(named: "ic_share"), for: .normal)
    shareButton.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
    shareButton.accessibilityLabel = String.claimExperimentsShareContentDescription

    let deleteButton = MDCFlatButton()
    deleteButton.setImage(UIImage(named: "ic_delete"), for: .normal)
    deleteButton.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
    deleteButton.accessibilityLabel = String.claimExperimentsDeleteContentDescription

    [addButton, shareButton, deleteButton].forEach {
      $0.setImageTintColor(MDCPalette.grey.tint600, for: .normal)
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.widthAnchor.constraint(equalToConstant: Metrics.iconDimension).isActive = true
      $0.heightAnchor.constraint(equalToConstant: Metrics.iconDimension).isActive = true
      $0.contentEdgeInsets = .zero
      $0.imageEdgeInsets = Metrics.buttonEdgeInsets
    }

    let claimButtonsStack = UIStackView(arrangedSubviews: [addButton, shareButton, deleteButton])
    claimButtonsStack.alignment = .center
    claimButtonsStack.distribution = .equalCentering
    claimButtonsStack.translatesAutoresizingMaskIntoConstraints = false
    outerStack.addArrangedSubview(claimButtonsStack)
    claimButtonsStack.heightAnchor.constraint(
        equalToConstant: Metrics.buttonHeight - SeparatorView.Metrics.dimension).isActive = true
  }

  // MARK: - User actions

  @objc private func addButtonPressed() {
    delegate?.claimExperimentListCellPresssedAddToDriveButton(self)
  }

  @objc private func shareButtonPressed(sender: UIButton) {
    delegate?.claimExperimentListCell(self, presssedShareButton: sender)
  }

  @objc private func deleteButtonPressed() {
    delegate?.claimExperimentListCellPresssedDeleteButton(self)
  }

}
