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

/// Merges two experiments and resolves any resulting merge conflicts.
public class ExperimentMerger {

  private var localExperiment: Experiment
  private var preMergePaths: Set<String>?
  private var preMergeTrialIDs: Set<String>?

  /// Returns an array of all asset paths for the current experiment.
  private var localExperimentPaths: [String] {
    var paths = localExperiment.pictureNotes.compactMap { $0.filePath }
    if let coverImagePath = localExperiment.imagePath {
      paths.append(coverImagePath)
    }
    return paths
  }

  /// The paths of all assets deleted as a result of a merge. Not available until after either
  /// `mergeFrom(experiment:)` or `replaceExperiment(withExperiment:)` are called.
  public var deletedAssetPaths: Set<String>?

  /// The IDs of all trials deleted as a result of a merge. Not available until after either
  /// `mergeFrom(experiment:)` or `replaceExperiment(withExperiment:)` are called.
  public var deletedTrialIDs: Set<String>?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - localExperiment: A local experiment.
  public init(localExperiment: Experiment) {
    self.localExperiment = localExperiment
  }

  /// Merges the local experiment with another experiment.
  ///
  /// - Parameter externalExperiment: An experiment.
  public func mergeFrom(experiment externalExperiment: Experiment) {
    capturePreMergeState()

    // Compile the changes that are unique to both local and external experiments.
    let localChanges = localExperiment.changes
    let externalChanges = externalExperiment.changes

    var localOnly = Set<ExperimentChange>(localChanges)
    var externalOnly = Set<ExperimentChange>(externalChanges)

    localOnly.subtract(externalChanges)
    externalOnly.subtract(localChanges)

    // Add all the external changes to the local experiment.
    externalOnly.forEach { localExperiment.trackChange($0) }

    // Build a dict of changes keyed by element ID, resulting in the most recent change being stored
    // for each element.
    var changedLocalElements = [String: ExperimentChange]()
    for change in localOnly {
      changedLocalElements[change.element.ID] = change
    }

    var changedExternalElements = [String: ExperimentChange]()
    for change in externalOnly {
      changedExternalElements[change.element.ID] = change
    }

    // For each change, if an element ID exists in both the local and remote change, handle as a
    // merge conflict, otherwise handle as a non-conflict merge.
    for change in changedExternalElements.values {
      if changedLocalElements[change.element.ID] != nil {
        handleConflictMerge(externalExperiment: externalExperiment, externalChange: change)
      } else {
        handleNoConflictMerge(externalExperiment: externalExperiment, externalChange: change)
      }
    }

    // Take the max total trials value between the two experiments.
    localExperiment.totalTrials = max(localExperiment.totalTrials, externalExperiment.totalTrials)

    computeDeletedAssetsAndTrials()
  }

  /// Replaces the local experiment with an external experiment. Fields that are local-only
  /// (available sensors, sensor layouts, triggers) are preserved.
  ///
  /// - Parameter externalExperiment: An experiment.
  public func replaceExperiment(withExperiment externalExperiment: Experiment) {
    capturePreMergeState()

    externalExperiment.availableSensors = localExperiment.availableSensors
    externalExperiment.sensorTriggers = localExperiment.sensorTriggers
    externalExperiment.sensorLayouts = localExperiment.sensorLayouts

    localExperiment = externalExperiment

    computeDeletedAssetsAndTrials()
  }

  // MARK: - Private

  private func handleConflictMerge(externalExperiment: Experiment,
                                   externalChange: ExperimentChange) {
    switch externalChange.element.type {
    case .experiment:
      handleExperimentConflict(externalExperiment)
    case .trial:
      handleTrialConflict(externalExperiment: externalExperiment, externalChange: externalChange)
    case .note, .caption:
      handleNoteConflict(externalExperiment: externalExperiment, externalChange: externalChange)
    case .unknown: break
    default: fatalError("Impossible case")
    }
  }

  private func handleNoConflictMerge(externalExperiment: Experiment,
                                     externalChange: ExperimentChange) {
    switch externalChange.element.type {
    case .experiment:
      copyExperimentChange(externalExperiment)
    case .trial:
      copyTrialChange(externalExperiment: externalExperiment, externalChange: externalChange)
    case .note, .caption:
      copyNoteChange(externalExperiment: externalExperiment, externalChange: externalChange)
    case .unknown: break
    default: fatalError("Impossible case")
    }
  }

  private func handleExperimentConflict(_ externalExperiment: Experiment) {
    // For an experiment conflict, combine the titles if they are different and always use the
    // external image path.
    if localExperiment.title != externalExperiment.title {
      // Set the new title without tracking a change since the local experiment already has a
      // modification change.
      let combinedTitle = concatenatedStrings(string1: localExperiment.title,
                                              string2: externalExperiment.title)
      localExperiment.setTitle(combinedTitle, withChange: false)
    }
    localExperiment.imagePath = externalExperiment.imagePath
  }

  private func handleTrialConflict(externalExperiment: Experiment,
                                   externalChange: ExperimentChange) {
    let trialID = externalChange.element.ID
    guard let localTrial = localExperiment.trial(withID: trialID) else {
      // The trial associated with this change doesn't exist in the local experiment, so
      // do nothing.
      return
    }

    if let externalTrial = externalExperiment.trial(withID: trialID) {
      // Both local and external have been edited. This is a title change.
      if localTrial.title != externalTrial.title {
        // Set the new title without tracking a change since the local experiment already has a
        // modification change.
        let combinedTitle = concatenatedStrings(string1: localTrial.title,
                                                string2: externalTrial.title)
        localTrial.setTitle(combinedTitle, experiment: localExperiment, withChange: false)
      }
    } else {
      // The trial associated with the change doesn't exist in the external experiment, so delete
      // the local one as well.
      localExperiment.removeTrial(withID: trialID, withChange: false)
    }
  }

  private func handleNoteConflict(externalExperiment: Experiment,
                                  externalChange: ExperimentChange) {
    let noteID = externalChange.element.ID
    let (externalNote, _) = externalExperiment.findNote(withID: noteID)
    let (findLocalNote, localTrial) = localExperiment.findNote(withID: noteID)

    guard let localNote = findLocalNote else {
      // This is a local delete. When there has been a local delete and a remote change, keep the
      // local delete. Alternatively, the remote was also deleted, so we can keep that delete, too.
      return
    }

    // This is a local edit. Determine if it's a trial note or an experiment note.
    if let localTrial = localTrial {
      // The local trial exists. That means either a) the trial contains a different version
      // of the label, or b) the label has been deleted. If edited, we have to create a new
      // label and add it to the trial. If deleted, we have to delete the local trial note.
      // If the trial doesn't exist, it has been deleted itself, and we can move on.
      if let externalNote = externalNote {
        if externalChange.element.type == .caption {
          // If the change is a caption change the captions are concatenated.
          let combinedCaption = concatenatedStrings(string1: localNote.caption?.text,
                                                    string2: externalNote.caption?.text)
          localNote.caption = Caption(text: combinedCaption)
          localTrial.updateNote(localNote, experiment: localExperiment)
        } else {
          // Non-caption changes mean we have to create a new note and add it to the trial. This is
          // a new change, so a change must be tracked for this addition.
          localTrial.addNote(externalNote.copyWithNewID(),
                             experiment: localExperiment,
                             isUndo: false)
        }
      } else {
        // The label was deleted externally (therefore do not record a new change).
        localTrial.removeNote(withID: noteID, experiment: localExperiment, withChange: false)
      }
    } else {
      // This is an experiment note. Either the experiment note has been deleted remotely, or
      // it has been edited. If it was deleted, we have to delete it locally, and if it's been
      // edited, we need to add a new label to the experiment.
      if let externalNote = externalNote {
        // Experiment note.
        if externalChange.element.type == .caption {
          // If the change is a caption change the captions are concatenated.
          let combinedCaption = concatenatedStrings(string1: localNote.caption?.text,
                                                    string2: externalNote.caption?.text)
          localNote.caption = Caption(text: combinedCaption)
          localExperiment.noteCaptionUpdated(withID: localNote.ID)
        } else {
          // Non-caption changes mean either the experiment note was deleted or modified locally.
          // Either way we need to re-add it as a new note.
          localExperiment.addNote(externalNote.copyWithNewID())
        }
      } else {
        // The label was deleted externally (therefore do not record a new change).
        localExperiment.removeNote(withID: noteID, withChange: false)
      }
    }
  }

  private func copyExperimentChange(_ externalExperiment: Experiment) {
    localExperiment.setTitle(externalExperiment.title, withChange: false)
    localExperiment.imagePath = externalExperiment.imagePath
  }

  private func copyTrialChange(externalExperiment: Experiment, externalChange: ExperimentChange) {
    let trialID = externalChange.element.ID
    if let externalTrial = externalExperiment.trial(withID: trialID) {
      // The external trial exists, so it needs to be copied to the local trial.
      if localExperiment.trial(withID: trialID) != nil {
        // This trial exists locally so update the local copy.
        localExperiment.updateTrial(externalTrial, withChange: false)
      } else {
        // This trial doesn't exist locally, so add it.
        localExperiment.addTrial(externalTrial, withChange: false, isUndo: false)
      }
    } else {
      // The trial was deleted externally, so delete it locally.
      localExperiment.removeTrial(withID: trialID, withChange: false)
    }
  }

  private func copyNoteChange(externalExperiment: Experiment, externalChange: ExperimentChange) {
    let noteID = externalChange.element.ID
    let (externalNote, externalTrial) = externalExperiment.findNote(withID: noteID)
    if let externalNote = externalNote {
      // The external label was not deleted.
      if let externalTrial = externalTrial {
        // It's a trial note.
        if let localTrial = localExperiment.trial(withID: externalTrial.ID) {
          if localTrial.note(withID: noteID) != nil {
            // The trial label exists locally, update it.
            localTrial.updateNote(externalNote, experiment: localExperiment, withChange: false)
          } else {
            // Otherwise add it.
            localTrial.addNote(externalNote,
                               experiment: localExperiment,
                               withChange: false,
                               isUndo: false)
          }
        } else {
          // If the trial doesn't exist locally, copy the entire external trial.
          localExperiment.addTrial(externalTrial, withChange: false, isUndo: false)
        }
      } else {
        // It's an experiment note.
        if localExperiment.note(withID: noteID) != nil {
          localExperiment.updateNote(externalNote, withChange: false)
        } else {
          localExperiment.addNote(externalNote, withChange: false)
        }
      }
    } else {
      let (localNote, localTrial) = localExperiment.findNote(withID: noteID)
      // The external label was deleted.
      if let localTrial = localTrial {
        // It's a trial note.
        localTrial.removeNote(withID: noteID, experiment: localExperiment, withChange: false)
      } else if localNote != nil {
        // It's an experiment note.
        localExperiment.removeNote(withID: noteID, withChange: false)
      }
      // If it's not in the experiment or a trial it may have been deleted since the last merge
      // which is fine since it shouldn't exist anyway.
    }
  }

  private func concatenatedStrings(string1: String?, string2: String?) -> String? {
    guard string1 != nil || string2 != nil else {
      return nil
    }
    return [string1, string2].compactMap({ $0 }).joined(separator: String.concatenationSeparator)
  }

  private func capturePreMergeState() {
    preMergePaths = Set(localExperimentPaths)
    preMergeTrialIDs = Set(localExperiment.trials.map { $0.ID })
  }

  private func computeDeletedAssetsAndTrials() {
    if let preMergePaths = preMergePaths, preMergePaths.count > 0 {
      let postMergePaths = Set(localExperimentPaths)
      deletedAssetPaths = preMergePaths.subtracting(postMergePaths)
    }
    if let preMergeTrialIDs = preMergeTrialIDs, preMergeTrialIDs.count > 0 {
      let postMergeTrialIDs = localExperiment.trials.map { $0.ID }
      deletedTrialIDs = preMergeTrialIDs.subtracting(postMergeTrialIDs)
    }
  }

}
