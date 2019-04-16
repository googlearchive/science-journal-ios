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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// Tests AudioAnalyzer against many samples with known fundamental frequencies
class AudioAnalayzerTest: XCTestCase {

  var audioAnalyzer: AudioAnalyzer!

  override func setUp() {
    audioAnalyzer = AudioAnalyzer(sampleRateInHz: AudioSession.shared.sampleRate)
  }

  func testCokeBottleSamples() {
    checkSample("coke_bottle_325", expectedFrequency: 325)
  }

  func testGuitarA() {
    checkSample("guitar_A_110_000", expectedFrequency: 110)
  }

  func testGuitarB() {
    checkSample("guitar_B_246_942", expectedFrequency: 246.942)
  }

  func testGuitarD() {
    checkSample("guitar_D_146_832", expectedFrequency: 146.832)
  }

  func testGuitarEHigh() {
    checkSample("guitar_E_329_628", expectedFrequency: 329.628)
  }

  func testGuitarELow() {
    checkSample("guitar_E_82_4069", expectedFrequency: 82.4069)
  }

  func testGuitarG() {
    checkSample("guitar_G_195_998", expectedFrequency: 195.998)
  }

  func testMelodicaA3() {
    checkSample("melodica_a3_220_000", expectedFrequency: 220)
  }

  func testMelodicaA4() {
    checkSample("melodica_a4_440_000", expectedFrequency: 440)
  }

  func testMelodicaA5() {
    checkSample("melodica_a5_880_000", expectedFrequency: 880)
  }

  func testMelodicaB3() {
    checkSample("melodica_b3_246_942", expectedFrequency: 246.942)
  }

  func testMelodicaB4() {
    checkSample("melodica_b4_493_883", expectedFrequency: 493.883)
  }

  func testMelodicaB5() {
    checkSample("melodica_b5_987_767", expectedFrequency: 987.767)
  }

  func testMelodicaC4() {
    checkSample("melodica_c4_261_626", expectedFrequency: 261.626)
  }

  func testMelodicaC5() {
    checkSample("melodica_c5_523_251", expectedFrequency: 523.251)
  }

  func testMelodicaC6() {
    checkSample("melodica_c6_1046_50", expectedFrequency: 1046.50)
  }

  func testMelodicaD4() {
    checkSample("melodica_d4_293_665", expectedFrequency: 293.665)
  }

  func testMelodicaD5() {
    checkSample("melodica_d5_587_330", expectedFrequency: 587.330)
  }

  func testMelodicaE4() {
    checkSample("melodica_e4_329_628", expectedFrequency: 329.628)
  }

  func testMelodicaE5() {
    checkSample("melodica_e5_659_255", expectedFrequency: 659.255)
  }

  func testMelodicaF3() {
    checkSample("melodica_f3_174_614", expectedFrequency: 174.614)
  }

  func testMelodicaF4() {
    checkSample("melodica_f4_349_228", expectedFrequency: 349.228)
  }

  func testMelodicaF5() {
    checkSample("melodica_f5_698_456", expectedFrequency: 698.456)
  }

  func testMelodicaG3() {
    checkSample("melodica_g3_195_998", expectedFrequency: 195.998)
  }

  func testMelodicaG4() {
    checkSample("melodica_g4_391_995", expectedFrequency: 391.995)
  }

  func testMelodicaG5() {
    checkSample("melodica_g5_783_991", expectedFrequency: 783.991)
  }

  func testPintGlass() {
    checkSample("pint_glass_1797", expectedFrequency: 1797)
  }

  func testSynthClarinetB2() {
    checkSample("synth_clarinet_b2_123_471", expectedFrequency: 123.471)
  }

  func testSynthClarinetB3() {
    checkSample("synth_clarinet_b3_246_942", expectedFrequency: 246.942)
  }

  func testSynthClarinetB4() {
    checkSample("synth_clarinet_b4_493_883", expectedFrequency: 493.883)
  }

  func testSynthClarinetB5() {
    checkSample("synth_clarinet_b5_987_767", expectedFrequency: 987.767)
  }

  func testSynthGuitarB2() {
    checkSample("synth_guitar_b2_123_471", expectedFrequency: 123.471)
  }

  func testSynthGuitarB3() {
    checkSample("synth_guitar_b3_246_942", expectedFrequency: 246.942)
  }

  func testSynthGuitarB4() {
    checkSample("synth_guitar_b4_493_883", expectedFrequency: 493.883)
  }

  func testSynthPianoB2() {
    checkSample("synth_piano_b2_123_471", expectedFrequency: 123.461)
  }

  func testSynthPianoB3() {
    checkSample("synth_piano_b3_246_942", expectedFrequency: 246.942)
  }

  func testSynthPianoB4() {
    checkSample("synth_piano_b4_496_357", expectedFrequency: 496.357)
  }

  func testSynthPianoB5() {
    checkSample("synth_piano_b5_987_767", expectedFrequency: 987.767)
  }

  func testToneB3() {
    checkSample("tone_b3_246_942", expectedFrequency: 246.942)
  }

  func testToneB4() {
    checkSample("tone_b4_493_883", expectedFrequency: 493.883)
  }

  func testToneB5() {
    checkSample("tone_b5_987_767", expectedFrequency: 987.767)
  }

  func testXylophone1() {
    checkSample("xylophone_1081", expectedFrequency: 1081)
  }

  func testXylophone2() {
    checkSample("xylophone_1250", expectedFrequency: 1250)
  }

  func testXylophone3() {
    checkSample("xylophone_1295", expectedFrequency: 1295)
  }

  func testXylophone4() {
    checkSample("xylophone_1466", expectedFrequency: 1466)
  }

  func testXylophone5() {
    checkSample("xylophone_1594", expectedFrequency: 1594)
  }

  func testXylophone6() {
    checkSample("xylophone_1802", expectedFrequency: 1802)
  }

  func testXylophone7() {
    checkSample("xylophone_1950", expectedFrequency: 1950)
  }

  func testXylophone8() {
    checkSample("xylophone_979", expectedFrequency: 979)
  }

  private func checkSample(_ named: String, expectedFrequency: Double) {
    let samples = readSamples(named: named)
    if let frequency = audioAnalyzer.detectFundamentalFrequency(samples: samples) {
      assertFrequencyEquals(expected: expectedFrequency, actual: frequency)
    } else {
      XCTFail("No fundamental frequency from sample: \(named), expecting: \(expectedFrequency)")
    }
  }

  private func readSamples(named sampleFilename: String) -> [Int16] {
    let resourceRelativePath = URL(fileURLWithPath: "TestResources", isDirectory: true)
      .appendingPathComponent(sampleFilename)
      .relativePath
    let testBundle = Bundle(for: type(of: self))
    let path = testBundle.path(forResource:resourceRelativePath, ofType: "samples")!

    let data = try? String(contentsOfFile: path, encoding: .utf8)
    let samples = data!
      .components(separatedBy: .newlines)
      .compactMap(Int16.init)

    return samples
  }

  private func assertFrequencyEquals(expected: Double, actual: Double, accuracy: Double = 2.0) {
    XCTAssertEqual(expected, actual, accuracy: accuracy)
  }

}
