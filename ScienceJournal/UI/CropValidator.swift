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

/// Responsible for validating and clamping trial crop ranges.
class CropValidator {

  // MARK: - Properties

  private static let minimumCropDuration: Int64 = 1000  // 1 second.
  private let trialRecordingRange: ChartAxis<Int64>

  /// True if the recording range is the minimum length for cropping, otherwise false.
  var isRecordingRangeValidForCropping: Bool {
    return isRangeAtLeastMinimumForCrop(trialRecordingRange)
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter trialRecordingRange: The trial recording range.
  init(trialRecordingRange: ChartAxis<Int64>) {
    self.trialRecordingRange = trialRecordingRange
  }

  /// True if the timestamp is within the recording range, otherwise false.
  ///
  /// - Parameter timestamp: A timestamp.
  /// - Returns: A Boolean indicating whether the timestamp is within the recording range.
  func isTimestampWithinRecordingRange(_ timestamp: Int64) -> Bool {
    return trialRecordingRange.contains(timestamp)
  }

  /// True if the crop range is valid, otherwise false.
  ///
  /// - Parameter cropRange: The crop range to test.
  /// - Returns: A Boolean indicating whether the crop range is valid.
  func isCropRangeValid(_ cropRange: ChartAxis<Int64>) -> Bool {
    guard trialRecordingRange.contains(cropRange.min) else {
      // Crop start is outside recording range.
      return false
    }

    guard trialRecordingRange.contains(cropRange.max) else {
      // Crop end is outside recording range.
      return false
    }

    // Crop must be at least the minimum crop duration.
    return isRangeAtLeastMinimumForCrop(cropRange)
  }

  /// Returns the input timestamp if it is within acceptable bounds for a crop start timetamp,
  /// otherwise clamps to the nearest boundary.
  ///
  /// - Parameters:
  ///   - timestamp: A crop start timestamp.
  ///   - cropRange: The current crop range.
  /// - Returns: A valid crop start timestamp.
  func startCropTimestampClampedToValidRange(_ timestamp: Int64,
                                             cropRange: ChartAxis<Int64>) -> Int64? {
    let maxTimestamp = cropRange.max - CropValidator.minimumCropDuration

    guard maxTimestamp >= trialRecordingRange.min else {
      // An invalid range will crash, so guard against it.
      return nil
    }

    return (trialRecordingRange.min...maxTimestamp).clamp(timestamp)
  }

  /// Returns the input timestamp if it is within acceptable bounds for a crop end timetamp,
  /// otherwise clamps to the nearest boundary.
  ///
  /// - Parameters:
  ///   - timestamp: A crop end timestamp.
  ///   - cropRange: The current crop range.
  /// - Returns: A valid crop end timestamp.
  func endCropTimestampClampedToValidRange(_ timestamp: Int64,
                                           cropRange: ChartAxis<Int64>) -> Int64? {
    let minTimestamp = cropRange.min + CropValidator.minimumCropDuration

    guard trialRecordingRange.max >= minTimestamp else {
      // An invalid range will crash, so guard against it.
      return nil
    }

    return (minTimestamp...trialRecordingRange.max).clamp(timestamp)
  }

  /// True if the range meets the minimum duration to perform a crop, otherwise false.
  ///
  /// - Parameter range: A time range.
  /// - Returns: A Boolean indicating whether the range is equal to or greater than the minimum
  ///            needed to crop.
  func isRangeAtLeastMinimumForCrop(_ range: ChartAxis<Int64>) -> Bool {
    return range.length >= CropValidator.minimumCropDuration
  }

}
