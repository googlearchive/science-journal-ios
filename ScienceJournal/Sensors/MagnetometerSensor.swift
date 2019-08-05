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

/// A sensor that measures magnetic strength.
class MagnetometerSensor: MotionSensor {

  private let whiteDwarfMagneticFieldStrength = 100_000_000.0

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    let animatingIconView = RelativeScaleAnimationView(iconName: "sensor_magnet")
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphMagneticStrength,
                              secondParagraph: String.sensorDescSecondParagraphMagneticStrength,
                              imageName: "learn_more_magnet")
    super.init(sensorId: "MagneticRotationSensor",
               name: String.magneticFieldStrength,
               textDescription: String.sensorDescShortMagneticStrength,
               iconName: "ic_sensor_magnet",
               animatingIconView: animatingIconView,
               unitDescription: String.magneticStrengthUnits,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    MagnetometerSensor.motionManager.magnetometerUpdateInterval = updateInterval
    isSupported = MagnetometerSensor.motionManager.isMagnetometerAvailable
    pointsAfterDecimal = 0
  }

  override func start() {
    guard state != .ready else {
      return
    }

    MagnetometerSensor.motionManager.startMagnetometerUpdates()
    state = .ready
  }

  override func pause() {
    guard state != .paused else { return }

    MagnetometerSensor.motionManager.stopMagnetometerUpdates()
    state = .paused
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    guard let magnetometerData = MagnetometerSensor.motionManager.magnetometerData else {
      return
    }

    let magneticField = magnetometerData.magneticField

    // The magnetic strength is the square root of the sum of the squares of the values in X, Y
    // and Z.
    var magnetometerDataMagneticStrength =
        sqrt(pow(magneticField.x, 2) + pow(magneticField.y, 2) + pow(magneticField.z, 2))

    // Typical white dwarf stars have a magnetic field of around 100 Tesla (100,000,000 µT), so
    // let's cap our values there.
    // Note: Not a good idea to get close enough to measure a white dwarf star.
    if magnetometerDataMagneticStrength > whiteDwarfMagneticFieldStrength {
      magnetometerDataMagneticStrength = whiteDwarfMagneticFieldStrength
    }

    let dataPoint = DataPoint(x: milliseconds, y: magnetometerDataMagneticStrength)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}
