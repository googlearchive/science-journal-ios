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

/// The experiment update manager delegate is designed to observe events specific to the operation
/// of the manager, not for observing changes to an experiment. Register as a listener for
/// experiment-level updates.
protocol ExperimentUpdateManagerDelegate: class {
  /// Informs the delegate an experiment was saved.
  ///
  /// - Parameter experimentID: An experiment ID.
  func experimentUpdateManagerDidSaveExperiment(withID experimentID: String)
}

/// Manages changes to an experiment and notifies interested objects via a listener pattern.
class ExperimentUpdateManager {

  // MARK: - Properties

  /// The experiment being updated.
  var experiment: Experiment

  /// The delegate.
  weak var delegate: ExperimentUpdateManagerDelegate?

  private let sensorDataManager: SensorDataManager
  private let metadataManager: MetadataManager
  private var updateListeners = NSHashTable<AnyObject>.weakObjects()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - experiment: The experiment to manage.
  ///   - metadataManager: The metadata manager.
  ///   - sensorDataManager: The sensor data manager.
  init(experiment: Experiment,
       metadataManager: MetadataManager,
       sensorDataManager: SensorDataManager) {
    self.experiment = experiment
    self.metadataManager = metadataManager
    self.sensorDataManager = sensorDataManager

    // Register for trial stats update notifications.
    NotificationCenter.default.addObserver(self,
        selector: #selector(handleTrialStatsDidCompleteNotification(notification:)),
        name: SensorDataManager.TrialStatsCalculationDidComplete,
        object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Adds the given object as a listener to experiment changes. Listener must conform to
  /// ExperimentUpdateListener to actually recieve updates. Maintains a weak reference to listeners.
  ///
  /// - Parameter listener: Any object that conforms to ExperimentUpdateListener.
  func addListener(_ listener: AnyObject) {
    updateListeners.add(listener)
  }

  /// Removes a listener.
  ///
  /// - Parameter listener: The listener to remove.
  func removeListener(_ listener: AnyObject) {
    updateListeners.remove(listener)
  }

  /// Sets the title of an experiment. Passing nil removes the title.
  ///
  /// - Parameter title: A string title.
  func setTitle(_ title: String?) {
    experiment.setTitle(title)
    saveExperiment()
  }

  /// Sets the experiment's cover image. Passing nil removes the previous image and deletes the
  /// asset from disk.
  ///
  /// - Parameters:
  ///   - imageData: The image data.
  ///   - metadata: The image metadata associated with the image.
  func setCoverImageData(_ imageData: Data?, metadata: NSDictionary?) {
    metadataManager.saveCoverImageData(imageData,
                                       metadata: metadata,
                                       forExperiment: experiment)
    saveExperiment()
  }

  /// Adds a note to the trial with the given ID.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - trialID: A trial ID.
  func addTrialNote(_ note: Note, trialID: String) {
    insertTrialNote(note, trialID: trialID, atIndex: nil)
  }

  /// Inserts a note in a trial with the given ID at a specific index.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - trialID: A trial ID.
  ///   - index: The index to insert the note in the trial.
  func insertTrialNote(_ note: Note, trialID: String, atIndex index: Int?) {
    // Get the trial corresponding to the display trial and the updated note.
    guard let trial = experiment.trial(withID: trialID) else {
      return
    }
    insertTrialNote(note, trial: trial, atIndex: index, isUndo: false)
  }

  /// Inserts a note in a trial at a specifc index.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - trial: A trial.
  ///   - index: The index to insert the note in the trial.
  ///   - isUndo: Whether the insert is undoing a deletion.
  func insertTrialNote(_ note: Note, trial: Trial, atIndex index: Int?, isUndo: Bool) {
    // Add to the end if no index is specified.
    var insertedIndex: Int
    if let index = index {
      insertedIndex = index
    } else {
      insertedIndex = trial.notes.endIndex
    }
    trial.insertNote(note, atIndex: insertedIndex, experiment: experiment, isUndo: isUndo)

    if let pictureNote = note as? PictureNote, let filePath = pictureNote.filePath {
      metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: filePath,
                                                            experiment: experiment)
    }

    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateTrialNoteAdded(note, toTrial: trial)
    }
  }

  /// Add a note to the experiment.
  ///
  /// - Parameter note: A note.
  func addExperimentNote(_ note: Note) {
    insertExperimentNote(note, atIndex: nil, isUndo: false)
  }

  /// Inserts a note in the experiment at a specific index.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - index: The index to insert the note.
  ///   - isUndo: Whether the insert is undoing a deletion.
  func insertExperimentNote(_ note: Note, atIndex index: Int?, isUndo: Bool) {
    // Add to the end if no index is specified.
    var insertedIndex: Int
    if let index = index {
      insertedIndex = index
    } else {
      insertedIndex = experiment.notes.endIndex
    }
    experiment.insertNote(note, atIndex: insertedIndex, isUndo: isUndo)

    if let pictureNote = note as? PictureNote, let filePath = pictureNote.filePath {
      metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: filePath,
                                                            experiment: experiment)
    }

    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateExperimentNoteAdded(note, toExperiment: experiment)
    }
  }

  /// Deletes a note from the experiment.
  ///
  /// - Parameter noteID: A note ID.
  func deleteExperimentNote(withID noteID: String) {
    guard let (removedNote, removedIndex) = experiment.removeNote(withID: noteID) else {
      return
    }

    // Attempt to delete an associated image if one exists.
    let imagePath = (removedNote as? PictureNote)?.filePath
    var coverImageUndo: (() -> Void)?
    if let imagePath = imagePath {
      metadataManager.deleteAssetAtPath(imagePath, experimentID: experiment.ID)
      coverImageUndo =
          metadataManager.updateCoverImageForRemovedImageIfNeeded(imagePath: imagePath,
                                                                  experiment: experiment)
    }

    saveExperiment()

    let undoBlock = {
      self.insertExperimentNote(removedNote, atIndex: removedIndex, isUndo: true)
      if let imagePath = imagePath {
        self.metadataManager.restoreDeletedAssetAtPath(imagePath, experimentID: self.experiment.ID)
      }
      coverImageUndo?()
    }

    notifyListeners { (listener) in
      listener.experimentUpdateExperimentNoteDeleted(removedNote,
                                                     experiment: self.experiment,
                                                     undoBlock: undoBlock)
    }
  }

  /// Deletes a note from a trial.
  ///
  /// - Parameters:
  ///   - noteID: A note ID.
  ///   - trialID: A trial ID.
  func deleteTrialNote(withID noteID: String, trialID: String) {
    guard let trial = experiment.trial(withID: trialID), let (removedNote, removedIndex) =
        trial.removeNote(withID: noteID, experiment: experiment) else {
      return
    }

    // Attempt to delete an associated image if one exists.
    let imagePath = (removedNote as? PictureNote)?.filePath
    var coverImageUndo: (() -> Void)?
    if let imagePath = imagePath {
      metadataManager.deleteAssetAtPath(imagePath, experimentID: experiment.ID)
      coverImageUndo =
          metadataManager.updateCoverImageForRemovedImageIfNeeded(imagePath: imagePath,
                                                                  experiment: experiment)
    }

    saveExperiment()

    let undoBlock = {
      self.insertTrialNote(removedNote, trial: trial, atIndex: removedIndex, isUndo: true)
      if let imagePath = imagePath {
        self.metadataManager.restoreDeletedAssetAtPath(imagePath, experimentID: self.experiment.ID)
      }
      coverImageUndo?()
    }

    notifyListeners { (listener) in
      listener.experimentUpdateTrialNoteDeleted(removedNote,
                                                trial: trial,
                                                experiment: experiment,
                                                undoBlock: undoBlock)
    }
  }

  /// Updates a note's caption. Text notes do not support captions so if `noteID` matches a text
  /// note this method is a no-op.
  ///
  /// - Parameters:
  ///   - captionString: The new caption string or nil to remove the caption.
  ///   - noteID: A note ID.
  ///   - trialID: A trial ID if the note belongs to a trial.
  func updateNoteCaption(_ captionString: String?, forNoteWithID noteID: String, trialID: String?) {
    let (note, trial) = noteWithID(noteID, trialID: trialID)

    // Protect against adding captions to text notes.
    guard let captionedNote = note, !(captionedNote is TextNote) else {
      return
    }

    if let captionString = captionString {
      captionedNote.caption = Caption(text: captionString)
    } else {
      captionedNote.caption = nil
    }

    experiment.noteCaptionUpdated(withID: noteID)
    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateNoteUpdated(captionedNote,
                                           trial: trial,
                                           experiment: experiment)
    }
  }

  /// Updates a text note's text. If `noteID` matches a non-text note, this method is a no-op.
  ///
  /// - Parameters:
  ///   - text: The new note text.
  ///   - noteID: A note ID.
  ///   - trialID: A trial ID if the note belongs to a trial.
  func updateText(_ text: String, forNoteWithID noteID: String, trialID: String?) {
    let (note, trial) = noteWithID(noteID, trialID: trialID)

    // Only text notes have a text attribute.
    guard let textNote = note as? TextNote else {
      return
    }

    textNote.text = text

    experiment.noteUpdated(withID: noteID)
    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateNoteUpdated(textNote, trial: trial, experiment: experiment)
    }
  }

  /// Updates a trial's crop range, title or caption string. Passing nil for an attribute means it
  /// will not be updated. To remove an attribute set an empty value.
  ///
  /// - Parameters:
  ///   - cropRange: A new crop range, optional.
  ///   - trialName: A new trial title, optional.
  ///   - captionString: A new caption string, optional.
  ///   - trialID: A trial ID.
  func updateTrial(cropRange: ChartAxis<Int64>?,
                   name trialName: String?,
                   captionString: String?,
                   forTrialID trialID: String) {
    guard let trial = experiment.trial(withID: trialID) else {
      return
    }

    var saveNeeded = false

    if let cropRange = cropRange {
      trial.cropRange = cropRange
      trial.trialStats.forEach { $0.status = .needsUpdate }
      sensorDataManager.recalculateStatsForTrial(trial, experimentID: experiment.ID)
      saveNeeded = true
    }

    if let trialName = trialName {
      trial.setTitle(trialName, experiment: experiment)
      saveNeeded = true
    }

    if let captionString = captionString {
      trial.caption = Caption(text: captionString)
      saveNeeded = true
    }

    guard saveNeeded else {
      return
    }

    experiment.trialUpdated(withID: trialID)
    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateTrialUpdated(trial, experiment: experiment, updatedStats: false)
    }
  }

  /// Adds a trial to the experiment.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - isRecording: Whether the trial is actively recording data.
  func addTrial(_ trial: Trial, recording isRecording: Bool) {
    addTrial(trial, recording: isRecording, isUndo: false)
  }

  /// Deletes a trial from the experiment. This method does not remove a trial's sensor data in case
  /// the user undoes the delete.
  ///
  /// - Parameter trialID: A trial ID.
  func deleteTrial(withID trialID: String) {
    guard let trial = experiment.removeTrial(withID: trialID) else {
      return
    }
    metadataManager.removeImagesAtPaths(trial.allImagePaths, experiment: experiment)

    saveExperiment()

    let undoBlock = {
      self.addTrial(trial, recording: false, isUndo: true)
      trial.allImagePaths.forEach {
        self.metadataManager.restoreDeletedAssetAtPath($0, experimentID: self.experiment.ID)
      }
      if let firstPath = trial.allImagePaths.first {
        self.metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: firstPath,
                                                                   experiment: self.experiment)
      }
    }

    notifyListeners { (listener) in
      listener.experimentUpdateTrialDeleted(trial, fromExperiment: experiment, undoBlock: undoBlock)
    }
  }

  /// Deletes a trial's sensor data. Sensor data should be deleted only if the user has declined to
  /// undo deleting a trial.
  ///
  /// - Parameter trialID: A trial ID.
  func deleteTrialData(forTrialID trialID: String) {
    sensorDataManager.removeData(forTrialID: trialID)
  }

  /// Toggles the archive state of an experiment.
  ///
  /// - Parameter trialID: A trial ID.
  func toggleArchivedState(forTrialID trialID: String) {
    guard let index = experiment.trials.index(where: { $0.ID == trialID }) else {
      return
    }

    let trial = experiment.trials[index]
    trial.isArchived.toggle()

    experiment.trialUpdated(withID: trialID)
    saveExperiment()

    let undoBlock = {
      self.toggleArchivedState(forTrialID: trialID)
    }

    notifyListeners { (listener) in
      listener.experimentUpdateTrialArchiveStateChanged(trial,
                                                        experiment: experiment,
                                                        undoBlock: undoBlock)
    }
  }

  /// Notifies the experiment update manager the experiment was changed externally and should
  /// be saved.
  func recordingTrialChangedExternally(_ recordingTrial: Trial) {
    if let existingIndex = experiment.trials.index(where: { $0.ID == recordingTrial.ID }) {
      experiment.trials[existingIndex] = recordingTrial
      saveExperiment()
    }
  }

  // MARK: - Private

  /// Adds a trial to the experiment.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - isRecording: Whether the trial is actively recording data.
  ///   - isUndo: Whether the add is undoing a deletion.
  private func addTrial(_ trial: Trial, recording isRecording: Bool, isUndo: Bool) {
    // Recording trials are new, so update the stored trial indexes.
    if isRecording {
      experiment.totalTrials += 1
      trial.trialNumberInExperiment = experiment.totalTrials
    }
    experiment.addTrial(trial, isUndo: isUndo)

    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateTrialAdded(trial, toExperiment: experiment, recording: isRecording)
    }
  }

  /// Notifies all listeners by calling the given block on each valid listener.
  ///
  /// - Parameter block: A block with a listener parameter.
  private func notifyListeners(_ block: (ExperimentUpdateListener) -> Void) {
    updateListeners.allObjects.forEach { (object) in
      guard let listener = object as? ExperimentUpdateListener else { return }
      block(listener)
    }
  }

  /// Returns the note with the given ID. Searches trial notes if a trial ID is given.
  ///
  /// - Parameters:
  ///   - noteID: A note ID.
  ///   - trialID: A trial ID.
  /// - Returns: A tuple containing an optional note and an optional trial.
  private func noteWithID(_ noteID: String, trialID: String?) -> (Note?, Trial?) {
    var foundNote: Note?
    var foundTrial: Trial?
    if let trialID = trialID {
      if let trial = experiment.trial(withID: trialID),
        let note = trial.note(withID: noteID) {
        foundNote = note
        foundTrial = trial
      }
    } else {
      if let note = experiment.note(withID: noteID) {
        foundNote = note
      }
    }
    return (foundNote, foundTrial)
  }

  /// Saves the experiment.
  private func saveExperiment() {
    metadataManager.saveExperiment(experiment)
    delegate?.experimentUpdateManagerDidSaveExperiment(withID: experiment.ID)
  }

  // MARK: - Notifications

  @objc private func handleTrialStatsDidCompleteNotification(notification: Notification) {
    guard let trialID =
        notification.userInfo?[SensorDataManager.TrialStatsDidCompleteTrialIDKey] as? String,
        let trial = experiment.trial(withID: trialID) else {
      return
    }

    saveExperiment()

    notifyListeners { (listener) in
      listener.experimentUpdateTrialUpdated(trial, experiment: experiment, updatedStats: true)
    }
  }

}
