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

/// An operation that exports an experiment as a Science Journal file (with extension: .sj).
class ExportDocumentOperation: GroupOperation {

  /// The URL the document will be written to.
  let documentURL: URL

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - coverImageURL: The URL of the experiment's cover image.
  ///   - defaultCoverImageURL: The default cover image URL required for export.
  ///   - experiment: An experiment.
  ///   - experimentURL: The URL location of the experiment directory.
  ///   - overview: The overview associated with the experiment.
  ///   - sensorDataManager: A sensor data manager.
  init(coverImageURL: URL?,
       defaultCoverImageURL: URL,
       experiment: Experiment,
       experimentURL: URL,
       overview: ExperimentOverview,
       sensorDataManager: SensorDataManager) {
    let tempFolder = ProcessInfo.processInfo.globallyUniqueString + "_export"
    let tempFolderURL =
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tempFolder)
    let copiedExperimentURL = tempFolderURL.appendingPathComponent(experiment.ID)
    let documentFilename = experiment.titleOrDefault.validFilename(withExtension: "sj")
    documentURL = tempFolderURL.appendingPathComponent(documentFilename)

    do {
      try FileManager.default.createDirectory(at: tempFolderURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
    } catch {
      // Just log the error for dev purposes. The copy operation will fail if this does.
      print("[ExportDocumentOperation] Error creating temp directory for export file: " +
          error.localizedDescription)
    }

    var operations = [GSJOperation]()

    let copyOperation = CopyFileOperation(fromURL: experimentURL, toURL: copiedExperimentURL)
    operations.append(copyOperation)

    let exportSensorDataOperation =
        ExportExperimentSensorDataOperation(saveDirectoryURL: copiedExperimentURL,
                                            sensorDataManager: sensorDataManager,
                                            experiment: experiment)
    operations.append(exportSensorDataOperation)
    let zipOperation = ZipOperation(sourceURL: copiedExperimentURL, destinationURL: documentURL)
    operations.append(zipOperation)
    let removeOperation = RemoveFileOperation(url: copiedExperimentURL)
    operations.append(removeOperation)

    // Create dependencies.
    exportSensorDataOperation.addDependency(copyOperation)
    zipOperation.addDependency(exportSensorDataOperation)
    removeOperation.addDependency(zipOperation)

    // Compatability with versions of Science Journal where experiment did not contain an image path
    // requires the cover image be saved with a special name.
    if let coverImageURL = coverImageURL {
      let copyCoverImageOperation = CopyFileOperation(fromURL: coverImageURL,
                                                      toURL: defaultCoverImageURL)
      operations.append(copyCoverImageOperation)

      // Copy the cover image after the experiment is copied, before zipping.
      copyCoverImageOperation.addDependency(copyOperation)
      zipOperation.addDependency(copyCoverImageOperation)
    }

    super.init(operations: operations)
  }

}
