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

import CoreLocation
import Foundation

/// A sensor that reads heading data from the device's heading.
class CompassSensor: Sensor, CLLocationManagerDelegate {

  // MARK: - Properties

  private let locationManager = CLLocationManager()
  private var currentHeading: Double?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    let animatingIconView = RelativeScaleAnimationView(iconName: "sensor_compass")
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphCompass,
                              secondParagraph: String.sensorDescSecondParagraphCompass,
                              imageName: "learn_more_compass")
    super.init(sensorId: "CompassSensor",
               name: String.compass,
               textDescription: String.sensorDescShortCompass,
               iconName: "ic_sensor_compass",
               animatingIconView: animatingIconView,
               unitDescription: String.compassUnits,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    isSupported = CLLocationManager.headingAvailable()
    pointsAfterDecimal = 0

    locationManager.delegate = self
  }

  override func start(completion: ((Error?) -> ())?) {
    guard state != .ready else {
      completion?(nil)
      return
    }

    locationManager.startUpdatingHeading()
    state = .ready
    completion?(nil)
  }

  override func pause() {
    guard state != .paused else { return }

    locationManager.stopUpdatingHeading()
    state = .paused
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    // TODO: Make sensors pending until a value is available. http://b/64477130
    guard let currentHeading = currentHeading else { return }
    let dataPoint = DataPoint(x: milliseconds, y: currentHeading)
    callListenerBlocksWithDataPoint(dataPoint)
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    if newHeading.headingAccuracy < 0 {
      return
    }

    // True north (CoreLocation's `trueHeading`) is north according to the earth's axis. Magnetic
    // north (CoreLocation's `magneticHeading`) is the direction in which the north end of a compass
    // needle or other freely suspended magnet will point in response to the earth's magnetic field.
    // It deviates from true north over time and from place to place because the earth's magnetic
    // poles are not fixed in relation to its axis.
    //
    // `trueHeading` is preferred, but can be invalid (indicated by a negative value).
    // `magneticHeading` should always be valid.
    currentHeading =
        newHeading.trueHeading >= 0.0 ? newHeading.trueHeading : newHeading.magneticHeading
  }

}
