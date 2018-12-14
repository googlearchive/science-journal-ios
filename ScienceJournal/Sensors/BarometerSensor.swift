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

/// A sensor that reads barometer pressure data from the device's altimeter sensor.
class BarometerSensor: AltimeterSensor {

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphBarometer,
                              secondParagraph: String.sensorDescSecondParagraphBarometer,
                              imageName: "learn_more_barometer")
    super.init(sensorId: "BarometerSensor",
               name: String.barometer,
               textDescription: String.sensorDescShortBarometer,
               iconName: "ic_sensor_barometer",
               animatingIconName: "sensor_barometer",
               unitDescription: String.barometerUnits,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    pointsAfterDecimal = 2
  }

  override func callListenerBlocksWithAltitudeData(_ altitudeData: CMAltitudeData,
                                                   atMilliseconds milliseconds: Int64) {
    // CMAltitudeData contains pressure in kPA. Convert to hPa.
    let hPa = altitudeData.pressure.doubleValue * 10
    let dataPoint = DataPoint(x: milliseconds, y: hPa)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}
