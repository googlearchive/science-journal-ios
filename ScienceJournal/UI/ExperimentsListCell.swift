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

protocol ExperimentsListCellDelegate: class {
  /// Tells the delegate the user tapped the menu button for a cell.
  func menuButtonPressedForCell(_ cell: ExperimentsListCell, attachmentButton: UIButton)
}

/// A cell displaying the photo, title and menu for an experiment that has been synced to an
/// account. It also displays a menu button.
class ExperimentsListCell: ExperimentsListCellBase {

  // MARK: - Properties

  private weak var delegate: ExperimentsListCellDelegate?
  private let menuButton = MenuButton()

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
                                      delegate: ExperimentsListCellDelegate,
                                      image: UIImage?) {
    self.delegate = delegate
    configureForExperimentOverview(experimentOverview, image: image)
  }

  /// The item size for the cell in a width.
  ///
  /// Parameter width: The width of the item.
  /// Returns: The size for the item.
  static func itemSize(inWidth width: CGFloat) -> CGSize {
    // The item should be 10% taller than its width.
    return CGSize(width: width, height: width * 1.1)
  }

  // MARK: - Private

  private func configureView() {
    // Menu button.
    titleStack.addArrangedSubview(menuButton)
    menuButton.tintColor = .black
    menuButton.hitAreaInsets = UIEdgeInsets(top: -30, left: -30, bottom: -10, right: -10)
    menuButton.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuButton.isAccessibilityElement = true
  }

  // MARK: - User actions

  @objc private func menuButtonPressed() {
    delegate?.menuButtonPressedForCell(self, attachmentButton: menuButton)
  }

}
