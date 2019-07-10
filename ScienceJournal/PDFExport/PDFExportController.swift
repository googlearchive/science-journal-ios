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

protocol PDFExportable {
  var scrollView: UIScrollView { get }
}

// Takes a scroll viewable experiment view controller and exports its scroll view view hierarchy
// into a PDF along with a custom header.
final class PDFExportController: UIViewController {

  // Specifies info for use in drawing the PDF export header.
  struct HeaderInfo {
    let title: String
    let subtitle: String
    let image: UIImage?
  }

  enum CompletionState {
    case success(URL)
    case error([Error])
    case cancel
  }

  typealias ContentViewController = UIViewController & PDFExportable
  typealias CompletionHandler = (CompletionState) -> Void

  // TODO: Determinate progress bar

  /// The URL the PDF will be written to.
  private let pdfURL: URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("Experiment.pdf")
  private let contentViewController: ContentViewController
  private let operationQueue = GSJOperationQueue()

  var completionHandler: CompletionHandler?

  // MARK: - Public

  init(contentViewController: ContentViewController) {
    self.contentViewController = contentViewController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    let closeMenuItem = MaterialCloseBarButtonItem(target: self,
                                                   action: #selector(closeButtonPressed))
    navigationItem.leftBarButtonItem = closeMenuItem

    setupContentViewController()
    setupOverlayViewController()
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    // TODO: Update values here if needed, once overlay is in place
    let frame = contentViewController.view.frame
    if size.isWiderThanTall {
      contentViewController.view.frame =
        frame.applying(CGAffineTransform(translationX: 100, y: 0))
    } else {
      contentViewController.view.frame =
        frame.applying(CGAffineTransform(translationX: -100, y: 0))
    }
  }

  /// Start the PDF export. Call after controller has been presented.
  func startPDFExport(headerInfo: HeaderInfo) {
    let pdfExportOperation = PDFExportOperation(contentViewController: contentViewController,
                                                pdfHeaderInfo: headerInfo,
                                                destinationURL: pdfURL)
    pdfExportOperation.addObserver(BlockObserver(startHandler: operationStartHandler,
                                                 spawnHandler: nil,
                                                 finishHandler: operationFinishHandler))
    operationQueue.addOperation(pdfExportOperation)
  }

  @objc private func closeButtonPressed() {
    cancelAndReport()
  }

  private func setupContentViewController() {
    // Intentionally omitting addChild and didMove(toParent:) calls so as to prevent the
    // contentViewController's navigation set-up from interfering with this controller's nav items.
    view.addSubview(contentViewController.view)
    contentViewController.view.translatesAutoresizingMaskIntoConstraints = true
    contentViewController.view.autoresizingMask = []
    contentViewController.view.frame = view.frame
  }

  private func setupOverlayViewController() {
    let overlayViewController = UIViewController()
    // TODO: Remove color and alpha once spinner is in place
    overlayViewController.view.backgroundColor = .red
    overlayViewController.view.alpha = 0.1
    addChild(overlayViewController)
    view.addSubview(overlayViewController.view)
    overlayViewController.didMove(toParent: self)

    overlayViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    overlayViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    overlayViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive =
    true
    overlayViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  private func completion(state: CompletionState) {
    self.dismiss(animated: true, completion: {
      self.completionHandler?(state)
    })
  }

  private func reportSuccess() {
    completion(state: .success(pdfURL))
  }

  private func cancelAndReport() {
    operationQueue.cancelAllOperations()
    completion(state: .cancel)
  }

  private func reportErrors(_ errors: [Error]) {
    completion(state: .error(errors))
  }

  private func operationStartHandler(operation: GSJOperation) {
    // TODO: Show spinner on overlay
  }

  private func operationFinishHandler(operation: GSJOperation, errors: [Error]) {
    if errors.isEmpty {
      reportSuccess()
    } else {
      reportErrors(errors)
    }
  }

}
