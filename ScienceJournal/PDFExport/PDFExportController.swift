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
import SnapKit

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
    case cancel(CancellationSource)
  }

  enum CancellationSource {
    case user
    case backgrounded

    var analyticsLabel: String {
      switch self {
      case .user: return "User cancelled"
      case .backgrounded: return "Backgrounded app"
      }
    }
  }

  private enum Metrics {
    static let captureWidth: CGFloat = 500
    static let progressUpdateInterval: TimeInterval = 0.1
  }

  typealias ContentViewController = UIViewController & PDFExportable
  typealias CompletionHandler = (CompletionState) -> Void

  var completionHandler: CompletionHandler?

  private let analyticsReporter: AnalyticsReporter
  private let overlayViewController: PDFExportOverlayViewController
  private var progressTimer: Timer?
  private var pdfExportOperation: PDFExportOperation?

  /// The URL the PDF will be written to.
  private var pdfURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("Experiment.pdf")
  private let contentViewController: ContentViewController
  private let operationQueue = GSJOperationQueue()

  // MARK: - Public

  init(contentViewController: ContentViewController, analyticsReporter: AnalyticsReporter) {
    self.contentViewController = contentViewController
    self.analyticsReporter = analyticsReporter
    self.overlayViewController =
      PDFExportOverlayViewController(analyticsReporter: analyticsReporter)
    super.init(nibName: nil, bundle: nil)

    overlayViewController.delegate = self

    // If the user backgrounds the app while exporting, cancel the export since this requires
    // crawling the UI and can be corrupted or broken by backgrounding in some cases.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(cancelBeforeBackgrounding),
                                           name: UIApplication.willResignActiveNotification,
                                           object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    analyticsReporter.track(.pdfExportStarted)
    setupContentViewController()
    setupOverlayViewController()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  /// Start the PDF export. Call after controller has been presented. If no destinationURL is
  /// provided, a suitable default will be used and returned in the completion handler.
  func exportPDF(with headerInfo: HeaderInfo, to destinationURL: URL? = nil) {
    if let destinationURL = destinationURL {
      pdfURL = destinationURL
    }
    let pdfExportOperation = PDFExportOperation(contentViewController: contentViewController,
                                                pdfHeaderInfo: headerInfo,
                                                destinationURL: pdfURL)
    pdfExportOperation.addObserver(BlockObserver(startHandler: operationStartHandler,
                                                 spawnHandler: nil,
                                                 finishHandler: operationFinishHandler))
    self.pdfExportOperation = pdfExportOperation
    operationQueue.addOperation(pdfExportOperation)
  }

  private func setupContentViewController() {
    // Intentionally omitting addChild and didMove(toParent:) calls so as to prevent the
    // contentViewController's navigation set-up from interfering with this controller's nav items.
    view.addSubview(contentViewController.view)
    contentViewController.view.translatesAutoresizingMaskIntoConstraints = true
    contentViewController.view.autoresizingMask = []
    var frameForCapturing = view.frame
    frameForCapturing.size.width = Metrics.captureWidth
    contentViewController.view.frame = frameForCapturing
  }

  private func setupOverlayViewController() {
    overlayViewController.view.backgroundColor = .white
    addChild(overlayViewController)
    view.addSubview(overlayViewController.view)
    overlayViewController.didMove(toParent: self)
    overlayViewController.view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func completion(state: CompletionState) {
    DispatchQueue.main.async {
      self.progressTimer?.invalidate()
      self.progressTimer = nil
      self.overlayViewController.progressView.progress = 1
    }

    pdfExportOperation = nil

    func dismissWithCompletion(_ state: CompletionState) {
      self.dismiss(animated: true, completion: {
        self.completionHandler?(state)
      })
    }

    switch state {
    case .success:
      analyticsReporter.track(.pdfExportCompleted)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        // Give the UI a moment to update progress to 100%, which _feels_ better.
        dismissWithCompletion(state)
      }
    case .cancel(let cancellationSource):
      analyticsReporter.track(.pdfExportCancelled(reason: cancellationSource.analyticsLabel))
      dismissWithCompletion(state)
    case .error:
      analyticsReporter.track(.pdfExportError)
      dismissWithCompletion(state)
    }
  }

  private func reportSuccess() {
    completion(state: .success(pdfURL))
  }

  @objc private func cancelBeforeBackgrounding() {
    operationQueue.cancelAllOperations()
    completion(state: .cancel(.backgrounded))
  }

  private func cancelAndReport() {
    operationQueue.cancelAllOperations()
    completion(state: .cancel(.user))
  }

  private func reportErrors(_ errors: [Error]) {
    completion(state: .error(errors))
  }

  private func operationStartHandler(operation: GSJOperation) {
    DispatchQueue.main.async {
      self.overlayViewController.progressView.indicatorMode = .determinate
      self.progressTimer = Timer.scheduledTimer(withTimeInterval: Metrics.progressUpdateInterval,
                                                repeats: true,
                                                block: { (_) in
        guard let pdfExportOperation = self.pdfExportOperation else { return }
        self.overlayViewController.progressView.progress = Float(pdfExportOperation.progress)
      })
    }
  }

  private func operationFinishHandler(operation: GSJOperation, errors: [Error]) {
    if errors.isEmpty {
      reportSuccess()
    } else {
      reportErrors(errors)
    }
  }

}

// MARK: - PDFExportOverlayViewControllerDelegate

extension PDFExportController: PDFExportOverlayViewControllerDelegate {

  func pdfExportShouldCancel() {
    cancelAndReport()
  }

}
