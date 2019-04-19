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

import Foundation
import Photos

protocol PhotoLibraryDataSourceDelegate: class {

  /// Informs the delegate the photo library contents changed.
  func photoLibraryDataSourceLibraryDidChange(changes: PHFetchResultChangeDetails<PHAsset>?)

  /// Informs the delegate the photo library permissions changed.
  func photoLibraryDataSourcePermissionsDidChange(accessGranted: Bool)

}

// TODO: Support albums. http://b/64225998
class PhotoLibraryDataSource: NSObject, PHPhotoLibraryChangeObserver {

  // MARK: - Nested class

  /// Stores progress data for photo downloads.
  private class DownloadProgressHandler {

    // MARK: - Properties

    // Photo download progress, keyed by photo asset ID.
    private var downloadProgress = [String : Double]()

    // Photo download progress blocks, keyed by photo asset ID, called with progress, error and
    // whether or not the download is complete.
    private var progressBlocks =
        [String : (progress: Double, error: Error?, complete: Bool) -> Void]()

    // MARK: - Public

    /// Sets the download progress for a photo asset.
    func setDownloadProgress(_ progress: Double, for photoAsset: PHAsset) {
      downloadProgress[photoAsset.localIdentifier] = (0.0...1.0).clamp(progress)
    }

    /// Gets the download progress for a photo asset.
    func downloadProgress(for photoAsset: PHAsset) -> Double? {
      return downloadProgress[photoAsset.localIdentifier]
    }

    /// Removes the download progress for a photo asset.
    func removeDownloadProgress(for photoAsset: PHAsset) {
      downloadProgress[photoAsset.localIdentifier] = nil
    }

    /// Sets a progress block for a photo asset.
    func setProgressBlock(_ progressBlock: ((Double, Error?, Bool) -> Void)?,
                          for photoAsset: PHAsset) {
      progressBlocks[photoAsset.localIdentifier] = progressBlock
    }

    /// Gets a progress block for a photo asset.
    func progressBlock(for photoAsset: PHAsset) -> ((Double, Error?, Bool) -> Void)? {
      return progressBlocks[photoAsset.localIdentifier]
    }

    /// Removes a progress block for a photo asset.
    func removeProgressBlock(for photoAsset: PHAsset) {
      progressBlocks[photoAsset.localIdentifier] = nil
    }

  }

  // MARK: - PhotoLibraryDataSource

  // MARK: - Properties

  /// Photo library data source delegate.
  weak var delegate: PhotoLibraryDataSourceDelegate?

  /// The permissions state of the capturer.
  var isPhotoLibraryPermissionGranted: Bool {
    let authStatus = PHPhotoLibrary.authorizationStatus()
    switch authStatus {
    case .denied, .restricted: return false
    case .authorized: return true
    case .notDetermined:
      // Prompt user for the permission to use the camera.
      PHPhotoLibrary.requestAuthorization({ (status) in
        DispatchQueue.main.sync {
          let granted = status == .authorized
          self.delegate?.photoLibraryDataSourcePermissionsDidChange(accessGranted: granted)
        }
      })
      return false
    }
  }

  private let downloadProgressHandler = DownloadProgressHandler()
  private var photoAssetFetchResult: PHFetchResult<PHAsset>?

  // Request options configured for image data.
  private var requestOptions: PHImageRequestOptions {
    let requestOptions = PHImageRequestOptions()
    requestOptions.version = .current
    requestOptions.deliveryMode = .fastFormat
    requestOptions.resizeMode = .fast
    requestOptions.isSynchronous = true
    requestOptions.isNetworkAccessAllowed = true
    return requestOptions
  }

  // MARK: - Public

  /// Performs a photo asset fetch.
  func fetch() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.fetchLimit = 250
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    photoAssetFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
  }

  /// The number of photo assets.
  var numberOfPhotoAssets: Int {
    guard let photoAssetFetchResult = photoAssetFetchResult else { return 0 }
    return photoAssetFetchResult.count
  }

  /// Returns the index path of a photo asset.
  ///
  /// - Parameter photoAsset: The photo asset.
  /// - Returns: The index path.
  func indexPathOfPhotoAsset(_ photoAsset: PHAsset) -> IndexPath? {
    guard let index = photoAssetFetchResult?.index(of: photoAsset) else { return nil }
    return indexPath(for: index)
  }

  /// Returns the photo asset for an index path.
  ///
  /// - Parameter indexPath: The index path.
  /// - Returns: The photo asset.
  func photoAsset(for indexPath: IndexPath) -> PHAsset? {
    guard let index = photoAssetIndex(for: indexPath) else { return nil }
    return photoAssetFetchResult?.object(at: index)
  }

  /// Starts the photo library observer. If the caller should reload after, true is returned.
  ///
  /// - Returns: Should the caller refresh collection data?
  func startObserving() -> Bool {
    PHPhotoLibrary.shared().register(self)
    if photoAssetFetchResult == nil {
      fetch()
      return true
    }
    return false
  }

  /// Stops the photo library observer.
  func stopObserving() {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }

  /// Returns the thumbnail for a photo asset at an index path.
  ///
  /// - Parameters:
  ///   - indexPath: The index path.
  ///   - size: The target size for the thumbnail.
  ///   - contentMode: The content mode for the thumbnail.
  ///   - completion: Called with the thumbnail image.
  func thumbnailImageForPhotoAsset(at indexPath: IndexPath,
                                   withSize size: CGSize,
                                   contentMode: PHImageContentMode,
                                   completion: @escaping (UIImage?) -> Void) {
    guard let photoAssetFetchResult = photoAssetFetchResult,
        let index = photoAssetIndex(for: indexPath) else {
      completion(nil)
      return
    }

    let photoAsset = photoAssetFetchResult.object(at: index)
    PHImageManager.default().requestImage(for: photoAsset,
                                          targetSize: size,
                                          contentMode: contentMode,
                                          options: requestOptions) { (image, info) in
      if let error = info?[PHImageErrorKey] as? Error {
        print(error)
        return
      }

      if let isDegradedNumber = info?[PHImageResultIsDegradedKey] as? NSNumber {
        // Ignore low-res thumbnails.
        guard !isDegradedNumber.boolValue else { return }
      }

      completion(image)
    }
  }

  /// Returns the data for an image at an index path, including available metadata.
  ///
  /// - Parameters:
  ///   - indexPath: The index path.
  ///   - downloadDidBegin: Called when a photo asset image download begins.
  ///   - completion: Called with the image, available metadata and photo asset the fetch was
  ///                 performed for.
  /// - Returns: The photo asset.
  func imageForPhotoAsset(
      at indexPath: IndexPath,
      downloadDidBegin: @escaping () -> Void,
      completion: @escaping (UIImage?, NSDictionary?, PHAsset?) -> Void) -> PHAsset? {
    guard let photoAssetFetchResult = photoAssetFetchResult,
        let index = photoAssetIndex(for: indexPath) else {
      completion(nil, nil, nil)
      return nil
    }

    let photoAsset = photoAssetFetchResult.object(at: index)

    // If the photo asset has a download in progress, return the photo asset so its cell can be
    // shown as selected when the download does complete.
    guard !isDownloadInProgress(for: indexPath).hasDownload else {
      completion(nil, nil, nil)
      return photoAsset
    }

    DispatchQueue.global().async {
      let targetSize = CGSize(width: 1000, height: 1000).applying(scale: UIScreen.main.scale)
      let options = self.requestOptions
      var isDownloading = false
      options.progressHandler = { (downloadProgress, error, _, _) in
        DispatchQueue.main.async {
          if !isDownloading {
            downloadDidBegin()
            isDownloading = true
          }

          self.downloadProgressHandler.setDownloadProgress(downloadProgress, for: photoAsset)
          if let progressBlock = self.downloadProgressHandler.progressBlock(for: photoAsset) {
            progressBlock((0.0...1.0).clamp(downloadProgress), error, false)
          }
          if error != nil {
            self.downloadProgressHandler.removeDownloadProgress(for: photoAsset)
          }
        }
      }
      PHImageManager.default().requestImage(for: photoAsset,
                                            targetSize: targetSize,
                                            contentMode: .aspectFit,
                                            options: options) { (image, imageInfo) in
        if let error = imageInfo?[PHImageErrorKey] as? Error {
          print(error)
          return
        }

        if let isDegradedNumber = imageInfo?[PHImageResultIsDegradedKey] as? NSNumber {
          // Ignore low-res thumbnails.
          guard !isDegradedNumber.boolValue else { return }
        }

        DispatchQueue.main.async {
          if let progressBlock = self.downloadProgressHandler.progressBlock(for: photoAsset) {
            progressBlock(1, nil, true)
          }
          self.downloadProgressHandler.removeDownloadProgress(for: photoAsset)

          // Return the image. We cannot capture metadata using requestImage, so we return nil. This
          // means any photo asset chosen for the picker will not bring across its metadata.
          completion(image, nil, photoAsset)
        }
      }
    }

    return photoAsset
  }

  /// Sets the progress block of download progress for an index path.
  ///
  /// - Parameters:
  ///   - indexPath: The index path.
  ///   - progressBlock: The progress block.
  func setDownloadProgressListener(for indexPath: IndexPath,
                                   progressBlock: ((Double, Error?, Bool) -> Void)?) {
    guard let index = photoAssetIndex(for: indexPath),
        let photoAsset = photoAssetFetchResult?.object(at: index) else { return }
    downloadProgressHandler.setProgressBlock(progressBlock, for: photoAsset)
  }

  /// Removes the download progress block for an index path.
  ///
  /// - Parameter indexPath: The index path.
  func removeDownloadProgressListener(for indexPath: IndexPath) {
    // This can be called for removed index paths, so we have to protect against a bad index.
    guard let index = photoAssetIndex(for: indexPath),
        let photoAssetFetchResult = photoAssetFetchResult,
        index < photoAssetFetchResult.count else { return }
    let photoAsset = photoAssetFetchResult.object(at: index)
    downloadProgressHandler.removeDownloadProgress(for: photoAsset)
  }

  /// Whether or not there is a download in progress for an index path.
  ///
  /// - Parameter indexPath: The index path.
  /// - Returns: Whether or not there is a download, and its progress.
  func isDownloadInProgress(for indexPath: IndexPath) -> (hasDownload: Bool, progress: Double) {
    guard let index = photoAssetIndex(for: indexPath),
        let photoAsset = photoAssetFetchResult?.object(at: index) else { return (false, 0) }
    if let progress = downloadProgressHandler.downloadProgress(for: photoAsset) {
      return (true, progress)
    } else {
      return (false, 0)
    }
  }

  // MARK: - Private

  private func indexPath(for photoAssetIndex: Int) -> IndexPath {
    // Only section 0 contains photo assets.
    return IndexPath(item: photoAssetIndex, section: 0)
  }

  private func photoAssetIndex(for indexPath: IndexPath) -> Int? {
    // Only section 0 contains photo assets .
    guard indexPath.section == 0 else { return nil }
    return indexPath.item
  }

  // MARK: - PHPhotoLibraryChangeObserver

  func photoLibraryDidChange(_ changeInstance: PHChange) {
    DispatchQueue.main.sync {
      if let previousFetchResult = photoAssetFetchResult,
          let changes = changeInstance.changeDetails(for: previousFetchResult) {

        // Remove any listeners for index paths that were removed.
        if let removedIndexes = changes.removedIndexes {
          for removedIndex in 0..<removedIndexes.count {
            let indexPath = IndexPath(item: removedIndex, section: 0)
            removeDownloadProgressListener(for: indexPath)
          }
        }

        // Keep the new fetch result for future use.
        photoAssetFetchResult = changes.fetchResultAfterChanges
        if changes.hasIncrementalChanges {
          delegate?.photoLibraryDataSourceLibraryDidChange(changes: changes)
        } else {
          // Reload the collection view if incremental diffs are not available.
          delegate?.photoLibraryDataSourceLibraryDidChange(changes: nil)
        }
      }
    }
  }

}
