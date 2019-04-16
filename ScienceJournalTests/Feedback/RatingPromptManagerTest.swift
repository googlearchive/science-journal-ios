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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class RatingPromptManagerTest: XCTestCase {

  func testRatingPromptShouldNotShowOnFreshInstall() {
    RatingsPromptManager.shared.resetAll()
    XCTAssertFalse(RatingsPromptManager.shared.promptForRatingIfNecessary(),
                   "Rating prompt should not have been requested for a user without actions " +
                       "tracked.")
  }

  func testSuccessfulRecordingCount() {
    if #available(iOS 10.3, *) {
      RatingsPromptManager.shared.resetAll()

      XCTAssertFalse(RatingsPromptManager.shared.promptForRatingIfNecessary(),
                     "User has not successfully ended the required number of recordings yet.")
      for _ in 0..<RatingsPromptManager.shared.minimumSuccessfulRecordings {
        RatingsPromptManager.shared.incrementSuccessfulRecordingCount()
      }
      XCTAssertTrue(RatingsPromptManager.shared.promptForRatingIfNecessary(),
                     "User has successfully ended the required number of recordings.")
    }
  }

}
