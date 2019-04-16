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

import Photos
import UIKit

/// Subclass of the photo library view controller for analytics purposes and uses a check mark
/// action bar button instead of a send icon.
open class StandalonePhotoLibraryViewController: PhotoLibraryViewController {

  public init(analyticsReporter: AnalyticsReporter) {
    super.init(actionBarButtonType: .check, analyticsReporter: analyticsReporter)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

}

/// View controller for selecting photos from the library.
open class PhotoLibraryViewController: ScienceJournalViewController, UICollectionViewDataSource,
                                       UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
                                       PhotoLibraryDataSourceDelegate, DrawerItemViewController,
                                       DrawerPositionListener, PhotoLibraryCellDelegate {

  // MARK: - Properties

  /// The photo library data source.
  let photoLibraryDataSource = PhotoLibraryDataSource()

  /// The selection delegate.
  weak var delegate: ImageSelectorDelegate?

  private var collectionView: UICollectionView

  // The disabled view when permission is not granted.
  private let disabledView = DisabledInputView()

  /// The photo library cell's reuse identifier.
  static let reuseIdentifier = "PhotoLibraryCell"

  /// The photo library cell inter-item spacing.
  static let interitemSpacing: CGFloat = 1

  /// The photo library item size.
  var itemSize: CGSize {
    let totalWidth = collectionView.bounds.size.width - view.safeAreaInsetsOrZero.left -
        view.safeAreaInsetsOrZero.right
    let approximateWidth: CGFloat = 90
    let numberOfItemsInWidth = floor(totalWidth / approximateWidth)
    let dimension = (totalWidth - PhotoLibraryViewController.interitemSpacing *
        (numberOfItemsInWidth - 1)) / numberOfItemsInWidth
    return CGSize(width: dimension, height: dimension)
  }

  private let actionBar: ActionBar
  private let actionBarWrapper = UIView()
  private var actionBarWrapperHeightConstraint: NSLayoutConstraint?
  private var drawerPanner: DrawerPanner?
  private var mostRecentlySelectedPhotoAsset: PHAsset?

  private var selectedImage: (image: UIImage, metadata: NSDictionary?)? {
    didSet {
      actionBar.button.isEnabled = selectedImage != nil
    }
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - actionBarButtonType: The button type for the action bar. Default is a send button.
  ///   - analyticsReporter: An AnalyticsReporter.
  public init(actionBarButtonType: ActionBar.ButtonType = .send,
              analyticsReporter: AnalyticsReporter) {
    // TODO: Confirm layout is correct in landscape.
    let collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.minimumLineSpacing = 1
    collectionViewLayout.minimumInteritemSpacing = PhotoLibraryViewController.interitemSpacing
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    collectionView.isAccessibilityElement = false
    collectionView.shouldGroupAccessibilityChildren = true

    actionBar = ActionBar(buttonType: actionBarButtonType)

    super.init(analyticsReporter: analyticsReporter)
    photoLibraryDataSource.delegate = self

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(accessibilityVoiceOverStatusChanged),
        name: NSNotification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged),
        object: nil)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Collection view.
    // Always register collection view cells early to avoid a reload occurring first.
    collectionView.register(PhotoLibraryCell.self,
                            forCellWithReuseIdentifier: PhotoLibraryViewController.reuseIdentifier)
    view.addSubview(collectionView)
    collectionView.alwaysBounceVertical = true
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = .white
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.pinToEdgesOfView(view)
    collectionView.panGestureRecognizer.addTarget(
        self,
        action: #selector(handleCollectionViewPanGesture(_:)))

    // Action bar.
    actionBar.button.addTarget(self, action: #selector(actionBarButtonPressed), for: .touchUpInside)
    actionBar.button.isEnabled = false
    actionBar.button.accessibilityLabel = String.addPictureNoteContentDescription
    actionBar.translatesAutoresizingMaskIntoConstraints = false
    actionBar.setContentHuggingPriority(.defaultHigh, for: .vertical)
    actionBarWrapper.addSubview(actionBar)
    actionBar.topAnchor.constraint(equalTo: actionBarWrapper.topAnchor).isActive = true
    actionBar.leadingAnchor.constraint(equalTo: actionBarWrapper.leadingAnchor).isActive = true
    actionBar.trailingAnchor.constraint(equalTo: actionBarWrapper.trailingAnchor).isActive = true

    actionBarWrapper.backgroundColor = DrawerView.actionBarBackgroundColor
    actionBarWrapper.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(actionBarWrapper)
    actionBarWrapper.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    actionBarWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    actionBarWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    actionBarWrapperHeightConstraint =
        actionBarWrapper.heightAnchor.constraint(equalTo: actionBar.heightAnchor)
    actionBarWrapperHeightConstraint?.isActive = true

    // Disabled view.
    view.addSubview(disabledView)
    disabledView.translatesAutoresizingMaskIntoConstraints = false
    disabledView.pinToEdgesOfView(view)
    disabledView.isHidden = true

    // Collection view content inset.
    collectionView.contentInset.bottom =
        actionBar.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    collectionView.scrollIndicatorInsets = collectionView.contentInset
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateDisabledView()
    updateCollectionViewScrollEnabled()
    deselectSelectedPhotoAsset()
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if photoLibraryDataSource.startObserving() {
      collectionView.reloadData()
    }
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    updateDisabledView()
    photoLibraryDataSource.stopObserving()
  }

  override open func viewWillTransition(to size: CGSize,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { (context) in
      self.collectionView.visibleCells.forEach({ (cell) in
        if let photoLibraryCell = cell as? PhotoLibraryCell {
          photoLibraryCell.setImageDimensionConstraints(with: self.itemSize)
        }
      })
      self.collectionView.collectionViewLayout.invalidateLayout()
    }, completion: nil)
  }

  override open func viewSafeAreaInsetsDidChange() {
    actionBarWrapperHeightConstraint?.constant = view.safeAreaInsetsOrZero.bottom
  }

  // MARK: - PhotoLibraryDataSourceDelegate

  func photoLibraryDataSourceLibraryDidChange(changes: PHFetchResultChangeDetails<PHAsset>?) {
    // Deselect the current photo.
    deselectSelectedPhotoAsset()

    guard let changes = changes else { collectionView.reloadData(); return }
    // If there are incremental diffs, animate them in the collection view.
    collectionView.performBatchUpdates({
      // For indexes to make sense, updates must be in this order:
      // delete, insert, reload, move
      if let removed = changes.removedIndexes, !removed.isEmpty {
        self.collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section: 0) })
      }
      if let inserted = changes.insertedIndexes, !inserted.isEmpty {
        self.collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section: 0) })
      }
      if let changed = changes.changedIndexes, !changed.isEmpty {
        self.collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section: 0) })
      }
      changes.enumerateMoves { fromIndex, toIndex in
        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                     to: IndexPath(item: toIndex, section: 0))
      }
    })
  }

  func photoLibraryDataSourcePermissionsDidChange(accessGranted: Bool) {
    guard accessGranted else { return }
    photoLibraryDataSource.fetch()
    collectionView.reloadData()
    updateDisabledView()
  }

  // MARK: - UICollectionViewDataSource

  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    return photoLibraryDataSource.numberOfPhotoAssets
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: PhotoLibraryViewController.reuseIdentifier, for: indexPath)
    if let photoLibraryCell = cell as? PhotoLibraryCell {
      photoLibraryCell.delegate = self
      photoLibraryCell.setImageDimensionConstraints(with: itemSize)
      photoLibraryDataSource.thumbnailImageForPhotoAsset(
          at: indexPath,
          withSize: itemSize.applying(scale: traitCollection.displayScale),
          contentMode: .aspectFill) {
        guard let image = $0 else { return }
        photoLibraryCell.image = image
      }

      // If this cell is for the photo asset that is selected, show the highlight.
      if isMostRecentlySelectedPhotoAsset(at: indexPath) {
        photoLibraryCell.isSelected = true
      }

      // If there is a download in progress for this cell's photo asset, show the spinner.
      let download = photoLibraryDataSource.isDownloadInProgress(for: indexPath)
      if download.hasDownload {
        photoLibraryCell.startSpinner(withProgress: download.progress)
      }
    }
    return cell
  }

  public func collectionView(_ collectionView: UICollectionView,
                             willDisplay cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {
    guard let photoLibraryCell = cell as? PhotoLibraryCell else { return }
    addDownloadProgressListener(for: photoLibraryCell, at: indexPath)
  }

  public func collectionView(_ collectionView: UICollectionView,
                             didEndDisplaying cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {
    photoLibraryDataSource.removeDownloadProgressListener(for: indexPath)
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0,
                        left: view.safeAreaInsetsOrZero.left,
                        bottom: 0,
                        right: view.safeAreaInsetsOrZero.right)
  }

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    return itemSize
  }

  // MARK: - DrawerItemViewController

  public func setUpDrawerPanner(with drawerViewController: DrawerViewController) {
    drawerPanner = DrawerPanner(drawerViewController: drawerViewController,
                                scrollView: collectionView)
  }

  public func reset() {
    collectionView.scrollToTop()
  }

  // MARK: - DrawerPositionListener

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   didChangeDrawerPosition position: DrawerPosition) {
    updateCollectionViewScrollEnabled()
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   didPanBeyondBounds panDistance: CGFloat) {
    collectionView.contentOffset = CGPoint(x: 0, y: panDistance)
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   willChangeDrawerPosition position: DrawerPosition) {
    // If the content offset of the scroll view is within the first four cells, scroll to the top
    // when the drawer position changes to anything but open full.
    let fourCellsHeight = itemSize.height * 4
    let isContentOffsetWithinFirstFourCells = collectionView.contentOffset.y < fourCellsHeight
    if isContentOffsetWithinFirstFourCells && !drawerViewController.isPositionOpenFull(position) {
      perform(#selector(setCollectionViewContentOffsetToZero), with: nil, afterDelay: 0.01)
    }
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   isPanningDrawerView drawerView: DrawerView) {}

  // MARK: - UIScrollViewDelegate

  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    drawerPanner?.scrollViewWillBeginDragging(scrollView)
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                       willDecelerate decelerate: Bool) {
    drawerPanner?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
  }

  // MARK: - PhotoLibraryCellDelegate

  func photoLibraryCellDidSelectImage(_ photoLibraryCell: PhotoLibraryCell) {
    guard let indexPath = collectionView.indexPath(for: photoLibraryCell) else { return }

    // A photo asset is deselected when it was selected and is tapped again.
    let isPhotoAssetDeselected = isMostRecentlySelectedPhotoAsset(at: indexPath)

    deselectSelectedPhotoAsset()
    if !isPhotoAssetDeselected {
      mostRecentlySelectedPhotoAsset = photoLibraryDataSource.imageForPhotoAsset(
          at: indexPath,
          downloadDidBegin: {
            photoLibraryCell.startSpinner()
          },
          completion: { (image, metadata, photoAsset) in
            // If this download was not for the most recenetly selected photo asset, the user
            // selected a different photo asset.
            if let mostRecentlySelectedPhotoAsset = self.mostRecentlySelectedPhotoAsset,
                let photoAsset = photoAsset,
                photoAsset == mostRecentlySelectedPhotoAsset,
                let image = image,
                let indexPath = self.photoLibraryDataSource.indexPathOfPhotoAsset(photoAsset) {
              self.selectedImage = (image, metadata)
              self.collectionView.cellForItem(at: indexPath)?.isSelected = true
            }
      })
    }
  }

  // MARK: - Gesture recognizer

  @objc func handleCollectionViewPanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    drawerPanner?.handlePanGesture(panGestureRecognizer)
  }

  // MARK: - Private

  // Update the state and contents of the disabled view based on permissions or camera allowance.
  private func updateDisabledView() {
    if !photoLibraryDataSource.isPhotoLibraryPermissionGranted {
      disabledView.isHidden = false
      disabledView.shouldDisplayActionButton = true
      disabledView.messageLabel.text = String.inputPhotoLibraryPermissionDenied
      disabledView.actionButton.setTitle(String.inputBlockedOpenSettingsButton, for: .normal)
      disabledView.actionButton.addTarget(self,
                                          action: #selector(openLibrarySettingsPressed),
                                          for: .touchUpInside)
    } else {
      disabledView.isHidden = true
    }
  }

  @objc private func openLibrarySettingsPressed() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(settingsURL)
  }

  @objc private func setCollectionViewContentOffsetToZero() {
    collectionView.setContentOffset(.zero, animated: true)
  }

  private func updateCollectionViewScrollEnabled() {
    // The collection view scrolling should be disabled when in a drawer, unless voiceover mode is
    // running or the drawer is open full.
    var shouldEnableScroll: Bool {
      guard let drawerViewController = drawerViewController else { return true }
      return drawerViewController.isOpenFull || UIAccessibility.isVoiceOverRunning
    }

    collectionView.isScrollEnabled = shouldEnableScroll
  }

  private func deselectSelectedPhotoAsset() {
    if let mostRecentlySelectedPhotoAsset = mostRecentlySelectedPhotoAsset,
        let indexPath =
            photoLibraryDataSource.indexPathOfPhotoAsset(mostRecentlySelectedPhotoAsset) {
      collectionView.cellForItem(at: indexPath)?.isSelected = false
      self.mostRecentlySelectedPhotoAsset = nil
    }
    selectedImage = nil
  }

  private func addDownloadProgressListener(for photoLibraryCell: PhotoLibraryCell,
                                           at indexPath: IndexPath) {
    photoLibraryDataSource.setDownloadProgressListener(for: indexPath) {
        (progress, error, complete) in
      if let error = error {
        photoLibraryCell.stopSpinner()
        print("[PhotoLibraryViewController] Error downloading image: \(error.localizedDescription)")
      } else if complete {
        photoLibraryCell.stopSpinner()
      } else {
        photoLibraryCell.setSpinnerProgress(progress)
      }
    }
  }

  // Whether or not the photo asset displayed at an index path is the most recently selected photo
  // asset.
  private func isMostRecentlySelectedPhotoAsset(at indexPath: IndexPath) -> Bool {
    guard let photoAsset = photoLibraryDataSource.photoAsset(for: indexPath) else { return false }
    return photoAsset == mostRecentlySelectedPhotoAsset
  }

  // MARK: - User actions

  @objc private func actionBarButtonPressed() {
    guard let selectedImage = selectedImage else { return }

    func createPhotoNote() {
      guard let imageData = selectedImage.image.jpegData(compressionQuality: 0.8) else {
        print("[PhotoLibraryViewController] Error creating image data.")
        return
      }

      self.delegate?.imageSelectorDidCreateImageData(imageData, metadata: selectedImage.metadata)
      self.deselectSelectedPhotoAsset()
    }

    // If the drawer will be animating, create the photo note after the animation completes.
    if let drawerViewController = drawerViewController {
      drawerViewController.minimizeFromFull(completion: {
        createPhotoNote()
      })
    } else {
      createPhotoNote()
    }
  }

  // MARK: - Notifications

  @objc private func accessibilityVoiceOverStatusChanged() {
    updateCollectionViewScrollEnabled()
  }

}
