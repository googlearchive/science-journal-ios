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

import CoreMotion
import Foundation

/// A sensor that reads data from the device's altimeter sensor.
class AltimeterSensor: Sensor {

  // MARK: - Properties

  private static let altimeter = CMAltimeter()
  private var currentAltitudeData: CMAltitudeData?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorId: The sensor ID.
  ///   - name: The name of the sensor.
  ///   - textDescription: The text description of the accelerometer sensor.
  ///   - iconName: The icon name for the sensor.
  ///   - animatingIconName: The animating icon name for the sensor.
  ///   - unitDescription: Units the sensor's values are measured in.
  ///   - learnMore: The contents of the learn more view for a sensor.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(sensorId: String,
       name: String,
       textDescription: String,
       iconName: String,
       animatingIconName: String,
       unitDescription: String?,
       learnMore: LearnMore,
       sensorTimer: SensorTimer) {
    let animatingIconView = RelativeScaleAnimationView(iconName: animatingIconName)
    super.init(sensorId: sensorId,
               name: name,
               textDescription: textDescription,
               iconName: iconName,
               animatingIconView: animatingIconView,
               unitDescription: unitDescription,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    isSupported = CMAltimeter.isRelativeAltitudeAvailable()
  }

  override func start() {
    guard state != .ready else { return }

    state = .ready
    AltimeterSensor.altimeter.startRelativeAltitudeUpdates(to: .main) {
        [weak self] (altitudeData, _) in
      if let altitudeData = altitudeData {
        self?.currentAltitudeData = altitudeData
      }
    }
  }

  override func pause() {
    guard state != .paused else { return }

    state = .paused
    AltimeterSensor.altimeter.stopRelativeAltitudeUpdates()
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    // TODO: Make sensors pending until a value is available. http://b/64477130
    guard let altitudeData = currentAltitudeData else { return }
    callListenerBlocksWithAltitudeData(altitudeData, atMilliseconds: milliseconds)
  }

  /// Calls all listener blocks with altitude data. Must be overriden by subclasses to call with
  /// the data value it is associated with (pressure or relative altitude).
  ///
  /// - Parameters:
  ///   - altitudeData: The CMAltitudeData received from the altimeter.
  ///   - milliseconds: The date in milliseconds when the timer fired.
  func callListenerBlocksWithAltitudeData(_ altitudeData: CMAltitudeData,
                                          atMilliseconds milliseconds: Int64) {
    fatalError("`callListenerBlocksWithAltitudeData` must be overridden by the subclass.")
  }

}
