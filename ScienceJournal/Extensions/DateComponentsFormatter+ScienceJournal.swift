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

extension DateComponentsFormatter {

  /// Returns a date formatter with a specific units style.
  static func intervalFormatter(withUnitsStyle
      unitsStyle: DateComponentsFormatter.UnitsStyle) -> DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = unitsStyle
    return formatter
  }

  /// Returns an accessible string based on the given time interval, appending any available
  /// fractional seconds as milliseconds using a NSCalendar.Unit.spellOut unitsStyle.
  ///
  /// - Parameters:
  ///   - ti: The time interval, measured in seconds. The value must be a finite number.
  ///     Negative numbers are treated as positive numbers when creating the string.
  ///   - fractional: The fractional seconds available on the time interval.
  ///     If this equals 0, milliseconds will not be appended to the string.
  /// - Returns: A formatted string representing the specified time interval.
  func string(from ti: TimeInterval, appending fractional: Int64) -> String {
    guard let duration = TimeInterval.accessibleIntervalFormatter.string(from: ti) else {
        return ""
    }
    if fractional > 0 {
        return duration + " \(fractional) " + String.timeIntervalMilliseconds
    }
    return duration
  }

}
