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

import third_party_objective_c_material_components_ios_components_CollectionCells_CollectionCells

/// A header cell for the sidebar menu that displays a static image.
class SidebarHeaderCell: MDCCollectionViewCell {

  // MARK: - Constants

  private let headerGap: CGFloat = 10.0

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureCell()
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)!
    configureCell()
  }

  // MARK: - Private

  private func configureCell() {
    let backgroundImage = UIImageView(image: UIImage(named: "sidebar_header_background"))
    contentView.addSubview(backgroundImage)
    backgroundImage.translatesAutoresizingMaskIntoConstraints = false
    backgroundImage.pinToEdgesOfView(contentView, withInsets: UIEdgeInsets(top: 0,
                                                                           left: 0,
                                                                           bottom: headerGap,
                                                                           right: 0))
    if #available(iOS 11.0, *) {
      backgroundImage.accessibilityIgnoresInvertColors = true
    }
  }

}
