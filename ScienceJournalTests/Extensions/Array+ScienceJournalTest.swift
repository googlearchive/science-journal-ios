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

class Array_ScienceJournalTest: XCTestCase {

  func testChunkedArray() {
    let testArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    let chunks = testArray.chunks(ofSize: 3)

    XCTAssertEqual(4, chunks.count)
    XCTAssertEqual(3, chunks[0].count)
    XCTAssertEqual(3, chunks[1].count)
    XCTAssertEqual(3, chunks[2].count)
    XCTAssertEqual(2, chunks[3].count, "The last chunk only has the remainder.")

    let largeChunks = testArray.chunks(ofSize: 12)
    XCTAssertEqual(1,
                   largeChunks.count,
                   "If the chunk size is larger than the count, there is only one chunk")
    XCTAssertEqual(11, largeChunks[0].count)
  }

  func testChunkedEmpty() {
    let testArray = [Int]()
    let chunks = testArray.chunks(ofSize: 3)
    XCTAssertEqual(0, chunks.count)
  }

  func testChunkedZeroSize() {
    let testArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    let chunks = testArray.chunks(ofSize: 0)
    XCTAssertEqual(0, chunks.count)
  }

}
