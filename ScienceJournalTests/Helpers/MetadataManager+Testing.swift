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

extension MetadataManager {
  /// Returns an instance of MetadataManager with a test directory root URL.
  public static var testingInstance: MetadataManager {
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    let rootURL = tempDirectory.appendingPathComponent("TESTING-" + UUID().uuidString)
    return MetadataManager(rootURL: rootURL,
                           deletedRootURL: rootURL,
                           preferenceManager: PreferenceManager(),
                           sensorController: MockSensorController(),
                           sensorDataManager: SensorDataManager.testStore)
  }

  func deleteRootDirectory() {
    do {
      try FileManager.default.removeItem(at: rootURL)
    } catch {
      print("[MetadataManager] Error deleting root directory: \(error)")
    }
  }
}
