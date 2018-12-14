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

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

extension SensorDataManager  {

  /// Returns an instance of `SensorDataManager` with a store in a test location.
  public static var testStore: SensorDataManager {
    let documentsURL = URL.documentsDirectoryURL
    let directoryURL = documentsURL.appendingPathComponent("TEST")
    let storeURL = directoryURL.appendingPathComponent("store.sqlite")

    if !FileManager.default.fileExists(atPath: directoryURL.path) {
      do {
        try FileManager.default.createDirectory(at: directoryURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
      } catch {
        print("Cannot create test store directory: \(error)")
      }
    }
    return SensorDataManager(storeURL: storeURL)
  }

}
