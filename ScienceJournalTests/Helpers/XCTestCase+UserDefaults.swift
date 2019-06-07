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

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

extension XCTestCase {
  // Create a `UserDefaults` instance in a test domain.
  //
  // There's not a good way to clean up after these because `UserDefaults` writes to a temporary
  // file first and copies that file over the old file to ensure it's an atomic operation.
  // Even when calling `synchronize`, this write may not have completed yet when a test finishes,
  // which would result in the original file being removed and then replaced with the copy.
  // We could possibly poll and wait, but that would be more complicated and slow down our tests.
  // Instead we generate a filename based on the name of the test file, which gives us some
  // amount of test isolation without having to worry about tons of test files building up.
  func createTestDefaults(file: String = #file) -> UserDefaults {
    let suiteName = String((file.split(separator: "/").last?.split(separator: ".").first)!)
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }
}

