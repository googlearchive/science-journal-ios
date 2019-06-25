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
import UIKit

/// Extensions on String for Science Journal.
extension String {

  /// Returns the height a UILabel would occupy given a constrainedWidth and font.
  ///
  /// - Parameters:
  ///   - width: Maximum width for the label to aid in vertical measurement. Can be 0.
  ///   - font: UIFont to use for the label.
  /// - Returns: Calculated height a UILabel would be.
  func labelHeight(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
    let boundingBox = self.boundingRect(with: constraintRect,
                                        options: .usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: font],
                                        context: nil)
    return boundingBox.height
  }

  /// Returns the width a UILabel would occupy with the given font.
  ///
  /// - Parameters:
  ///   - font: UIFont to use for the label.
  /// - Returns: Calculated width a UILabel would be.
  func labelWidth(font: UIFont) -> CGFloat {
    let boundingBox = self.boundingRect(with: .zero,
                                        options: .usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: font],
                                        context: nil)
    return boundingBox.width
  }

  /// Returns the size a UILabel would occupy with the given font.
  ///
  /// - Parameters:
  ///   - font: UIFont to use for the label.
  /// - Returns: Calculated size a UILabel would be.
  func labelSize(font: UIFont) -> CGSize {
    let boundingBox = self.boundingRect(with: .zero,
                                        options: .usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: font],
                                        context: nil)
    return boundingBox.size
  }

  /// Returns the localized string matching with a key matching `self`. See ScienceJournalStrings
  /// for actual string lookup. If a string is not found in a non-English language, the English
  /// string will be returned instead.
  var localized: String {
    guard let bundle = Bundle.stringsBundle else {
      print("[Localization] Error opening strings bundle.")
      // Couldn't find the strings bundle, return the string key. This is not a good option for the
      // UI of the app, but if we hit this, there's a serious configuration problem.
      return self
    }

    // Get the current preferred language or set it to English as a fallback if we can't find one.
    let preferredLanguage = NSLocale.preferredLanguages.first ?? "en_US"
    // Get the lanuage code from the preferred language.
    let languageComponents = NSLocale.components(fromLocaleIdentifier: preferredLanguage)
    let languageCode = languageComponents[NSLocale.Key.languageCode.rawValue]

    if let languagePath = bundle.path(forResource: languageCode, ofType: "lproj"),
        let langBundle = Bundle(path: languagePath) {
      // We found the preferred language.
      return langBundle.localizedString(forKey: self, value: "", table: nil)
    } else if let languagePath = bundle.path(forResource: "en", ofType: "lproj"),
        let langBundle = Bundle(path: languagePath) {
      // We found English as a backup.
      return langBundle.localizedString(forKey: self, value: "", table: nil)
    } else {
      // We found nothing, unfortunately all we can do here is return.
      return self
    }
  }

  /// Returns the localized default untitled experiment name.
  static var localizedUntitledExperiment: String {
    return String.defaultExperimentName
  }

  /// A localized default untitled recording name, taking into account the recording's index.
  ///
  /// - Parameter index: The index of this recording.
  /// - Returns: The resulting string title.
  static func localizedUntitledTrial(withIndex index: Int32) -> String {
    return "\(String.runDefaultTitle) \(index)"
  }

  /// Returns a whitespace-trimmed version of the string, or nil if the trimmed string is empty.
  ///
  /// - Returns: A trimmed version or nil if empty.
  public var trimmedOrNil: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed != "" else { return nil }
    return trimmed
  }

  /// Truncates a string to a maximum length. If the string exceeds the max length a hash of the
  /// remaining string is appended to the end. Note: This method assumes all characters in the
  /// string are ASCII or UTF8 compatible. Characters that use more than 8 bytes will yield
  /// inaccurate truncation.
  ///
  /// - Parameter maxLength: The maximum string length.
  /// - Returns: The truncated string.
  func truncatedWithHex(maxLength: Int) -> String {
    guard count > maxLength else {
      return self
    }

    let maxHexLength = 8

    if maxLength <= maxHexLength {
      return String(self[..<index(startIndex, offsetBy: maxLength)])
    }

    let cutoff = maxLength - maxHexLength
    let prefix = String(self[..<index(startIndex, offsetBy: cutoff)])
    let suffix = dropFirst(count - cutoff)
    let suffixHex = String(format: "%2x", suffix.hashValue)

    return String(prefix + suffixHex)
  }

  /// Returns the string sanitized for use as a filename. Invalid characters are replaced with `_`.
  /// This method is not smart about multi-character glyphs, so they will be replaced by multiple
  /// underscore characters.
  var sanitizedForFilename: String {
    do {
      let regex = try NSRegularExpression(pattern: "[^ a-zA-Z0-9-_\\.]", options: [])
      let range = NSRange(location: 0, length: utf16.count)
      return regex.stringByReplacingMatches(in: self,
                                            options: [],
                                            range: range,
                                            withTemplate: "_")
    } catch {
      print("[TrialDetailViewController] Error creating regular expression: \(error)")
    }
    return self
  }

  /// Returns a string that is a valid filename. Most non-alphanumeric characters are stripped and
  /// the length is truncated to support the max filename length the system supports.
  ///
  /// - Parameter fileExtension: The file extension.
  /// - Returns: A valid filename.
  func validFilename(withExtension fileExtension: String) -> String {
    // syslimits.h defines the NAME_MAX as 255. We will hard code the value here instead of relying
    // on the define to protect against a future increase causing files incompatible with older
    // OSes. Also 255 is the known Android limit as well.
    let systemMax = 255

    let dotExtension = "." + fileExtension
    let maxLength = systemMax - (dotExtension.count)
    let truncatedString = sanitizedForFilename.truncatedWithHex(maxLength: maxLength)
    return truncatedString + dotExtension
  }

}
