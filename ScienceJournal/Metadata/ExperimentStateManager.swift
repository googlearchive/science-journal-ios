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

protocol ExperimentStateListener: class {

  /// Informs the delegate the experiment's archive state changed.
  ///
  /// - Parameters:
  ///   - experiment: The experiment with the archive state change.
  ///   - overview: The overview corresponding to the experiment.
  ///   - undoBlock: A block that will undo the archive state change if executed.
  func experimentStateArchiveStateChanged(forExperiment experiment: Experiment,
                                          overview: ExperimentOverview,
                                          undoBlock: @escaping () -> Void)

  /// Informs the delegate the experiment was deleted.
  ///
  /// - Parameters:
  ///   - deletedExperiment: The deleted experiment.
  ///   - undoBlock: A block that will undo the deletion if executed.
  func experimentStateDeleted(_ deletedExperiment: DeletedExperiment, undoBlock: (() -> Void)?)

  /// Informs the delegate the experiment was restored after being deleted.
  ///
  /// - Parameters:
  ///   - experiment: The restored experiment.
  ///   - overview: The overview corresponding to the experiment.
  func experimentStateRestored(_ experiment: Experiment, overview: ExperimentOverview)

}

/// Manages archiving and deleting experiments.
class ExperimentStateManager {

  // MARK: - Properties

  private let experimentDataDeleter: ExperimentDataDeleter
  private let sensorDataManager: SensorDataManager
  private let metadataManager: MetadataManager
  private var stateListeners = NSHashTable<AnyObject>.weakObjects()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - experimentDataDeleter: The experiment data deleter.
  ///   - metadataManager: The metadata manager.
  ///   - sensorDataManager: The sensor data manager.
  init(experimentDataDeleter: ExperimentDataDeleter,
       metadataManager: MetadataManager,
       sensorDataManager: SensorDataManager) {
    self.experimentDataDeleter = experimentDataDeleter
    self.metadataManager = metadataManager
    self.sensorDataManager = sensorDataManager
  }

  /// Adds the given object conforming to ExperimentStateListener as a listener to experiment state
  /// changes. Maintains a weak reference to listeners.
  ///
  /// - Parameter listener: Any object that conforms to ExperimentUpdateListener.
  func addListener(_ listener: ExperimentStateListener) {
    stateListeners.add(listener)
  }

  /// Removes a listener.
  ///
  /// - Parameter listener: The listener to remove.
  func removeListener(_ listener: ExperimentStateListener) {
    stateListeners.remove(listener)
  }

  /// Toggles the archive state for an experiment.
  ///
  /// - Parameter experimentID: An experiment ID.
  func toggleArchiveStateForExperiment(withID experimentID: String) {
    guard let experiment = metadataManager.experiment(withID: experimentID),
        let overview = metadataManager.toggleArchiveStateForExperiment(withID: experimentID) else {
      return
    }

    let undoBlock = {
      self.toggleArchiveStateForExperiment(withID: experimentID)
    }

    notifyListeners { (listener) in
      listener.experimentStateArchiveStateChanged(forExperiment: experiment,
                                                  overview: overview,
                                                  undoBlock: undoBlock)
    }
  }

  /// Deletes an experiment.
  ///
  /// - Parameter experimentID: An experiment ID.
  func deleteExperiment(withID experimentID: String) {
    guard let deletedExperiment =
        experimentDataDeleter.performUndoableDeleteForExperiment(withID: experimentID) else {
      return
    }

    // Only allow undo if the experiment is not empty.
    var undoBlock: (() -> Void)?
    if !deletedExperiment.isEmpty {
      undoBlock = { self.restoreExperiment(deletedExperiment) }
    }

    notifyListeners { (listener) in
      listener.experimentStateDeleted(deletedExperiment,
                                      undoBlock: undoBlock)
    }
  }

  // MARK: - Private

  /// Restores a deleted experiment.
  ///
  /// - Parameter deletedExperiment: The deleted experiment to restore.
  private func restoreExperiment(_ deletedExperiment: DeletedExperiment) {
    let (experiment, overview) = experimentDataDeleter.restoreExperiment(deletedExperiment)

    notifyListeners { (listener) in
      listener.experimentStateRestored(experiment, overview: overview)
    }
  }

  /// Confirms an experiment should be permanently deleted.
  ///
  /// - Parameter deletedExperiment: A deleted experiment.
  func confirmDeletion(for deletedExperiment: DeletedExperiment) {
    experimentDataDeleter.confirmDeletion(for: deletedExperiment)
  }

  /// Notifies all listeners by calling the given block on each valid listener.
  ///
  /// - Parameter block: A block with a listener parameter.
  private func notifyListeners(_ block: (ExperimentStateListener) -> Void) {
    stateListeners.allObjects.forEach { (object) in
      guard let listener = object as? ExperimentStateListener else { return }
      block(listener)
    }
  }

}
