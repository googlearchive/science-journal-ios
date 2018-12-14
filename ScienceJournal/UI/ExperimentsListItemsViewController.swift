/*
 *  Copyright 2019 Google Inc. All Rights Reserved.
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

import third_party_objective_c_material_components_ios_components_Collections_Collections
import third_party_objective_c_material_components_ios_components_Palettes_Palettes

protocol ExperimentsListItemsDelegate: class {
  /// Tells the delegate the user selected an experiment.
  func experimentsListItemsViewControllerDidSelectExperiment(withID experimentID: String)
}

/// Signature for a block that configures a collection view header.
typealias ExperimentsListHeaderConfigurationBlock = (UICollectionReusableView) -> Void

/// Signature for a block that calculates the size of the collection view header in a given width.
typealias ExperimentsListHeaderSizeBlock = (CGFloat) -> CGSize

/// Signature for a block that configures a cell for an experiment overview, with an optional image.
typealias ExperimentsListCellConfigurationBlock =
    (UICollectionViewCell, ExperimentOverview?, UIImage?) -> Void

/// Signature for a block that calculates the size of the item to display in a given width.
typealias ExperimentsListCellSizeBlock = (CGFloat) -> CGSize

/// The view controller that owns the collection view with the list of the user's experiments.
class ExperimentsListItemsViewController: UIViewController, UICollectionViewDataSource,
    UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

  // MARK: - Properties

  /// The experiments list items delegate.
  weak var delegate: ExperimentsListItemsDelegate?

  /// The scroll delegate will recieve a subset of scroll delegate calls (didScroll,
  /// didEndDecelerating, didEndDragging, willEndDragging).
  weak var scrollDelegate: UIScrollViewDelegate?

  /// The collection view.
  let collectionView: UICollectionView

  private var collectionViewHeaderConfigurationBlock: ExperimentsListHeaderConfigurationBlock?
  private var collectionViewHeaderSizeBlock: ExperimentsListHeaderSizeBlock?

  /// The item count in the collection view.
  var itemCount: Int {
    return experimentsListDataSource.itemCount
  }

  /// Whether or not the collection view is empty.
  var isEmpty: Bool {
    return experimentsListDataSource.isEmpty
  }

  /// Whether or not to include archived experiments.
  var shouldIncludeArchivedExperiments: Bool {
    didSet {
      self.experimentsListDataSource.includeArchived = shouldIncludeArchivedExperiments
      self.collectionView.collectionViewLayout.invalidateLayout()
      self.collectionView.reloadData()
    }
  }

  /// The configuration block to use for experiments list cells.
  var cellConfigurationBlock: ExperimentsListCellConfigurationBlock?

  /// The size calculation block to use for experiments list cells.
  var cellSizeBlock: ExperimentsListCellSizeBlock?

  private let experimentsListDataSource: ExperimentsListDataSource
  private let metadataManager: MetadataManager
  private let cellClass: AnyClass
  private let sectionHeaderIdentifier = "ExperimentsListHeaderView"
  private let collectionViewHeaderIdentifier = "CollectionViewHeader"

  private var collectionEdgeInsets: UIEdgeInsets {
    return UIEdgeInsets(top: 16,
                        left: 16 + view.safeAreaInsetsOrZero.left,
                        bottom: 16,
                        right: 16 + view.safeAreaInsetsOrZero.right)
  }

  // Are we currently loading an experiment? This is used to prevent users from loading multiple
  // experiments at once due to how we delay showing an experiment for the loading indicator to
  // appear. Also works around split-tap Voice Over gestures which could also rapidly load the same
  // experiment twice.
  private var isLoadingExperiment: Bool = false

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - cellClass: The cell class to use for experiment items.
  ///   - metadataManager: The metadata manager.
  ///   - preferenceManager: The preference manager.
  init(cellClass: AnyClass,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager) {
    self.cellClass = cellClass
    self.metadataManager = metadataManager
    shouldIncludeArchivedExperiments = preferenceManager.shouldShowArchivedExperiments
    experimentsListDataSource =
        ExperimentsListDataSource(includeArchived: shouldIncludeArchivedExperiments,
                                  metadataManager: metadataManager)

    let flowLayout = MDCCollectionViewFlowLayout()
    flowLayout.minimumLineSpacing = MaterialCardCell.cardInsets.bottom
    flowLayout.minimumInteritemSpacing = MaterialCardCell.cardInsets.left
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView.register(cellClass.self,
                            forCellWithReuseIdentifier: NSStringFromClass(cellClass))
    collectionView.register(ExperimentsListHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: sectionHeaderIdentifier)

    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = MDCPalette.grey.tint200
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.isAccessibilityElement = false
    collectionView.shouldGroupAccessibilityChildren = true
    view.addSubview(collectionView)
    collectionView.pinToEdgesOfView(view)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    isLoadingExperiment = false
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { (context) in
      self.collectionView.collectionViewLayout.invalidateLayout()
    })
  }

  /// Updates experiments in the data source and reloads the collection view.
  func updateExperiments() {
    experimentsListDataSource.updateOverviewSections()
    collectionView.reloadData()
  }

  /// Inserts an experiment overview.
  ///
  /// - Parameters:
  ///   - overview: An experiment overview.
  ///   - atBeginning: Whether to insert the overview at the beginning.
  func insertOverview(_ overview: ExperimentOverview, atBeginning: Bool = false) {
    // Collection view will reflect new experiment after it appears again because of section
    // recreation that occurs in `viewWillAppear()`.
    experimentsListDataSource.insertOverview(overview, atBeginning: atBeginning)
  }

  /// Handles the event that an experiment fails to load.
  func handleExperimentLoadingFailure() {
    isLoadingExperiment = false
    collectionView.reloadData()
  }

  /// Should be called when an experiment's archived state changes.
  ///
  /// - Parameters:
  ///   - overview: The experiment overview.
  ///   - shouldUpdateCollectionView: Whether or not to update the collection view.
  /// - Returns: Whether or not the collection view changes.
  func experimentArchivedStateChanged(
      forExperimentOverview overview: ExperimentOverview,
      updateCollectionView shouldUpdateCollectionView: Bool) -> Bool {
    // If the experiment is archived, remove it if necessary.
    var collectionViewChanges: [CollectionViewChange]?
    if overview.isArchived && !experimentsListDataSource.includeArchived {
      collectionViewChanges =
          experimentsListDataSource.removeExperiment(withID: overview.experimentID)
    } else if !overview.isArchived || experimentsListDataSource.includeArchived {
      collectionViewChanges = experimentsListDataSource.addOrUpdateOverview(overview)
    }

    guard shouldUpdateCollectionView, let changes = collectionViewChanges else {
      return false
    }

    collectionView.performChanges(changes)
    return true
  }

  /// Should be called when an experiment is removed.
  ///
  /// - Parameters:
  ///   - experimentID: The experiment ID.
  ///   - shouldUpdateCollectionView: Whether or not to update the collection view.
  /// - Returns: Whether or not the collection view changes.
  @discardableResult func experimentWasRemoved(
      withID experimentID: String, updateCollectionView shouldUpdateCollectionView: Bool) -> Bool {
    let collectionViewChanges = experimentsListDataSource.removeExperiment(withID: experimentID)

    guard shouldUpdateCollectionView, let changes = collectionViewChanges else {
      return false
    }

    collectionView.performChanges(changes)
    return true
  }

  /// Should be called when an experiment is restored.
  ///
  /// - Parameters:
  ///   - overview: The experiment overview.
  ///   - shouldUpdateCollectionView: Whether or not to update the collection view.
  /// - Returns: Whether or not the collection view changes.
  func experimentWasRestored(forExperimentOverview overview: ExperimentOverview,
                             updateCollectionView shouldUpdateCollectionView: Bool) -> Bool {
    guard !overview.isArchived || experimentsListDataSource.includeArchived else {
        return false
    }

    let changes = experimentsListDataSource.insertOverview(overview)

    guard shouldUpdateCollectionView else {
      return false
    }

    collectionView.performChanges(changes)
    return true
  }

  /// Sets an optional header view that can be shown on top of all other content in the collection
  /// view.
  ///
  /// - Parameters:
  ///   - headerViewConfigurationBlock: The header view configuration block, if needed.
  ///   - aClass: The header view class.
  ///   - height: The header view height.
  func setCollectionViewHeader(
      configurationBlock: ExperimentsListHeaderConfigurationBlock? = nil,
      headerSizeBlock: @escaping ExperimentsListHeaderSizeBlock,
      class aClass: AnyClass) {
    collectionViewHeaderConfigurationBlock = configurationBlock
    collectionViewHeaderSizeBlock = headerSizeBlock
    collectionView.register(aClass,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: collectionViewHeaderIdentifier)
    experimentsListDataSource.shouldShowCollectionViewHeader = true
    collectionView.reloadSections(
        [experimentsListDataSource.collectionViewHeaderSectionIndex])
  }

  /// Removes the collection view header.
  func removeCollectionViewHeader() {
    collectionViewHeaderConfigurationBlock = nil
    collectionViewHeaderSizeBlock = nil
    experimentsListDataSource.shouldShowCollectionViewHeader = false
    collectionView.reloadSections(
        [experimentsListDataSource.collectionViewHeaderSectionIndex])
  }

  /// Returns the experiment overview associated with a cell.
  ///
  /// - Parameter cell: An experiments list item cell.
  /// - Returns: The experiment overview.
  func overview(forCell cell: ExperimentsListCellBase) -> ExperimentOverview? {
    guard let indexPath = collectionView.indexPath(for: cell) else { return nil }
    return experimentsListDataSource.itemAt(indexPath)
  }

  /// Reloads visible cells that contain a cover image for one of the given paths.
  ///
  /// - Parameter imagePaths: Paths of images that were newly downloaded.
  func reloadCells(forDownloadedImagePaths imagePaths: [String]) {
    var indexPaths = [IndexPath]()
    for imagePath in imagePaths {
      if let indexPath =
          experimentsListDataSource.indexPath(ofItemContainingImagePath: imagePath),
          collectionView.indexPathsForVisibleItems.contains(indexPath) {
        indexPaths.append(indexPath)
      }
    }

    guard indexPaths.count > 0 else { return }

    collectionView.reloadItems(at: indexPaths)
  }

  // MARK: - Private

  /// Shows the experiment at an index path.
  @objc private func showExperiment(atIndexPath indexPath: IndexPath) {
    if let experimentOverview = experimentsListDataSource.itemAt(indexPath) {
      delegate?.experimentsListItemsViewControllerDidSelectExperiment(
          withID: experimentOverview.experimentID)
    }
  }

  // Returns an image for an experiment overview if possible.
  private func imageForOverview(_ overview: ExperimentOverview?) -> UIImage? {
    guard let overview = overview, let overviewImagePath = overview.imagePath else {
      return nil
    }
    return metadataManager.image(forPicturePath: overviewImagePath,
                                 experimentID: overview.experimentID)
  }

  // MARK: - UICollectionViewDataSource

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return experimentsListDataSource.numberOfSections
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return experimentsListDataSource.numberOfItemsInSection(section)
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(cellClass),
                                                  for: indexPath)
    let overview = experimentsListDataSource.itemAt(indexPath)
    let image = imageForOverview(overview)
    cellConfigurationBlock?(cell, overview, image)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    if experimentsListDataSource.isCollectionViewHeaderSection(atIndex: indexPath.section) {
      let header = collectionView.dequeueReusableSupplementaryView(
          ofKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: collectionViewHeaderIdentifier,
          for: indexPath)
      collectionViewHeaderConfigurationBlock?(header)
      return header
    }

    let header = collectionView.dequeueReusableSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader,
        withReuseIdentifier: sectionHeaderIdentifier,
        for: indexPath)
    if let header = header as? ExperimentsListHeaderView {
      header.textLabel.text = experimentsListDataSource.headerAt(indexPath)
    }
    return header
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    guard !experimentsListDataSource.isCollectionViewHeaderSection(atIndex: section) else {
      return .zero
    }

    return collectionEdgeInsets
  }

  // MARK: - UICollectionViewDelegate

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      referenceSizeForHeaderInSection section: Int) -> CGSize {
    let width = collectionView.bounds.size.width

    if experimentsListDataSource.isCollectionViewHeaderSection(atIndex: section) {
      if experimentsListDataSource.shouldShowCollectionViewHeader,
          let collectionViewHeaderSizeBlock = collectionViewHeaderSizeBlock {
        return collectionViewHeaderSizeBlock(width)
      } else {
        return .zero
      }
    }

    let headerString = experimentsListDataSource.headerAt(IndexPath(item: 0, section: section))
    return CGSize(width: width,
                  height: ExperimentsListHeaderView.viewHeightWithString(headerString,
                                                                         inWidth: width))
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    // In landscape, 4 cells horizontally, in portrait, 2.
    let wide = collectionView.bounds.size.isWiderThanTall
    let availableWidth = collectionView.bounds.size.width - collectionEdgeInsets.left -
        collectionEdgeInsets.right - (MaterialCardCell.cardInsets.left * (CGFloat(wide ? 3 : 1)))
    let itemDimension = floor(availableWidth / CGFloat(wide ? 4 : 2))
    return cellSizeBlock?(itemDimension) ?? CGSize(width: itemDimension, height: itemDimension)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    // If we're currently loading an experiment, do nothing.
    guard !isLoadingExperiment else { return }

    // If this is the collection view header section, do nothing.
    guard !experimentsListDataSource.isCollectionViewHeaderSection(
        atIndex: indexPath.section) else { return }

    isLoadingExperiment = true
    if let cell = collectionView.cellForItem(at: indexPath) as? ExperimentsListCellBase {
      cell.spinner.startAnimating()
      perform(#selector(showExperiment(atIndexPath:)), with: indexPath, afterDelay: 0.1)
    } else {
      showExperiment(atIndexPath: indexPath)
    }
  }

  // MARK: - UIScrollViewDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollDelegate?.scrollViewDidScroll!(scrollView)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollDelegate?.scrollViewDidEndDecelerating!(scrollView)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                willDecelerate decelerate: Bool) {
    scrollDelegate?.scrollViewDidEndDragging!(scrollView, willDecelerate: decelerate)
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                 withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    scrollDelegate?.scrollViewWillEndDragging!(scrollView,
                                               withVelocity: velocity,
                                               targetContentOffset: targetContentOffset)
  }

}
