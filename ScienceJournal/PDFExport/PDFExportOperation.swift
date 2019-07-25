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

/// An operation that exports an experiment as a PDF document.
final class PDFExportOperation: GSJOperation {

  enum Error: Swift.Error {
    case snapshotsGeneration
  }

  private enum Metrics {
    static let snapshotCaptureScale: CGFloat = 2
    static let headerHeight: CGFloat = 200
    static let padding: CGFloat = 16
    static let titleFont = UIFont.boldSystemFont(ofSize: 40)
    static let subtitleFont = UIFont.systemFont(ofSize: 35)
  }

  private let contentViewController: PDFExportController.ContentViewController
  private let pdfHeaderInfo: PDFExportController.HeaderInfo
  private let pdfURL: URL

  private var snapshotProgress: CGFloat = 0
  private var renderProgress: CGFloat = 0

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - contentViewController: The view controller with the scroll view to export into PDF.
  ///   - pdfHeaderInfo: Info to render in the PDF header.
  ///   - destinationURL: URL where PDF file will be written.
  init(contentViewController: PDFExportController.ContentViewController,
       pdfHeaderInfo: PDFExportController.HeaderInfo,
       destinationURL: URL) {
    self.contentViewController = contentViewController
    self.pdfHeaderInfo = pdfHeaderInfo
    self.pdfURL = destinationURL
    super.init()
  }

  override func execute() {
    generatePDF()
  }

  /// Returns an indication of the overall progress of this operation. 0.0 <= progress <= 1.0.
  var progress: CGFloat {
    // Weight snapshot progress much higher than render progress as it takes much longer.
    return snapshotProgress * 0.9 + renderProgress * 0.1
  }

  private func logProgress() {
    sjlog_info("PDF Export Progress: \(progress)", category: .general)
  }

  // MARK: - PDF Generation

  func generatePDF() {
    DispatchQueue.main.async {
      func shouldCancel() -> Bool {
        return self.isCancelled
      }

      func updateProgress(snapshotProgress: CGFloat) {
        self.snapshotProgress = snapshotProgress
        self.logProgress()
      }

      let scrollView = self.contentViewController.scrollView
      scrollView.snapshotContents(scale: Metrics.snapshotCaptureScale,
                                  shouldCancel: shouldCancel,
                                  updateProgress: updateProgress) {
        (snapshotCollection) -> Void in
        guard let snapshotCollection = snapshotCollection else {
          if self.isCancelled {
            self.finish()
          } else {
            self.finish(withErrors: [Error.snapshotsGeneration])
          }
          return
        }
        self.renderPDFData(from: snapshotCollection)
        self.finish()
      }
    }
  }

  private func renderPDFData(from snapshotCollection: ScrollViewSnapshotCollection) {
    let data = createPDFDataFromSnapshotCollection(snapshotCollection)
    data.write(to: pdfURL, atomically: true)
  }

  private func createPDFDataFromSnapshotCollection(
    _ snapshotCollection: ScrollViewSnapshotCollection) -> NSMutableData {
    let data = NSMutableData()
    guard snapshotCollection.snapshots.count > 0 else { return data }

    let snapshotSize = snapshotCollection.finalSize
    let headerSize = CGSize(width: snapshotSize.width, height: Metrics.headerHeight)
    let finalFrame = CGRect(origin: .zero, size: CGSize(width: snapshotSize.width,
                                                        height: snapshotSize.height +
                                                          headerSize.height + Metrics.padding))

    UIGraphicsBeginPDFContextToData(data, finalFrame, nil)
    UIGraphicsBeginPDFPageWithInfo(finalFrame, nil)

    drawHeader(in: CGRect(origin: .zero, size: headerSize))

    var offsetY: CGFloat = Metrics.headerHeight + Metrics.padding
    for (renderCount, snapshot) in snapshotCollection.snapshots.enumerated() {
      guard isCancelled == false else {
        finish()
        return NSMutableData()
      }

      let rect = CGRect(x: 0,
                        y: offsetY,
                        width: snapshot.size.width,
                        height: snapshot.size.height)

      if let snapshotData = snapshot.jpegData(compressionQuality: 0.75),
         let reducedSnapshot = UIImage(data: snapshotData) {
        reducedSnapshot.draw(in: rect)
      } else {
        // If we failed to reduce the file size, draw the original.
        snapshot.draw(in: rect)
      }

      offsetY += snapshot.size.height
      renderProgress = CGFloat(renderCount) / CGFloat(snapshotCollection.snapshots.count)
      logProgress()
    }
    UIGraphicsEndPDFContext()
    return data
  }

  // MARK: - Header Drawing

  /// Returns copy of image stylized as needed for the experiment PDF export header
  private func headerThumbnail(for image: UIImage?) -> UIImage? {
    guard let image = image else { return nil }
    let rect = CGRect(origin: .zero, size: image.size)
    UIGraphicsBeginImageContextWithOptions(image.size, false, 1)
    defer {
      UIGraphicsEndImageContext()
    }
    UIBezierPath(roundedRect: rect, cornerRadius: image.size.height / 8).addClip()
    image.draw(in: rect)
    if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
      return resizedImage
    }
    return nil
  }

  private func drawHeader(in rect: CGRect) {
    let rightToLeft = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    var xOffset = Metrics.padding
    var yOffset = Metrics.padding

    if rightToLeft {
      xOffset = rect.size.width - Metrics.padding
    }

    let imageDimension = ceil(rect.size.height - Metrics.padding * 2)
    if let thumbnail = headerThumbnail(for: pdfHeaderInfo.image?
      .sizedWithAspect(to: CGSize(width: imageDimension, height: imageDimension))) {

      if rightToLeft {
        xOffset -= imageDimension
      }

      let imageRect = CGRect(origin: CGPoint(x: xOffset, y: yOffset),
                             size: CGSize(width: imageDimension, height: imageDimension))
      let context = UIGraphicsGetCurrentContext()!
      context.saveGState()
      context.setShadow(offset: CGSize(width: 0, height: 5), blur: 10)
      thumbnail.draw(in: imageRect)
      context.restoreGState()

      if rightToLeft {
        xOffset -= Metrics.padding
      } else {
        xOffset += imageDimension + Metrics.padding
      }
    }

    let title = pdfHeaderInfo.title
    let titleAttributes = [NSAttributedString.Key.font: Metrics.titleFont,
                           NSAttributedString.Key.foregroundColor: UIColor.black]
    let titleTextSize = title.labelSize(font: Metrics.titleFont)

    let subtitle = pdfHeaderInfo.subtitle
    let subtitleAttributes = [NSAttributedString.Key.font: Metrics.subtitleFont,
                              NSAttributedString.Key.foregroundColor: UIColor.gray]
    let subtitleTextSize = subtitle.labelSize(font: Metrics.subtitleFont)

    yOffset = ceil(rect.size.height - titleTextSize.height - subtitleTextSize.height) / 2
    let textXOffset = xOffset
    if rightToLeft {
      xOffset = textXOffset - titleTextSize.width
    }

    let titleRect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: titleTextSize)
    title.draw(at: titleRect.origin, withAttributes: titleAttributes)

    yOffset += ceil(titleTextSize.height + Metrics.padding / 2)
    if rightToLeft {
      xOffset = textXOffset - subtitleTextSize.width
    }

    let subtitleRect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: subtitleTextSize)
    subtitle.draw(at: subtitleRect.origin, withAttributes: subtitleAttributes)
  }

}
