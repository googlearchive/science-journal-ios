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

protocol ExperimentUpdateListener {

  /// Informs the delegate a trial note was added.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - trial: The trial the note was added to.
  func experimentUpdateTrialNoteAdded(_ note: Note, toTrial trial: Trial)

  /// Informs the delegate a note was added to an experiment.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - experiment: The experiment to which the note was added.
  func experimentUpdateExperimentNoteAdded(_ note: Note,
                                           toExperiment experiment: Experiment)

  /// Informs the delegate a note was deleted from an experiment.
  ///
  /// - Parameters:
  ///   - note: The deleted note.
  ///   - experiment: The experiment from which the note was deleted.
  ///   - undoBlock: A block that will undo the delete if executed.
  func experimentUpdateExperimentNoteDeleted(_ note: Note,
                                             experiment: Experiment,
                                             undoBlock: @escaping () -> Void)

  /// Informs the delegate a note was deleted from an experiment.
  ///
  /// - Parameters:
  ///   - note: The deleted note.
  ///   - trial: The trial from which the note was deleted.
  ///   - experiment: The experiment that owns the trial.
  ///   - undoBlock: A block that will undo the delete if executed.
  func experimentUpdateTrialNoteDeleted(_ note: Note,
                                        trial: Trial,
                                        experiment: Experiment,
                                        undoBlock: @escaping () -> Void)

  /// Informs the delegate a note was updated. For example, a caption changed or the content of a
  /// text note.
  ///
  /// - Parameters:
  ///   - note: The updated note.
  ///   - trial: The trial that owns the note if applicable.
  ///   - experiment: The experiment that owns the note.
  func experimentUpdateNoteUpdated(_ note: Note, trial: Trial?, experiment: Experiment)

  /// Informs the delegate a change was made to a trial. For example the title or caption.
  ///
  /// - Parameters:
  ///   - trial: The updated trial.
  ///   - experiment: The experiment that owns the trial.
  ///   - updatedStats: Whether the trial's stats were updated.
  func experimentUpdateTrialUpdated(_ trial: Trial, experiment: Experiment, updatedStats: Bool)

  /// Informs the delegate a trial was added to the experiment.
  ///
  /// - Parameters:
  ///   - trial: The added trial.
  ///   - experiment: The experiment to which the trail was added.
  ///   - isRecording: Whether the trial is actively recording data.
  func experimentUpdateTrialAdded(_ trial: Trial,
                                  toExperiment experiment: Experiment,
                                  recording isRecording: Bool)

  /// Informs the delegate a trial was deleted from an experiment.
  ///
  /// - Parameters:
  ///   - trial: The deleted trial.
  ///   - experiment: The experiment from which the trial was deleted.
  ///   - undoBlock: A block that will undo the delete if executed.
  func experimentUpdateTrialDeleted(_ trial: Trial,
                                    fromExperiment experiment: Experiment,
                                    undoBlock: @escaping () -> Void)

  /// Informs the delegate a trial's archive state changed.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - experiment: The experiment that owns the trial.
  ///   - undoBlock: A block that will undo the archive action if executed.
  func experimentUpdateTrialArchiveStateChanged(_ trial: Trial,
                                                experiment: Experiment,
                                                undoBlock: @escaping () -> Void)

}

// All methods are optional.
extension ExperimentUpdateListener {
  func experimentUpdateTrialNoteAdded(_ note: Note, toTrial trial: Trial) {}
  func experimentUpdateExperimentNoteAdded(_ note: Note,
                                           toExperiment experiment: Experiment) {}
  func experimentUpdateExperimentNoteDeleted(_ note: Note,
                                             experiment: Experiment,
                                             undoBlock: @escaping () -> Void) {}
  func experimentUpdateTrialNoteDeleted(_ note: Note,
                                        trial: Trial,
                                        experiment: Experiment,
                                        undoBlock: @escaping () -> Void) {}
  func experimentUpdateNoteUpdated(_ note: Note, trial: Trial?, experiment: Experiment) {}
  func experimentUpdateTrialUpdated(_ trial: Trial, experiment: Experiment, updatedStats: Bool) {}
  func experimentUpdateTrialAdded(_ trial: Trial,
                                  toExperiment experiment: Experiment,
                                  recording isRecording: Bool) {}
  func experimentUpdateTrialDeleted(_ trial: Trial,
                                    fromExperiment experiment: Experiment,
                                    undoBlock: @escaping () -> Void) {}
  func experimentUpdateTrialArchiveStateChanged(_ trial: Trial,
                                                experiment: Experiment,
                                                undoBlock: @escaping () -> Void) {}
}
