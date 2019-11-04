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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJTrial. Represents a collection of data during a discrete recording event.
/// Includes sensor data and notes.
public class Trial {

  // MARK: - Properties

  /// A trial's unique ID.
  public var ID: String {
    get {
      return backingProto.trialId
    }
    set {
      backingProto.trialId = newValue
    }
  }

  /// The trial's creation date.
  var creationDate: Date {
    get {
      return Date(milliseconds: backingProto.creationTimeMs)
    }
    set {
      backingProto.creationTimeMs = newValue.millisecondsSince1970
    }
  }

  /// The trial's title.
  private(set) var title: String? {
    get {
      guard backingProto.hasTitle else {
        return nil
      }
      return backingProto.title
    }
    set {
      backingProto.title = newValue
    }
  }

  /// Whether the trial is archived.
  var isArchived: Bool {
    get {
      return backingProto.archived
    }
    set {
      backingProto.archived = newValue
    }
  }

  /// The time range for the recording.
  var recordingRange: ChartAxis<Int64> {
    get {
      return ChartAxis(min: backingProto.recordingRange.startMs,
                       max: backingProto.recordingRange.endMs)
    }
    set {
      backingProto.recordingRange.startMs = newValue.min
      backingProto.recordingRange.endMs = newValue.max
    }
  }

  /// The trial's duration interval (recording range end minus recording range start), in seconds.
  var durationInterval: TimeInterval {
    if let cropRange = cropRange {
      return TimeInterval((cropRange.max - cropRange.min) / 1000)
    } else {
      return TimeInterval((recordingRange.max - recordingRange.min) / 1000)
    }
  }

  /// The cropped time range.
  var cropRange: ChartAxis<Int64>? {
    get {
      guard backingProto.hasCropRange else { return nil }
      return ChartAxis(min: backingProto.cropRange.startMs, max: backingProto.cropRange.endMs)
    }
    set {
      if let range = newValue {
        let rangeProto = GSJRange()
        rangeProto.startMs = range.min
        rangeProto.endMs = range.max
        backingProto.cropRange = rangeProto
      } else {
        backingProto.cropRange = nil
      }
    }
  }

  /// Whether auto-zoom is enabled.
  var isAutoZoomEnabled: Bool {
    get {
      return backingProto.autoZoomEnabled
    }
    set {
      backingProto.autoZoomEnabled = newValue
    }
  }

  /// The sensor layouts that correspond to the recorded sensors.
  var sensorLayouts: [SensorLayout]

  /// The stats for a sensor recording, one for each recording.
  var trialStats: [TrialStats]

  /// The notes attached to the trial.
  public var notes: [Note]

  /// A caption for the trial. This property is deprecated and should not be used. Trials can no
  /// longer have captions.
  var caption: Caption?

  /// The unique number for of this trial within an experiment, used to name the trial if a custom
  /// name has not been set. Indexes start at 1, not 0.
  var trialNumberInExperiment: Int32 {
    get {
      return backingProto.trialNumberInExperiment
    }
    set {
      backingProto.trialNumberInExperiment = newValue
    }
  }

  /// A proto representation of a trial.
  var proto: GSJTrial {
    // Update arrays.
    backingProto.sensorLayoutsArray = NSMutableArray(array: sensorLayouts.map { $0.proto })
    backingProto.trialStatsArray = NSMutableArray(array: trialStats.map { $0.proto })
    backingProto.labelsArray = NSMutableArray(array: notes.map { $0.proto })
    backingProto.caption = caption?.proto
    return backingProto
  }

  /// A data representation of the underlying proto. Read-only.
  var data: Data? {
    return proto.data()
  }

  /// Returns a copy of the trial. This is not a deep copy.
  var copy: Trial {
    return Trial(trial: self)
  }

  /// An array of image paths for a given trial.
  var allImagePaths: [String] {
    return notes.compactMap { ($0 as? PictureNote)?.filePath }
  }

  /// Designated initializer.
  ///
  /// - Parameter proto: A trial proto.
  init(proto: GSJTrial) {
    // swiftlint:disable force_cast
    let protoCopy = proto.copy() as! GSJTrial
    sensorLayouts = protoCopy.sensorLayoutsArray.map { SensorLayout(proto: $0 as! GSJSensorLayout) }
    trialStats = protoCopy.trialStatsArray.map { TrialStats(proto: $0 as! GSJSensorTrialStats) }
    notes = protoCopy.labelsArray.map { Note.from($0 as! GSJLabel) }
    // swiftlint:enable force_cast
    caption = protoCopy.hasCaption ? Caption(proto: protoCopy.caption) : nil
    backingProto = protoCopy
  }

  /// Initializes a trial with a trialID and empty proto.
  /// - Parameter trialID: A trial ID.
  convenience init(trialID: String = UUID().uuidString) {
    let proto = GSJTrial()
    self.init(proto: proto)
    ID = trialID
    creationDate = Date()
  }

  /// Convenience initializer that creates a new trial from a given trial. The new trial is a true
  /// copy with the same ID.
  ///
  /// - Parameter note: A note.
  convenience init(trial: Trial) {
    // swiftlint:disable force_cast
    self.init(proto: trial.proto.copy() as! GSJTrial)
    // swiftlint:enable force_cast
  }

  /// Sets the trial's title.
  ///
  /// - Parameters:
  ///   - newTitle: A title.
  ///   - experiment: The experiment that owns the trial.
  ///   - withChange: Whether a change should be tracked for this modification.
  func setTitle(_ newTitle: String?, experiment: Experiment, withChange: Bool = true) {
    title = newTitle

    if withChange {
      experiment.trackChange(ExperimentChange.modifyChange(forElement: .trial, withID: ID))
    }
  }

  /// Returns the sensor trial stats for a sensor.
  ///
  /// - Parameter sensorId: The sensor ID.
  /// - Returns: The sensor trial stats.
  func sensorTrialStats(for sensorID: String) -> TrialStats? {
    return trialStats.first(where: { $0.sensorID == sensorID })
  }

  func sensorLayout(forSensorID sensorID: String) -> SensorLayout? {
    let sensorLayouts = proto.sensorLayoutsArray.compactMap { $0 as? GSJSensorLayout }
    guard let sensor = sensorLayouts.first(where: { $0.sensorId == sensorID }) else {
      return nil
    }
    return SensorLayout(proto: sensor)
  }

  /// Returns the appearance of a sensor.
  ///
  /// - Parameter sensorID: The sensor ID.
  /// - Returns: The appearance for the sensor.
  func sensorAppearance(for sensorID: String) -> BasicSensorAppearance? {
    let appearances = proto.sensorAppearancesArray.compactMap { $0 as? GSJTrial_AppearanceEntry }
    guard let proto = appearances.first(where: { $0.sensorId == sensorID }) else { return nil }
    return BasicSensorAppearance(proto: proto.rememberedAppearance)
  }

  /// Adds the appearance of a sensor.
  ///
  /// - Parameters:
  ///   - appearance: A basic sensor appearance.
  ///   - sensorID: The sensor ID.
  func addSensorAppearance(_ appearance: BasicSensorAppearance, for sensorID: String) {
    let appearanceEntry = GSJTrial_AppearanceEntry()
    appearanceEntry.sensorId = sensorID
    appearanceEntry.rememberedAppearance = appearance.proto
    proto.sensorAppearancesArray.add(appearanceEntry)
  }

  /// Removes all sensor appearances.
  func removeAllSensorAppearances() {
    proto.sensorAppearancesArray.removeAllObjects()
  }

  /// Returns a note with the given ID.
  ///
  /// - Parameter ID: A string ID.
  /// - Returns: The note with a matching ID, otherwise nil.
  func note(withID noteID: String) -> Note? {
    return notes.first(where: { $0.ID == noteID })
  }

  /// Adds a note.
  ///
  /// - Parameters:
  ///   - note: A note to insert.
  ///   - experiment: The experiment that owns the trial.
  ///   - withChange: Whether a change should be recorded for this action.
  ///   - isUndo: Whether the insert is undoing a deletion.
  func addNote(_ note: Note, experiment: Experiment, withChange: Bool = true, isUndo: Bool) {
    insertNote(note,
               atIndex: notes.endIndex,
               experiment: experiment,
               withChange: withChange,
               isUndo: isUndo)
  }

  /// Inserts a note at a given index.
  ///
  /// - Parameters:
  ///   - note: A note to insert.
  ///   - index: The index at which to insert the note.
  ///   - experiment: The experiment that owns the trial.
  ///   - withChange: Whether a change should be recorded for this action.
  ///   - isUndo: Whether the insert is undoing a deletion.
  func insertNote(_ note: Note,
                  atIndex index: Int,
                  experiment: Experiment,
                  withChange: Bool = true,
                  isUndo: Bool) {
    notes.insert(note, at: index)

    guard withChange else { return }

    if isUndo {
      experiment.trackChange(ExperimentChange.modifyChange(forElement: .note, withID: note.ID))
    } else {
      experiment.trackChange(ExperimentChange.addChange(forElement: .note, withID: note.ID))
    }
  }

  /// Removes a note with the given ID.
  ///
  /// - Parameters:
  ///   - noteID: A note ID.
  ///   - experiment: The experiment that owns the trial.
  ///   - withChange: Whether a change should be recorded for this action.
  /// - Returns: A tuple of the removed note and its index, if a note was removed.
  @discardableResult func removeNote(withID noteID: String,
                                     experiment: Experiment,
                                     withChange: Bool = true) -> (Note, Int)? {
    guard let index = notes.firstIndex(where: { $0.ID == noteID }) else {
      return nil
    }
    let removedNote = notes.remove(at: index)
    if withChange {
      experiment.trackChange(ExperimentChange.deleteChange(forElement: .note, withID: noteID))
    }
    return (removedNote, index)
  }

  /// Updates an existing note by replacing it with a new note with the same ID.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - experiment: The experiment that owns the trial.
  ///   - withChange: Whether a change should be recorded for this action.
  func updateNote(_ note: Note, experiment: Experiment, withChange: Bool = true) {
    guard let index = notes.firstIndex(where: { $0.ID == note.ID }) else {
      return
    }
    notes[index] = note.copy()

    if withChange {
      experiment.noteUpdated(withID: note.ID)
    }
  }

  // Estimates the database size based on an experimentally derived estimate of how many bytes one
  // second of one sensor uses when written to Core Data.
  var estimatedRecordingDatabaseSize: Double {
    return 1430 * durationInterval * Double(sensorLayouts.count)
  }

  // MARK: - Private

  /// The private backing proto.
  private let backingProto: GSJTrial

}
