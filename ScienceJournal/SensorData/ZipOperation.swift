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

import third_party_objective_c_ssziparchive_ssziparchive

enum ZipError: Error {
  /// The URL to zip is not valid.
  case sourceURLIsInvalid
  /// There was an error creating the zip archive.
  case errorCreatingZipArchive
}

/// An operation that zips the contents of a source directory.
class ZipOperation: GSJOperation {

  private let sourceURL: URL
  private let destinationURL: URL

  init(sourceURL: URL, destinationURL: URL) {
    self.sourceURL = sourceURL
    self.destinationURL = destinationURL
  }

  override func execute() {
    var isDirectory: ObjCBool = false
    let directoryExists =
        FileManager.default.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory)

    guard directoryExists && isDirectory.boolValue else {
      finish(withErrors: [ZipError.sourceURLIsInvalid])
      return
    }

    let success = SSZipArchive.createZipFile(atPath: destinationURL.path,
                                             withContentsOfDirectory: sourceURL.path)
    guard success else {
      finish(withErrors: [ZipError.errorCreatingZipArchive])
      return
    }

    finish()
  }

}
