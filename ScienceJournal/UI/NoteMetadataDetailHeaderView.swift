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

/// The header view that appears above metadata detail cells in note detail views.
class NoteMetadataDetailHeaderView: UICollectionReusableView {

  // MARK: - Constants

  static let edgeInsets = UIEdgeInsets(top: 8.0, left: 0, bottom: 0, right: 16.0)

  // MARK: - Properties

  static let height: CGFloat = {
    return NoteMetadataDetailHeaderView.edgeInsets.top +
        NoteMetadataDetailHeaderView.edgeInsets.bottom +
        String.detailsHeader.labelHeight(withConstrainedWidth: 0,
                                         font: MDCTypography.body2Font())
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

  // MARK: - Private

  private func configureView() {
    let headerLabel = UILabel()
    addSubview(headerLabel)
    headerLabel.text = String.detailsHeader
    headerLabel.font = MDCTypography.body2Font()
    headerLabel.textColor = MDCPalette.grey.tint500
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    headerLabel.pinToEdgesOfView(self, withInsets: NoteMetadataDetailHeaderView.edgeInsets)
  }

}
