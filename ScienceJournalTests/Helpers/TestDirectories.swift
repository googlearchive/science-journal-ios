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
import XCTest

/// URLs and support behavior for test-specific directories.
public protocol TestDirectories {
  func addTeardownBlock(_ block: @escaping () -> Void)
}

extension TestDirectories {
  /// The test directory under which other test-specific directories are created.
  public var testRootDirectoryURL: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("TEST")
  }

  /// Create a unique test directory.
  ///
  /// - Parameter removeDuringTeardown: Whether to remove the directory during teardown.
  public func createUniqueTestDirectoryURL(removeDuringTeardown: Bool = true) -> URL {
    let uniqueTestDirectoryURL = testRootDirectoryURL.appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(
      at: uniqueTestDirectoryURL,
      withIntermediateDirectories: true
    )
    if removeDuringTeardown {
      addTeardownBlock {
        try! FileManager.default.removeItem(at: uniqueTestDirectoryURL)
      }
    }
    return uniqueTestDirectoryURL
  }
}

extension XCTestCase: TestDirectories {}
