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
  /// - Parameters:
  ///   - pathComponent: The path component to append.
  ///   - removeDuringTeardown: Whether to remove the directory during teardown.
  public func createUniqueTestDirectoryURL(
    appendingPathComponent pathComponent: String? = nil,
    removeDuringTeardown: Bool = true
  ) -> URL {
    let uniqueTestDirectoryURL =
      generateUniqueTestDirectoryURL(appendingPathComponent: pathComponent,
                                     removeDuringTeardown: removeDuringTeardown)
    try! FileManager.default.createDirectory(
      at: uniqueTestDirectoryURL,
      withIntermediateDirectories: true
    )
    return uniqueTestDirectoryURL
  }

  /// Generate a unique test directory URL.
  ///
  /// - Parameters:
  ///   - pathComponent: The path component to append.
  ///   - removeDuringTeardown: Whether to remove the directory during teardown.
  public func generateUniqueTestDirectoryURL(
    appendingPathComponent pathComponent: String? = nil,
    removeDuringTeardown: Bool = true
  ) -> URL {
    var uniqueTestDirectoryURL = testRootDirectoryURL.appendingPathComponent(UUID().uuidString)
    if removeDuringTeardown {
      removeItemDuringTeardown(uniqueTestDirectoryURL)
    }
    if let pathComponent = pathComponent {
      uniqueTestDirectoryURL.appendPathComponent(pathComponent)
    }
    return uniqueTestDirectoryURL
  }

  /// Add a teardown block to remove the specified URL.
  ///
  /// - Parameters:
  ///   - url: The URL to remove.
  public func removeItemDuringTeardown(_ url: URL) {
    addTeardownBlock {
      guard FileManager.default.fileExists(atPath: url.path) else {
        return
      }
      do {
        try FileManager.default.removeItem(at: url)
      } catch {
        XCTFail("failed to remove \(url) during teardown")
      }
    }
  }
}

extension XCTestCase: TestDirectories {}
