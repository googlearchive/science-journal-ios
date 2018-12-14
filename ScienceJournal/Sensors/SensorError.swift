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

import Foundation

/// Hardware used for sensors that require user permission.
enum SensorHardwareUserPermission {
  /// The camera used to observe brightness or take photos.
  case camera

  /// The microphone used to observe audio.
  case microphone

  /// The message to use for requesting user permission for the sensor hardware.
  ///
  /// - Returns: The alert message.
  var message: String {
    switch self {
    case .microphone:
      return String.sensorCardSoundPermissionError
    case .camera:
      return String.sensorCardBrightnessPermissionError
    }
  }

  /// The alert action settings title to use for requesting user permission for the sensor hardware.
  ///
  /// - Returns: The alert action settings title.
  var settingsActionTitle: String {
    return String.sensorAlertSettingsButtonTitle
  }

}

/// Errors that can be thrown by a sensor.
///
/// - notSupported: The sensor is not supported on this device.
/// - userPermissionError: There was an error accessing hardware due to user permissions.
/// - unavailableHardware: Hardware is unavailable.
enum SensorError: Error {
  case notSupported
  case userPermissionError(SensorHardwareUserPermission)
  case unavailableHardware

  /// The message to display to the user when this error occurs.
  var message: String {
    switch self {
    case .notSupported, .unavailableHardware:
      return String.sensorCardErrorText
    case .userPermissionError(let userPermission):
      return userPermission.message
    }
  }

  /// The title of the action button associated with this error.
  var actionButtonTitle: String? {
    switch self {
    case .notSupported:
      return nil
    case .unavailableHardware:
      return String.actionRetry
    case .userPermissionError(_):
      return String.sensorAlertSettingsButtonTitle
    }
  }
}
