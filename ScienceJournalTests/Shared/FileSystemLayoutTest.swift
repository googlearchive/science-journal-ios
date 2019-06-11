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

class FileSystemLayoutTest: XCTestCase {

  private let fileManager = FileManager.default

  func testVersionIsComparable() {
    XCTAssertLessThan(FileSystemLayout.Version.one, FileSystemLayout.Version.two)
    XCTAssertGreaterThan(FileSystemLayout.Version.two, FileSystemLayout.Version.one)
  }

  func testVersionOneBaseURL() {
    XCTAssertEqual(FileSystemLayout.Version.one.baseURL.pathComponents.last, "Documents")
  }

  func testVersionTwoBaseURL() {
    XCTAssertEqual(FileSystemLayout.Version.two.baseURL.pathComponents.suffix(2),
                   ["Application Support", "Science Journal"])
  }

  func testProductionConfiguration() {
    XCTAssertEqual(FileSystemLayout.production.baseURL, FileSystemLayout.Version.two.baseURL)
  }

  func testAccountsDirectoryURL() {
    let layout = FileSystemLayout(baseURL: URL(fileURLWithPath: "/tmp"))
    XCTAssertEqual(layout.accountsDirectoryURL.path, "/tmp/accounts")
  }

  func testRootUserURL() {
    let layout = FileSystemLayout(baseURL: URL(fileURLWithPath: "/tmp"))
    XCTAssertEqual(layout.rootUserURL.path, "/tmp/root")
  }

  func testAccountURL() {
    let layout = FileSystemLayout(baseURL: URL(fileURLWithPath: "/tmp"))
    XCTAssertEqual(layout.accountURL(for: "TEST").path, "/tmp/accounts/TEST")
  }

  func testHasAccountDirectoryFalse() {
    let layout = FileSystemLayout(baseURL: createUniqueTestDirectoryURL())
    let accountURL = layout.accountURL(for: "TEST")

    XCTAssertFalse(layout.hasAccountDirectory(for: "TEST"), "unexpected directory at \(accountURL)")
  }

  func testHasAccountDirectoryTrue() {
    let layout = FileSystemLayout(baseURL: createUniqueTestDirectoryURL())
    let accountURL = layout.accountURL(for: "TEST")
    XCTAssertNoThrow(try fileManager.createDirectory(at: accountURL,
                                                     withIntermediateDirectories: true))

    XCTAssert(layout.hasAccountDirectory(for: "TEST"), "expected directory at \(accountURL)")
  }

}
