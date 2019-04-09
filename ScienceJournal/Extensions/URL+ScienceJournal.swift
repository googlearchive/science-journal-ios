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

extension URL {

  /// The documents directory URL.
  public static var documentsDirectoryURL: URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  /// The accounts directory URL.
  public static var accountsDirectoryURL: URL {
    return URL.documentsDirectoryURL.appendingPathComponent("accounts")
  }

  /// Excludes documents URL and data from iCloud backups.
  public static func excludeDocumentsURLFromiCloud() {
    var docsURL = URL.documentsDirectoryURL
    do {
      var resourceValues = URLResourceValues()
      resourceValues.isExcludedFromBackup = true
      try docsURL.setResourceValues(resourceValues)
    } catch {
      print("Error excluding \(docsURL) from backup \(error.localizedDescription)");
    }
  }

  static var allocatedSizeResourceKeys: [URLResourceKey] = [.isRegularFileKey,
                                                            .fileAllocatedSizeKey,
                                                            .totalFileAllocatedSizeKey]

  /// Returns the allocated file size of the file at the URL
  var fileAllocatedSize: UInt64? {
    let values = try? resourceValues(forKeys: Set(URL.allocatedSizeResourceKeys))
    guard let resourceValues = values, resourceValues.isRegularFile == true else {
      return 0
    }
    guard let size =
        resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize else {
      return nil
    }
    return UInt64(size)
  }

}
