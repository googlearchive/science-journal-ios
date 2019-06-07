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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class FileSystemLayoutMigrationTest: XCTestCase {

  private let fileManager = FileManager.default
  private var fromBaseDirectory: URL!
  private var toBaseDirectory: URL!
  private var migration: FileSystemLayoutMigration!

  override func setUp() {
    super.setUp()
    fromBaseDirectory = createUniqueTestDirectoryURL(appendingPathComponent: "Documents")
    toBaseDirectory =
      generateUniqueTestDirectoryURL(appendingPathComponent: "Application Support/Science Journal")
    let devicePreferenceManager = DevicePreferenceManager(defaults: createTestDefaults())
    migration = FileSystemLayoutMigration(from: fromBaseDirectory,
                                          to: toBaseDirectory,
                                          devicePreferenceManager: devicePreferenceManager)
  }

  // ~/Documents/accounts -> ~/Application Support/Science Journal/accounts
  func testMigrateAccountsDirectory() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    let fromAccountsDirectory = from(directory: "accounts")
    let toAccountsDirectory = to(directory: "accounts")
    assertExists(directory: fromAccountsDirectory)
    assertDoesNotExist(directory: toAccountsDirectory)

    XCTAssertNoThrow(try migration.execute())

    assertExists(directory: toAccountsDirectory)
  }

  // ~/Documents/Science Journal -> ~/Application Support/Science Journal/accounts/root
  func testMigrateRootUser() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    let fromRootUserDirectory = from(directory: "Science Journal")
    let toRootUserDirectory = to(directory: "accounts/root")
    assertExists(directory: fromRootUserDirectory)
    assertDoesNotExist(directory: toRootUserDirectory)

    XCTAssertNoThrow(try migration.execute())

    assertExists(directory: toRootUserDirectory)
  }

  // ~/Documents/DeletedData -> ~/Application Support/Science Journal/accounts/root/DeletedData
  func testMigrateRootUserDeletedData() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    let fromRootUserDeletedDataDirectory = from(directory: "DeletedData")
    let toRootUserDeletedDataDirectory = to(directory: "accounts/root/DeletedData")
    assertExists(directory: fromRootUserDeletedDataDirectory)
    assertDoesNotExist(directory: toRootUserDeletedDataDirectory)

    XCTAssertNoThrow(try migration.execute())

    assertExists(directory: toRootUserDeletedDataDirectory)
  }

  // ~/Documents/ScienceJournal.sqlite ->
  //   ~/Application Support/Science Journal/accounts/root/sensor_data.sqlite
  // ~/Documents/ScienceJournal.sqlite-shm ->
  //   ~/Application Support/Science Journal/accounts/root/sensor_data.sqlite-shm
  // ~/Documents/ScienceJournal.sqlite-wal ->
  //   ~/Application Support/Science Journal/accounts/root/sensor_data.sqlite-wal
  func testMigrateRootUserSensorData() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    let fromSQLiteFile = from(file: "ScienceJournal.sqlite")
    let fromSQLiteSHMFile = from(file: "ScienceJournal.sqlite-shm")
    let fromSQLiteWALFile = from(file: "ScienceJournal.sqlite-wal")
    let toSQLiteFile = to(file: "accounts/root/sensor_data.sqlite")
    let toSQLiteSHMFile = to(file: "accounts/root/sensor_data.sqlite-shm")
    let toSQLiteWALFile = to(file: "accounts/root/sensor_data.sqlite-wal")
    assertExists(file: fromSQLiteFile)
    assertExists(file: fromSQLiteSHMFile)
    assertExists(file: fromSQLiteWALFile)
    assertDoesNotExist(file: toSQLiteFile)
    assertDoesNotExist(file: toSQLiteSHMFile)
    assertDoesNotExist(file: toSQLiteWALFile)

    XCTAssertNoThrow(try migration.execute())

    assertExists(file: toSQLiteFile)
    assertExists(file: toSQLiteSHMFile)
    assertExists(file: toSQLiteWALFile)
  }

  func testMigrationOrder() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)

    typealias FSLM = FileSystemLayoutMigration
    XCTAssertEqual(migration.steps, [
      FSLM.Step(from: "accounts", to: "accounts"),
      FSLM.Step(from: "Science Journal", to: "accounts/root"),
      FSLM.Step(from: "DeletedData", to: "accounts/root/DeletedData"),
      FSLM.Step(from: "ScienceJournal.sqlite", to: "accounts/root/sensor_data.sqlite"),
      FSLM.Step(from: "ScienceJournal.sqlite-shm", to: "accounts/root/sensor_data.sqlite-shm"),
      FSLM.Step(from: "ScienceJournal.sqlite-wal", to: "accounts/root/sensor_data.sqlite-wal"),
    ])
  }

  func testMigrationCleanup() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    let fromAccountsDirectory = from(directory: "accounts")
    let fromRootUserDirectory = from(directory: "Science Journal")
    let fromRootUserDeletedDataDirectory = from(directory: "DeletedData")
    let fromSQLiteFile = from(file: "ScienceJournal.sqlite")
    let fromSQLiteSHMFile = from(file: "ScienceJournal.sqlite-shm")
    let fromSQLiteWALFile = from(file: "ScienceJournal.sqlite-wal")
    assertExists(directory: fromAccountsDirectory)
    assertExists(directory: fromRootUserDirectory)
    assertExists(directory: fromRootUserDeletedDataDirectory)
    assertExists(file: fromSQLiteFile)
    assertExists(file: fromSQLiteSHMFile)
    assertExists(file: fromSQLiteWALFile)

    XCTAssertNoThrow(try migration.execute())
    XCTAssertNoThrow(try migration.cleanup())

    assertDoesNotExist(directory: fromAccountsDirectory)
    assertDoesNotExist(directory: fromRootUserDirectory)
    assertDoesNotExist(directory: fromRootUserDeletedDataDirectory)
    assertDoesNotExist(file: fromSQLiteFile)
    assertDoesNotExist(file: fromSQLiteSHMFile)
    assertDoesNotExist(file: fromSQLiteWALFile)
  }

  func testMigrationOnlyRunsOnce() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    XCTAssertNoThrow(try migration.execute())
    XCTAssertNoThrow(try migration.cleanup())

    XCTAssertThrowsError(try migration.execute()) { error in
      XCTAssertEqual(error as? FileSystemLayoutMigration.Error,
                     FileSystemLayoutMigration.Error.migrationAlreadyCompleted)
    }
  }

  func testMigrationCanBeReRunAfterFailure() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    XCTAssertNoThrow(try migration.execute())
    // The above call won't actually fail, but because we didn't call `cleanup`
    // the success hasn't been persisted yet.

    XCTAssertNoThrow(try migration.execute())
  }

  func testMigrationHandlesEmptyFromDirectory() {
    // Do not create the legacy directory structure to ensure `fromBaseDirectory` will be empty.

    XCTAssertNoThrow(try migration.execute())
  }

  func testMigrationHandlesCommonFromDirectoryStructure() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    XCTAssertNoThrow(try fileManager.removeItem(at: from(directory: "accounts")))
    XCTAssertNoThrow(try fileManager.removeItem(at: from(directory: "DeletedData")))

    XCTAssertNoThrow(try migration.execute())
  }

  func testCleanupDoesNotRunIfMigrationFailed() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)

    XCTAssertThrowsError(try migration.cleanup()) { error in
      XCTAssertEqual(error as? FileSystemLayoutMigration.Error,
                     FileSystemLayoutMigration.Error.migrationFailed)
    }
  }

  func testMigrationIsNeeded() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)

    XCTAssert(migration.isNeeded, "expected migration to be needed")
  }

  func testMigrationIsNotNeeded() {
    createLegacyDirectoryStructure(at: fromBaseDirectory)
    XCTAssertNoThrow(try migration.execute())
    XCTAssertNoThrow(try migration.cleanup())

    XCTAssertFalse(migration.isNeeded, "expected migration to not be needed")
  }

  // MARK: - Test Helpers

  private func assertDoesNotExist(directory directoryURL: URL,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
    XCTAssertFalse(fileManager.fileExists(atPath: directoryURL.path),
                   "expected nothing to exist at \(directoryURL)", file: file, line: line)
  }

  private func assertDoesNotExist(file fileURL: URL,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
    XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path),
                   "expected nothing to exist at \(fileURL)", file: file, line: line)
  }

  private func assertExists(directory directoryURL: URL,
                            file: StaticString = #file,
                            line: UInt = #line) {
    var isDirectory = ObjCBool(false)
    XCTAssert(fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
              "expected directory at \(directoryURL)", file: file, line: line)
    XCTAssert(isDirectory.boolValue,
              "expected \(directoryURL) to be a directory",
              file: file,
              line: line)
  }

  private func assertExists(file fileURL: URL, file: StaticString = #file, line: UInt = #line) {
    var isDirectory = ObjCBool(false)
    XCTAssert(fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
              "expected file at \(fileURL)", file: file, line: line)
    XCTAssertFalse(isDirectory.boolValue, "expected \(fileURL) to be a file",
                   file: file,
                   line: line)
  }

  private func create(directory directoryURL: URL) {
    do {
      try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    } catch {
      XCTFail("Failed to create directory at \(directoryURL)")
    }
  }

  private func create(file fileURL: URL) {
    guard fileManager.createFile(atPath: fileURL.path, contents: nil) else {
      XCTFail("Failed to create file at \(fileURL)")
      return
    }
  }

  private func createLegacyDirectoryStructure(at baseDirectory: URL) {
    create(directory: baseDirectory.appendingPathComponent("accounts", isDirectory: true))
    create(directory: baseDirectory.appendingPathComponent("DeletedData", isDirectory: true))
    create(directory: baseDirectory.appendingPathComponent("Science Journal", isDirectory: true))
    create(file: baseDirectory.appendingPathComponent("ScienceJournal.sqlite", isDirectory: false))
    create(file: baseDirectory.appendingPathComponent("ScienceJournal.sqlite-shm",
                                                    isDirectory: false))
    create(file: baseDirectory.appendingPathComponent("ScienceJournal.sqlite-wal",
                                                    isDirectory: false))
  }

  private func from(directory pathComponent: String) -> URL {
    return fromBaseDirectory.appendingPathComponent(pathComponent, isDirectory: true)
  }

  private func from(file pathComponent: String) -> URL {
    return fromBaseDirectory.appendingPathComponent(pathComponent, isDirectory: false)
  }

  private func to(directory pathComponent: String) -> URL {
    return toBaseDirectory.appendingPathComponent(pathComponent, isDirectory: true)
  }

  private func to(file pathComponent: String) -> URL {
    return toBaseDirectory.appendingPathComponent(pathComponent, isDirectory: false)
  }

}
