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

/// Handles deleting experiments and their associated assets on disk. This class only manages local
/// data, it does not handle deleting data on Drive.
public class ExperimentDataDeleter {

  private let metadataManager: MetadataManager
  private let sensorDataManager: SensorDataManager

  private let deletingTrialsKey: String

  init(accountID: String?, metadataManager: MetadataManager, sensorDataManager: SensorDataManager) {
    self.metadataManager = metadataManager
    self.sensorDataManager = sensorDataManager

    deletingTrialsKey = {
      let keySuffix: String
      if let accountID = accountID {
        keySuffix = "_" + accountID
      } else {
        keySuffix = ""
      }
      return "ExperimentDataDeleterDeletingExperiments" + keySuffix
    }()

    performAllPendingSensorDataDeletes()
  }

  private var deletingTrialIDs: [String] {
    get {
      return (UserDefaults.standard.array(forKey: deletingTrialsKey) as? [String]) ?? []
    }
    set {
      UserDefaults.standard.set(newValue, forKey: deletingTrialsKey)
      UserDefaults.standard.synchronize()
    }
  }

  // MARK: - Experiment deletion

  /// Deletes an experiment in a way that can be undone (via `restoreExperiment(_)`).
  ///
  /// - Parameter experimentID: The ID of the experiment to delete.
  /// - Returns: A deleted experiment object.
  public func performUndoableDeleteForExperiment(
      withID experimentID: String) -> DeletedExperiment? {
    guard let overview = metadataManager.removeOverview(forExperimentID: experimentID),
        let experiment = metadataManager.experiment(withID: experimentID) else {
      return nil
    }
    let experimentPath = pathForExperiment(withID: experimentID)
    moveItemToDeletedData(fromRelativePath: experimentPath)
    return DeletedExperiment(overview: overview, experiment: experiment)
  }

  /// Moves an experiment from the deleted experiments directory back to the Science Journal
  /// directory. Also adds the experiment overview back into user metadata.
  ///
  /// - Parameter: deletedExperiment: Pass back the deleted experiment from calling
  ///                                 `performUndoableDeleteForExperiment(withID:)`.
  /// - Returns: A tuple with the experiment and overview that were restored.
  public func restoreExperiment(
      _ deletedExperiment: DeletedExperiment) -> (Experiment, ExperimentOverview) {
    let experimentPath = pathForExperiment(withID: deletedExperiment.experiment.ID)
    moveItemFromDeletedDataToExperiments(atRelativePath: experimentPath)
    metadataManager.addOverview(deletedExperiment.overview)
    return (deletedExperiment.experiment, deletedExperiment.overview)
  }

  /// Confirms an undoable deletion. This should be called when the user opts to not undo
  /// the delete.
  ///
  /// - Parameter deletedExperiment: The deleted experiment.
  public func confirmDeletion(for deletedExperiment: DeletedExperiment) {
    let deletedExperimentURL = self.deletedExperimentURL(forID: deletedExperiment.experiment.ID)
    deleteItemIfNecessary(atURL: deletedExperimentURL)
    deleteSensorData(for: deletedExperiment.experiment)
  }

  /// Permanently deletes an experiment. If the experiment has already been deleted this method will
  /// return false, in which case no actions are performed.
  ///
  /// - Parameters:
  ///   - experimentID: The ID of the experiment to delete.
  ///   - completion: An optional closure called when the deletion is finished.
  /// - Returns: True if there was an experiment to delete, otherwise false. Sensor data may not yet
  ///            be deleted at the time of return.
  @discardableResult public func permanentlyDeleteExperiment(
      withID experimentID: String, completion: (() -> Void)? = nil) -> Bool {
    guard let experiment = metadataManager.experiment(withID: experimentID) else {
      completion?()
      return false
    }

    metadataManager.removeOverview(forExperimentID: experimentID)
    metadataManager.localSyncStatus.removeExperiment(withID: experimentID)
    metadataManager.saveLocalSyncStatus()

    // Mark trial IDs for deletion before the experiment is deleted.
    let trialIDs = experiment.trials.map { $0.ID }
    deletingTrialIDs.append(contentsOf: trialIDs)

    let experimentURL = metadataManager.experimentDirectoryURL(for: experimentID)
    deleteItemIfNecessary(atURL: experimentURL)

    deleteSensorData(for: experiment, completion: completion)
    return true
  }

  // MARK: - Private

  private func performAllPendingSensorDataDeletes() {
    let trialIDs = deletingTrialIDs
    deleteSensorData(forTrialIDs: trialIDs)
  }

  private func deleteSensorData(forTrialIDs trialIDs: [String], completion: (() -> Void)? = nil) {
    let group = DispatchGroup()
    for trialID in trialIDs {
      group.enter()
      sensorDataManager.removeData(forTrialID: trialID) { [weak self] in
        self?.deletingTrialIDs.removeAll(where: { $0 == trialID })
        group.leave()
      }
    }

    group.notify(queue: DispatchQueue.main) {
      completion?()
    }
  }

  private func deleteSensorData(for experiment: Experiment, completion: (() -> Void)? = nil) {
    let trialIDs = experiment.trials.map { $0.ID }
    deletingTrialIDs.append(contentsOf: trialIDs)
    deleteSensorData(forTrialIDs: trialIDs, completion: completion)
  }

  // Moves the file or directory at `path` to the same relative location in the deleted data
  // directory. `path` must be the location within the Science Journal directory.
  private func moveItemToDeletedData(fromRelativePath path: String) {
    let fromURL = metadataManager.rootURL.appendingPathComponent(path)
    let moveURL = metadataManager.deletedDataDirectoryURL.appendingPathComponent(path)
    var moveDirectoryURL = moveURL.deletingLastPathComponent()

    if FileManager.default.fileExists(atPath: moveDirectoryURL.path, isDirectory:nil) {
      // If the directory already exists, replace the item.
      do {
        _ = try FileManager.default.replaceItemAt(moveURL, withItemAt: fromURL)
      } catch {
        sjlog_error("Error replacing item at '\(moveURL) with item at \(fromURL)': " +
                        error.localizedDescription,
                    category: .general)
      }
    } else {
      // Create the directory.
      do {
        try FileManager.default.createDirectory(atPath: moveDirectoryURL.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
      } catch {
        sjlog_error("Error creating directory: \(error.localizedDescription)",
                    category: .general)
        return
      }

      // Deleted data should not be backed up to iCloud.
      var resourceValues = URLResourceValues()
      resourceValues.isExcludedFromBackup = true
      do {
        try moveDirectoryURL.setResourceValues(resourceValues)
      } catch {
        sjlog_error("Error setting resource values on directory " +
                        "'\(moveDirectoryURL)': \(error.localizedDescription)",
                    category: .general)
      }

      // Move the item to deleted data.
      do {
        try FileManager.default.moveItem(at: fromURL, to: moveURL)
      } catch {
        sjlog_error("Error moving item at '\(fromURL)': \(error.localizedDescription)",
                    category: .general)
      }
    }
  }

  private func deleteItemIfNecessary(atURL url: URL) {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: url.path) else {
      return
    }

    do {
      try fileManager.removeItem(at: url)
    } catch {
      sjlog_error("Error deleting item at '\(url)': " + error.localizedDescription,
                  category: .general)
    }
  }

  private func moveItemFromDeletedDataToExperiments(atRelativePath path: String) {
    let deletedURL = metadataManager.deletedDataDirectoryURL.appendingPathComponent(path)
    let restoreURL = metadataManager.rootURL.appendingPathComponent(path)

    do {
      try FileManager.default.moveItem(at: deletedURL, to: restoreURL)
    } catch {
      sjlog_error("Error moving item at '\(deletedURL)': \(error.localizedDescription)",
                  category: .general)
    }
  }

  private func pathForExperiment(withID experimentID: String) -> String {
    return "\(metadataManager.experimentsDirectoryName)/\(experimentID)/"
  }

  private func rootPathForAsset(atRelativePath relativePath: String,
                                experimentID: String) -> String {
    let experimentPath = pathForExperiment(withID: experimentID)
    return experimentPath + relativePath
  }

  private func deletedExperimentURL(forID experimentID: String) -> URL {
    return metadataManager.deletedExperimentsDirectoryURL.appendingPathComponent(experimentID)
  }

}

// MARK: - DeletedExperiment

/// Represents a deleted experiment.
public struct DeletedExperiment {
  fileprivate let overview: ExperimentOverview
  fileprivate let experiment: Experiment

  var experimentID: String {
    return experiment.ID
  }

  var isEmpty: Bool {
    return experiment.isEmpty
  }
}
