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

/// A view controller that wraps a PhotoLibraryViewController to give it an app bar.
class EditExperimentPhotoLibraryViewController: MaterialHeaderViewController,
                                                ImageSelectorDelegate {

  // MARK: - Properties

  weak var delegate: ImageSelectorDelegate?
  private let photoLibraryViewController: StandalonePhotoLibraryViewController

  // MARK: - Public

  override init(analyticsReporter: AnalyticsReporter) {
    photoLibraryViewController =
        StandalonePhotoLibraryViewController(analyticsReporter: analyticsReporter)
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    title = String.choosePhotoButtonText

    accessibilityViewIsModal = true

    let closeMenuItem = MaterialCloseBarButtonItem(target: self,
                                                   action: #selector(closeButtonPressed))
    navigationItem.leftBarButtonItem = closeMenuItem

    guard let photoLibraryView = photoLibraryViewController.view else { return }
    photoLibraryViewController.delegate = self
    addChild(photoLibraryViewController)
    view.addSubview(photoLibraryView)
    photoLibraryView.translatesAutoresizingMaskIntoConstraints = false
    photoLibraryView.topAnchor
      .constraint(equalTo: appBar.headerViewController.view.bottomAnchor).isActive = true
    photoLibraryView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    photoLibraryView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    photoLibraryView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    appBar.headerViewController.updateTopLayoutGuide()
  }

  override func accessibilityPerformEscape() -> Bool {
    dismiss(animated: true)
    return true
  }

  // MARK: - ImageSelectorDelegate
  func imageSelectorDidCreateImageData(
    _ imageDatas: [(imageData: Data, metadata: NSDictionary?)]) {
    guard imageDatas.count == 1 else {
      fatalError("Only one image can be selected for the experiment cover.")
    }

    delegate?.imageSelectorDidCreateImageData(imageDatas)
    dismiss(animated: true)
  }

  func imageSelectorDidCancel() {}

  // MARK: - Private

  // MARK: - User actions

  @objc private func closeButtonPressed() {
    dismiss(animated: true)
  }

}
