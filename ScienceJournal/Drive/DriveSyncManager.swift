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

public protocol DriveSyncManagerDelegate: class {
  /// Informs the delegate the experiment library was updated.
  func driveSyncDidUpdateExperimentLibrary()

  /// Informs the delegate an experiment was updated or is newly downloaded.
  ///
  /// - Parameter experiment: An experiment.
  func driveSyncDidUpdateExperiment(_ experiment: Experiment)

  /// Informs the delegate an experiment was deleted.
  ///
  /// - Parameter experimentID: An experiment ID.
  func driveSyncDidDeleteExperiment(withID experimentID: String)

  /// Informs the delegate a trial was deleted from an experiment.
  ///
  /// - Parameter trialID: A trial ID.
  /// - Parameter experimentID: An experimentID from which the trial was deleted.
  func driveSyncDidDeleteTrial(withID trialID: String, experimentID: String)
}

extension Notification.Name {
  /// Posted when image asset downloads complete. Access the paths of the downloaded images with
  /// DriveSyncUserInfoConstants.downloadedImagePathsKey.
  public static let driveSyncManagerDownloadedImages =
      NSNotification.Name("DriveSyncManagerDownloadedImages")

  /// Posted when sensor data downloads complete. Access the IDs of the trials the sensor data
  /// belongs to with DriveSyncUserInfoConstants.downloadedSensorDataTrialIDsKey.
  public static let driveSyncManagerDownloadedSensorData =
      NSNotification.Name("DriveSyncManagerDownloadedImages")
}

/// A protocol that defines a manager object for Drive sync.
public protocol DriveSyncManager: class {

  /// A delegate that will be informed when Drive Sync changes data.
  var delegate: DriveSyncManagerDelegate? { get set }

  /// Syncs the experiment library and uploads new experiments. Also optionally reconciles the
  /// the new library which includes syncing dirty experiments and downloading experiments missing
  /// locally.
  ///
  /// - Parameters:
  ///   - shouldReconcile: Whether to sync dirty experiments and download missing experiments.
  ///   - userInitiated: Whether this sync call was user initiated.
  func syncExperimentLibrary(andReconcile shouldReconcile: Bool, userInitiated: Bool)

  /// Syncs one experiment.
  ///
  /// - Parameters:
  ///   - experimentID: An experiment ID.
  ///   - onlyIfDirty: Whether to sync the experiment only if it is dirty.
  func syncExperiment(withID experimentID: String, onlyIfDirty: Bool)

  /// Syncs trial sensor data to Drive.
  ///
  /// - Parameters:
  ///   - url: The URL of the trial sensor data proto on disk.
  ///   - experimentID: The ID of the experiment that owns the trial.
  func syncTrialSensorData(atURL url: URL, experimentID: String)

  /// Deletes an experiment from Drive.
  ///
  /// - Parameter experimentID: The experiment ID.
  func deleteExperiment(withID experimentID: String)

  /// Checks Drive to see if the experiment library exists.
  ///
  /// - Parameter completion: A completion block called when the search is finished with a Bool
  ///                         parameter indicating whether the library exists. Nil indicates the
  ///                         existence could not be determined.
  func experimentLibraryExists(completion: @escaping (Bool?) -> Void)

  /// Deletes image assets from Drive.
  ///
  /// - Parameters:
  ///   - urls: The local urls of the image assets.
  ///   - experimentID: The ID of the experiment the image asset belongs to.
  func deleteImageAssets(atURLs urls: [URL], experimentID: String)

  /// Deletes a sensor data asset from Drive.
  ///
  /// - Parameters:
  ///   - url: The local url of the sensor data asset.
  ///   - experimentID: The ID of the experiment the sensor data asset belongs to.
  func deleteSensorDataAsset(atURL url: URL, experimentID: String)

  #if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD

  // MARK: - Debug additions for deleting all Drive user data.

  /// Deletes the experiment library proto from Drive.
  ///
  /// Parameter completion: Called on completion with the number of files deleted and errors if
  ///                       applicable.
  func debug_removeAllUserDriveData(completion: @escaping (Int, [Error]) -> Void)

  #endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD

}
