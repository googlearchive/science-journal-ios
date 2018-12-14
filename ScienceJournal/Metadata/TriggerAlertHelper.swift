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

import AudioToolbox
import AVFoundation
import Foundation

/// Plays trigger sounds and vibration with logic to prevent either from playing too frequently.
class TriggerAlertHelper {

  /// The last time a sound was played.
  var lastSoundTime: Int64?

  /// The last time a vibration was played.
  var lastVibrateTime: Int64?

  /// The amount of time that must pass to allow the sound to be played again (ms).
  let lastAlertLimit: Int64 = 200

  /// Returns an `AVAudioPlayer` set up to play the trigger alert sound.
  lazy var alertAudioPlayer: AVAudioPlayer? = {
    guard let url = Bundle.currentBundle.url(forResource: "trigger_sound1",
                                             withExtension: "mp3") else {
        print("TriggerAlertHelper::trigger_sound1.mp3 not found in bundle.")
        return nil
    }

    do {
      let audioPlayer = try AVAudioPlayer(contentsOf: url)
      audioPlayer.prepareToPlay()
      return audioPlayer
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }()

  init() {
    AudioSession.shared.startUsing()
  }

  deinit {
    alertAudioPlayer?.stop()
    AudioSession.shared.endUsing()
  }

  /// Plays the trigger alert sound if enough time has passed since last playing it.
  func playTriggerAlertSound() {
    guard shouldAlert(for: lastSoundTime) else {
      return
    }
    alertAudioPlayer?.play()
    lastSoundTime = Date().millisecondsSince1970
  }

  /// Plays the trigger alert vibration if enough time has passed since last vibrating.
  func playTriggerAlertVibration() {
    guard shouldAlert(for: lastVibrateTime) else { return }
    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate), nil)
    lastVibrateTime = Date().millisecondsSince1970
  }

  /// Whether or not enough time has passed to alert again.
  ///
  /// - Parameter lastAlertTime: The last time the alert occured.
  /// - Returns: `true` if an alert can play again, otherwise `false`.
  func shouldAlert(for lastAlertTime: Int64?) -> Bool {
    return lastAlertTime == nil || Date().millisecondsSince1970 - lastAlertTime! > lastAlertLimit
  }

}
