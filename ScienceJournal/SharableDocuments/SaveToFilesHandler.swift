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
import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs

/// Handles saving experiments, trial data and images to the Files app.
class SaveToFilesHandler: NSObject, UIDocumentPickerDelegate {

  /// The completion called when save to files completes. Called with a bool indicating whether a
  /// file was saved. If not, the user canceled.
  typealias SaveToFilesCompletion = (Bool) -> Void

  private var completion: SaveToFilesCompletion?
  private var documentPicker: UIDocumentPickerViewController?

  /// Presents the save to files browser for a URL.
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

  /// Presents the save to files browser for an experiment.
  ///
  /// - Parameters:
  ///   - experiment: The experiment to save.
  ///   - documentManager: The document manager.
  ///   - presentingViewController: A view controller to present the save to files VC.
  func presentSaveToFiles(forExperiment experiment: Experiment,
                          documentManager: DocumentManager,
                          presentingViewController: UIViewController) {
    let spinnerViewController = SpinnerViewController()

    func saveExperimentToFiles() {
      documentManager.createExportDocument(forExperimentWithID: experiment.ID) { url in
        spinnerViewController.dismissSpinner {
          guard let url = url else {
            // The export failed, show an error message.
            showSnackbar(withMessage: String.saveToFilesSingleErrorMessage)
            return
          }

          self.presentSaveToFiles(forURL: url,
                                  fromViewController: presentingViewController) { fileWasSaved in
            if fileWasSaved {
              showSnackbar(withMessage: String.saveToFilesSingleSuccessMessage)
            }
            documentManager.finishedWithExportDocument(atURL: url)
          }
        }
      }
    }

    spinnerViewController.present(fromViewController: presentingViewController) {
      documentManager.experimentIsReadyForExport(experiment) { isReady in
        if isReady {
          saveExperimentToFiles()
        } else {
          spinnerViewController.dismissSpinner {
            let alertController =
                MDCAlertController(title: String.experimentNotFinishedDownloadingTitle,
                                   message: String.experimentNotFinishedDownloadingMessage)
            let cancelAction = MDCAlertAction(title: String.actionCancel)
            let okAction =
                MDCAlertAction(title: String.experimentNotFinishedDownloadingConfirmButton) { _ in
              saveExperimentToFiles()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            alertController.accessibilityViewIsModal = true
            presentingViewController.present(alertController, animated: true)
          }
        }
      }
    }
  }

  // MARK: - Private

  private func handleDocumentPicked() {
    completion?(true)
    completion = nil
    documentPicker = nil
  }

  // MARK: - UIDocumentPickerDelegate

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion?(false)
    completion = nil
    documentPicker = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController,
                      didPickDocumentsAt urls: [URL]) {
    handleDocumentPicked()
  }

  // Needed for iOS 10 support. When it is no longer supported, this can be removed.
  func documentPicker(_ controller: UIDocumentPickerViewController,
                      didPickDocumentAt url: URL) {
    handleDocumentPicked()
  }

}
