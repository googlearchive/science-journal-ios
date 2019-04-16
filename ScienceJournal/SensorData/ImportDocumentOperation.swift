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

/// An operation that encapsulates the full process of importing a .sj file.
class ImportDocumentOperation: GroupOperation {

  /// Designated initialzer.
  ///
  /// - Parameters:
  ///   - sourceURL: The source URL of the imported document as given by the system.
  ///   - zipURL: The URL where the source file will be copied.
  ///   - extractionURL: The URL where the file will be extracted.
  ///   - experimentURL: The URL of the new experiment that will be created.
  ///   - sensorDataManager: A sensor data manager.
  ///   - metadataManager: A metadata manager.
  init(sourceURL: URL,
       zipURL: URL,
       extractionURL: URL,
       experimentURL: URL,
       sensorDataManager: SensorDataManager,
       metadataManager: MetadataManager) {
    // Copy the file, Unzip it, import the experiment, then clean up.
    let copySourceOperation = CopyFileOperation(fromURL: sourceURL, toURL: zipURL)
    let unzipOperation = UnzipOperation(sourceURL: zipURL, destinationURL: extractionURL)
    let importExperimentOperation = ImportExperimentOperation(importDirectoryURL: extractionURL,
                                                              metadataManager: metadataManager)
    let importSensorDataOperation =
        ImportSensorDataFromProtoOperation(sensorDataManager: sensorDataManager)
    let copyImportedFilesOperation =
        CopyImportedFilesOperation(destinationExperimentURL: experimentURL)
    let removeExtractedOperation = RemoveFileOperation(url: extractionURL)
    let removeZipOperation = RemoveFileOperation(url: zipURL)

    // Set up dependencies.
    unzipOperation.addDependency(copySourceOperation)
    importExperimentOperation.addDependency(unzipOperation)
    importSensorDataOperation.addDependency(importExperimentOperation)
    copyImportedFilesOperation.addDependency(importExperimentOperation)

    // The cleanup operations depend on both copy and import sensor data finishing.
    removeExtractedOperation.addDependency(copyImportedFilesOperation)
    removeExtractedOperation.addDependency(importSensorDataOperation)
    removeZipOperation.addDependency(copyImportedFilesOperation)
    removeZipOperation.addDependency(importSensorDataOperation)

    super.init(operations: [copySourceOperation,
                            unzipOperation,
                            importExperimentOperation,
                            importSensorDataOperation,
                            copyImportedFilesOperation,
                            removeExtractedOperation,
                            removeZipOperation])
  }

}
