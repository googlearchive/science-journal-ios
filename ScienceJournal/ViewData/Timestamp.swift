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

import Foundation

/// An object for displaying timestamps. Initializing with only `milliseconds` will result in a
/// non-relative timestamp (example: "May 16, 2017, 4:58 PM". Initializing with `milliseconds` and
/// `relativeMilliseconds` will result in a relative timestamp (example: "12:00").
class Timestamp {

  /// The timestamp milliseconds.
  let milliseconds: Int64

  /// The relative milliseconds, if this should be displayed in relatively.
  private var relativeMilliseconds: Int64?

  /// An elapsed time formatter.
  private static let elapsedTimeFormatter = ElapsedTimeFormatter()

  /// Is this a relative timestamp?
  var isRelative: Bool {
    return relativeMilliseconds != nil
  }

  /// A date formatter.
  static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    return dateFormatter
  }()

  /// A string version of the timestamp to be used for display.
  var string: String {
    if let relativeMilliseconds = relativeMilliseconds {
      return Timestamp.elapsedTimeFormatter.string(
        fromTimestamp: milliseconds - relativeMilliseconds)
    } else {
      return Timestamp.dateFormatter.string(from: Date(milliseconds: milliseconds))
    }
  }

  /// Designated initalizer.
  ///
  /// - Parameters:
  ///   - milliseconds: The timestamp milliseconds.
  ///   - relativeMilliseconds: The relative milliseconds or nil.
  init(_ milliseconds: Int64, relativeTo relativeMilliseconds: Int64? = nil) {
    self.milliseconds = milliseconds
    self.relativeMilliseconds = relativeMilliseconds
  }

}
