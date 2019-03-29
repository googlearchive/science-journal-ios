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

extension CMAcceleration {

  /// Acceleration in the x direction in m/s².
  var xMetersPerSecondSquared: Double {
    return Double.metersPerSecondSquared(fromGs: x)
  }

  /// Acceleration in the y direction in m/s².
  var yMetersPerSecondSquared: Double {
    return Double.metersPerSecondSquared(fromGs: y)
  }

  /// Acceleration in the z direction in m/s².
  var zMetersPerSecondSquared: Double {
    return Double.metersPerSecondSquared(fromGs: z)
  }

}

extension Double {
  /// Converts Gs, a unit of gravitational force equal to that exerted by the earth’s gravitational
  /// field (9.81 m/s²) to m/s².
  ///
  /// - Parameter Gs: The value in Gs.
  /// - Returns: The value in m/s².
  static func metersPerSecondSquared(fromGs Gs: Double) -> Double {
    return Gs * 9.81
  }
}

/// A sensor that measures acceleration data.
class AccelerometerSensor: MotionSensor {

  /// The number of instances of AccelerometerSensor running. Used to decide when to start and stop
  /// motion manager accelerometer updates.
  static var instancesRunningCount = 0 {
    didSet {
      if instancesRunningCount > 0 {
        if !MotionSensor.motionManager.isAccelerometerActive {
          MotionSensor.motionManager.startAccelerometerUpdates()
        }
      } else {
        if MotionSensor.motionManager.isAccelerometerActive {
          MotionSensor.motionManager.stopAccelerometerUpdates()
        }
      }
    }
  }

  /// Designated initializer for creating an accelerometer sensor.
  ///
  /// - Parameters:
  ///   - sensorId: The sensor ID.
  ///   - name: The name of the sensor.
  ///   - iconName: The icon name for the sensor.
  ///   - animatingIconView: The animating icon view.
  ///   - textDescription: The text description of the accelerometer sensor.
  ///   - learnMore: The contents of the learn more view for a sensor.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(sensorId: String,
       name: String,
       iconName: String,
       animatingIconView: SensorAnimationView,
       textDescription: String,
       learnMore: LearnMore,
       sensorTimer: SensorTimer) {
    super.init(sensorId: sensorId,
               name: name,
               textDescription: textDescription,
               iconName: iconName,
               animatingIconView: animatingIconView,
               unitDescription: String.accUnits,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    MotionSensor.motionManager.accelerometerUpdateInterval = updateInterval
    isSupported = MotionSensor.motionManager.isAccelerometerAvailable
  }

  override func start() {
    guard state != .ready else {
      return
    }

    AccelerometerSensor.instancesRunningCount += 1
    state = .ready
  }

  override func pause() {
    guard state != .paused else { return }

    AccelerometerSensor.instancesRunningCount -= 1
    state = .paused
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    if let accelerometerData = MotionSensor.motionManager.accelerometerData {
      callListenerBlocksWithAcceleration(accelerometerData.acceleration,
                                         atMilliseconds: milliseconds)
    }
  }

  /// Calls all listener blocks with acceleration data. Must be overriden by subclasses to call with
  /// the data value it is associated with (x, y or z).
  ///
  /// - Parameters:
  ///   - acceleration: The CMAcceleration accessed from the motion manager.
  ///   - milliseconds: The date in milliseconds when the timer fired.
  func callListenerBlocksWithAcceleration(_ acceleration: CMAcceleration,
                                          atMilliseconds milliseconds: Int64) {
    fatalError("`callListenerBlocksWithAcceleration` must be overridden by the subclass.")
  }

}

/// An accelerometer sensor that measures acceleration on a single axis.
class SingleAxisAccelerometer: AccelerometerSensor {

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorId: The sensor ID.
  ///   - name: The name of the sensor.
  ///   - iconName: The icon name for the sensor.
  ///   - animatingIconName: The animating icon name for the sensor.
  ///   - textDescription: The text description of the accelerometer sensor.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(sensorId: String,
       name: String,
       iconName: String,
       animatingIconName: String,
       textDescription: String,
       sensorTimer: SensorTimer) {
    let animatingIconView = AccelerometerAnimationView(iconName: animatingIconName)
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphAcc,
                              secondParagraph: String.sensorDescSecondParagraphAcc,
                              imageName: "learn_more_acc")
    super.init(sensorId: sensorId,
               name: name,
               iconName: iconName,
               animatingIconView: animatingIconView,
               textDescription: textDescription,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
  }

}

/// An accelerometer sensor that measures acceleration left and right.
class AccelerometerXSensor: SingleAxisAccelerometer {

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    super.init(sensorId: "AccX",
               name: String.accX,
               iconName: "ic_sensor_acc_x",
               animatingIconName: "sensor_acc_x",
               textDescription: String.sensorDescShortAccX,
               sensorTimer: sensorTimer)
  }

  override func callListenerBlocksWithAcceleration(_ acceleration: CMAcceleration,
                                                   atMilliseconds milliseconds: Int64) {
    // Acceleration value is negated to match the values seen in Android devices.
    let dataPoint = DataPoint(x: milliseconds, y: -acceleration.xMetersPerSecondSquared)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}

/// An accelerometer sensor that measures acceleration forward and back.
class AccelerometerYSensor: SingleAxisAccelerometer {

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    super.init(sensorId: "AccY",
               name: String.accY,
               iconName: "ic_sensor_acc_y",
               animatingIconName: "sensor_acc_y",
               textDescription: String.sensorDescShortAccY,
               sensorTimer: sensorTimer)
  }

  override func callListenerBlocksWithAcceleration(_ acceleration: CMAcceleration,
                                                   atMilliseconds milliseconds: Int64) {
    // Acceleration value is negated to match the values seen in Android devices.
    let dataPoint = DataPoint(x: milliseconds, y: -acceleration.yMetersPerSecondSquared)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}

/// An accelerometer sensor that measures acceleration up and down.
class AccelerometerZSensor: SingleAxisAccelerometer {

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    super.init(sensorId: "AccZ",
               name: String.accZ,
               iconName: "ic_sensor_acc_z",
               animatingIconName: "sensor_acc_z",
               textDescription: String.sensorDescShortAccZ,
               sensorTimer: sensorTimer)
  }

  override func callListenerBlocksWithAcceleration(_ acceleration: CMAcceleration,
                                                   atMilliseconds milliseconds: Int64) {
    // Acceleration value is negated to match the values seen in Android devices.
    let dataPoint = DataPoint(x: milliseconds, y: -acceleration.zMetersPerSecondSquared)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}

/// An accelerometer sensor that measures combined acceleration in all three axes, excluding
/// gravity.
class LinearAccelerometerSensor: AccelerometerSensor {

  // MARK: - Nested class

  /// A filter that removes gravity from acceleration.
  /// https://en.wikipedia.org/wiki/High-pass_filter
  private class HighpassFilter {

    var x: Double = 0
    var y: Double = 0
    var z: Double = 0

    var lastX: Double = 0
    var lastY: Double = 0
    var lastZ: Double = 0

    let accelerometerMinStep = 0.02
    let accelerometerNoiseAttenuation = 3.0

    let filterConstant: Double

    var adaptive: Bool = true

    init(sampleRate: Double, cutoffFrequency: Double) {
      let dt = 1 / sampleRate
      let RC = 1 / cutoffFrequency
      filterConstant = RC / (dt + RC)
    }

    func addAcceleration(_ acceleration: CMAcceleration) {
      var alpha = filterConstant

      if adaptive {
        let previousNormalized = norm(x: x, y: y, z: z)
        let newNormalized = norm(x: acceleration.x, y: acceleration.y, z: acceleration.z)
        let clampedByValue = abs(previousNormalized - newNormalized) / accelerometerMinStep - 1
        let d = (0.0...1.0).clamp(clampedByValue)
        alpha = d * filterConstant / accelerometerNoiseAttenuation + (1 - d) * filterConstant
      }

      x = alpha * (x + acceleration.x - lastX)
      y = alpha * (y + acceleration.y - lastY)
      z = alpha * (z + acceleration.z - lastZ)

      lastX = acceleration.x
      lastY = acceleration.y
      lastZ = acceleration.z
    }

    func norm(x: Double, y: Double, z: Double) -> Double {
      return sqrt(x * x + y * y + z * z)
    }

  }

  // MARK: - LinearAccelerometerSensor

  private let highpassFilter = HighpassFilter(sampleRate: 15, cutoffFrequency: 5)

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    let animatingIconView = RelativeScaleAnimationView(iconName: "sensor_acc_linear")
    let learnMore =
        LearnMore(firstParagraph: String.sensorDescFirstParagraphLinearAcc,
                  secondParagraph: String.sensorDescSecondParagraphLinearAcc,
                  imageName: "learn_more_acc")
    super.init(sensorId: "LinearAccelerometerSensor",
               name: String.linearAccelerometer,
               iconName: "ic_sensor_acc_linear",
               animatingIconView: animatingIconView,
               textDescription: String.sensorDescShortLinearAcc,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
  }

  override func callListenerBlocksWithAcceleration(_ acceleration: CMAcceleration,
                                                   atMilliseconds milliseconds: Int64) {
    highpassFilter.addAcceleration(acceleration)
    let x = Double.metersPerSecondSquared(fromGs: highpassFilter.x)
    let y = Double.metersPerSecondSquared(fromGs: highpassFilter.y)
    let z = Double.metersPerSecondSquared(fromGs: highpassFilter.z)
    let linear = sqrt(x * x + y * y + z * z)
    let dataPoint = DataPoint(x: milliseconds, y: linear)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}
