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

/// Handles checking and asking for camera access permission.
class CameraAccessHandler {

  /// Checks the permissions status of the camera, and requests access if needed.
  ///
  /// - Parameter requestCompletion: Called with the status of the permission (true if granted),
  ///              when access had to be requested.
  /// - Returns: Whether or not permission has been granted.
  static func checkForPermission(requestCompletion: ((Bool) -> ())? = nil) -> Bool {
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch authStatus {
    case .denied, .restricted: return false
    case .authorized: return true
    case .notDetermined:
      // Prompt user for the permission to use the camera.
      AVCaptureDevice.requestAccess(for: .video) { granted in
        requestCompletion?(granted)
      }
      return false
    }
  }

}
