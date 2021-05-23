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

extension TimeInterval {

  /// A date components formatter.
  static let intervalFormatter: DateComponentsFormatter = {
    return DateComponentsFormatter.intervalFormatter(withUnitsStyle: .abbreviated)
  }()

  /// A date components formatter for accessibility without abbreviated units.
  static let accessibleIntervalFormatter: DateComponentsFormatter = {
    return DateComponentsFormatter.intervalFormatter(withUnitsStyle: .spellOut)
  }()

  /// A duration value to use in animations that inherit their duration.
  static let inherited: TimeInterval = 0

  /// Returns the time interval as a string in component format with hours, minutes and seconds.
  /// Example: "1h 46m 11s"
  var durationString: String {
    return TimeInterval.intervalFormatter.string(from: self) ?? ""
  }

  /// Returns the time interval as an accessible string in component format with hours, minutes and
  /// seconds without abbreviation.  When there are fractional seconds present on the time interval,
  /// this will include them as milliseconds.
  /// Example: "One hour 46 minutes 11 seconds" and "One second 250 milliseconds".
  var accessibleDurationString: String {
    return TimeInterval.accessibleIntervalFormatter.string(from: self, appending: fractional)
  }

  /// The fractional seconds available on the time interval.
  /// Example: 250 when the time interval equals 1.250, and 0 when the time interval equals 3.0.
  private var fractional: Int64 {
    let remainder = truncatingRemainder(dividingBy: 1)
    guard remainder > 0.0 else { return 0 }
    return Int64(remainder * 1000)
  }

}
