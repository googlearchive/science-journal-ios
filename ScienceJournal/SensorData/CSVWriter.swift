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

/// Writes a comma separated value file to disk by adding rows of values one at a time.
class CSVWriter {

  /// The file URL of the CSV file.
  let fileURL: URL

  private var fileHandle: FileHandle?
  private let columnCount: Int

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - fileURL: The file URL to write to.
  ///   - columnTitles: An array of string titles, one for each column.
  /// - Throws: An error if a file handle cannot be created for the given file URL.
  init?(fileURL: URL, columnTitles: [String]) {
    self.fileURL = fileURL
    do {
      // Create an empty file. This will overwrite any existing files.
      try "".write(to: fileURL, atomically: true, encoding: .utf8)
      fileHandle = try FileHandle(forWritingTo: fileURL)
    } catch {
      print("error: \(error)")
      return nil
    }
    columnCount = columnTitles.count
    addValues(columnTitles)
  }

  deinit {
    finish()
  }

  /// Add a row of string values to the CSV file on disk.
  ///
  /// - Parameter values: An array of string values.
  func addValues(_ values: [String]) {
    assert(values.count == columnCount,
           "[CSVWriter] The number of value columns added to a CSV file should equal the count " +
           "of column titles")
    let csvLine = values.joined(separator: ",") + "\n"
    guard let lineData = csvLine.data(using: .utf8) else {
      return
    }
    fileHandle?.write(lineData)
  }

  /// Closes the file handle. Should be called after adding the last row of values.
  func finish() {
    fileHandle?.closeFile()
  }

}
