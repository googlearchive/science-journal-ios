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

import third_party_objective_c_ssziparchive_ssziparchive

/// An operation that unzips a zip archive.
class UnzipOperation: GSJOperation {

  private let sourceURL: URL
  private let destinationURL: URL

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sourceURL: The URL of the zip file to extract.
  ///   - destinationURL: The URL where the zip file should be extracted to.
  init(sourceURL: URL, destinationURL: URL) {
    self.sourceURL = sourceURL
    self.destinationURL = destinationURL
  }

  override func execute() {
    do {
      try SSZipArchive.unzipFile(atPath: sourceURL.path,
                                 toDestination: destinationURL.path,
                                 overwrite: true,
                                 password: nil)
    } catch {
      finish(withErrors: [error])
      return
    }

    finish()
  }

}
