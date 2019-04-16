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

extension Date {

  /// Whether a birthdate is for an age that is 13 or older.
  var isBirthdateAge13OrOlder: Bool {
    let calendar = Calendar(identifier: .gregorian)
    let sinceComponents = calendar.dateComponents([.year], from: self, to: Date())
    guard let yearsBetweenDates = sinceComponents.year else { return false }
    return yearsBetweenDates >= 13
  }

  /// Returns an Int64 of the time interval since 1970 in milliseconds.
  var millisecondsSince1970: Int64 {
    return Int64(self.timeIntervalSince1970 * 1000)
  }

  /// Initializer that extends Date to work with milliseconds.
  init(milliseconds: Int64) {
    let timeInterval = Double(milliseconds) / 1000.0
    self.init(timeIntervalSince1970: timeInterval)
  }

}
