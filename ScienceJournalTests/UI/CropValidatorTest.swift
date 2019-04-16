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

class CropValidatorTest: XCTestCase {

  func testIsRecordingRangeValidForCropping() {
    var cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 1000, max: 1900))
    XCTAssertFalse(cropValidator.isRecordingRangeValidForCropping)
    cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 1000, max: 2000))
    XCTAssertTrue(cropValidator.isRecordingRangeValidForCropping)
    cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 1000, max: 2001))
    XCTAssertTrue(cropValidator.isRecordingRangeValidForCropping)
    cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 1001, max: 2000))
    XCTAssertFalse(cropValidator.isRecordingRangeValidForCropping)
  }

  func testIsTimestampWithinRecordingRange() {
    let cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 1000, max: 5000))
    XCTAssertFalse(cropValidator.isTimestampWithinRecordingRange(500))
    XCTAssertFalse(cropValidator.isTimestampWithinRecordingRange(5500))
    XCTAssertTrue(cropValidator.isTimestampWithinRecordingRange(1000))
    XCTAssertTrue(cropValidator.isTimestampWithinRecordingRange(2000))
    XCTAssertTrue(cropValidator.isTimestampWithinRecordingRange(5000))
  }

  func testIsCropRangeValid() {
    let cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 1000, max: 5000))
    XCTAssertFalse(cropValidator.isCropRangeValid(ChartAxis(min: 999, max: 2000)))
    XCTAssertFalse(cropValidator.isCropRangeValid(ChartAxis(min: 2000, max: 5500)))
    XCTAssertFalse(cropValidator.isCropRangeValid(ChartAxis(min: 2000, max: 2500)))
    XCTAssertTrue(cropValidator.isCropRangeValid(ChartAxis(min: 1000, max: 5000)))
    XCTAssertTrue(cropValidator.isCropRangeValid(ChartAxis(min: 2000, max: 3000)))
  }

  func testStartCropTimestampClampedToValidRange() {
    let cropRange = ChartAxis<Int64>(min: 2500, max: 3700)
    let cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 2000, max: 4000))

    var timestamp = cropValidator.startCropTimestampClampedToValidRange(1000, cropRange: cropRange)
    XCTAssertEqual(2000, timestamp)

    timestamp = cropValidator.startCropTimestampClampedToValidRange(2000, cropRange: cropRange)
    XCTAssertEqual(2000, timestamp)

    timestamp = cropValidator.startCropTimestampClampedToValidRange(2100, cropRange: cropRange)
    XCTAssertEqual(2100, timestamp)

    timestamp = cropValidator.startCropTimestampClampedToValidRange(2500, cropRange: cropRange)
    XCTAssertEqual(2500, timestamp)

    timestamp = cropValidator.startCropTimestampClampedToValidRange(2600, cropRange: cropRange)
    XCTAssertEqual(2600, timestamp)

    timestamp = cropValidator.startCropTimestampClampedToValidRange(2800, cropRange: cropRange)
    XCTAssertEqual(2700,
                   timestamp,
                   "2700 is the max start time to preserve a one second minimum crop.")
  }

  func testEndCropTimestampClampedToValidRange() {
    let cropRange = ChartAxis<Int64>(min: 2500, max: 3700)
    let cropValidator = CropValidator(trialRecordingRange: ChartAxis(min: 2000, max: 4000))

    var timestamp = cropValidator.endCropTimestampClampedToValidRange(1000, cropRange: cropRange)
    XCTAssertEqual(3500, timestamp)

    timestamp = cropValidator.endCropTimestampClampedToValidRange(2000, cropRange: cropRange)
    XCTAssertEqual(3500, timestamp)

    timestamp = cropValidator.endCropTimestampClampedToValidRange(3500, cropRange: cropRange)
    XCTAssertEqual(3500, timestamp)

    timestamp = cropValidator.endCropTimestampClampedToValidRange(3700, cropRange: cropRange)
    XCTAssertEqual(3700, timestamp)

    timestamp = cropValidator.endCropTimestampClampedToValidRange(4000, cropRange: cropRange)
    XCTAssertEqual(4000, timestamp)

    timestamp = cropValidator.endCropTimestampClampedToValidRange(4500, cropRange: cropRange)
    XCTAssertEqual(4000, timestamp, "Crop end time cannot go beyond recording bounds.")
  }

}
