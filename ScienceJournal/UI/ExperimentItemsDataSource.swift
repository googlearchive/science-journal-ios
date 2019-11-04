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

protocol ExperimentItemsDataSourceDelegate: class {
  /// Called when the experiment data source changes.
  ///
  /// - Parameters:
  ///   - experimentDataSource: The experiment data source.
  ///   - changes: An array of changes.
  ///   - indexPath: An optional index path to scroll to.
  func experimentDataSource(_ experimentDataSource: ExperimentItemsDataSource,
                            didChange changes: [CollectionViewChange],
                            scrollToIndexPath indexPath: IndexPath?)
}

/// The data source for displaying experiment items.
class ExperimentItemsDataSource {

  // MARK: - Nested types

  /// Represents the sections of the experiment view.
  enum Section: Int {
    // The archived flag.
    case archivedFlag
    // The experiment data.
    case experimentData
    // The recording trial.
    case recordingTrial

    static let numberOfSections = 3

    init(collectionViewSection: Int) {
      // Force unwrap because an invalid section indicates an invalid application state which
      // should crash.
      self.init(rawValue: collectionViewSection)!
    }
  }

  // MARK: - Properties

  /// The archived flag section index.
  var archivedFlagSectionIndex = Section.archivedFlag.rawValue

  /// The archived flag index path.
  let archivedFlagIndexPath = IndexPath(item: 0, section: Section.archivedFlag.rawValue)

  /// Whether to show the archived flag.
  var shouldShowArchivedFlag: Bool {
    didSet {
      guard shouldShowArchivedFlag != oldValue else {
        return
      }

      let change: CollectionViewChange
      if shouldShowArchivedFlag {
        change = .insert([archivedFlagIndexPath])
      } else {
        change = .delete([archivedFlagIndexPath])
      }
      delegate?.experimentDataSource(self, didChange: [change], scrollToIndexPath: nil)
    }
  }

  /// The experiment data section index.
  var experimentDataSectionIndex = Section.experimentData.rawValue

  /// The recording trial section index.
  var recordingTrialSectionIndex = Section.recordingTrial.rawValue

  /// The experiment items. These can be trials or notes.
  var experimentItems = [DisplayItem]()

  /// The delegate.
  weak var delegate: ExperimentItemsDataSourceDelegate?

  /// The recording trial, if there is one in progress.
  private var recordingTrial: DisplayTrial?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter shouldShowArchivedFlag: Whether to show the archived flag.
  init(shouldShowArchivedFlag: Bool) {
    self.shouldShowArchivedFlag = shouldShowArchivedFlag
  }

  /// Returns the item at an index, within a section.
  ///
  /// - Parameters:
  ///   - section: The section.
  ///   - index: The index.
  /// - Returns: The display item.
  func item(inSection section: Section, atIndex index: Int) -> DisplayItem? {
    switch section {
    case .experimentData:
      guard index < experimentItems.endIndex else { return nil }
      return experimentItems[index]
    case .recordingTrial:
      // Index 0 is the trial itself. Note indexes are 1 less than `index`.
      if index == 0 {
        return recordingTrial
      } else {
        return recordingTrial?.notes[index - 1]
      }
    default:
      return nil
    }
  }

  /// The number of sections in the data source.
  var numberOfSections = Section.numberOfSections

  /// The total number of experiment data items.
  var itemCount: Int {
    return experimentItems.count
  }

  /// The total number of recording trial items.
  var recordingTrialItemCount: Int {
    guard let recordingTrial = recordingTrial else { return 0 }
    // 1 for the trial itself, plus all of the notes.
    return 1 + recordingTrial.notes.count
  }

  /// The number of items in the data source.
  func numberOfItemsInSection(_ section: Int) -> Int {
    switch Section(collectionViewSection: section) {
    case .archivedFlag: return shouldShowArchivedFlag ? 1 : 0
    case .experimentData: return itemCount
    case .recordingTrial: return recordingTrialItemCount
    }
  }

  /// The section type at the index.
  func section(atIndex index: Int) -> Section {
    return Section(collectionViewSection: index)
  }

  /// Whether the section is the archived flag section.
  ///
  /// - Parameter index: A section index.
  /// - Returns: True if the section is the archived flag section, false if not.
  func isArchivedFlagSection(_ index: Int) -> Bool {
    return index == archivedFlagSectionIndex
  }

  /// Whether the section is the experiment data section.
  ///
  /// - Parameter index: A section index.
  /// - Returns: True if the section is the experiment data section, false if not.
  func isExperimentDataSection(_ index: Int) -> Bool {
    return index == experimentDataSectionIndex
  }

  /// Whether the section is the recording trial section.
  ///
  /// - Parameter index: A section index.
  /// - Returns: True if the section is the recording trial section, false if not.
  func isRecordingTrialSection(_ index: Int) -> Bool {
    return index == recordingTrialSectionIndex
  }

  // MARK: - Item Updates

  /// If a trial with a matching ID exists it will be updated with the given trial, otherwise the
  /// trial will be added in the proper sort order.
  ///
  /// - Parameter displayTrial: A display trial.
  func addOrUpdateTrial(_ displayTrial: DisplayTrial) {
    if experimentItems.firstIndex(
      where: { $0 is DisplayTrial && $0.ID == displayTrial.ID }) != nil {
      // Trial exists so update it.
      updateTrial(displayTrial)
    } else {
      // Trial doesn't exist, so add it in the right place.
      addItem(displayTrial, sorted: true)
    }
  }

  /// Adds an experiment item to the end of the existing items.
  ///
  /// - Parameters:
  ///   - displayItem: A display item.
  ///   - isSorted: Whether the item should be inserted in the correct sort order or added
  ///               to the end.
  func addItem(_ displayItem: DisplayItem, sorted isSorted: Bool) {
    var insertIndex: Int
    if isSorted {
      insertIndex = 0
      // Find the index where the item belongs sorted by timestamp ascending.
      for (index, item) in experimentItems.enumerated() {
        if displayItem.timestamp.milliseconds < item.timestamp.milliseconds {
          break
        }
        insertIndex = index + 1
      }
    } else {
      insertIndex = experimentItems.endIndex
    }
    experimentItems.insert(displayItem, at: insertIndex)
    let indexPath = IndexPath(item: insertIndex, section: experimentDataSectionIndex)
    delegate?.experimentDataSource(self,
                                   didChange: [.insert([indexPath])],
                                   scrollToIndexPath: indexPath)
  }

  /// Adds or updates a recording trial.
  ///
  /// - Parameter recordingTrial: A recording trial.
  func addOrUpdateRecordingTrial(_ recordingTrial: DisplayTrial) {
    let previousCount = recordingTrialItemCount
    self.recordingTrial = recordingTrial

    guard recordingTrialItemCount >= previousCount else { return }

    // The only collection view changes that can occur are for new cells to be inserted, and for the
    // cell that was previously the last one to have its bottom border removed by reloading it.
    var indexPathToReload: IndexPath?
    var indexPathToInsert: IndexPath?
    for index in previousCount..<recordingTrialItemCount {
      if previousCount > 0 {
        indexPathToReload = IndexPath(item: index - 1, section: recordingTrialSectionIndex)
      }
      indexPathToInsert = IndexPath(item: index, section: recordingTrialSectionIndex)
    }

    var changes = [CollectionViewChange]()
    if let indexPathToReload = indexPathToReload {
      changes.append(.reload([indexPathToReload]))
    }
    if let indexPathToInsert = indexPathToInsert {
      changes.append(.insert([indexPathToInsert]))
    }
    delegate?.experimentDataSource(self, didChange: changes, scrollToIndexPath: indexPathToInsert)
  }

  /// Removes the recording trial.
  func removeRecordingTrial() {
    // All recording trial index paths need to removed.
    var indexPaths = [IndexPath]()
    for index in 0..<recordingTrialItemCount {
      indexPaths.append(IndexPath(item: index, section: recordingTrialSectionIndex))
    }

    recordingTrial = nil
    delegate?.experimentDataSource(self,
                                   didChange: [.delete(indexPaths)],
                                   scrollToIndexPath: nil)
  }

  /// Removes the trial with a given ID.
  ///
  /// - Parameter trialID: A trial ID.
  /// - Returns: The index of the removed trial if the removal succeeded.
  @discardableResult func removeTrial(withID trialID: String) -> Int? {
    guard let index =
        experimentItems.firstIndex(where: { $0 is DisplayTrial && $0.ID == trialID }) else {
      return nil
    }
    experimentItems.remove(at: index)
    let indexPath = IndexPath(item: index, section: experimentDataSectionIndex)
    delegate?.experimentDataSource(self, didChange: [.delete([indexPath])], scrollToIndexPath: nil)
    return index
  }

  /// Updates a matching trial with a new trial.
  ///
  /// - Parameter displayTrial: A display trial.
  func updateTrial(_ displayTrial: DisplayTrial) {
    guard let index =
        experimentItems.firstIndex(where: { $0 is DisplayTrial && $0.ID == displayTrial.ID }) else {
      return
    }
    updateItem(displayTrial, atIndex: index)
  }

  /// Updates a matching note with a new note.
  ///
  /// - Parameter displayNote: A display note.
  func updateNote(_ displayNote: DisplayNote) {
    guard let index =
        experimentItems.firstIndex(where: { $0 is DisplayNote && $0.ID == displayNote.ID }) else {
      return
    }
    updateItem(displayNote, atIndex: index)
  }

  /// Removes the note with a given ID.
  ///
  /// - Parameter noteID: A note ID.
  func removeNote(withNoteID noteID: String) {
    guard let index =
        experimentItems.firstIndex(where: { $0 is DisplayNote && $0.ID == noteID }) else {
      return
    }
    experimentItems.remove(at: index)
    let indexPath = IndexPath(item: index, section: experimentDataSectionIndex)
    delegate?.experimentDataSource(self, didChange: [.delete([indexPath])], scrollToIndexPath: nil)
  }

  // MARK: - Private

  /// Replaces the trial at the given index with a new item.
  ///
  /// - Parameters:
  ///   - displayItem: A display item.
  ///   - index: The index to replace.
  private func updateItem(_ displayItem: DisplayItem, atIndex index: Int) {
    experimentItems.remove(at: index)
    experimentItems.insert(displayItem, at: index)
    let indexPath = IndexPath(item: index, section: experimentDataSectionIndex)
    delegate?.experimentDataSource(self,
                                   didChange: [.reload([indexPath])],
                                   scrollToIndexPath: indexPath)
  }

}
