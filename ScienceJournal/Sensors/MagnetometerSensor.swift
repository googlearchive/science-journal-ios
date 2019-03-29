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

/// A sensor that measures magnetic strength.
class MagnetometerSensor: MotionSensor {

  private let magneticFieldReferenceFrame = CMAttitudeReferenceFrame.xMagneticNorthZVertical

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
    MagnetometerSensor.motionManager.deviceMotionUpdateInterval = updateInterval
    isSupported = MagnetometerSensor.motionManager.isDeviceMotionAvailable &&
        CMMotionManager.availableAttitudeReferenceFrames().contains(magneticFieldReferenceFrame)
    pointsAfterDecimal = 0
  }

  override func start() {
    guard state != .ready else {
      return
    }

    MagnetometerSensor.motionManager.startDeviceMotionUpdates(using: magneticFieldReferenceFrame)
    state = .ready
  }

  override func pause() {
    guard state != .paused else { return }

    MagnetometerSensor.motionManager.stopDeviceMotionUpdates()
    state = .paused
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    guard let magneticField =
        MagnetometerSensor.motionManager.deviceMotion?.magneticField.field else { return }

    // The magnetic strength is the square root of the sum of the squares of the values in X, Y
    // and Z.
    let magneticStrength =
        sqrt(pow(magneticField.x, 2) + pow(magneticField.y, 2) + pow(magneticField.z, 2))
    let dataPoint = DataPoint(x: milliseconds, y: magneticStrength)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}
