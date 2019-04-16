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

/// An operation that updates the experiment library and local sync status for a deleted experiment.
public class MarkExperimentDeletedOperation: GSJOperation {

  private let experimentID: String
  private let metadataManager: MetadataManager

  /// Designated initialzier.
  public init(experimentID: String, metadataManager: MetadataManager) {
    self.experimentID = experimentID
    self.metadataManager = metadataManager
  }

  public override func execute() {
    // Experiment library
    metadataManager.experimentLibrary.setExperimentDeleted(true, experimentID: experimentID)
    metadataManager.saveExperimentLibrary()

    // Local sync status
    metadataManager.localSyncStatus.removeExperiment(withID: experimentID)
    metadataManager.saveLocalSyncStatus()

    finish()
  }

}
