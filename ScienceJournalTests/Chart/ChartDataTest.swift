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

struct MockDisplayNote: DisplayTextNote {
  var ID: String = "TestID"
  var trialID: String?
  var timestamp: Timestamp
  var text: String = "Note text"
  var valueSnapshots: String?
  var noteType: DisplayNoteType { return .textNote(self) }
  var itemType: DisplayItemType { return .textNote(self) }

  init(timestamp: Int64) {
    self.timestamp = Timestamp(timestamp)
  }
}

class ChartDataTest: XCTestCase {

  var chartData: ChartData!

  override func setUp() {
    super.setUp()
    chartData = ChartData()
  }

  func testMinMaxY() {
    // No values.
    XCTAssertNil(chartData.minY)
    XCTAssertNil(chartData.maxY)

    // One Value.
    chartData = ChartData([DataPoint(x: 0, y: 5.0)])
    XCTAssertEqual(5.0, chartData.minY)
    XCTAssertEqual(5.0, chartData.maxY)

    // Multiple values.
    chartData = ChartData([DataPoint(x: 0, y: -10.0),
                           DataPoint(x: 1, y: 0.0),
                           DataPoint(x: 2, y: 12.0)])
    XCTAssertTrue(chartData.minY == -10.0)
    XCTAssertTrue(chartData.maxY == 12.0)

    // Changed values.
    chartData.addDataPoint(DataPoint(x: 3, y: 24))
    XCTAssertTrue(chartData.minY == -10.0)
    XCTAssertTrue(chartData.maxY == 24.0)
  }

  func testFirstLastX() {
    chartData.addDataPoint(DataPoint(x: 0, y: 10.0))
    chartData.addDataPoint(DataPoint(x: 10, y: 11.0))
    chartData.addDataPoint(DataPoint(x: 20, y: 12.0))
    chartData.addDataPoint(DataPoint(x: 30, y: 13.0))
    XCTAssertEqual(0, chartData.firstX)
    XCTAssertEqual(30, chartData.lastX)

    chartData.addDataPoint(DataPoint(x: 1, y: 14.0))

    XCTAssertEqual(0, chartData.firstX)
    XCTAssertEqual(1, chartData.lastX)
  }

  func testExactBinarySearchSizeOne() {
    populatePoints(count: 1)
    XCTAssertEqual(0, chartData.exactBinarySearch(forTimestamp: 0, startIndex: 0))
  }

  func testExactBinarySearchSizeFive() {
    populatePoints(count: 5)
    XCTAssertEqual(0, chartData.exactBinarySearch(forTimestamp: 0, startIndex: 0))
    XCTAssertEqual(4, chartData.exactBinarySearch(forTimestamp: 4, startIndex: 0))
  }

  func textExactBinarySearchPrefersStart() {
    for index: Int64 in stride(from: 0, to: 5, by: 1) {
      chartData.addDataPoint(DataPoint(x: index * 2, y: Double(index)))
    }
    XCTAssertEqual(2, chartData.exactBinarySearch(forTimestamp: 4, startIndex: 0))
    // Search for 5, "exact" search rounds down.
    XCTAssertEqual(2, chartData.exactBinarySearch(forTimestamp: 5, startIndex: 0))
  }

  func testBinarySearchLargerThanBinaryRange() {
    // Test a tolerance larger than half the data size.
    populatePoints(count: 5)
    XCTAssertEqual(0, chartData.binarySearch(forTimestamp: 1,
                                             startIndex: 0,
                                             endIndex: 4,
                                             preferStart: true,
                                             tolerance: 3))
    XCTAssertTrue(0...3 ~= chartData.binarySearch(forTimestamp: 3,
                                                  startIndex: 0,
                                                  endIndex: 4,
                                                  preferStart: true,
                                                  tolerance: 3))
    XCTAssertTrue(0...3 ~= chartData.binarySearch(forTimestamp: 1,
                                                  startIndex: 0,
                                                  endIndex: 4,
                                                  preferStart: true,
                                                  tolerance: 3))
    XCTAssertTrue(3...6 ~= chartData.binarySearch(forTimestamp: 3,
                                                  startIndex: 0,
                                                  endIndex: 4,
                                                  preferStart: false,
                                                  tolerance: 3))
  }

  func testBinarySearchToleranceLargerThanSize() {
    // This chartData has a larger tolerance than data size, so this is a test
    // of preferStart and ranges.
    populatePoints(count: 5)
    XCTAssertEqual(0, chartData.binarySearch(forTimestamp: 1,
                                             startIndex: 0,
                                             endIndex: 4,
                                             preferStart: true,
                                             tolerance: 10))
    XCTAssertEqual(4, chartData.binarySearch(forTimestamp: 1,
                                             startIndex: 0,
                                             endIndex: 4,
                                             preferStart: false,
                                             tolerance: 10))
  }

  func testBinarySearchTolerance() {
    populatePoints(count: 100)

    for timestamp: Int64 in stride(from: 5, to: 99, by: 10) {
      let result = chartData.binarySearch(forTimestamp: timestamp,
                                          startIndex: 0,
                                          endIndex: 99,
                                          preferStart: true,
                                          tolerance: 10)
      let rangeStart = Int(timestamp) - 10
      let rangeEnd = Int(timestamp)
      XCTAssertTrue(rangeStart...rangeEnd ~= result)
    }
  }

  func testAddNote() {
    // Add some data points.
    chartData.addDataPoint(DataPoint(x: 10000, y: 1))
    chartData.addDataPoint(DataPoint(x: 20000, y: 2))
    XCTAssertEqual(0, chartData.noteDataPoints.count)

    // Add a note beyond the current data's range.
    let displayNote = MockDisplayNote(timestamp: 21000)
    chartData.addNote(displayNote)
    XCTAssertEqual(0, chartData.noteDataPoints.count)

    // Add a new point after the note's timestamp.
    chartData.addDataPoint(DataPoint(x: 30000, y: 3))
    XCTAssertEqual(1, chartData.noteDataPoints.count)
    let point = chartData.noteDataPoints[0]
    XCTAssertEqual(21000, point.x)
    XCTAssertEqual(2.1, point.y, accuracy: 0.00001)

    // Add a note within the current data's range.
    let displayNote2 = MockDisplayNote(timestamp: 29000)
    chartData.addNote(displayNote2)
    XCTAssertEqual(2, chartData.noteDataPoints.count)
    let point2 = chartData.noteDataPoints[1]
    XCTAssertEqual(29000, point2.x)
    XCTAssertEqual(2.9, point2.y, accuracy: 0.00001)
  }

  func testAddNoteWithOneDataPointMatchingTimestamp() {
    chartData.addDataPoint(DataPoint(x: 10000, y: 1))
    XCTAssertEqual(0, chartData.noteDataPoints.count)

    let displayNote = MockDisplayNote(timestamp: 10000)
    chartData.addNote(displayNote)
    XCTAssertEqual(1, chartData.noteDataPoints.count)
    let point = chartData.noteDataPoints[0]
    XCTAssertEqual(10000, point.x)
    XCTAssertEqual(1, point.y)
  }

  func testAddNoteWithOneDataPointNotMatchingTimestamp() {
    chartData.addDataPoint(DataPoint(x: 10000, y: 1))
    XCTAssertEqual(0, chartData.noteDataPoints.count)

    let displayNote = MockDisplayNote(timestamp: 11000)
    chartData.addNote(displayNote)
    XCTAssertEqual(0, chartData.noteDataPoints.count)
  }

  func testRemoveNote() {
    // Add some data points.
    chartData.addDataPoint(DataPoint(x: 10000, y: 1))
    chartData.addDataPoint(DataPoint(x: 20000, y: 1))
    chartData.addDataPoint(DataPoint(x: 30000, y: 1))
    XCTAssertEqual(0, chartData.noteDataPoints.count)

    // Add a note within the current data's range.
    let displayNote = MockDisplayNote(timestamp: 21000)
    chartData.addNote(displayNote)
    XCTAssertEqual(1, chartData.noteDataPoints.count)

    // Remove a note for a timestamp that doesn't exist.
    let otherNote = MockDisplayNote(timestamp: 10000)
    chartData.removeNote(withID: otherNote.ID, atTimestamp: otherNote.timestamp.milliseconds)
    XCTAssertEqual(1, chartData.noteDataPoints.count)

    // Remove the note with the timestamp we added.
    chartData.removeNote(withID: displayNote.ID, atTimestamp: displayNote.timestamp.milliseconds)
    XCTAssertEqual(0, chartData.noteDataPoints.count)
  }

  func testRemoveAll() {
    for i: Int64 in 0...99 {
      chartData.addDataPoint(DataPoint(x: i, y: Double(i)))

      let note = DisplayTextNoteModel(ID: String(i),
                                      trialID: nil,
                                      text: "TEST NOTE",
                                      valueSnapshots: nil, timestamp: Timestamp(i))
      chartData.addNote(note)
    }

    XCTAssertEqual(100, chartData.dataPoints.count)
    XCTAssertEqual(100, chartData.noteDataPoints.count)

    chartData.removeAll()

    XCTAssertEqual(0, chartData.dataPoints.count)
    XCTAssertEqual(0, chartData.noteDataPoints.count)
  }

  func testRemoveAllDataPoints() {
    for i: Int64 in 0...99 {
      chartData.addDataPoint(DataPoint(x: i, y: Double(i)))

      let note = DisplayTextNoteModel(ID: String(i),
                                      trialID: nil,
                                      text: "TEST NOTE",
                                      valueSnapshots: nil, timestamp: Timestamp(i))
      chartData.addNote(note)
    }

    XCTAssertEqual(100, chartData.dataPoints.count)
    XCTAssertEqual(100, chartData.noteDataPoints.count)

    chartData.removeAllDataPoints()

    XCTAssertEqual(0, chartData.dataPoints.count)
    XCTAssertEqual(100, chartData.noteDataPoints.count)
  }

  func testRemoveAllNotes() {
    for i: Int64 in 0...99 {
      chartData.addDataPoint(DataPoint(x: i, y: Double(i)))

      let note = DisplayTextNoteModel(ID: String(i),
                                      trialID: nil,
                                      text: "TEST NOTE",
                                      valueSnapshots: nil, timestamp: Timestamp(i))
      chartData.addNote(note)
    }

    XCTAssertEqual(100, chartData.dataPoints.count)
    XCTAssertEqual(100, chartData.noteDataPoints.count)

    chartData.removeAllNotes()

    XCTAssertEqual(100, chartData.dataPoints.count)
    XCTAssertEqual(0, chartData.noteDataPoints.count)
  }

  func populatePoints(count: Int64) {
    for index: Int64 in 0...count {
      chartData.addDataPoint(DataPoint(x: index, y: Double(index) / 10.0))
    }
  }

  func testThrowAwayBefore() {
    // No threshold needed for small test data sets.
    chartData.throwAwayThreshold = 0

    // 0, 5, 10, 15, 20, 25, 30, 35
    for index in 0..<8 {
      chartData.addDataPoint(DataPoint(x: Int64(index * 5), y: Double(index * 5)))
    }
    chartData.throwAwayBefore(17)
    let closestToZero = chartData.closestDataPointToTimestamp(0)
    XCTAssertEqual(20, closestToZero!.x)
    XCTAssertEqual(4, chartData.dataPoints.count)

    // If there are no data points before the timestamp, nothing should be removed.
    chartData.throwAwayBefore(0)
    XCTAssertEqual(4, chartData.dataPoints.count)
  }

  func testThrowAwayAfter() {
    // No threshold needed for small test data sets.
    chartData.throwAwayThreshold = 0

    // 0, 5, 10, 15, 20, 25, 30, 35
    for index in 0..<8 {
      chartData.addDataPoint(DataPoint(x: Int64(index * 5), y: Double(index * 5)))
    }
    chartData.throwAwayAfter(17)
    let closestToZero = chartData.closestDataPointToTimestamp(35)
    XCTAssertEqual(15, closestToZero!.x)
    XCTAssertEqual(4, chartData.dataPoints.count)

    // Specifying a timestamp that exists should not remove it.
    chartData.throwAwayAfter(15)
    XCTAssertEqual(4, chartData.dataPoints.count)
  }

  func testThrowAwayBetween() {
    // No threshold needed for small test data sets.
    chartData.throwAwayThreshold = 0

    // 0, 5, 10, 15, 20, 25, 30, 35
    for index in 0..<8 {
      chartData.addDataPoint(DataPoint(x: Int64(index * 5), y: Double(index * 5)))
    }
    chartData.throwAwayBetween(7, and: 27)
    XCTAssertEqual(4, chartData.dataPoints.count)
    XCTAssertEqual(0, chartData.dataPoints[0].x)
    XCTAssertEqual(5, chartData.dataPoints[1].x)
    XCTAssertEqual(30, chartData.dataPoints[2].x)
    XCTAssertEqual(35, chartData.dataPoints[3].x)
  }

}
