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

enum ImportExperimentError: Error {
  /// The import directory doesn't exist.
  case importDirectoryDoesNotExist
  /// Cannot read the contents of the import directory.
  case cannotReadImportDirectory
  /// The imported document did not contain an experiment proto.
  case experimentProtoNotFound
  /// The experiment proto cannot be read, it may be corrupt or an unsupported version.
  case experimentProtoCannotBeRead
}

/// An operation that validates and copies an imported experiment to the user's experiments
/// directory.
class ImportExperimentOperation: GSJOperation {

  // MARK: - Properties

  /// Populated with a sensor data proto when the operation is complete.
  var sensorData: GSJScalarSensorData?

  /// The imported experiment proto URL.
  var experimentProtoURL: URL?

  /// The imported sensor data proto URL.
  var sensorDataProtoURL: URL?

  /// An array of imported asset URLs.
  var assets = [URL]()

  /// A dict that maps old trial IDs to the new ones. Used when importing sensor data which contains
  /// the old IDs.
  var trialIDMap = [String: String]()

  private let jpegExtension = "jpg"
  private let importDirectoryURL: URL
  private let metadataManager: MetadataManager

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - importDirectoryURL: The location of the experiment folder to be imported.
  ///   - metadataManager: A metadata manager.
  init(importDirectoryURL: URL,
       metadataManager: MetadataManager) {
    self.importDirectoryURL = importDirectoryURL
    self.metadataManager = metadataManager
  }

  override func execute() {
    // Verify the file exists.
    guard FileManager.default.fileExists(atPath: importDirectoryURL.path) else {
      finish(withErrors: [ImportExperimentError.importDirectoryDoesNotExist])
      return
    }

    guard let enumerator = FileManager.default.enumerator(at: importDirectoryURL,
                                                          includingPropertiesForKeys: nil) else {
      finish(withErrors: [ImportExperimentError.cannotReadImportDirectory])
      return
    }

    while let url = enumerator.nextObject() as? URL {
      let filename = url.lastPathComponent
      if filename == MetadataManager.experimentProtoFilename {
        experimentProtoURL = url
      } else if filename == MetadataManager.sensorDataProtoFilename {
        sensorDataProtoURL = url
      } else if url.pathExtension == jpegExtension {
        assets.append(url)
      }
    }

    // The directory must contain an experiment proto.
    guard let experimentProtoURL = experimentProtoURL else {
      finish(withErrors: [ImportExperimentError.experimentProtoNotFound])
      return
    }

    // The experiment proto must be openable. Use an arbitrary ID since it doesn't matter at this
    // point.
    guard let experiment =
        metadataManager.experiment(atURL: URL(fileURLWithPath: experimentProtoURL.path),
                                   withID: "TempID") else {
      finish(withErrors: [ImportExperimentError.experimentProtoCannotBeRead])
      return
    }

    // Validate the trial data.
    if experiment.trials.count > 0 {
      // Re-ID the trials. If the same experiment is imported multiple times this keeps the data
      // uniquely keyed.
      for trial in experiment.trials {
        let oldID = trial.ID
        trial.ID = UUID().uuidString
        trialIDMap[oldID] = trial.ID
      }
      metadataManager.saveExperiment(experiment, toURL: experimentProtoURL)

      // Note: The sensor data is not checked to make sure it contains the same number of sensors
      // as the experiment or if they contain any data. The experiment will import even if the
      // sensor data isn't quite right.
      if let sensorDataProtoURL = sensorDataProtoURL,
          let proto = metadataManager.readSensorDataProto(atURL: sensorDataProtoURL) {
        // Make the proto accessible to other operations if it exists.
        sensorData = proto
      }
    }

    finish()
  }

  // MARK: - Private

  private func removeItem(atURL url: URL) {
    do {
      try FileManager.default.removeItem(at: url)
    } catch {
      print("[ImportExperimentOperation] Error removing item: " + error.localizedDescription)
    }
  }

}
