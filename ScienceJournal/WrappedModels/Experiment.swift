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

import Foundation

import ScienceJournalProtos

/// A wrapper for GSJExperiment. Represents one experiment.
public class Experiment {

  /// The latest experiment file version.
  public enum Version {
    // The current version number we expect from experiments.
    public static let major: Int32 = 1

    // The current minor version number we expect from experiments.
    public static let minor: Int32 = 2

    // The current platform version number for experiments we write.
    // This is implementation-specific; it _shouldn't_ affect future readers of the data, but it
    // will allow us to detect files written by buggy versions if needed.
    //
    // Set to the current build number. Previous to Science Journal 2.1 the platform versions
    // were not set to build numbers but instead incrementing numbers:
    // v2.0.0   - 1.1.1
    // v2.0.410 - 1.1.1
    // v2.0.512 - 1.1.2
    // v2.0.606 - 1.1.2
    // (NOTE: In development platform is set to a fixed value.)
    public static let platform: Int32 = Bundle.buildVersion
  }

  /// The date the experiment was created.
  var creationDate: Date {
    get {
      return Date(milliseconds: proto.creationTimeMs)
    }
    set {
      proto.creationTimeMs = newValue.millisecondsSince1970
    }
  }

  /// The title of the experiment.
  public private(set) var title: String? {
    get {
      return proto.hasTitle ? proto.title : nil
    }
    set {
      proto.title = newValue
    }
  }

  /// The title of the experiment, if set, otherwise the localized default name.
  public var titleOrDefault: String {
    return title ?? String.defaultExperimentName
  }

  /// The image path of the cover image, relative to the experiment directory.
  public var imagePath: String? {
    get {
      return proto.hasImagePath ? proto.imagePath : nil
    }
    set {
      proto.imagePath = newValue
    }
  }

  /// An array of sensor layouts that corresponds to the most recent layout for any sensors that
  /// have been added. Used to restore the last layout when using sensors.
  var sensorLayouts: [SensorLayout]

  /// An array of trials.
  public var trials: [Trial]

  /// An array of notes.
  public var notes: [Note]

  /// The total count of all notes and trials.
  var itemCount: Int {
    return trials.count + notes.count
  }

  /// An array of sensor triggers.
  var sensorTriggers: [SensorTrigger]

  /// Identifies the intended format version of this file, and the app that wrote it.
  public var fileVersion: FileVersion

  /// The total number of trials ever made in this experiment. This is used to create unique
  /// names for untitled trials.
  var totalTrials: Int32 {
    get {
      return backingProto.totalTrials
    }
    set {
      backingProto.totalTrials = newValue
    }
  }

  /// An array of entries for available sensors.
  var availableSensors: [SensorEntry]

  /// The experiment's available sensor IDs.
  var availableSensorIDs: [String] {
    return availableSensors.map { $0.sensorID }
  }

  /// An array of changes to the experiment, used for Drive sync conflict resolution.
  var changes: [ExperimentChange]

  /// Returns all picture notes found in experiment and trial notes combined.
  public var pictureNotes: [PictureNote] {
    var pictureNotes = notes.compactMap { $0 as? PictureNote }
    pictureNotes += trials.reduce([], { (result, trial) -> [PictureNote] in
      result + trial.notes.compactMap { $0 as? PictureNote }
    })
    return pictureNotes
  }

  /// Whether the experiment contains any items that have corresponding assets.
  public var hasAssetReferences: Bool {
    return trials.count + pictureNotes.count + (imagePath != nil ? 1 : 0) > 0
  }

  /// A proto representation of a trial.
  public var proto: GSJExperiment {
    backingProto.sensorLayoutsArray = NSMutableArray(array: sensorLayouts.map { $0.proto })
    backingProto.trialsArray = NSMutableArray(array: trials.map { $0.proto })
    backingProto.labelsArray = NSMutableArray(array: notes.map { $0.proto })
    backingProto.sensorTriggersArray = NSMutableArray(array: sensorTriggers.map { $0.proto })
    backingProto.fileVersion = fileVersion.proto
    backingProto.availableSensorsArray = NSMutableArray(array: availableSensors.map { $0.proto })
    backingProto.changesArray = NSMutableArray(array: changes.map { $0.proto })
    return backingProto
  }

  /// The experiment's unique ID. The ID is stored for convenience but is not backed by the proto.
  /// ExperimentOverview owns the ID.
  public let ID: String

  /// Returns true if the user has never set a title or image and the experiment has no items,
  /// otherwise returns false.
  public var isEmpty: Bool {
    return title == nil && imagePath == nil && itemCount == 0
  }

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: An experiment proto.
  ///   - ID: A unique ID.
  public init(proto: GSJExperiment, ID: String) {
    let protoCopy = proto.copy() as! GSJExperiment
    sensorLayouts = protoCopy.sensorLayoutsArray.map { SensorLayout(proto: $0 as! GSJSensorLayout) }
    trials = protoCopy.trialsArray.map { Trial(proto: $0 as! GSJTrial) }
    notes = protoCopy.labelsArray.map { Note.from($0 as! GSJLabel) }
    sensorTriggers =
        protoCopy.sensorTriggersArray.map { SensorTrigger(proto: $0 as! GSJSensorTrigger) }
    fileVersion = FileVersion(proto: protoCopy.fileVersion)
    availableSensors =
        protoCopy.availableSensorsArray.map {SensorEntry(proto: $0 as! GSJExperiment_SensorEntry) }
    changes = protoCopy.changesArray.map { ExperimentChange(proto: $0 as! GSJChange) }
    backingProto = protoCopy
    self.ID = ID
  }

  /// Initializes an experiment with an empty proto.
  ///
  /// - Parameter ID: A unique ID.
  public convenience init(ID: String) {
    let proto = GSJExperiment()
    proto.fileVersion.platform = .ios
    self.init(proto: proto, ID: ID)
  }

  /// Sets the title experiment.
  ///
  /// - Parameters:
  ///   - newTitle: A new title or nil.
  ///   - withChange: Whether a change should be recorded for this action.
  func setTitle(_ newTitle: String?, withChange: Bool = true) {
    title = newTitle
    if withChange {
      trackChange(ExperimentChange.modifyChange(forElement: .experiment, withID: ID))
    }
  }

  /// Returns the enabled state of a sensor.
  ///
  /// - Parameter searchId: The sensor id to search for.
  /// - Returns: True if the associated sensor is enabled, otherwise false.
  func isSensorEnabled(_ searchId: String) -> Bool {
    let availableSensors = proto.availableSensorsArray as! [GSJExperiment_SensorEntry]
    let availableIDs = availableSensors.compactMap { $0.sensorId }
    return availableIDs.contains(searchId)
  }

  /// Returns a trial with the given ID.
  ///
  /// - Parameter ID: A string ID.
  /// - Returns: The trial with a matching ID, otherwise nil.
  func trial(withID ID: String) -> Trial? {
    guard let index = trials.index(where: { $0.ID == ID }) else { return nil }
    return trials[index]
  }

  /// Returns an experiment note with the given ID.
  ///
  /// - Parameter ID: A string ID.
  /// - Returns: The note with a matching ID, otherwise nil.
  func note(withID noteID: String) -> Note? {
    guard let index = notes.index(where: { $0.ID == noteID }) else { return nil }
    return notes[index]
  }

  /// Returns either an experiment note or a trial note with the given ID.
  ///
  /// - Parameter noteID: A note ID.
  /// - Returns: The note with a matching ID, otherwise nil.
  func findNote(withID noteID: String) -> (Note?, Trial?) {
    if let index = notes.index(where: { $0.ID == noteID }) {
      return (notes[index], nil)
    } else {
      for trial in trials {
        if let index = trial.notes.index(where: { $0.ID == noteID }) {
          return (trial.notes[index], trial)
        }
      }
    }
    return (nil, nil)
  }

  /// Adds a trial to the experiment.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - withChange: Whether a change should be recorded for this action.
  ///   - isUndo: Whether the add is undoing a deletion.
  func addTrial(_ trial: Trial, withChange: Bool = true, isUndo: Bool) {
    trials.append(trial)

    guard withChange else { return }

    if isUndo {
      trackChange(ExperimentChange.modifyChange(forElement: .trial, withID: trial.ID))
    } else {
      trackChange(ExperimentChange.addChange(forElement: .trial, withID: trial.ID))
    }
  }

  /// Removes a trial with the given ID.
  ///
  /// - Parameters:
  ///   - trialID: A string ID.
  ///   - withChange: Whether a change should be recorded for this action.
  /// - Returns: The trial that was removed.
  @discardableResult func removeTrial(withID trialID: String, withChange: Bool = true) -> Trial? {
    guard let index = trials.index(where: { $0.ID == trialID }) else { return nil }
    if withChange {
      trackChange(ExperimentChange.deleteChange(forElement: .trial, withID: trialID))
    }
    return trials.remove(at: index)
  }

  /// Updates an existing trial by replacing it with a new note with the same ID.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - withChange: Whether a change should be recorded for this action.
  func updateTrial(_ trial: Trial, withChange: Bool) {
    guard let index = trials.index(where: { $0.ID == trial.ID }) else {
      return
    }

    trials[index] = trial.copy
    if withChange {
      trackChange(ExperimentChange.modifyChange(forElement: .trial, withID: trial.ID))
    }
  }

  /// Adds a note at the end of all existig notes.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - withChange: Whether a change should be recorded for this action.
  func addNote(_ note: Note, withChange: Bool = true) {
    insertNote(note, atIndex: notes.endIndex, withChange: withChange, isUndo: false)
  }

  /// Inserts a note at a given index.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - index: The index at which to add the note.
  ///   - withChange: Whether a change should be recorded for this action.
  ///   - isUndo: Whether the insert is undoing a deletion.
  func insertNote(_ note: Note, atIndex index: Int, withChange: Bool = true, isUndo: Bool) {
    notes.insert(note, at: index)

    guard withChange else { return }

    if isUndo {
      trackChange(ExperimentChange.modifyChange(forElement: .note, withID: note.ID))
    } else {
      trackChange(ExperimentChange.addChange(forElement: .note, withID: note.ID))
    }
  }

  /// Removes a note with the given ID.
  ///
  /// - Parameters:
  ///   - noteID: A note ID.
  ///   - withChange: Whether a change should be recorded for this action.
  /// - Returns: The removed note, if a note was removed.
  @discardableResult func removeNote(withID noteID: String,
                                     withChange: Bool = true) -> (Note, Int)? {
    guard let index = notes.index(where: { $0.ID == noteID }) else { return nil }
    let removedNote = notes.remove(at: index)
    if withChange {
      trackChange(ExperimentChange.deleteChange(forElement: .note, withID: noteID))
    }
    return (removedNote, index)
  }

  /// Should be called anytime an experiment or trial note is modified, so the change is tracked
  /// for Drive sync.
  ///
  /// - Parameter noteID: A note ID.
  func noteUpdated(withID noteID: String) {
    trackChange(ExperimentChange.modifyChange(forElement: .note, withID: noteID))
  }

  /// Should be called anytime an experiment or trial note's caption is modified, so the change is
  /// tracked for Drive sync.
  ///
  /// - Parameter noteID: A note ID.
  func noteCaptionUpdated(withID noteID: String) {
    trackChange(ExperimentChange.modifyChange(forElement: .caption, withID: noteID))
  }

  /// Updates an existing note by replacing it with a new note with the same ID.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - withChange: Whether a change should be recorded for this action.
  func updateNote(_ note: Note, withChange: Bool = true) {
    guard let index = notes.index(where: { $0.ID == note.ID }) else {
      return
    }
    notes[index] = note.copy()
    if withChange {
      noteUpdated(withID: note.ID)
    }
  }

  /// Should be called anytime a trial is modified, so the change is tracked for Drive sync.
  ///
  /// - Parameter trialID: A trial ID.
  func trialUpdated(withID trialID: String) {
    trackChange(ExperimentChange.modifyChange(forElement: .trial, withID: trialID))
  }

  /// Returns the sensor triggers for a particular sensor, within the experiment.
  ///
  /// - Parameter sensor: The sensor.
  /// - Returns: The triggers.
  func triggersForSensor(_ sensor: Sensor) -> [SensorTrigger] {
    return sensorTriggers.filter { $0.sensorID == sensor.sensorId  }
  }

  /// Returns the sensor layout for a sensor ID, within the experiment.
  ///
  /// - Parameter sensorID: The sensor ID.
  /// - Returns: The sensor layout.
  func sensorLayoutForSensorID(_ sensorID: String) -> SensorLayout? {
    guard let index = sensorLayouts.index(where: { $0.sensorID == sensorID }) else { return nil }
    return sensorLayouts[index]
  }

  /// Adds a change to an experiment. Changes correspond with modifications to an experiment and
  /// are used by Drive sync to resolve conflicts.
  ///
  /// - Parameter change: An experiment change.
  func trackChange(_ change: ExperimentChange) {
    changes.append(change)
  }

  /// Removes available sensors from the experiment.
  public func removeAvailableSensors() {
    availableSensors.removeAll()
  }

  /// Removes sensor triggers from the experiment.
  public func removeSensorTriggers() {
    sensorTriggers.removeAll()
  }

  /// Removes sensor layouts from the experiment.
  public func removeSensorLayouts() {
    sensorLayouts.removeAll()
  }

  // MARK: - Private

  /// The private backing proto.
  private let backingProto: GSJExperiment

}
