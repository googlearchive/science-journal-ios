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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class CSVWriterTest: XCTestCase {

  func testWritingFile() {
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    let tempURL = tempDirectory.appendingPathComponent("test_csv.csv")

    if FileManager.default.fileExists(atPath: tempURL.path) {
      try! FileManager.default.removeItem(at: tempURL)
    }

    let csvWriter = CSVWriter(fileURL: tempURL, columnTitles: ["A", "B", "C"])!
    XCTAssertNotNil(csvWriter)

    csvWriter.addValues(["1", "2", "3"])
    csvWriter.addValues(["4", "5", "6"])
    let fileContents = try! String(contentsOf: tempURL)

    let expectedContents = "A,B,C\n1,2,3\n4,5,6\n"

    XCTAssertEqual(expectedContents, fileContents)

    try! FileManager.default.removeItem(at: tempURL)
  }

}
