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

/// The data source for displaying experiments in ExperimentsListVC.
class ExperimentsListDataSource {

  // MARK: - Nested types

  struct OverviewSection {

    /// The key for this section, which is YYYY-MonthName.
    var key: String

    /// The title for this section, which is a string month (example: "May"), generated from key.
    var title: String {
      return key.components(separatedBy: "-")[1]
    }

    /// An array of experiment overviews in this section.
    var experimentOverviews = [ExperimentOverview]()

  }

  // MARK: - Properties

  /// Whether or not to include archived experiments.
  var includeArchived: Bool {
    didSet {
      guard includeArchived != oldValue else { return }
      overviewSections.removeAll()
      configureOverviewSections(metadataManager.experimentOverviews)
    }
  }

  /// The section index for a collection view header.
  let collectionViewHeaderSectionIndex = 0

  /// Whether or not to show a collection view header.
  var shouldShowCollectionViewHeader = false

  private let calendar = Calendar.current
  private let metadataManager: MetadataManager
  private var overviewSections = [OverviewSection]()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - includeArchived: Whether or not to include archived experiments.
  ///   - metadataManager: The metadata manager.
  init(includeArchived: Bool, metadataManager: MetadataManager) {
    self.includeArchived = includeArchived
    self.metadataManager = metadataManager
    configureOverviewSections(metadataManager.experimentOverviews)
  }

  /// The number of sections in the collection.
  var numberOfSections: Int {
    /// The overview sections, plus the collection view header section.
    return overviewSections.count + 1
  }

  /// The number of items in a given section.
  func numberOfItemsInSection(_ section: Int) -> Int {
    guard !isCollectionViewHeaderSection(atIndex: section) else { return 0 }

    // The first section is the collection view header section.
    return overviewSections[section - 1].experimentOverviews.count
  }

  /// The total number of items in all overview sections.
  var itemCount: Int {
    return overviewSections.reduce(0, { (result, section) -> Int in
      return result + section.experimentOverviews.count
    })
  }

  /// Whether or not there are no experiments in the data source.
  var isEmpty: Bool {
    return itemCount == 0
  }

  /// Adds an experiment to the correct section, creating the section if necessary.
  ///
  /// - Parameters:
  ///   - overview: An experiment overview.
  ///   - atBeginning: Whether to insert sections at the beginning, and overviews at the beginning
  ///                  of sections, or if the dates should be compared to decide insertion index.
  /// - Returns: A set of collection view changes to perform.
  @discardableResult func insertOverview(_ overview: ExperimentOverview,
                                         atBeginning: Bool = false) -> [CollectionViewChange] {
    let key = sectionKeyFromDate(overview.lastUsedDate)
    if let sectionIndex = overviewSections.firstIndex(where: { $0.key == key }) {
      // If this section exists, insert the experiment in the section to preserve descending sort
      // order (newest at top).
      var itemInsertIndex = 0
      if !atBeginning {
        // Figure out where to insert this overview into the section.
        for (index, sectionOverview) in
            overviewSections[sectionIndex].experimentOverviews.enumerated() {
          if overview.lastUsedDate > sectionOverview.lastUsedDate {
            // If the overview to insert has a last used date newer than the overview at this index,
            // insert it here. No need to check any further.
            itemInsertIndex = index
            break
          } else {
            // If the overview to insert is older than the overview at this index, it needs to be
            // inserted after it. Continue checking the remaining overviews, though.
            itemInsertIndex = index + 1
          }
        }
      }
      overviewSections[sectionIndex].experimentOverviews.insert(overview, at: itemInsertIndex)

      // The collection view section to insert at should be one more than the overviewSections
      // index.
      return [.insert([IndexPath(item: itemInsertIndex, section: sectionIndex + 1)])]
    } else {
      // Section doesn't exist, create it, and insert it in the sections array to preserve
      // descending sort order (newest at top).
      var insertIndex = 0
      if !atBeginning {
        // Figure out where to insert this section.
        for (index, section) in overviewSections.enumerated() {
          guard let sectionOverview = section.experimentOverviews.first else { continue }
          if overview.lastUsedDate > sectionOverview.lastUsedDate {
            // If the section to insert has an overview with a last used date newer than an overview
            // in this section, insert the section here. No need to check any further.
            insertIndex = index
            break
          } else {
            // If the section to insert is older than an overview in this section, it needs to be
            // inserted after it. Continue checking the remaining sections, though.
            insertIndex = index + 1
          }
        }
      }
      let newSection = OverviewSection(key: key, experimentOverviews: [overview])
      overviewSections.insert(newSection, at: insertIndex)

      // The collection view section to insert at should be one more than the overviewSections
      // index.
      return [.insertSections([insertIndex + 1])]
    }
  }

  func updateOverview(withID experimentID: String) -> [CollectionViewChange]? {
    guard let overview = overview(withID: experimentID),
        let indexPath = indexPath(of: overview) else {
      return nil
    }
    return [.reload([indexPath])]
  }

  func addOrUpdateOverview(_ overview: ExperimentOverview) -> [CollectionViewChange] {
    if let indexPath = indexPath(of: overview) {
      return [.reload([indexPath])]
    } else {
      return insertOverview(overview, atBeginning: false)
    }
  }

  /// Deletes an experiment with the given ID.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: Collection view changes if the operation succeeded.
  func removeExperiment(withID experimentID: String) -> [CollectionViewChange]? {
    guard let overview = overview(withID: experimentID),
        let indexPath = self.indexPath(of: overview) else {
      return nil
    }

    // Remove the item from the data source.
    // The overview sections are one less than the index path section.
    let sectionIndex = indexPath.section - 1

    overviewSections[sectionIndex].experimentOverviews.remove(at: indexPath.item)

    // If there are still going to be items in the section, just remove the item.
    var collectionViewChange: CollectionViewChange = .delete([indexPath])
    if numberOfItemsInSection(indexPath.section) == 0 {
      // If there are now zero items, remove the section.
      overviewSections.remove(at: sectionIndex)
      collectionViewChange = .deleteSections([indexPath.section])
    }
    return [collectionViewChange]
  }

  /// Update data after a change such as a deletion.
  func updateOverviewSections() {
    overviewSections.removeAll()
    configureOverviewSections(metadataManager.experimentOverviews)
  }

  /// Returns an experiment overview at the given index path.
  ///
  /// - Parameter indexPath: The index path for the given item.
  /// - Returns: An experiment overview at the given path.
  func itemAt(_ indexPath: IndexPath) -> ExperimentOverview? {
    guard !isCollectionViewHeaderSection(atIndex: indexPath.section) else { return nil }

    // The first section is the collection view header section, subtract one from the section index.
    return overviewSections[indexPath.section - 1].experimentOverviews[indexPath.item]
  }

  /// Returns a header string for the given section.
  ///
  /// - Parameter indexPath: The index path for the header.
  /// - Returns: A string header for the given path (example: "May").
  func headerAt(_ indexPath: IndexPath) -> String {
    guard !isCollectionViewHeaderSection(atIndex: indexPath.section) else { return "" }

    // The first section is the collection view header section, subtract one from the section index.
    return overviewSections[indexPath.section - 1].title
  }

  /// Whether or not this is the collection view header section.
  func isCollectionViewHeaderSection(atIndex index: Int) -> Bool {
    return index == collectionViewHeaderSectionIndex
  }

  /// Returns the index path of the item that has the cover image with the given path.
  ///
  /// - Parameter imagePath: An image path.
  /// - Returns: The index path.
  func indexPath(ofItemContainingImagePath imagePath: String) -> IndexPath? {
    for (sectionIndex, overviewSection) in overviewSections.enumerated() {
      for (overviewIndex, experimentOverview) in overviewSection.experimentOverviews.enumerated() {
        if let overviewImagePath = experimentOverview.imagePath {
          let imageURL =
              metadataManager.pictureFileURL(for: overviewImagePath,
                                             experimentID: experimentOverview.experimentID)
          if imagePath == imageURL.path {
            return IndexPath(item: overviewIndex, section: sectionIndex + 1)
          }
        }
      }
    }

    return nil
  }

  // MARK: - Private

  private func overview(withID experimentID: String) -> ExperimentOverview? {
    let overviews = overviewSections.reduce([]) { (result, section) -> [ExperimentOverview] in
      return result + section.experimentOverviews
    }
    guard let index = overviews.firstIndex(where: { $0.experimentID == experimentID }) else {
      return nil
    }
    return overviews[index]
  }

  /// Returns the indexPath for a given overview, if found.
  ///
  /// - Parameter experimentOverview: The overview to look for.
  /// - Returns: The index path of the overview, if found.
  private func indexPath(of experimentOverview: ExperimentOverview) -> IndexPath? {
    let key = sectionKeyFromDate(experimentOverview.lastUsedDate)
    guard let sectionIndex = overviewSections.firstIndex(where: { $0.key == key }),
      let overviewIndex = overviewSections[sectionIndex].experimentOverviews.firstIndex(
          where: { $0.experimentID == experimentOverview.experimentID }) else { return nil }

    // Section plus one, to account for the collection view header section.
    return IndexPath(item: overviewIndex, section: sectionIndex + 1)
  }

  // Generates a section key from the date of an overview.
  private func sectionKeyFromDate(_ date: Date) -> String {
    let year = calendar.component(.year, from: date)
    let month = calendar.monthSymbols[calendar.component(.month, from: date) - 1]
    return "\(year)-\(month)"
  }

  // Configure experiment overviews by sorting and grouping into sections.
  private func configureOverviewSections(_ experimentOverviews: [ExperimentOverview]) {
    // Sort the experiments.
    let sortedOverviews = experimentOverviews.sorted { $0.lastUsedDate < $1.lastUsedDate }

    for overview in sortedOverviews {
      // If we should not include archived and this experiment is, skip it.
      if !includeArchived && overview.isArchived { continue }

      // Insert the overview.
      insertOverview(overview, atBeginning: true)
    }
  }

}
