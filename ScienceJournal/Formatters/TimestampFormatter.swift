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

import UIKit

/// A formatter for converting a timestamp in milliseconds to and from a string.
class TimestampFormatter: Formatter {

  /// Returns a string representation of the given timestamp.
  ///
  /// - Parameter timestamp: A timestamp in milliseconds.
  /// - Returns: A string, if the timestamp was valid.
  func string(fromTimestamp timestamp: Int64) -> String? {
    guard timestamp >= 0 else {
      return nil
    }

    let hours = timestamp/1000/60/60
    let minutes = timestamp/1000/60 % 60
    let seconds = timestamp/1000 % 60
    let milliseconds = timestamp % 1000

    return String(format:"%d:%02d:%02d.%03ld", hours, minutes, seconds, milliseconds)
  }

  /// Returns a timestamp in milliseconds from the given timestamp string.
  ///
  /// - Parameter timestampString: A string in the format h:mm:ss.SSS
  /// - Returns: A timestamp, if the string was valid.
  func timestamp(fromString timestampString: String) -> Int64? {
    let regex: NSRegularExpression
    do {
      let pattern = "^([0-9]{1,2}):([0-9]{2}):([0-9]{2}(\\.[0-9]{1,3})?)$"
      regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    } catch {
      print("[CropRangeViewController] Error creating regular expression: \(error)")
      return nil
    }

    let firstMatch = regex.firstMatch(in: timestampString,
                                      options: [],
                                      range: NSRange(location: 0, length: timestampString.count))
    guard let match = firstMatch else {
      // Timestamp format is incorrect.
      return nil
    }

    guard let hourRange = Range(match.range(at: 1), in: timestampString),
        let minuteRange = Range(match.range(at: 2), in: timestampString),
        let secondRange = Range(match.range(at: 3), in: timestampString) else {
      // Timestamp format is incorrect.
      return nil
    }

    let hourString = String(timestampString[hourRange])
    let minuteString = String(timestampString[minuteRange])
    let secondString = String(timestampString[secondRange])

    guard let hours = Int64(hourString), let minutes = Int64(minuteString),
        let seconds = Double(secondString) else {
      // At least one number isn't a valid Int64/Double (probably because it is too large).
      return nil
    }

    let millisecondsInAnHour: Int64 = 1000 * 60 * 60
    let millisecondsInAMinute: Int64 = 1000 * 60
    return hours * millisecondsInAnHour + minutes * millisecondsInAMinute +
        Int64(seconds * 1000.0)
  }

  // MARK: - Formatter

  override func string(for obj: Any?) -> String? {
    if let timestamp = obj as? Int64 {
      return string(fromTimestamp: timestamp)
    }
    return nil
  }

  // swiftlint:disable vertical_parameter_alignment
  override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
      for string: String,
      errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    if let timestamp = timestamp(fromString: string) {
      obj?.pointee = timestamp as AnyObject
      return true
    }
    return false
  }
  // swiftlint:enable vertical_parameter_alignment

}
