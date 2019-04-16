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

/// A sensor that generates one consistent value over time. Used only for testing.
class SingleValueSensor: Sensor {

  /// The value to output.
  private let singleValue = 22.22

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    let sensorName = "Single Value"
    let textDescription = "Outputs a fixed value over time."
    let animatingIconView = RelativeScaleAnimationView(iconName: "sensor_generic")
    let learnMore = LearnMore(firstParagraph: "This is a test sensor.",
                              secondParagraph: "It shows a fixed value.",
                              imageName: "ic_sensor_generic_full_color")
    super.init(sensorId: "DEBUG_SINGLE_VALUE_SENSOR",
               name: sensorName,
               textDescription: textDescription,
               iconName: "ic_sensor_generic",
               animatingIconView: animatingIconView,
               unitDescription: nil,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    isSupported = true
  }

  override func start() {
    guard state != .ready else {
      return
    }

    state = .ready
  }

  override func pause() {
    state = .paused
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    let dataPoint = DataPoint(x: milliseconds, y: singleValue)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}
