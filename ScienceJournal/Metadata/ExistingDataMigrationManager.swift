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

/// Errors that can be passed back by the existing data migration manager.
enum ExistingDataMigrationManagerError: Error {
  /// Error loading experiments from disk. Called with the IDs of the experiments.
  case experimentLoadError(experimentIDs: [String])
  /// Error saving experiments. Called with the IDs of the experiments.
  case experimentSaveError(experimentIDs: [String])
  /// Error fetching sensor data for trials. Called with the IDs of the trials.
  case sensorDataFetchError(trialIDs: [String])
  /// Error storing assets for the experiment. Called with the IDs of the experiments.
  case assetsSaveError(experimentIDs: [String])
}

/// Manages migrating data from the pre-accounts root user to per-user storage, including
/// experiments, sensor data and preferences.
class ExistingDataMigrationManager {

  // MARK: - Properties

  /// The user manager for the user migrating data.
  let accountUserManager: AccountUserManager

  /// The user manager for the pre-accounts root user.
  let rootUserManager: RootUserManager

  /// The number of existing experiments.
  var numberOfExistingExperiments: Int {
    return rootUserManager.metadataManager.experimentOverviews.count
  }

  /// Whether or not there are existing experiments.
  var hasExistingExperiments: Bool {
    return numberOfExistingExperiments > 0
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - accountUserManager: The user manager for the user migrating data.
  ///   - rootUserManager: The user manager for the pre-accounts root user.
  init(accountUserManager: AccountUserManager, rootUserManager: RootUserManager) {
    self.accountUserManager = accountUserManager
    self.rootUserManager = rootUserManager
  }

  // MARK: Experiments

  /// Moves an experiment from pre-account storage to storage for this user.
  ///
  /// - Parameters:
  ///   - experimentID: The ID of the experiment to migrate.
  ///   - completion: Called when migration is complete, with errors if any.
  func migrateExperiment(withID experimentID: String, completion: @escaping ([Error]) -> Void) {
    guard let experimentAndOverview = self.rootUserManager.metadataManager.experimentAndOverview(
        forExperimentID: experimentID) else {
      let error =
          ExistingDataMigrationManagerError.experimentLoadError(experimentIDs: [experimentID])
      completion([error])
      return
    }

    // Begin a background task.
    var backgroundTaskID = UIApplication.shared.beginBackgroundTask()

    let dispatchGroup = DispatchGroup()

    // Sensor data
    var errorTrialIDs = [String]()
    experimentAndOverview.experiment.trials.forEach { (trial) in
      dispatchGroup.enter()

      accountUserManager.sensorDataManager.countOfAllSensorData(forTrialID: trial.ID,
                                                                completion: { (accountCount) in
        self.rootUserManager.sensorDataManager.countOfAllSensorData(forTrialID: trial.ID,
                                                                    completion: { (rootCount) in
          var shouldMigrateSensorData = true
          if let accountCount = accountCount {
            if rootCount == accountCount {
              shouldMigrateSensorData = false
            } else if accountCount > 0 {
              self.accountUserManager.sensorDataManager.removeData(forTrialID: trial.ID)
            }
          }
          if shouldMigrateSensorData {
            self.rootUserManager.sensorDataManager.fetchAllSensorData(forTrialID: trial.ID,
                                                                      completion: { (sensorData) in
              if let sensorData = sensorData {
                self.accountUserManager.sensorDataManager.addSensorDataPoints(sensorData)
              } else {
                errorTrialIDs.append(trial.ID)
              }
              dispatchGroup.leave()
            })
          } else {
            dispatchGroup.leave()
          }
        })
      })
    }

    dispatchGroup.notify(qos: .userInitiated, queue: .global()) {
      self.accountUserManager.sensorDataManager.savePrivateContext()

      // Experiment
      let addExperimentSuccess = self.accountUserManager.metadataManager.addExperiment(
          experimentAndOverview.experiment, overview: experimentAndOverview.overview)
      var saveAssetsSuccess = true
      if addExperimentSuccess {
        let rootAssetsURL =
            self.rootUserManager.metadataManager.assetsURL(for: experimentAndOverview.experiment)
        if FileManager.default.fileExists(atPath: rootAssetsURL.path) {
          let accountAssetsURL = self.accountUserManager.metadataManager.assetsURL(
              for: experimentAndOverview.experiment)
          do {
            try FileManager.default.moveItem(at: rootAssetsURL, to: accountAssetsURL)
          } catch {
            saveAssetsSuccess = false
            print("[ExistingDataMigrationManager] Error moving assets directory at " +
                      "'\(rootAssetsURL)' to '\(accountAssetsURL)': \(error.localizedDescription)")
          }
        }
        self.removeExperimentFromRootUser(experimentAndOverview.experiment)
      }

      // Errors
      var errors = [ExistingDataMigrationManagerError]()
      if !addExperimentSuccess {
        errors.append(.experimentSaveError(experimentIDs: [experimentID]))
      }
      if !errorTrialIDs.isEmpty {
        errors.append(.sensorDataFetchError(trialIDs: errorTrialIDs))
      }
      if !saveAssetsSuccess {
        errors.append(.assetsSaveError(experimentIDs: [experimentID]))
      }

      DispatchQueue.main.async {
        completion(errors)
      }

      // End background task.
      if backgroundTaskID != .invalid {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
      }
      backgroundTaskID = .invalid
    }
  }

  /// Moves all experiments from pre-account storage to storage for this user.
  ///
  /// - Parameter completion: Called when migration is complete, with errors if any.
  func migrateAllExperiments(completion: @escaping ([Error]) -> Void) {
    let dispatchGroup = DispatchGroup()
    var experimentLoadErrorIDs = [String]()
    var experimentSaveErrorIDs = [String]()
    var sensorDataFetchErrorIDs = [String]()
    var assetsSaveErrorIDs = [String]()
    var otherErrors = [Error]()
    let experimentIDs = rootUserManager.metadataManager.experimentOverviews.map { $0.experimentID }
    experimentIDs.forEach {
      dispatchGroup.enter()
      migrateExperiment(withID: $0) {
        $0.forEach {
          if let error = $0 as? ExistingDataMigrationManagerError {
            switch error {
            case .experimentLoadError(let experimentIDs):
              experimentLoadErrorIDs.append(contentsOf: experimentIDs)
            case .experimentSaveError(let experimentIDs):
              experimentSaveErrorIDs.append(contentsOf: experimentIDs)
            case .sensorDataFetchError(let trialIDs):
              sensorDataFetchErrorIDs.append(contentsOf: trialIDs)
            case .assetsSaveError(let experimentIDs):
              assetsSaveErrorIDs.append(contentsOf: experimentIDs)
            }
          } else {
            otherErrors.append($0)
          }
        }
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(qos: .userInitiated, queue: .global()) {
      var errors = [Error]()
      if !experimentLoadErrorIDs.isEmpty {
        errors.append(ExistingDataMigrationManagerError.experimentLoadError(
            experimentIDs: experimentLoadErrorIDs))
      }
      if !experimentSaveErrorIDs.isEmpty {
        errors.append(ExistingDataMigrationManagerError.experimentSaveError(
            experimentIDs: experimentSaveErrorIDs))
      }
      if !sensorDataFetchErrorIDs.isEmpty {
        errors.append(ExistingDataMigrationManagerError.sensorDataFetchError(
            trialIDs: sensorDataFetchErrorIDs))
      }
      if !assetsSaveErrorIDs.isEmpty {
        errors.append(ExistingDataMigrationManagerError.assetsSaveError(
            experimentIDs: assetsSaveErrorIDs))
      }
      if !otherErrors.isEmpty {
        errors.append(contentsOf: otherErrors)
      }

      DispatchQueue.main.async {
        completion(errors)
      }
    }
  }

  /// Removes an experiment from pre-account storage, as well as its trial sensor data.
  ///
  /// - Parameters:
  ///   - experiment: The experiment to remove.
  func removeExperimentFromRootUser(_ experiment: Experiment) {
    // Sensor data
    experiment.trials.forEach {
      self.rootUserManager.sensorDataManager.removeData(forTrialID: $0.ID)
    }

    // Experiment
    self.rootUserManager.metadataManager.removeExperiment(withID: experiment.ID)
  }

  /// Removes an experiment from pre-account storage.
  ///
  /// - Parameter experimentID: The ID of the experiment to remove.
  func removeExperimentFromRootUser(withID experimentID: String) {
    guard let experiment = rootUserManager.metadataManager.experiment(withID: experimentID) else {
      return
    }
    removeExperimentFromRootUser(experiment)
    return
  }

  /// Removes all experiments from pre-account storage.
  func removeAllExperimentsFromRootUser() {
    let experimentIDs = rootUserManager.metadataManager.experimentOverviews.map { $0.experimentID }
    experimentIDs.forEach {
      removeExperimentFromRootUser(withID: $0)
    }
  }

  // MARK: Preferences

  /// Moves preferences from pre-account user defaults to user defaults for this user.
  func migratePreferences() {
    accountUserManager.preferenceManager.copyPreferences(
        fromManager: rootUserManager.preferenceManager)
  }

  // MARK: Bluetooth Devices

  /// Removes all bluetooth devices for the root user, as bluetooth devices are not a supported
  /// migration data type and must be reconfigured in the future by signed in accounts.
  func removeAllBluetoothDevices() {
    rootUserManager.metadataManager.deleteAllBluetoothSensors()
  }

}
