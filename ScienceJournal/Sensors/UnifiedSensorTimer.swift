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

import Foundation

/// A class that unifies timers for sensors, calling them all at the same timestamp when it is time
/// to update.
class UnifiedSensorTimer: SensorTimer {

  /// MARK: - Properties

  /// A timer used to continuously check accelerometer data.
  private var timer: Timer?

  /// Sensors that should be updated when the timer fires.
  private var sensors = NSHashTable<Sensor>.weakObjects()

  /// The time interval of how often to check for new data (1/15th of a second).
  private let updateTimeInterval: TimeInterval = 0.066667

  /// MARK: - Public

  func add(sensor: Sensor) {
    sensors.add(sensor)

    if sensors.count == 1 {
      startTimer()
    }
  }

  func remove(sensor: Sensor) {
    sensors.remove(sensor)

    if sensors.count == 0 {
      stopTimer()
    }
  }

  // MARK: - Private

  private func startTimer() {
    timer = Timer.scheduledTimer(timeInterval: updateTimeInterval,
                                 target: self,
                                 selector: #selector(timerFired),
                                 userInfo: nil,
                                 repeats: true)
    // Allows the timer to fire while scroll views are tracking.
    RunLoop.main.add(timer!, forMode: .common)
  }

  private func stopTimer() {
    timer?.invalidate()
  }

  @objc private func timerFired() {
    let currentMilliseconds = Date().millisecondsSince1970
    sensors.allObjects.forEach {
      $0.callListenerBlocksWithData(atMilliseconds: currentMilliseconds)
    }
  }

}
