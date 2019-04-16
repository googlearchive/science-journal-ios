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

import UIKit

protocol SensorDelegate: class {
  func sensorStateDidChange(_ sensor: Sensor)
}

/// The sensor base class, that includes all basic sensor properties and actions.
class Sensor: NSObject {

  // MARK: - Properties

  /// The sensor ID.
  let sensorId: String
  /// The name of the sensor.
  let name: String
  /// The text description of the sensor.
  let textDescription: String
  /// An icon file name for the Sensor, used in places like the sensor picker in Observe.
  let iconName: String
  /// The animating icon view for the sensor.
  let animatingIconView: SensorAnimationView
  /// Units the sensor's values are measured in.
  let unitDescription: String?
  /// Whether or not the sensor is supported on the current device. False by default.
  var isSupported = false
  /// The decimal precision to use when formatting the sensor's values for display.
  var pointsAfterDecimal: Int32 = 1

  /// The delegate
  weak var delegate: SensorDelegate?

  /// The state of the sensor.
  var state = LoadingState.paused {
    didSet {
      guard state != oldValue else { return }
      delegate?.sensorStateDidChange(self)
    }
  }

  /// Whether or not the sensor should display a loading state. Some sensors have negligible delays
  /// between starting and receiving the first data point so displaying a loading screen is
  /// not necessary.
  var displaysLoadingState = false

  /// Dictionary of closures to be called with sensor data.
  var listenerBlocks = [AnyHashable : (DataPoint) -> Void]()

  /// The contents of the learn more view for a sensor.
  let learnMore: LearnMore?

  private let sensorTimer: SensorTimer

  // MARK: - Public

  /// Designated initializer for creating a sensor.
  ///
  /// - Parameters:
  ///   - sensorId: The sensor ID.
  ///   - name: The name of the sensor.
  ///   - textDescription: The text description of the sensor.
  ///   - iconName: The icon name for the sensor.
  ///   - animatingIconView: The animating icon view.
  ///   - unitDescription: Units the sensor's values are measured in.
  ///   - learnMore: The contents of the learn more view for a sensor.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(sensorId: String,
       name: String,
       textDescription: String,
       iconName: String,
       animatingIconView: SensorAnimationView,
       unitDescription: String?,
       learnMore: LearnMore,
       sensorTimer: SensorTimer) {
    self.sensorId = sensorId
    self.name = name
    self.textDescription = textDescription
    self.iconName = iconName
    self.animatingIconView = animatingIconView
    self.unitDescription = unitDescription
    self.learnMore = learnMore
    self.sensorTimer = sensorTimer

    super.init()
  }

  /// Adds a closure to be called with sensor data, for an object, or updates that object's closure.
  ///
  /// - Parameters:
  ///   - listener: Object registering as a listener.
  ///   - block: Closure that is called when sensor data is sent.
  func addListener(_ listener: AnyObject, using block: @escaping (DataPoint) -> Void) {
    guard isSupported else {
      state = .failed(.notSupported)
      return
    }

    let previousCount = listenerBlocks.count
    listenerBlocks[ObjectIdentifier(listener)] = block
    if previousCount == 0 && listenerBlocks.count == 1 {
      sensorTimer.add(sensor: self)
      start()
    }
  }

  /// Removes a closure to be called with sensor data, for an object, or updates that object's
  /// closure.
  ///
  /// - Parameter listener: Object removing itself as a listener.
  func removeListener(_ listener: AnyObject) {
    let previousCount = listenerBlocks.count
    listenerBlocks[ObjectIdentifier(listener)] = nil
    if previousCount == 1 && listenerBlocks.count == 0 {
      sensorTimer.remove(sensor: self)
      pause()
    }
  }

  /// Called when the update interval timer and the sensor should call listener block with data.
  /// Subclasses must override.
  ///
  /// - Parameter milliseconds: The date in milliseconds when the timer fired.
  func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    // Default implementation does nothing.
  }

  /// Calls all listener blocks with the data point.
  ///
  /// - Parameter dataPoint: The data point containing the sensor data.
  func callListenerBlocksWithDataPoint(_ dataPoint: DataPoint) {
    for (_, listener) in listenerBlocks {
      listener(dataPoint)
    }
  }

  /// Starts the sensor.
  ///
  /// Important: `start` must be overridden by the subclass.
  func start() {
    fatalError("`start` must be overridden by the subclass.")
  }

  /// Indicates the sensor should try to start again. Should be called based on a user request to
  /// retry. The default implementation does nothing, subclasses must override to support retry.
  func retry() {}

  /// Pauses the sensor.
  ///
  /// Important: `pause` must be overridden by the subclass.
  func pause() {
    fatalError("`pause` must be overridden by the subclass.")
  }

  /// Returns a formatted string for the value.
  ///
  /// - Parameters:
  ///   - value: The sensor data value to format.
  ///   - includeUnits: Whether to include units.
  /// - Returns: The formatted string.
  func string(for value: Double, withUnits includeUnits: Bool = false) -> String {
    let units: String? = includeUnits ? unitDescription : nil
    return Sensor.string(for: value, units: units, pointsAfterDecimal: pointsAfterDecimal)
  }

  /// Returns a formatted value string.
  ///
  /// - Parameters:
  ///   - value: The sensor data value to format.
  ///   - units: The units as a string.
  ///   - pointsAfterDecimal: Decimal precision of the formatted value.
  /// - Returns: A formatted value string.
  class func string(for value: Double, units: String?, pointsAfterDecimal: Int32) -> String {
    let dataFormat = "%." + String(pointsAfterDecimal) + "f"
    var valueString = String(format: dataFormat, value)
    if let units = units {
      if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
        valueString = "\(units) " + valueString
      } else {
        valueString += " \(units)"
      }
    }
    return valueString
  }

  /// Called when the app will enter the background. Override if needed.
  func prepareForBackground() {
    // Default implementation does nothing.
  }

  /// Called when the app will enter the foreground. Override if needed.
  func prepareForForeground() {
    // Default implementation does nothing.
  }

  // MARK: - Sub types

  /// The state of a sensor.
  ///
  /// - paused: The sensor has been paused or has not yet been started. All sensors default to
  ///           paused.
  /// - loading: The sensor is a loading state, such as a prolonged configuration or establishing
  ///            a connection.
  /// - failed: The sensor failed to start due to an error.
  /// - noPermission: The sensor failed to start because the proper permissions are not granted.
  /// - ready: The sensor has successfully started and it vending data.
  /// - interrupted: The sensor hardware is interrupted by another client.
  enum LoadingState: Equatable {
    case paused
    case loading
    case failed(SensorError)
    case noPermission(SensorError)
    case ready
    case interrupted

    /// This equality test does not compare associated values.
    public static func ==(lhs: LoadingState, rhs: LoadingState) -> Bool {
      switch (lhs, rhs) {
      case (.paused, .paused):
        return true
      case (.loading, .loading):
        return true
      case (.ready, .ready):
        return true
      case (.failed(_), .failed(_)):
        return true
      case (.noPermission(_), .noPermission(_)):
        return true
      case (.interrupted, .interrupted):
        return true
      default:
        return false
      }
    }
  }

  /// The contents of the learn more view for a sensor.
  class LearnMore {

    // MARK: - Properties

    /// The first paragraph of text for the learn more view of a sensor.
    let firstParagraph: String

    /// The second paragraph of text for the learn more view of a sensor.
    let secondParagraph: String

    /// The name of the image for the learn more view of a sensor.
    let imageName: String

    // MARK: - Public

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - firstParagraph: The first paragraph of text for the learn more view of a sensor.
    ///   - secondParagraph: The second paragraph of text for the learn more view of a sensor.
    ///   - imageName: The name of the image for the learn more view of a sensor.
    init(firstParagraph: String, secondParagraph: String, imageName: String) {
      self.firstParagraph = firstParagraph
      self.secondParagraph = secondParagraph
      self.imageName = imageName
    }

  }

}
