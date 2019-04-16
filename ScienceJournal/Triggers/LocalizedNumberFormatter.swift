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

/// Formats numbers to numbers in the given locale.
class LocalizedNumberFormatter: NumberFormatter {

  override convenience init() {
    self.init(locale: .current)
  }

  /// Designated initializer.
  ///
  /// - Parameter locale: The locale number strings will be formatted for.
  init(locale: Locale) {
    super.init()
    self.locale = locale
    numberStyle = .decimal
    usesGroupingSeparator = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  /// Returns a localized string of the given double.
  ///
  /// - Parameter double: A double.
  /// - Returns: The localized string.
  func string(fromDouble double: Double) -> String? {
    return string(from: NSNumber(value: double))
  }

  /// Returns a double for a number string in any locale.
  ///
  /// - Parameter string: A number string.
  /// - Returns: A double.
  func double(fromString string: String) -> Double? {
    return number(from: string) as? Double
  }

}
