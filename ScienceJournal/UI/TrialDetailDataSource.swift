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

protocol TrialDetailDataSourceDelegate: class {
  /// Called when the trial detail data source changes.
  ///
  /// - Parameters:
  ///   - trialDetailDataSource: The trial detail data source.
  ///   - changes: An array of changes.
  ///   - scrollIndexPath: An optional index path to scroll to.
  func trialDetailDataSource(_ trialDetailDataSource: TrialDetailDataSource,
                             didChange changes: [CollectionViewChange],
                             scrollTo scrollIndexPath: IndexPath?)
}

// Manages the trial data displayed by TrialDetailViewController.
class TrialDetailDataSource {

  /// Represents the sections of the trial detail view.
  enum Section: Int {
    // The archived flag.
    case archivedFlag
    // The trial header.
    case header
    // The playback chart and all notes.
    case chartAndNotes

    static let numberOfSections = 3

    init(collectionViewSection: Int) {
      // Force unwrap because an invalid section indicates an invalid application state which
      // should crash.
      self.init(rawValue: collectionViewSection)!
    }
  }

  // MARK: - Properties

  /// The trial.
  var trial: Trial

  /// The trial detail data source delegate.
  weak var delegate: TrialDetailDataSourceDelegate?

  /// Returns the title of the trial, either the user created title or a placeholder.
  var trialTitle: String {
    if let displayTrialTitle = displayTrial.title, displayTrialTitle.count > 0 {
      return displayTrialTitle
    } else {
      return displayTrial.alternateTitle
    }
  }

  private(set) var displayTrial: DisplayTrial

  /// The index path of the header.
  var headerIndexPath: IndexPath {
    return IndexPath(item: 0, section: Section.header.rawValue)
  }

  /// The first index of the chart and notes section.
  var chartAndNotesFirstIndexPath: IndexPath {
    return IndexPath(item: 0, section: Section.chartAndNotes.rawValue)
  }

  /// The archived flag index path.
  let archivedFlagIndexPath = IndexPath(item: 0, section: Section.archivedFlag.rawValue)

  /// An experiment data parser.
  private let experimentDataParser: ExperimentDataParser

  private let experimentInteractionOptions: ExperimentInteractionOptions

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - experimentID: The ID of the experiment that owns the trial. Necessary when parsing because
  ///                   picture paths are relative to the experiment directory.
  ///   - experimentDataParser: An experiment data parser.
  ///   - experimentInteractionOptions: Experiment interaction options.
  init(trial: Trial,
       experimentDataParser: ExperimentDataParser,
       experimentInteractionOptions: ExperimentInteractionOptions) {
    self.trial = trial
    self.experimentDataParser = experimentDataParser
    self.experimentInteractionOptions = experimentInteractionOptions
    displayTrial = experimentDataParser.parseTrial(trial)
  }

  /// The number of items in the data source.
  func numberOfItemsInSection(_ section: Int) -> Int {
    switch Section(collectionViewSection: section) {
    case .archivedFlag: return trial.isArchived ? 1 : 0
    case .header: return 1
    case .chartAndNotes:
      // The notes, plus one for the add note to timeline button, if edits are allowed.
      return displayTrial.notes.count + (experimentInteractionOptions.shouldAllowEdits ? 1 : 0)
    }
  }

  /// Whether the section is the archived flag section.
  ///
  /// - Parameter index: A section index.
  /// - Returns: True if the section is the archived flag section, false if not.
  func isArchivedFlagSection(_ index: Int) -> Bool {
    return index == archivedFlagIndexPath.section
  }

  /// Returns a note at an index path.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: A note.
  func noteForIndexPath(_ indexPath: IndexPath) -> Note {
    let index = indexOfNote(forIndexPath: indexPath)
    return trial.notes[index]
  }

  /// Returns a note with a given ID.
  ///
  /// - Parameter noteID: A note ID.
  /// - Returns: A note.
  func noteWithID(_ noteID: String) -> Note? {
    guard let index = trial.notes.index(where: { $0.ID == noteID }) else { return nil }
    return trial.notes[index]
  }

  /// Returns a display note for an index path.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: A display note.
  func displayNoteForIndexPath(_ indexPath: IndexPath) -> DisplayNote {
    let index = indexOfNote(forIndexPath: indexPath)
    return displayTrial.notes[index]
  }

  /// Whether the index path is the add note index path.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: True if the index path is add note, otherwise false.
  func isAddNoteIndexPath(_ indexPath: IndexPath) -> Bool {
    return experimentInteractionOptions.shouldAllowEdits &&
        indexPath.section == Section.chartAndNotes.rawValue && indexPath.item == 0
  }

  /// Whether the index path is the trial header index path.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: True if the index path is the trial header, otherwise false.
  func isTrialHeaderIndexPath(_ indexPath: IndexPath) -> Bool {
    return indexPath.section == Section.header.rawValue
  }

  /// Whether the index path is a valid note index path.
  ///
  /// - Parameter indexPath: An index path.
  /// - Returns: True if the index path is a trial note in a valid range, otherwise false.
  func isTrialNoteIndexPath(_ indexPath: IndexPath) -> Bool {
    if experimentInteractionOptions.shouldAllowEdits {
      return indexPath.section == Section.chartAndNotes.rawValue && indexPath.item > 0 &&
          indexPath.item <= displayTrial.notes.count
    } else {
      return indexPath.section == Section.chartAndNotes.rawValue
    }
  }

  /// Whether the section is the trial notes section.
  ///
  /// - Parameter section: A section.
  /// - Returns: True if the section is the trial notes section, otherwise false.
  func isTrialNotesSection(_ section: Int) -> Bool {
    return section == Section.chartAndNotes.rawValue
  }

  /// Adds a note.
  ///
  /// - Parameters:
  ///   - addedNote: A note.
  ///   - isSorted: Whether the note should be inserted in the correct sort order or added
  ///               to the end.
  /// - Returns: The added display note.
  @discardableResult func addNote(_ addedNote: Note,
                                  sorted isSorted: Bool = false) -> DisplayNote? {
    // Generate the display note if possible.
    guard let addedDisplayNote = experimentDataParser.parseNote(addedNote, forTrial: trial) else {
      return nil
    }

    var insertIndex: Int
    if isSorted {
      insertIndex = 0
      // Find the index where the item belongs sorted by timestamp ascending.
      for (index, displayNote) in displayTrial.notes.enumerated() {
        if addedNote.timestamp < displayNote.timestamp.milliseconds {
          break
        }
        insertIndex = index + 1
      }
    } else {
      insertIndex = displayTrial.notes.endIndex
    }

    // Add the note.
    displayTrial.notes.insert(addedDisplayNote, at: insertIndex)

    // Update collection view.
    let indexPath = indexPathForNote(atIndex: insertIndex)
    delegate?.trialDetailDataSource(self, didChange: [.insert([indexPath])], scrollTo: indexPath)

    return addedDisplayNote
  }

  /// Removes a note.
  ///
  /// - Parameter noteID: A note ID.
  /// - Returns: A tuple with the deleted note and the index of the deleted note.
  func removeNote(withID noteID: String) {
    guard let index = displayTrial.notes.index(where: { $0.ID == noteID }) else {
      return
    }
    displayTrial.notes.remove(at: index)
    let indexPath = indexPathForNote(atIndex: index)
    delegate?.trialDetailDataSource(self, didChange: [.delete([indexPath])], scrollTo: nil)
  }

  /// Updates a note by generating a new display note.
  ///
  /// - Parameter note: A note.
  func updateNote(_ note: Note) {
    guard let index = displayTrial.notes.index(where: { $0.ID == note.ID }),
        let displayNote = experimentDataParser.parseNote(note, forTrial: trial) else {
      return
    }

    displayTrial.notes.remove(at: index)
    displayTrial.notes.insert(displayNote, at: index)

    let indexPath = indexPathForNote(atIndex: index)
    delegate?.trialDetailDataSource(self, didChange: [.reload([indexPath])], scrollTo: nil)
  }

  /// Sets the chart presentation view for a sensor.
  ///
  /// - Parameters:
  ///   - view: The chart presentation view.
  ///   - sensorID: A sensor ID.
  func setChartPresentationView(_ view: UIView, forSensorID sensorID: String) {
    guard let index = displayTrial.sensors.index(where: { $0.ID == sensorID }) else { return }
    var displaySensor = displayTrial.sensors.remove(at: index)
    displaySensor.chartPresentationView = view
    displayTrial.sensors.insert(displaySensor, at: index)
  }

  /// Updates the display trial based on the trial.
  func updateDisplayTrial() {
    displayTrial = experimentDataParser.parseTrial(trial)
  }

  // MARK: - Private

  /// Returns the index path for a note, given its index in the notes array. The adjustment is
  /// necessary because the add note button is at item 0 when edits are allowed.
  ///
  /// - Parameter index: The index of the note in the notes array.
  /// - Returns: The index path for the note.
  private func indexPathForNote(atIndex index: Int) -> IndexPath {
    var itemIndex = index
    if experimentInteractionOptions.shouldAllowEdits {
      itemIndex += 1
    }
    return IndexPath(item: itemIndex, section: Section.chartAndNotes.rawValue)
  }

  /// Returns the index in the notes array of a note, given its index path. The adjustment is
  /// necessary because the add note button is at item 0 when edits are allowed.
  ///
  /// - Parameter indexPath: The index path for the note.
  /// - Returns: The index of the note in the notes array.
  private func indexOfNote(forIndexPath indexPath: IndexPath) -> Int {
    var index = indexPath.item
    if experimentInteractionOptions.shouldAllowEdits {
      index -= 1
    }
    return index
  }

}
