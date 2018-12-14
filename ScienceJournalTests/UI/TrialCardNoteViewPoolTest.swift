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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class TrialCardNoteViewPoolTest: XCTestCase {

  func testViewForType() {
    let trialCardNoteViewPool = TrialCardNoteViewPool()

    XCTAssertNil(trialCardNoteViewPool.view(forClass: TextNoteCardView.self),
                 "The trial card note view pool should not have any text note card views.")
    XCTAssertNil(trialCardNoteViewPool.view(forClass: TriggerCardView.self),
                 "The trial card note view pool should not have any trigger card views.")

    // Store two views each, for snapshot and trigger types.
    let textNote = DisplayTextNoteModel(ID: "",
                                        trialID: nil,
                                        text: "",
                                        valueSnapshots: nil,
                                        timestamp: Timestamp(1))
    let view1 = TextNoteCardView(textNote: textNote, preferredMaxLayoutWidth: 2)
    let view2 = TextNoteCardView(textNote: textNote, preferredMaxLayoutWidth: 3)
    trialCardNoteViewPool.storeViews([view1, view2])
    let view3 = TriggerCardView(preferredMaxLayoutWidth: 4)
    let view4 = TriggerCardView(preferredMaxLayoutWidth: 5)
    trialCardNoteViewPool.storeViews([view3, view4])

    let view1FromPool = trialCardNoteViewPool.view(forClass: TextNoteCardView.self)
    XCTAssertEqual(view1,
                   view1FromPool,
                   "The first text note card view returned by the trial card note view pool " +
                       "should be the one that was stored first.")
    let view2FromPool = trialCardNoteViewPool.view(forClass: TextNoteCardView.self)
    XCTAssertEqual(view2,
                   view2FromPool,
                   "The second text note card view returned by the trial card note view pool " +
                       "should be the one that was stored second.")
    XCTAssertNil(trialCardNoteViewPool.view(forClass: TextNoteCardView.self),
                 "The trial card note view pool should not have any more text note card views.")

    let view3FromPool = trialCardNoteViewPool.view(forClass: TriggerCardView.self)
    XCTAssertEqual(view3,
                   view3FromPool,
                   "The first trigger card view returned by the trial card note view pool should " +
                       "be the one that was stored first.")
    let view4FromPool = trialCardNoteViewPool.view(forClass: TriggerCardView.self)
    XCTAssertEqual(view4,
                   view4FromPool,
                   "The second trigger card view returned by the trial card note view pool " +
                       "should be the one that was stored second.")
    XCTAssertNil(trialCardNoteViewPool.view(forClass: TriggerCardView.self),
                 "The trial card note view pool should not have any more trigger card views.")
  }

  func testMaximumCount() {
    let trialCardNoteViewPool = TrialCardNoteViewPool()

    XCTAssertNil(trialCardNoteViewPool.view(forClass: SnapshotCardView.self),
                 "The trial card note view pool should not have any snapshot card views.")

    // Store more snapshot card views than the maximum count in the trial card note view pool.
    var snapshotCardViews = [SnapshotCardView]()
    for _ in 0...110 {
      snapshotCardViews.append(SnapshotCardView(preferredMaxLayoutWidth: 6))
    }
    trialCardNoteViewPool.storeViews(snapshotCardViews)

    // Get 100 snapshot card views out of the trial card note view pool.
    for count in 0...99 {
      XCTAssertNotNil(trialCardNoteViewPool.view(forClass: SnapshotCardView.self),
                      "There should be \(count) snapshot card views in the trial card note view " +
                          "pool.")
    }

    // Try to get one more snapshot card view out of the trial card note view pool.
    XCTAssertNil(trialCardNoteViewPool.view(forClass: SnapshotCardView.self),
                 "There should not be a snapshot card view in the trial card note view pool.")

    XCTAssertNil(trialCardNoteViewPool.view(forClass: PictureCardView.self),
                 "The trial card note view pool should not have any picture card views.")

    // Store more snapshot card views than the maximum count in the trial card note view pool.
    var pictureCardViews = [PictureCardView]()
    for _ in 0...11 {
      pictureCardViews.append(PictureCardView(style: .small))
    }
    trialCardNoteViewPool.storeViews(pictureCardViews)

    // Get 10 picture card views out of the trial card note view pool.
    for count in 0...9 {
      XCTAssertNotNil(trialCardNoteViewPool.view(forClass: PictureCardView.self),
                      "There should be \(count) picture card views in the trial card note view " +
                          "pool.")
    }

    // Try to get one more picture card view out of the trial card note view pool.
    XCTAssertNil(trialCardNoteViewPool.view(forClass: PictureCardView.self),
                 "There should not be a picture card view in the trial card note view pool.")
  }

  func testReset() {
    let trialCardNoteViewPool = TrialCardNoteViewPool()
    let mockExperimentCardView = MockExperimentCardView()
    trialCardNoteViewPool.storeViews([mockExperimentCardView])
    XCTAssertTrue(mockExperimentCardView.isResetCalled,
                  "Reset should be called on experiment card views when storing them to the " +
                      "trial card note view pool.")
  }

  func testMemoryWarning() {
    let trialCardNoteViewPool = TrialCardNoteViewPool()
    trialCardNoteViewPool.storeViews([ExperimentCardCaptionView(),
                                      SeparatorView(direction: .horizontal, style: .light)])
    NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification,
                                    object: nil)
    XCTAssertNil(trialCardNoteViewPool.view(forClass: ExperimentCardCaptionView.self),
                 "There should be no views stored after a memory warning.")
    XCTAssertNil(trialCardNoteViewPool.view(forClass: SeparatorView.self),
                 "There should be no views stored after a memory warning.")
  }

  // MARK: - Nested Types

  class MockExperimentCardView: ExperimentCardView {
    var isResetCalled = false

    override func reset() {
      isResetCalled = true
    }
  }

}

