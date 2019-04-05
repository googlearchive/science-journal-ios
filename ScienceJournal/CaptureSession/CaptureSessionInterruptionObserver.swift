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

class CaptureSessionInterruptionObserver {

  // MARK: - Properties

  static let shared = CaptureSessionInterruptionObserver()

  /// Should be set to true when a capture session interruption notification is received, so that
  /// camera use will not be allowed.
  var isCaptureSessionInterrupted = false

  /// Should be set to true when the brightness sensor is being used, so that camera use will not
  /// be allowed.
  var isBrightnessSensorInUse = false

  /// Can the camera be used? This is disabled if a user chooses a brightness sensor and starts a
  /// recording, during which the camera cannot be used.
  var isCameraUseAllowed: Bool {
    return !isCaptureSessionInterrupted && !isBrightnessSensorInUse &&
        CameraAccessHandler.checkForPermission()
  }

  // MARK: - Public

  // MARK: - Private

  /// Use `shared`.
  private init() {
    // Capture session notifications.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionWasInterrupted(_:)),
                                           name: .AVCaptureSessionWasInterrupted,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionInterruptionEnded(_:)),
                                           name: .AVCaptureSessionInterruptionEnded,
                                           object: nil)
  }

  @objc private func captureSessionWasInterrupted(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionWasInterrupted(notification)
      }
      return
    }

    guard AVCaptureSession.InterruptionReason(notificationUserInfo: notification.userInfo) ==
        .videoDeviceNotAvailableWithMultipleForegroundApps else { return }
    isCaptureSessionInterrupted = true
  }

  @objc private func captureSessionInterruptionEnded(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionInterruptionEnded(notification)
      }
      return
    }

    isCaptureSessionInterrupted = false
  }

}
