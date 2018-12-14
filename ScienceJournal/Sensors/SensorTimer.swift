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

/// A protocol for creating timers that sensors will use for the interval at which to update.
protocol SensorTimer {

  /// Adds a sensor that will be updated when the timer fires. The timer should begin messaging the
  /// sensors as soon as it is added.
  func add(sensor: Sensor)

  /// Removes a sensor so it will no longer be updated when the timer fires.
  func remove(sensor: Sensor)

}
