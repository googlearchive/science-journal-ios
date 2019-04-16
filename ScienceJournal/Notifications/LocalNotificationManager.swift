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

import UIKit
import UserNotifications

/// Manages local notifications.
class LocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {

  private enum ActionIdentifier: String {
    case continueRecording = "ContinueRecordingActionIdentifier"
    case stopRecording = "StopRecordingActionIdentifier"
  }

  // MARK: - Properties

  /// Shared instance.
  static let shared = LocalNotificationManager()

  /// The notification posted when receiving a stop recording action.
  static let DidReceiveStopRecordingAction =
      Notification.Name("GSJLocalNotificationManagerDidReceiveStopRecordingAction")

  /// The notification posted when push notification registration is complete.
  static let PushNotificationRegistrationComplete =
      Notification.Name("GSJNotificationRegistrationComplete")

  private let recordingWillEndCategoryIdentifier = "RecordingWillEndCategoryIdentifier"
  private let userNotificationCenter = UNUserNotificationCenter.current()

  // MARK: - Public

  // Use the shared instance.
  private override init() {
    super.init()
    userNotificationCenter.delegate = self
  }

  /// Registers user notifications.
  func registerUserNotifications() {
    userNotificationCenter.requestAuthorization(options: .alert) { (granted, error) in
      guard granted else {
        sjlog_error("Authorizationwas not granted for user notifications.", category: .general)
        DispatchQueue.main.async {
          NotificationCenter.default.post(
              name: LocalNotificationManager.PushNotificationRegistrationComplete, object: nil)
        }
        return
      }

      let continueRecordingAction =
          UNNotificationAction(identifier: ActionIdentifier.continueRecording.rawValue,
                               title: String.recordingWillEndContinue,
                               options: [.foreground])
      let stopRecordingAction =
          UNNotificationAction(identifier: ActionIdentifier.stopRecording.rawValue,
                               title: String.recordingWillEndStop,
                               options: [.destructive])
      let category = UNNotificationCategory(identifier: self.recordingWillEndCategoryIdentifier,
                                            actions: [continueRecordingAction, stopRecordingAction],
                                            intentIdentifiers: [],
                                            options: [])
      self.userNotificationCenter.setNotificationCategories([category])

      DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: LocalNotificationManager.PushNotificationRegistrationComplete, object: nil)
      }
    }
  }

  /// Presents a local notification saying that recording will end, with options to stop or
  /// continue recording.
  func presentRecordingWillEndNotification() {
    userNotificationCenter.getNotificationSettings { (settings) in
      guard settings.alertSetting == .enabled else {
        sjlog_error("Notification alerts are not enabled.", category: .general)
        return
      }

      let content = UNMutableNotificationContent()
      content.categoryIdentifier = self.recordingWillEndCategoryIdentifier
      content.title = String.recordingWillEndDialogTitle
      content.body = String.recordingWillEndDialogMessage
      // Time interval has to be greater than 0.
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(identifier: self.recordingWillEndCategoryIdentifier,
                                          content: content,
                                          trigger: trigger)
      self.userNotificationCenter.add(request, withCompletionHandler: { (error) in
        if let error = error {
          sjlog_error("Recording will end notification could not be added: \(error)",
                      category: .general)
        }
      })
    }
  }

  /// Cancels the local notification saying that recording will end.
  func cancelRecordingWillEndNotification() {
    userNotificationCenter.removeDeliveredNotifications(
        withIdentifiers: [recordingWillEndCategoryIdentifier])
  }

  /// Presents a local notification saying that recording ended.
  func presentRecordingEndedNotification() {
    userNotificationCenter.getNotificationSettings { (settings) in
      guard settings.alertSetting == .enabled else {
        sjlog_error("Notification alerts are not enabled.", category: .general)
        return
      }

      let content = UNMutableNotificationContent()
      content.title = String.recordingEndedDialogTitle
      content.body = String.recordingEndedDialogMessage
      // Time interval has to be greater than 0.
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(identifier: "RecordingEnded",
                                          content: content,
                                          trigger: trigger)
      self.userNotificationCenter.add(request, withCompletionHandler: { (error) in
        if let error = error {
          sjlog_error("Recording ended notification could not be added: \(error)",
                      category: .general)
        }
      })
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    switch response.actionIdentifier {
    case ActionIdentifier.continueRecording.rawValue:
      // Continuing recording requries the app is foregrounded. The continue recording action's
      // activation mode is set to `.foreground`, so choosing "continue recording" already opened
      // the app. We can just call completion.
      completionHandler()
    case ActionIdentifier.stopRecording.rawValue:
      // Post a notification so observe will know to stop recording. Then call completion.
      NotificationCenter.default.post(name: LocalNotificationManager.DidReceiveStopRecordingAction,
                                      object: nil)
      completionHandler()
    default:
      // Not a known action identifier, just call completion.
      completionHandler()
    }
  }

}
