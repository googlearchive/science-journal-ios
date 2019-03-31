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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class LocalizedNumberFormatterTest: XCTestCase {

  func testStringFromDouble() {
    let arabicEasternNumberFormatter =
        LocalizedNumberFormatter(locale: Locale(identifier: "ar_IQ"))
    XCTAssertEqual("٣٤٨٦٩١٢٨٨٫١",
                   arabicEasternNumberFormatter.string(fromDouble: 348691288.1))
  }

  func testDoubleFromString() {
    let englishNumberFormatter = LocalizedNumberFormatter(locale: LocaleUtils.enLocale)
    XCTAssertEqual(3486912881, englishNumberFormatter.double(fromString: "٣٤٨٦٩١٢٨٨١"))
  }

  func testNonNumberStringFromDouble() {
    let englishNumberFormatter = LocalizedNumberFormatter(locale: LocaleUtils.enLocale)
    XCTAssertNil(englishNumberFormatter.double(fromString: "cat"))
    XCTAssertNil(englishNumberFormatter.double(fromString: "one"))
  }

  func testDecimalPointStringFromDouble() {
    let englishNumberFormatter = LocalizedNumberFormatter(locale: LocaleUtils.enLocale)
    XCTAssertEqual("12.34",
                   englishNumberFormatter.string(fromDouble: 12.34))
  }

  func testStringFromEnglishDouble() {
    let englishNumberFormatter = LocalizedNumberFormatter(locale: LocaleUtils.enLocale)
    XCTAssertEqual("567",
                   englishNumberFormatter.string(fromDouble: 567))
  }

}
