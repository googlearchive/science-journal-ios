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

/// An operation that copies a file from one URL to another.
class CopyFileOperation: GSJOperation {

  private let fromURL: URL
  private let toURL: URL

  /// Designated initialzer.
  ///
  /// - Parameters:
  ///   - fromURL: The source URL to copy.
  ///   - toURL: Where the source URL should be copied to.
  init(fromURL: URL, toURL: URL) {
    self.fromURL = fromURL
    self.toURL = toURL
  }

  override func execute() {
    do {
      try FileManager.default.copyItem(at: fromURL, to: toURL)
    } catch {
      print("[MetadataManager] Error copying imported file from '\(fromURL)' to '\(toURL)': " +
          "\(error)")
      finish(withErrors: [error])
      return
    }
    finish()
  }

}
