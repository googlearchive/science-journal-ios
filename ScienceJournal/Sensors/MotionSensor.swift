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

import CoreMotion
import Foundation

/// A sensor that uses a motion manager to collect data from the device.
class MotionSensor: Sensor {

  /// The motion manager for the motion manager sensor.
  ///
  /// Important: An app should create only a single instance of the CMMotionManager class. Multiple
  /// instances of this class can affect the rate at which data is received from the accelerometer
  /// and gyroscope.
  static let motionManager = CMMotionManager()

  /// The interval at which to have the motion sensor update its data. 0.01 is suggested when using
  /// the "pull" method of accessing data.
  let updateInterval = 0.01

}
