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

/// A struct to store a scroll view snapshot collection including an array of snapshots and the
/// final size a composed rect of snapshots should be.
public struct ScrollViewSnapshotCollection {
  var snapshots: [UIImage]
  var finalSize: CGSize
}

/// An extension to provide support for capturing an image snapshot of the entirety of a
/// scrollView. Inspired by ScrollViewImager example code by Romain Menke
/// [https://stackoverflow.com/a/32836124].
extension UIScrollView {

  /// Takes a series of snapshots of the entire contents of a scrollView.
  ///
  /// - Parameters:
  ///   - scale: The scale at which to render snapshots.
  ///   - shouldCancel: A block that reports progress (0.0 - 1.0) and can be used to signal
  ///                   snapshotting cancellation.
  ///   - completion: A block which fires upon completion and provides an optional
  ///                 ScrollViewSnapshotCollection.
  func snapshotContents(
      scale: CGFloat = UIScreen.main.scale,
      shouldCancel: @escaping () -> Bool,
      updateProgress: @escaping (CGFloat) -> Void,
      completion: @escaping (_ snapshotCollection: ScrollViewSnapshotCollection?) -> Void) {
    let offsets = prepareSnapshotOffsets()
    guard !offsets.isEmpty else { return completion(nil) }
    let finalSize = self.contentSize.applying(scale: scale)
    captureSnapshots(offsets: offsets,
                     scale: scale,
                     shouldCancel: shouldCancel,
                     updateProgress: updateProgress) {
      (snapshots) -> Void in
      guard !snapshots.isEmpty else { return completion(nil) }
      completion(ScrollViewSnapshotCollection(snapshots: snapshots, finalSize: finalSize))
    }
  }

}

private extension UIScrollView {

  /// Determines all the page regions that need to be captured, given the scrollView's content.
  ///
  /// - Returns: An array of offset CGPoints to use to capture pages of snapshots.
  func prepareSnapshotOffsets() -> [CGPoint] {
    guard bounds.size.height > 0 else { return [] }

    // Initial offset.
    var currentOffset = CGPoint.zero
    // Determine any remaining height that will be left over after even increments of screen
    // scrolling in the content view.
    let remainderHeight = contentSize.height.truncatingRemainder(dividingBy: bounds.size.height)
    // Total number of vertical pages to capture, minus the remainder height.
    let pages = Int((contentSize.height - remainderHeight) / bounds.size.height)
    // Total number of pages to capture, including an additional page to cover any remainder height.
    let totalPages = pages + (remainderHeight > 0 ? 1 : 0)

    var offsets: [CGPoint] = []
    for y in 0..<totalPages {
      // Grab the current offset.
      offsets.append(currentOffset)

      if y == pages {
        // We're capturing the remainder height area.
        currentOffset.y = contentSize.height - bounds.size.height
      } else {
        // This is the first page.
        currentOffset.y += bounds.size.height // not a partial
      }
    }
    return offsets
  }

  /// Loops through a set of regions and captures a snapshot of each.
  ///
  /// - Parameters:
  ///   - offsets: An array of offset points.
  ///   - scale: The scale at which to render.
  ///   - shouldCancel: A block that reports progress (0.0 - 1.0) and can be used to signal
  ///                   snapshotting cancellation.
  ///   - completion: Called after capturing all snapshots and returns an array of UIImages.
  func captureSnapshots(offsets: [CGPoint],
                        scale: CGFloat,
                        shouldCancel: @escaping () -> Bool,
                        updateProgress: @escaping (CGFloat) -> Void,
                        completion: @escaping (_ snapshots: [UIImage]) -> Void) {
    var page = 0

    var images: [UIImage] = [] {
      // Using the didSet of this array to store, loop and call completion when complete ensures
      // sequential execution of the captures.
      didSet {
        guard offsets.count > 0, shouldCancel() == false else {
            completion([])
            return
        }

        updateProgress(CGFloat(page) / CGFloat(offsets.count))

        if page < offsets.count {
          capturePageSnapshot()
        } else {
          completion(images)
        }
      }
    }

    // Nested function to run the snapshot and update page count and images array.
    func capturePageSnapshot() {
      captureAtPoint(offsets[page], scale: scale) { (snapshot) -> Void in
        if let snapshot = snapshot {
          page += 1
          images.append(snapshot)
        }
      }
    }

    // Fire off the first capture.
    capturePageSnapshot()
  }

  /// Captures a snapshot of the scrollView's content at a given point.
  ///
  /// - Parameters:
  ///   - point: The point to scroll to and capture.
  ///   - scale: The scale at which to capture.
  ///   - completion: A block fired upon completion containing an optional image result.
  private func captureAtPoint(_ point: CGPoint,
                              scale: CGFloat,
                              completion: @escaping (_ snapshot: UIImage?) -> Void) {
    // Initial frame and offset.
    let frame = CGRect(origin: .zero, size: self.bounds.size)
    let currentOffset = contentOffset

    // Scroll to the specified point.
    setContentOffset(point, animated: false)

    // After a delay, capture the contents.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      UIGraphicsBeginImageContextWithOptions(frame.size, true, scale)
      self.drawHierarchy(in: frame, afterScreenUpdates: true)
      var image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      // Resize image if necessary.
      image = self.resizeImage(image: image, scale: scale)

      // Reset the contentOffset to the initial state.
      self.setContentOffset(currentOffset, animated: false)

      completion(image)
    }
  }

  /// Resizes an image.
  ///
  /// - Parameters:
  ///   - image: The image to resize.
  ///   - scale: The scale at which the image should be resized by.
  /// - Returns: The resized image, the original image if resizing was not necessary, or nil.
  private func resizeImage(image: UIImage?, scale: CGFloat) -> UIImage? {
    guard let image = image else { return nil }
    guard scale != 1 else { return image }

    let initialSize = image.size
    let targetSize = initialSize.applying(scale: scale)
    let frame = CGRect(origin: .zero, size: targetSize)

    UIGraphicsBeginImageContextWithOptions(targetSize, true, 1)
    image.draw(in: frame)
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage
  }

}
