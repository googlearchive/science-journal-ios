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

/// The `FileSystemLayoutMigration` copies data persisted in the `Documents` directory
/// to a location in `Application Support` and then removes the data from `Documents`.
/// Some files are renamed for consistentency. This class is very defensive in order to
/// reduce the risk of any data corruption or loss.
final class FileSystemLayoutMigration {

  /// Migration errors.
  enum Error: Swift.Error, Equatable {

    /// The migration has already been completed.
    case migrationAlreadyCompleted

    /// The migration failed and cleanup would result in data loss.
    case migrationFailed

  }

  /// A `Step` in the migration.
  struct Step: Equatable {

    /// The path to copy from.
    let from: String

    /// The path to copy to.
    let to: String

  }

  // MARK: - Properties

  /// The ordered steps in the migration.
  let steps: [Step] = [
    Step(from: "accounts", to: "accounts"),
    Step(from: "Science Journal", to: "root"),
    Step(from: "DeletedData", to: "root/DeletedData"),
    Step(from: "ScienceJournal.sqlite", to: "root/sensor_data.sqlite"),
    Step(from: "ScienceJournal.sqlite-shm", to: "root/sensor_data.sqlite-shm"),
    Step(from: "ScienceJournal.sqlite-wal", to: "root/sensor_data.sqlite-wal"),
  ]

  /// Whether or not a migration is needed.
  ///
  /// Check this property before calling `execute`.
  ///
  /// - Returns: true if a migration is needed, otherwise false.
  var isNeeded: Bool {
    return devicePreferenceManager.fileSystemLayoutVersion < postMigrationFileSystemLayoutVersion
  }

  private let fromBaseDirectory: URL
  private let toBaseDirectory: URL
  private let devicePreferenceManager: DevicePreferenceManager
  private let fileManager: FileManager = .default
  private let postMigrationFileSystemLayoutVersion: FileSystemLayout.Version = .two
  private var executeCompleted = false

  // MARK: - Public

  /// Designated Initializer.
  ///
  /// - Parameters:
  ///   - fromBaseDirectory: the base directory for all from paths.
  ///   - toBaseDirectory: the base directory for all to paths.
  ///   - devicePreferenceManager: the device preference manager.
  init(from fromBaseDirectory: URL,
       to toBaseDirectory: URL,
       devicePreferenceManager: DevicePreferenceManager = DevicePreferenceManager()) {
    self.fromBaseDirectory = fromBaseDirectory
    self.toBaseDirectory = toBaseDirectory
    self.devicePreferenceManager = devicePreferenceManager
  }

  /// Execute the migration.
  ///
  /// Call `isNeeded` to see if a migration is needed before calling this method. After this
  /// method completes, call `cleanup` to clean up the legacy directory structure.
  ///
  /// - Throws:
  ///   - migrationAlreadyCompleted: if the file system is not in the expected state.
  ///   - Error: a `FileManager` error if something goes wrong.
  func execute() throws {
    guard isNeeded else {
      throw Error.migrationAlreadyCompleted
    }

    try prepareToBaseDirectory()

    try steps
      .map {(
        fromBaseDirectory.appendingPathComponent($0.from),
        toBaseDirectory.appendingPathComponent($0.to)
      )}
      .forEach(copyItem(at:to:))

    executeCompleted = true
  }

  private func prepareToBaseDirectory() throws {
    if fileManager.fileExists(atPath: toBaseDirectory.path) {
      try fileManager.removeItem(at: toBaseDirectory)
    }
    try fileManager.createDirectory(at: toBaseDirectory, withIntermediateDirectories: true)
    URL.excludeFromiCloudBackups(url: toBaseDirectory)
  }

  private func copyItem(at atURL: URL, to toURL: URL) throws {
    if fileManager.fileExists(atPath: atURL.path) {
      let parentDirectory = toURL.deletingLastPathComponent()
      if !fileManager.fileExists(atPath: parentDirectory.path) {
        try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
      }
      try fileManager.copyItem(at: atURL, to: toURL)
    }
  }

  /// Clean up known files and directories in the `fromBaseDirectory`.
  ///
  /// You must call `execute` before calling this method.
  ///
  /// - Throws:
  ///   - migrationFailed: if the migration did not complete successfully.
  ///   - Error: a `FileManager` error if something goes wrong during cleanup.
  func cleanup() throws {
    guard executeCompleted else {
      throw Error.migrationFailed
    }

    try steps
      .map { fromBaseDirectory.appendingPathComponent($0.from) }
      .forEach(removeItem(at:))

    devicePreferenceManager.fileSystemLayoutVersion = postMigrationFileSystemLayoutVersion
  }

  private func removeItem(at atURL: URL) throws {
    if fileManager.fileExists(atPath: atURL.path) {
      try fileManager.removeItem(at: atURL)
    }
  }

}
