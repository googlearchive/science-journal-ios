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

extension PopUpMenuAction {

  /// Returns an action that shares a file path via the activity view controller.
  ///
  /// - Parameters:
  ///   - filePath: A string path to a file.
  ///   - presentingViewController: A view controller to present the activity VC.
  ///   - sourceView: For iPad only, the view to which the popover should point.
  /// - Returns: A pop up menu action.
  static func share(withFilePath filePath: String,
                    presentingViewController: UIViewController,
                    sourceView: UIView) -> PopUpMenuAction {
    return PopUpMenuAction(
      title: String.sendCopyAction,
      icon: UIImage(named: "ic_share"),
      handler: { (_) in
        let url = URL(fileURLWithPath: filePath)
        let activityVC = UIActivityViewController(activityItems: [url],
                                                  applicationActivities: nil)
        if let presentationController = activityVC.popoverPresentationController {
          // Configure as a popover on iPad if necessary.
          presentationController.sourceView = sourceView
          presentationController.sourceRect = sourceView.bounds
        }
        presentingViewController.present(activityVC, animated: true)
    })
  }

  /// Returns an action that saves a file path to files.
  ///
  /// - Parameters:
  ///   - filePath: A string path to a file.
  ///   - presentingViewController: A view controller to present the activity VC.
  ///   - saveToFilesHandler: The save to files handler.
  /// - Returns: A pop up menu action.
  static func saveToFiles(withFilePath filePath: String,
                          presentingViewController: UIViewController,
                          saveToFilesHandler: SaveToFilesHandler) -> PopUpMenuAction {
    return PopUpMenuAction(title: String.saveToFilesTitle,
                           icon: UIImage(named: "ic_save_alt"),
                           accessibilityHint: String.saveToFilesContentDescription,
                           handler: { (_) in
      saveToFilesHandler.presentSaveToFiles(
          forURL: URL(fileURLWithPath: filePath),
          fromViewController: presentingViewController) { result in
        switch result {
        case .saved:
          showSnackbar(withMessage: String.saveToFilesSingleSuccessMessage)
        case .cancelled:
          break
        }
      }
    })
  }

  /// Returns an action that shares an experiment via the activity view controller.
  ///
  /// - Parameters:
  ///   - experiment: An experiment.
  ///   - presentingViewController: A view controller to present the activity VC.
  ///   - sourceView: For iPad only, the view to which the popover should point.
  ///   - documentManager: The document manager.
  /// - Returns: A pop up menu action.
  static func exportExperiment(_ experiment: Experiment,
                               presentingViewController: UIViewController,
                               sourceView: UIView,
                               documentManager: DocumentManager) -> PopUpMenuAction {
    return PopUpMenuAction(title: String.sendCopyAction,
                           icon: UIImage(named: "ic_share"),
                           handler: { _ in
      let spinnerViewController = SpinnerViewController()
      spinnerViewController.present(fromViewController: presentingViewController)

      func exportExperiment() {
        documentManager.createExportDocument(forExperimentWithID: experiment.ID,
                                             completion: { url in
          spinnerViewController.dismissSpinner(completion: {
            guard let url = url else {
              // The export failed, show an error message.
              showSnackbar(withMessage: String.exportError)
              return
            }

            let activityVC = UIActivityViewController(activityItems: [url],
                                                      applicationActivities: nil)
            activityVC.completionWithItemsHandler = { (_, _, _, _) in
              documentManager.finishedWithExportDocument(atURL: url)
            }
            if let presentationController = activityVC.popoverPresentationController {
              // Configure as a popover on iPad if necessary.
              presentationController.sourceView = sourceView
              presentationController.sourceRect = sourceView.bounds
            }
            presentingViewController.present(activityVC, animated: true)
          })
        })
      }

      documentManager.experimentIsReadyForExport(experiment, completion: { (isReady) in
        if isReady {
          exportExperiment()
        } else {
          presentExperimentNotFinishedDownloadingAlert(fromViewController: spinnerViewController,
                                                       cancelHandler: { (_) in
            spinnerViewController.dismissSpinner()
          },
                                                       confirmHandler: { (_) in
            exportExperiment()
          })
        }
      })
    })
  }

  /// Returns an action that saves an experiment to files.
  ///
  /// - Parameters:
  ///   - experiment: An experiment.
  ///   - presentingViewController: A view controller to present the activity VC.
  ///   - documentManager: The document manager.
  ///   - saveToFilesHandler: The save to files handler.
  /// - Returns: A pop up menu action.
  static func saveExperimentToFiles(_ experiment: Experiment,
                                    presentingViewController: UIViewController,
                                    documentManager: DocumentManager,
                                    saveToFilesHandler: SaveToFilesHandler) -> PopUpMenuAction {
    return PopUpMenuAction(title: String.saveToFilesTitle,
                           icon: UIImage(named: "ic_save_alt"),
                           accessibilityHint: String.saveToFilesContentDescription,
                           handler: { _ in
      saveToFilesHandler.presentSaveToFiles(forExperiment: experiment,
                                            documentManager: documentManager,
                                            presentingViewController: presentingViewController)
    })
  }

  // MARK: - Helpers

  private static func presentExperimentNotFinishedDownloadingAlert(
      fromViewController presentingViewController: UIViewController,
      cancelHandler: @escaping MDCActionHandler,
      confirmHandler: @escaping MDCActionHandler) {
    let alertController =
      MDCAlertController(title: String.experimentNotFinishedDownloadingTitle,
                         message: String.experimentNotFinishedDownloadingMessage)
    let cancelAction = MDCAlertAction(title: String.actionCancel, handler: cancelHandler)
    let okAction = MDCAlertAction(title: String.experimentNotFinishedDownloadingConfirmButton,
                                  handler: confirmHandler)
    alertController.addAction(cancelAction)
    alertController.addAction(okAction)
    alertController.accessibilityViewIsModal = true
    presentingViewController.present(alertController, animated: true)
  }

}
