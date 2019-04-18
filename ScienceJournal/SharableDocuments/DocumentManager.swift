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

/// Document errors.
enum DocumentManagerError: Error {
  /// Cannot import a document while the app is recording.
  case importingDocumentWhileRecording
  // Cannot import a document until permission and age setup is complete.
  case importingDocumentBeforeSetupComplete

  var logString: String {
    switch self {
    case .importingDocumentWhileRecording:
      return "Cannot import a document while the app is recording."
    case .importingDocumentBeforeSetupComplete:
      return "Cannot import a document until permission and age setup is complete"
    }
  }
}

extension Notification.Name {
  /// Posted when the app begins to import a file.
  static let documentManagerDidBeginImportExperiment =
      Notification.Name("DocumentManagerDidBeginImportExperiment")
  /// Posted when the app finishes importing a file successfully.
  static let documentManagerDidImportExperiment =
      Notification.Name("DocumentManagerDidImportExperiment")
  /// Posted when the app finishes importing a file but it failed. Access an array of errors with
  /// user info key DocumentManager.importFailedErrorsKey.
  static let documentManagerImportExperimentFailed =
      Notification.Name("DocumentManagerImportExperimentFailed")
}

/// Manages the import and export of the sharable Science Journal document format
/// (files with extension: .sj).
class DocumentManager {

  /// When the notification `documentManagerImportExperimentFailed` is posted, this is the key
  /// for an array of errors in `userInfo`.
  static let importFailedErrorsKey = "DocumentManagerImportFailedErrorsKey"
  /// When the notification `documentManagerDidImportExperiment` is posted, this is the key for the
  /// imported experiment ID in `userInfo`.
  static let importedExperimentIDKey = "DocumentManagerImportedExperimentIDKey"

  private let experimentDataDeleter: ExperimentDataDeleter
  private let metadataManager: MetadataManager
  private let operationQueue = GSJOperationQueue()
  private let sensorDataManager: SensorDataManager

  private let documentFileExtension = "sj"

  /// Returns a unique import filename each time the property is called.
  private var uniqueImportFilename: String {
    return ProcessInfo.processInfo.globallyUniqueString + "_import"
  }

  init(experimentDataDeleter: ExperimentDataDeleter,
       metadataManager: MetadataManager,
       sensorDataManager: SensorDataManager) {
    self.experimentDataDeleter = experimentDataDeleter
    self.metadataManager = metadataManager
    self.sensorDataManager = sensorDataManager
  }

  func tearDown() {
    operationQueue.terminate()
  }

  // MARK: - Document Import

  /// Handles an import URL if it points to a valid import document.
  ///
  /// - Parameter url: The URL of an imported file to evaluate.
  /// - Returns: Returns true if the url can be handled as an imported document, otherwise false.
  func handleImportURL(_ url: URL) -> Bool {
    guard url.pathExtension == documentFileExtension else {
      return false
    }

    // Importing when the app is recording is not supported.
    guard !RecordingState.isRecording else {
      let errors = [DocumentManagerError.importingDocumentWhileRecording]
      let userInfo = [DocumentManager.importFailedErrorsKey: errors]
      NotificationCenter.default.post(name: .documentManagerImportExperimentFailed,
                                      object: self,
                                      userInfo: userInfo)
      return false
    }

    let baseFilename = uniqueImportFilename
    let filename = baseFilename + "." + documentFileExtension
    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let copiedFileURL = tempDirectoryURL.appendingPathComponent(filename)

    let zipFilename = exportFilename(withBasename: baseFilename)
    let zipDestinationURL = tempDirectoryURL.appendingPathComponent(zipFilename)

    let newExperimentID = UUID().uuidString
    let newExperimentURL = metadataManager.experimentDirectoryURL(for: newExperimentID)

    // Notify so the UI can show a loading state if necessary. File importing is a modal process.
    NotificationCenter.default.post(name: .documentManagerDidBeginImportExperiment, object: self)

    // The import document operation will validate and copy the extracted file to the
    // experiments directory.
    let importDocumentOperation =
        ImportDocumentOperation(sourceURL: url,
                                zipURL: copiedFileURL,
                                extractionURL: zipDestinationURL,
                                experimentURL: newExperimentURL,
                                sensorDataManager: sensorDataManager,
                                metadataManager: metadataManager)
    let observer = BlockObserver { (operation, errors) in
      if !operation.didFinishSuccessfully {
        self.experimentDataDeleter.permanentlyDeleteExperiment(withID: newExperimentID)

        let userInfo = [DocumentManager.importFailedErrorsKey: errors]
        NotificationCenter.default.post(name: .documentManagerImportExperimentFailed,
                                        object: self,
                                        userInfo: userInfo)
      } else {
        self.metadataManager.addImportedExperiment(withID: newExperimentID)

        let userInfo = [DocumentManager.importedExperimentIDKey: newExperimentID]
        NotificationCenter.default.post(name: .documentManagerDidImportExperiment,
                                        object: self,
                                        userInfo: userInfo)
      }
    }
    importDocumentOperation.addObserver(observer)
    importDocumentOperation.addObserver(BackgroundTaskObserver())
    operationQueue.addOperation(importDocumentOperation)

    return true
  }

  // MARK: - Document Export

  /// Checks that an experiment is ready for export, which means it is not missing any assets
  /// (sensor data or images).
  ///
  /// - Parameters:
  ///   - experiment: The experiment to check.
  ///   - completion: Closure called when the check is complete with a Bool idicating the
  ///                 experiment's readiness.
  func experimentIsReadyForExport(_ experiment: Experiment, completion: @escaping (Bool) -> Void) {
    sensorDataManager.sensorDataExists(forExperiment: experiment, completion: { (exists) in
      var experimentAssetsDownloaded = exists
      if experimentAssetsDownloaded &&
          self.metadataManager.imageFilesExist(forExperiment: experiment) == false {
        experimentAssetsDownloaded = false
      }
      completion(experimentAssetsDownloaded)
    })
  }

  /// Creates a document file for exporting an experiment.
  ///
  /// - Parameters:
  ///   - experimentID: An experiment ID.
  ///   - completion: A block called on completion with an optional url.
  ///                 Guaranteed to be called on the main thread.
  func createExportDocument(forExperimentWithID experimentID: String,
                            completion: @escaping (URL?) -> Void) {
    guard let (experiment, overview) =
        metadataManager.experimentAndOverview(forExperimentID: experimentID) else {
      sjlog_error("Failed to find experiment with ID '\(experimentID)' when exporting experiment.",
                  category: .general)
      completion(nil)
      return
    }

    // Migrate image path from overview if necessary.
    if experiment.imagePath == nil {
      experiment.imagePath = overview.imagePath
    }

    experiment.setTitleToDefaultIfNil()

    // Make sure there are no unsaved changes.
    metadataManager.saveExperimentWithoutDateOrDirtyChange(experiment)

    var coverImageURL: URL?
    if let imagePath = experiment.imagePath {
      coverImageURL = metadataManager.pictureFileURL(for: imagePath, experimentID: experiment.ID)
    }

    let documentExportOperation = ExportDocumentOperation(
        coverImageURL: coverImageURL,
        experiment: experiment,
        experimentURL: metadataManager.experimentDirectoryURL(for: experimentID),
        sensorDataManager: sensorDataManager)
    let blockObserver = BlockObserver { (operation, _) in
      DispatchQueue.main.async {
        guard let documentURL = (operation as? ExportDocumentOperation)?.documentURL else {
          completion(nil)
          return
        }
        completion(documentURL)
      }
    }
    documentExportOperation.addObserver(blockObserver)
    documentExportOperation.addObserver(BackgroundTaskObserver())

    // Add it to the queue.
    operationQueue.addOperation(documentExportOperation)
  }

  /// This should be called after a document has finished sharing. The item at the url will be
  /// deleted.
  ///
  /// - Parameter url: The url of an export document.
  func finishedWithExportDocument(atURL url: URL) {
    operationQueue.addOperation(RemoveFileOperation(url: url))
  }

  // MARK: - Private

  private func exportFilename(withBasename basename: String) -> String {
    return basename + "_extracted"
  }

}

#if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
/// Extension to generate debug data in dev builds via document import.
extension DocumentManager {

  /// Generates debug test data for the root user.
  func debug_createRootUserData(completion: (() -> Void)? = nil) {
    // Set chronological timestamps so they display in the correct order.

    guard let urls = Bundle.currentBundle.urls(forResourcesWithExtension: "sj",
                                               subdirectory: nil) else { return }

    var importOperations: [ImportDocumentOperation] = []

    func randomBool() -> Bool { return arc4random_uniform(2) == 0 }

    for (i, url) in urls.enumerated() {
      let baseFilename = uniqueImportFilename
      let filename = baseFilename + "." + documentFileExtension
      let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
      let copiedFileURL = tempDirectoryURL.appendingPathComponent(filename)

      let zipFilename = exportFilename(withBasename: baseFilename)
      let zipDestinationURL = tempDirectoryURL.appendingPathComponent(zipFilename)

      let newExperimentID = UUID().uuidString
      let newExperimentURL = metadataManager.experimentDirectoryURL(for: newExperimentID)

      // The import document operation will validate and copy the extracted file to the
      // experiments directory.
      let importDocumentOperation =
          ImportDocumentOperation(sourceURL: url,
                                  zipURL: copiedFileURL,
                                  extractionURL: zipDestinationURL,
                                  experimentURL: newExperimentURL,
                                  sensorDataManager: sensorDataManager,
                                  metadataManager: metadataManager)
      let observer = BlockObserver { (operation, errors) in
        if operation.didFinishSuccessfully {
          self.metadataManager.addImportedExperiment(withID: newExperimentID)

          // Mark the last experiment as archived for test purposes.
          if i == urls.count - 1 {
            self.metadataManager.toggleArchiveStateForExperiment(withID: newExperimentID)
          }
        } else {
          self.experimentDataDeleter.permanentlyDeleteExperiment(withID: newExperimentID)
        }
      }
      importDocumentOperation.addObserver(observer)
      importDocumentOperation.addObserver(BackgroundTaskObserver())
      importOperations.append(importDocumentOperation)
    }

    let groupOperation = GroupOperation(operations: importOperations)
    let groupObserver = BlockObserver { (operation, errors) in
      completion?()
    }
    groupOperation.addObserver(groupObserver)
    operationQueue.addOperation(groupOperation)
  }

}
#endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
