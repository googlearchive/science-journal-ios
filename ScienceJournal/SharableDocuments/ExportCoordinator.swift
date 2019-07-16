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

protocol ExportCoordinatorDelegate: class {

  /// Informs the delegate to show the PDF export flow for an experiment.
  ///
  /// - Parameters:
  ///   - experiment: The experiment to be exported.
  ///   - completionHandler: The completion handler.
  func showPDFExportFlow(for experiment: Experiment,
                         completionHandler: @escaping PDFExportController.CompletionHandler)
}

// A coordinator to manage and centralize UI flows for exporting an experiment into SJ or PDF docs.
final class ExportCoordinator {

  let exportType: UserExportType
  weak var delegate: ExportCoordinatorDelegate?

  private let saveToFilesHandler = SaveToFilesHandler()
  private let fileTypeSelectionHandler = FileTypeSelectionHandler()

  init(exportType: UserExportType) {
    self.exportType = exportType
  }

  func presentExportFlow(for experiment: Experiment,
                         from presentingViewController: UIViewController,
                         documentManager: DocumentManager,
                         sourceView: UIView) {
    switch exportType {
    case .saveToFiles:
      presentFlowForSaveToFiles(for: experiment,
                                from: presentingViewController,
                                documentManager: documentManager,
                                sourceView: sourceView)
    case .share:
      presentFlowForShare(for: experiment,
                          from: presentingViewController,
                          documentManager: documentManager,
                          sourceView: sourceView)
    }
  }

  private func presentFlowForSaveToFiles(for experiment: Experiment,
                                         from presentingViewController: UIViewController,
                                         documentManager: DocumentManager,
                                         sourceView: UIView) {
    #if FEATURE_PDF_EXPORT
    fileTypeSelectionHandler.showFileTypeSelection(from: presentingViewController,
                                                   exportType: .saveToFiles) { (fileTypeResult) in
      switch fileTypeResult {
      case .pdf:
        self.showPDFExport(for: experiment,
                           from: presentingViewController,
                           sourceView: sourceView)
      case .sj:
        self.showSaveToFiles(for: experiment,
                             from: presentingViewController,
                             documentManager: documentManager)
      }
    }
    #else
    showSaveToFiles(for: experiment,
                    from: presentingViewController,
                    documentManager: documentManager)
    #endif
  }

  private func presentFlowForShare(for experiment: Experiment,
                                   from presentingViewController: UIViewController,
                                   documentManager: DocumentManager,
                                   sourceView: UIView) {
    #if FEATURE_PDF_EXPORT
    fileTypeSelectionHandler.showFileTypeSelection(from: presentingViewController,
                                                   exportType: .share) { (fileTypeResult) in
      switch fileTypeResult {
      case .pdf:
        self.showPDFExport(for: experiment,
                           from: presentingViewController,
                           sourceView: sourceView)
      case .sj:
        self.showExportExperimentFlow(for: experiment,
                                      from: presentingViewController,
                                      documentManager: documentManager,
                                      sourceView: sourceView)
      }
    }
    #else
    showExportExperimentFlow(for: experiment,
                             from: presentingViewController,
                             documentManager: documentManager,
                             sourceView: sourceView)
    #endif
  }

  private func showSaveToFiles(for experiment: Experiment,
                               from presentingViewController: UIViewController,
                               documentManager: DocumentManager) {
    saveToFilesHandler.presentSaveToFiles(
      forExperiment: experiment,
      documentManager: documentManager,
      presentingViewController: presentingViewController)
  }

  private func showExportExperimentFlow(for experiment: Experiment,
                                        from presentingViewController: UIViewController,
                                        documentManager: DocumentManager,
                                        sourceView: UIView) {
    let spinnerViewController = SpinnerViewController()
    spinnerViewController.present(fromViewController: presentingViewController)

    func exportExperiment() {
      documentManager.createExportDocument(
        forExperimentWithID: experiment.ID,
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

    documentManager.experimentIsReadyForExport(experiment) { (isReady) in
      if isReady {
        exportExperiment()
      } else {
        PopUpMenuAction.presentExperimentNotFinishedDownloadingAlert(
          fromViewController: spinnerViewController, cancelHandler: { (_) in
            spinnerViewController.dismissSpinner()
        }, confirmHandler: { (_) in
          exportExperiment()
        })
      }
    }
  }

  private func showPDFExport(for experiment: Experiment,
                             from presentingViewController: UIViewController,
                             sourceView: UIView) {
    let completionHandler: PDFExportController.CompletionHandler = { completion in
      switch completion {
      case .success(let pdfURL):
        self.present(pdfURL: pdfURL, from: presentingViewController, sourceView: sourceView)
      case .cancel:
        break
      case .error(let errors):
        if errors.isEmpty != false {
          sjlog_error("Error(s) in the PDF export flow: \(errors)", category: .general)
        } else {
          sjlog_error("Unknown error in the PDF export flow.", category: .general)
        }
      }
    }

    delegate?.showPDFExportFlow(for: experiment, completionHandler: completionHandler)
  }

  private func present(pdfURL: URL,
                       from presentingViewController: UIViewController,
                       sourceView: UIView) {
    switch exportType {
    case .saveToFiles:
      saveToFilesHandler.presentSaveToFiles(for: pdfURL,
                                            from: presentingViewController) { result in
        switch result {
        case .saved:
          showSnackbar(withMessage: String.saveToFilesSingleSuccessMessage)
        case .cancelled:
          break
        }
      }
    case .share:
      let activityVC = UIActivityViewController(activityItems: [pdfURL],
                                                applicationActivities: nil)

      if let presentationController = activityVC.popoverPresentationController {
        // Configure as a popover on iPad if necessary.
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
      }
      presentingViewController.present(activityVC, animated: true)
    }
  }

}
