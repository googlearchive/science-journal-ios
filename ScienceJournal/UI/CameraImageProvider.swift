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

protocol CameraImageProviderDelegate: class {
  func cameraImageProviderDidPick(imageData: Data, metadata: NSDictionary?)
  func cameraImageProviderDidComplete()
}

/// A class that provides the system's image picker and provides the user's picked image
/// to the delegate after processing. The caller/delegate is responsible for presenting and
/// dismissing the image picker using the `cameraViewController` property and callbacks.
final class CameraImageProvider: NSObject {

  weak var delegate: CameraImageProviderDelegate?

  private(set) lazy var cameraViewController: UIImagePickerController = {
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.sourceType = .camera
    return imagePicker
  }()

}

// MARK: - UIImagePickerControllerDelegate

extension CameraImageProvider: UIImagePickerControllerDelegate {

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    delegate?.cameraImageProviderDidComplete()
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    guard let image = info[.originalImage] as? UIImage,
      let imageData = image.jpegData(compressionQuality: 0.8) else {
        delegate?.cameraImageProviderDidComplete()
        return
    }

    let metadata = info[.mediaMetadata] as? NSDictionary
    delegate?.cameraImageProviderDidPick(imageData: imageData, metadata: metadata)
  }

}

// MARK: - UINavigationControllerDelegate

extension CameraImageProvider: UINavigationControllerDelegate {}
