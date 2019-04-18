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

/// Formats a timestamp in milliseconds to a string representation:
///
/// 01:30    - one minute, thirty seconds
/// 9:00:45  - 9 hours, fourty-five seconds
/// -15:25   - negative fifteen minutes, twenty-five seconds
///
/// Only displays hours if the time is greater than or equal to one hour.
/// Toggle isToTenths to display tenths of a second.
class ElapsedTimeFormatter: Formatter {

  let millisInSecond: Int64 = 1000
  let minutesInHour: Int64 = 60
  let secondsInMinute: Int64 = 60
  let tenthsInSecond: Int64 = 10

  /// If true displays tenths of a second.
  var shouldDisplayTenths = false

  override func string(for obj: Any?) -> String? {
    guard let timestamp = obj as? Int64 else {
      return nil
    }

    return string(fromTimestamp: timestamp)
  }

  /// Returns a string representation of the given timestamp.
  ///
  /// - Parameter timestamp: A timestamp in milliseconds.
  /// - Returns: A string.
  func string(fromTimestamp timestamp: Int64) -> String {
    // Calculate the format independent of sign. A minus sign is prepended if necessary.
    let isNegative = timestamp < 0
    let absTimestamp = abs(timestamp)

    let secondsInHour = secondsInMinute * minutesInHour

    let hours = absTimestamp / millisInSecond / secondsInHour
    let secondsInTotalHours = hours * secondsInHour
    let minutes = (absTimestamp / millisInSecond - secondsInTotalHours) / secondsInMinute
    let seconds = absTimestamp / millisInSecond - secondsInTotalHours - minutes * secondsInMinute

    // This method of padding a leading zero is more performant than using
    // `String(format: "%02d", seconds)` and makes a difference when this is called rapidly (such as
    // when drawing TimeAxisView.
    var secondsFormatted = String(seconds)
    if seconds < 10 {
      secondsFormatted = "0" + secondsFormatted
    }

    var formatted: String
    if hours > 0 {
      var minutesFormatted = String(minutes)
      if minutes < 10 {
        minutesFormatted = "0" + minutesFormatted
      }
      formatted = "\(hours):\(minutesFormatted):\(secondsFormatted)"
    } else {
      formatted = "\(minutes):\(secondsFormatted)"
    }

    if shouldDisplayTenths {
      let tenths = absTimestamp * tenthsInSecond /
          millisInSecond - secondsInTotalHours *
          tenthsInSecond - minutes *
          secondsInMinute * tenthsInSecond -
          seconds * tenthsInSecond
      formatted += "." + String(tenths)
    }

    // Prepend a minus sign if the number is negative.
    return isNegative ? "-" + formatted : formatted
  }

}
