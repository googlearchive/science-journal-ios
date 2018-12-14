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

protocol SensorTriggerFrequencyObserverDelegate {
  /// Called when the sensor being observed exceeds the maximum allowed trigger fire limit.
  ///
  /// - Parameter sensorTriggerFrequencyObserver: The sensor trigger frequency observer.
  func sensorTriggerFrequencyObserverDidExceedFireLimit(_
      sensorTriggerFrequencyObserver: SensorTriggerFrequencyObserver)
}

/// Observes the frequency of a sensor triggers firing. If a trigger is firing too often, all
/// triggers for its sensor should be disabled.
class SensorTriggerFrequencyObserver {

  // MARK: - Properties

  private var delegate: SensorTriggerFrequencyObserverDelegate?

  // The duration in which the fire limits are allowed.
  private let duration: Int64 = 1000

  // Tracks the timestamps per trigger type.
  private var timestampsNote = [Int64]()
  private var timestampsStopRecording = [Int64]()

  // Tracks the limit per `duration` for each trigger type.
  private let triggerFireLimitNote = 5
  private let triggerFireLimitStopRecording = 2

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter delegate: The sensor trigger frequency observer delegate.
  init(delegate: SensorTriggerFrequencyObserverDelegate) {
    self.delegate = delegate
  }

  /// Call this method when a trigger fires to track its frequency.
  ///
  ///   - trigger: The trigger that fired.
  ///   - timestamp: The timestamp it fired at.
  func triggerFired(_ trigger: SensorTrigger, at timestamp: Int64) {
    // Adds the timestamp to the timestamps array, and then checks to make sure the trigger didn't
    // fire over its limit per the duration.
    func addTimestampAndCheckCount(with timestamps: inout [Int64],
                                   limitWithinOneSecond limit: Int) {
      timestamps.append(timestamp)

      if timestamps.count > limit {
        if timestamp - timestamps[0] < duration {
          delegate?.sensorTriggerFrequencyObserverDidExceedFireLimit(self)
        }
        timestamps.removeFirst()
      }
    }

    switch trigger.triggerInformation.triggerActionType {
    case .triggerActionNote:
      addTimestampAndCheckCount(with: &timestampsNote, limitWithinOneSecond: triggerFireLimitNote)
    case .triggerActionStopRecording:
      addTimestampAndCheckCount(with: &timestampsStopRecording,
                                limitWithinOneSecond: triggerFireLimitStopRecording)
    default:
      return
    }
  }

}
