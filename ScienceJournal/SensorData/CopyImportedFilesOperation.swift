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

enum CopyImportedFilesError: Error {
  /// The operation did not have the required `ImportExperimentOperation` as a dependency.
  case importExperimentOperationNotFound
  /// The destination directory could not be created.
  case cannotCreateDestinationDirectory
  /// The destination assets directroy could not be created.
  case cannotCreateAssetsDirectory
}

/// An operation that copies the imported files to a destination experiment directory. Requires
/// an `ImportExperimentOperation` as a dependency.
class CopyImportedFilesOperation: GroupOperation {

  private let destinationExperimentURL: URL

  /// Designated initializer.
  ///
  /// - Parameter destinationExperimentURL: The destination directory to which files should
  ///                                       be copied.
  init(destinationExperimentURL: URL) {
    self.destinationExperimentURL = destinationExperimentURL
    // Operations are added at execution time.
    super.init(operations: [])
  }

  override func execute() {
    guard let importExperimentOperation =
        (dependencies.compactMap { $0 as? ImportExperimentOperation }).first else {
      finish(withErrors: [CopyImportedFilesError.importExperimentOperationNotFound])
      return
    }

    do {
      try FileManager.default.createDirectory(at: destinationExperimentURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
    } catch {
      finish(withErrors: [CopyImportedFilesError.cannotCreateDestinationDirectory])
      return
    }

    var copyOperations = [CopyFileOperation]()

    if let experimentProtoURL = importExperimentOperation.experimentProtoURL {
      let experimentDestinationURL =
          destinationExperimentURL.appendingPathComponent(experimentProtoURL.lastPathComponent)
      copyOperations.append(CopyFileOperation(fromURL: experimentProtoURL,
                                              toURL: experimentDestinationURL))
    }

    if let sensorDataProtoURL = importExperimentOperation.sensorDataProtoURL {
      let sensorDataDestinationURL =
          destinationExperimentURL.appendingPathComponent(sensorDataProtoURL.lastPathComponent)
      copyOperations.append(CopyFileOperation(fromURL: sensorDataProtoURL,
                                              toURL: sensorDataDestinationURL))
    }

    if importExperimentOperation.assets.count > 0 {
      let assetsURL =
          destinationExperimentURL.appendingPathComponent(MetadataManager.assetsDirectoryName)
      do {
        try FileManager.default.createDirectory(at: assetsURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
      } catch {
        finish(withErrors: [CopyImportedFilesError.cannotCreateAssetsDirectory])
        return
      }

      for assetURL in importExperimentOperation.assets {
        let destinationAssetURL = assetsURL.appendingPathComponent(assetURL.lastPathComponent)
        copyOperations.append(CopyFileOperation(fromURL: assetURL, toURL: destinationAssetURL))
      }
    }

    for copyOp in copyOperations {
      addDependency(copyOp)
      addOperation(copyOp)
    }

    // GroupOperation's execute method begins the execution of all sub-operations, so it must be
    // called last.
    super.execute()
  }

}
