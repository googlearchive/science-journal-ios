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

class String_ScienceJournalTest: XCTestCase {

  func testLocalizedUntitledTrialString() {
    let index: Int32 = 5
    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
      XCTAssertEqual(String.localizedUntitledTrial(withIndex: index), "5 \(String.runDefaultTitle)")
    } else {
      XCTAssertEqual(String.localizedUntitledTrial(withIndex: index), "\(String.runDefaultTitle) 5")
    }
  }

  func testTruncatedWithHex() {
    let string = "AVeryLongStringWhichWillBeTruncatedByAddingHashOfOverflowCharacters"
    let truncated = string.truncatedWithHex(maxLength: 23)
    XCTAssertTrue(truncated.count <= 23)
    XCTAssertTrue(truncated.starts(with: "AVeryLongString"),
                  "The input string should be the same up to the start of the hash.")

    let string2 = "AnotherString"
    XCTAssertEqual(string2,
                   string2.truncatedWithHex(maxLength: 13),
                   "No truncation if the input string is less than or equal to maxLength.")

    let string3 = "Short"
    XCTAssertEqual("Sho",
                   string3.truncatedWithHex(maxLength: 3),
                   "No hash is added if max Length is less than typical hex length")
  }

  func testSanitizedForFilename() {
    let allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZ - abcdefghijklmnopqrstuvwxyz - 0123456789"
    XCTAssertEqual(allowed, allowed.sanitizedForFilename)

    // Some glyphs like the heart are composed of two unicode characters which are replaced with two
    // underscores. Without a more complicated implementation this is unavoidable.
    let emoji = "E🤓M😫O🤯J💡I🔧S❤️"
    XCTAssertEqual("E_M_O_J_I_S__", emoji.sanitizedForFilename)

    let specials = "eéuüaåiîEÉUÜAÅIÎ"
    XCTAssertEqual("e_u_a_i_E_U_A_I_", specials.sanitizedForFilename)
  }

  func testValidFilename() {
    // String with 252 characters which should be the max allowed after adding the extension.
    let string = "3456789012345678901234567890123456789012345678901234567890123456789012345678901" +
        "23456789012345678ssafasdfasfasdfsfasfasfdsfasfasfasfsadfsdfasfsadfdsfsdafasdfsdafsadfads" +
        "fasdfsdafsadfdsafsdafdsfasdfasdfasdfasdfasdfasfasdffsadfasfasdfasfasfdsafsadfasdfa252"
    let ext = "sj"
    var filename = string.validFilename(withExtension: "sj")
    let unprocessedName = string + "." + ext
    XCTAssertEqual(unprocessedName.utf16.count, filename.utf16.count)
    XCTAssertTrue(filename.utf16.count <= 255)

    let longString = "012345678901234567890123456789012345678901234567890123456789012345678901234" +
        "567890123456789012345678ssafasdfasfasdfsfasfasfdsfasfasfasfsadfsdfasfsadfdsfsdafasdfsdaf" +
        "sadfadsfasdfsdafsadfdsafsdafdsfasdfasdfasdfasdfasdfasfasdffsadfasfasdfasfasfdsafsadfasdf" +
        "abvs012345678901234567890123456789012345678901234567890123456789012345678901234567890123" +
        "456789012345678ssafasdfasfasdfsfasfasfdsfasfasfasfsadfsdfasfsadfdsfsdafasdfsdafsadfadsfa" +
        "sdfsdafsadfdsafsdafdsfasdfasdfasdfasdfasdfasfasdffsadfasfasdfasfasfdsafsadfasdfabvs"
    filename = longString.validFilename(withExtension: "sj")
    XCTAssertTrue(filename.utf16.count <= 255)

    let specialCharName = "My Fun Expériment Å - 🙀🖖👀😎"
    let sanitizedName = specialCharName.sanitizedForFilename
    print("sanitizedName: '\(sanitizedName)'")
    filename = specialCharName.validFilename(withExtension: "sj")
    print("filename: '\(filename)'")
    XCTAssertEqual("My Fun Exp_riment _ - ____.sj", filename)
    XCTAssertTrue(filename.utf16.count <= 255)
  }

}

