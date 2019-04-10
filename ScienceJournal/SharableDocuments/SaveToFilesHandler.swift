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

/// Handles saving experiments, trial data and images to the Files app.
class SaveToFilesHandler: NSObject, UIDocumentPickerDelegate {

  /// The completion called when save to files completes. Called with a bool indicating whether a
  /// file was saved. If not, the user canceled.
  typealias SaveToFilesCompletion = (Bool) -> Void

  private var completion: SaveToFilesCompletion?
  private var documentPicker: UIDocumentPickerViewController?

  /// Presents the save to files browser.
  ///
  /// - Parameters:
  ///   - url: The url of the file to save.
  ///   - presentingViewController: A view controller to present the save to files VC.
  ///   - completion: Called when complete.
  func presentSaveToFiles(forURL url: URL,
                          fromViewController presentingViewController: UIViewController,
                          completion: @escaping SaveToFilesCompletion) {
    self.completion = completion
    let documentPicker = UIDocumentPickerViewController(url: url, in: .exportToService)
    self.documentPicker = documentPicker
    documentPicker.delegate = self
    if UIDevice.current.userInterfaceIdiom == .pad {
      documentPicker.modalPresentationStyle = .formSheet
    }
    presentingViewController.present(documentPicker, animated: true, completion: nil)
  }

  // MARK: - UIDocumentPickerDelegate

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion?(false)
    completion = nil
    documentPicker = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController,
                      didPickDocumentsAt urls: [URL]) {
    completion?(true)
    completion = nil
    documentPicker = nil
  }

}
