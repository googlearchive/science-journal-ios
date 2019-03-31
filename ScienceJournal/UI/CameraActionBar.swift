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

/// The action bar for the camera tab of the drawer. Contains a capture photo button.
class CameraActionBar: UIView {

  /// The take photo button.
  let takePhotoButton = MDCFlatButton(type: .custom)

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: ViewConstants.toolbarHeight)
  }

  // MARK: - Private

  private func configureView() {
    addSubview(takePhotoButton)
    takePhotoButton.setImage(UIImage(named: "take_photo_button"), for: .normal)
    takePhotoButton.tintColor = .white
    takePhotoButton.inkColor = .clear
    takePhotoButton.translatesAutoresizingMaskIntoConstraints = false
    takePhotoButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    takePhotoButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    takePhotoButton.accessibilityLabel = String.btnTakePictureContentDescription
  }

}
