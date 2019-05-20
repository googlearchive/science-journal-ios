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

extension FileManager {

  /// Returns the size of a directory on disk.
  ///
  /// - Parameter url: A URL.
  /// - Returns: The size.
  func sizeOfDirectory(at url: URL) -> UInt64? {
    var enumeratorError: Error?
    let enumerator = self.enumerator(at: url,
                                     includingPropertiesForKeys: URL.allocatedSizeResourceKeys,
                                     options: []) { (_, error) -> Bool in
      enumeratorError = error
      return false
    }

    guard let directoryEnumerator = enumerator else {
      return nil
    }

    var totalSize: UInt64 = 0

    for item in directoryEnumerator {
      guard let url = item as? URL else {
        continue
      }

      guard enumeratorError == nil, let size = url.fileAllocatedSize else {
        return nil
      }
      totalSize += size
    }

    return totalSize
  }

  /// The available system disk space.
  var availableSystemDiskSpace: UInt64? {
    let path = URL.documentsDirectoryURL.path
    guard let systemAttributes = try? attributesOfFileSystem(forPath: path),
        let freeSize = systemAttributes[.systemFreeSize] as? NSNumber else {
      return nil
    }
    return freeSize.uint64Value
  }

  /// Checks if the storage space is greater than the queried byte count times the padding factor.
  ///
  /// - Parameters:
  ///   - byteCount: The byte count.
  ///   - padding: The padding factor.
  /// - Returns: True, if storage space is greater, false otherwise.
  func hasStorageSpace(for byteCount: UInt64, padding: Double = 1.1) -> Bool {
    guard let availableSystemDiskSpace = availableSystemDiskSpace else {
      return false
    }

    let safeSize = UInt64(Double(byteCount) * padding)
    return availableSystemDiskSpace > safeSize
  }
}
