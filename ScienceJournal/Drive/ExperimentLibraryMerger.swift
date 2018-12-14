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

/// Handles merging of two experiment libraries.
public class ExperimentLibraryMerger {

  private let localLibrary: ExperimentLibrary
  private let localSyncStatus: LocalSyncStatus

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - localLibrary: The local experiment library.
  ///   - localSyncStatus: The local sync status.
  public init(localLibrary: ExperimentLibrary,
              localSyncStatus: LocalSyncStatus) {
    self.localLibrary = localLibrary
    self.localSyncStatus = localSyncStatus
  }

  /// Merges the local library with the external library.
  ///
  /// - Parameter externalLibrary: An external library.
  public func merge(fromLibrary externalLibrary: ExperimentLibrary) {
    if externalLibrary.folderID != nil {
      localLibrary.folderID = externalLibrary.folderID
    }
    for experiment in externalLibrary.syncExperiments {
      let experimentID = experiment.experimentID
      let isServerArchived =
          localSyncStatus.isExperimentServerArchived(withID: experimentID) ?? false
      updateExperiment(experiment, serverArchived: isServerArchived)
    }
  }

  /// Updates the local experiment by comparing values with another experiment and determining
  /// which values to use when there are differences.
  ///
  /// - Parameters:
  ///   - experiment: An experiment.
  ///   - isServerArchived: The last seen archived state for this experiment.
  private func updateExperiment(_ experiment: SyncExperiment,
                                serverArchived isServerArchived: Bool) {
    guard let localExperiment = localLibrary.syncExperiment(forID: experiment.experimentID) else {
      localLibrary.addExperiment(experiment)
      return
    }

    // Update last opened timestamp if remote experiment is more recent.
    if experiment.lastOpenedTimestamp > localExperiment.lastOpenedTimestamp {
      localExperiment.lastOpenedTimestamp = experiment.lastOpenedTimestamp
    }

    // Update last modified timestamp if remote experiment is more recent.
    if experiment.lastModifiedTimestamp > localExperiment.lastModifiedTimestamp {
      localExperiment.lastModifiedTimestamp = experiment.lastModifiedTimestamp
    }

    // If remote experiment is deleted, mark local as deleted.
    if experiment.isDeleted {
      localExperiment.isDeleted = true
    }

    // If remote experiment's archived state is different than we last saw on the server, update
    // the local experiment to match.
    if experiment.isArchived != isServerArchived {
      localExperiment.isArchived = experiment.isArchived
    }

    // Update the file ID if the local experiment's file ID is nil.
    if localExperiment.fileID == nil {
      localExperiment.fileID = experiment.fileID
    }

    // The archived state post-merge is the new server archived state.
    localSyncStatus.setExperimentServerArchived(localExperiment.isArchived,
                                                withID: experiment.experimentID)
  }

}
