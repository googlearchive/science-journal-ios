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

/// Evaluates sensor triggers to decide when they should fire.
class SensorTriggerEvaluator {

  /// The sensor trigger.
  let sensorTrigger: SensorTrigger

  /// The previous value checked by the trigger.
  var previousValue: Double?

  /// The clock used for setting the `sensorTrigger`'s last used time.
  var clock = Clock()

  /// Designated initalizer.
  ///
  /// - Parameter sensorTrigger: The sensor trigger to evaluate.
  init(sensorTrigger: SensorTrigger) {
    self.sensorTrigger = sensorTrigger
  }

  /// Whether or not the trigger should be fired by a value.
  ///
  /// - Parameter value: The value.
  /// - Returns: `true` if the trigger should be fired.
  func shouldTrigger(withValue value: Double) -> Bool {
    var result = false
    if let previousValue = previousValue {
      switch sensorTrigger.triggerInformation.triggerWhen {
      case .triggerWhenAt:
        // TODO: For nearly equal values, store `valueToTrigger` as the `previousValue`.
        // http://b/37269026
        result = value.isNearlyEqual(to: sensorTrigger.triggerInformation.valueToTrigger) ||
            crossedThreshold(value: value, previousValue: previousValue)
      case .triggerWhenDropsBelow:
        result = droppedBelow(value: value, previousValue: previousValue)
      case .triggerWhenRisesAbove:
        result = roseAbove(value: value, previousValue: previousValue)
      case .triggerWhenBelow:
        return value < sensorTrigger.triggerInformation.valueToTrigger
      case .triggerWhenAbove:
        return value > sensorTrigger.triggerInformation.valueToTrigger
      }
    }
    self.previousValue = value
    setLastUsedToNow()
    return result;
  }

  /// Returns an array of sensor trigger evaluators for each sensor trigger.
  ///
  /// - Parameter sensorTriggers: The sensor triggers to create sensor trigger evaluators for.
  /// - Returns: The array of sensor trigger evaluators.
  static func sensorTriggerEvaluators(for sensorTriggers: [SensorTrigger]) ->
      [SensorTriggerEvaluator] {
    var sensorTriggerEvaluators: [SensorTriggerEvaluator] = []
    for sensorTrigger in sensorTriggers {
      sensorTriggerEvaluators.append(SensorTriggerEvaluator(sensorTrigger: sensorTrigger))
    }
    return sensorTriggerEvaluators
  }

  // MARK: - Helpers

  /// Whether or not the value crossed the threshold, based on the previous value.
  ///
  /// - Parameters:
  ///   - value: The value.
  ///   - previousValue: The previous value.
  /// - Returns: `true` if it crossed the threshold, otherwise `false`.
  func crossedThreshold(value: Double, previousValue: Double) -> Bool {
    let triggerValue = sensorTrigger.triggerInformation.valueToTrigger
    return (value < triggerValue && previousValue > triggerValue) ||
        (value > triggerValue && previousValue < triggerValue)
  }

  /// Whether or not the value dropped below the threshold, based on the previous value.
  ///
  /// - Parameters:
  ///   - value: The value.
  ///   - previousValue: The previous value.
  /// - Returns: `true` if it dropped below the threshold, otherwise `false`.
  func droppedBelow(value: Double, previousValue: Double) -> Bool {
    return value < sensorTrigger.triggerInformation.valueToTrigger &&
        previousValue >= sensorTrigger.triggerInformation.valueToTrigger
  }

  /// Whether or not the value rose above the threshold, based on the previous value.
  ///
  /// - Parameters:
  ///   - value: The value.
  ///   - previousValue: The previous value.
  /// - Returns: `true` if it rose above the threshold, otherwise `false`.
  func roseAbove(value: Double, previousValue: Double) -> Bool {
    return value > sensorTrigger.triggerInformation.valueToTrigger &&
        previousValue <= sensorTrigger.triggerInformation.valueToTrigger
  }

  /// Sets the last used date to now.
  func setLastUsedToNow() {
    sensorTrigger.lastUsedDate = Date(milliseconds: clock.millisecondsSince1970)
  }

}
