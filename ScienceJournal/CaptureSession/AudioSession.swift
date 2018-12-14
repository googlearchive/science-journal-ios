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

import AVFoundation

/// Manages the audio session for Science Journal.
class AudioSession {

  /// Types of audio session use.
  ///
  /// - playback: Audio session is being used for playback.
  /// - recording: Audio session is being used for recording.
  enum UseType {
    case playback
    case recording
  }

  // MARK: - Properties

  /// The audio session singleton.
  static let shared = AudioSession()

  /// The sample rate of the audio session, in hertz.
  var sampleRate: Double {
    return underlyingAudioSession.sampleRate
  }

  /// The underlying audio session that this class is wrapping.
  private let underlyingAudioSession = AVAudioSession.sharedInstance()

  /// The number of objects using the audio session.
  private var numberOfObjectsUsingAudioSession = 0

  // MARK: - Public

  // Use `shared`.
  private init() {
    // Set the category and options.
    var options: AVAudioSession.CategoryOptions {
      return [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP]
    }

    do {
      try underlyingAudioSession.setCategory(.playAndRecord,
                                             mode: .measurement,
                                             options: options)
    } catch {
      print("[AudioSession] Error when setting category: \(error.localizedDescription)")
    }
  }

  /// Starts the audio session for use.
  func startUsing() {
    numberOfObjectsUsingAudioSession += 1

    if numberOfObjectsUsingAudioSession == 1 {
      do {
        try underlyingAudioSession.setActive(true)
      } catch {
        print("[AudioSession] Error when setting active: \(error.localizedDescription)")
      }
    }
  }

  /// Ends using the audio session.
  func endUsing() {
    numberOfObjectsUsingAudioSession -= 1

    if numberOfObjectsUsingAudioSession == 0 {
      do {
        try underlyingAudioSession.setActive(false)
      } catch {
        print("[AudioSession] Error when setting not active.: \(error.localizedDescription)")
      }
    }
  }

}
