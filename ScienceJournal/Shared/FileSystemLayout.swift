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

/// Common, app-specific paths
public struct FileSystemLayout {

  /// The version of the file system layout.
  public enum Version: Int {

    /// The layout for versions <= 3.1. (User data stored in `Documents`)
    case one = 1

    /// The layout for versions >= 3.2 (User data stored in `Application Support`)
    case two = 2

  }

  /// The production configuration
  public static let production = FileSystemLayout(baseURL: URL.documentsDirectoryURL)

  /// The base URL that other URLs are relative to.
  let baseURL: URL

  /// The accounts directory URL.
  public var accountsDirectoryURL: URL {
    return baseURL.appendingPathComponent("accounts")
  }

  /// Whether or not there is a root directory for this account.
  ///
  /// - Parameter accountID: An account ID.
  /// - Returns: True if there is a root directory for this account, otherwise false.
  public func hasAccountDirectory(for accountID: String) -> Bool {
    let accountPath = accountURL(for: accountID).path
    return FileManager.default.fileExists(atPath: accountPath)
  }

  /// The account URL for the specified account.
  ///
  /// - Parameter accountID: An account ID.
  /// - Returns: The URL for the specified account.
  public func accountURL(for accountID: String) -> URL {
    return accountsDirectoryURL.appendingPathComponent(accountID)
  }

}

extension FileSystemLayout.Version: Comparable {

  public static func < (lhs: FileSystemLayout.Version, rhs: FileSystemLayout.Version) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }

}
