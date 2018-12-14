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

import third_party_sciencejournal_ios_ScienceJournalProtos

class TrialStats {

  // MARK: - Public

  /// The sensor ID associated with these stats.
  var sensorID: String {
    get {
      return proto.sensorId
    }
    set {
      proto.sensorId = newValue
    }
  }

  /// The state of the stats. Either they are valid or they need updating.
  var status: GSJSensorTrialStats_StatStatus {
    get {
      return proto.hasStatStatus ? proto.statStatus : .needsUpdate
    }
    set {
      proto.statStatus = status
    }
  }

  /// Returns the minimum stat value for the sensor ID.
  var minimumValue: Double? {
    get {
      return statValue(for: .minimum)
    }
    set {
      setStatValue(newValue, forStatType: .minimum)
    }
  }

  /// Returns the maximum stat value for the sensor ID.
  var maximumValue: Double? {
    get {
      return statValue(for: .maximum)
    }
    set {
      setStatValue(newValue, forStatType: .maximum)
    }
  }

  /// Returns the average stat value for the sensor ID.
  var averageValue: Double? {
    get {
      return statValue(for: .average)
    }
    set {
      setStatValue(newValue, forStatType: .average)
    }
  }

  /// The number of values recorded in a trial.
  var numberOfValues: Int? {
    get {
      guard let value = statValue(for: .numDataPoints) else {
        return nil
      }
      return Int(value)
    }
    set {
      setStatValue(Double(newValue), forStatType: .numDataPoints)
    }
  }

  /// The total duration of values in a trial, in milliseconds.
  var totalDuration: Int64? {
    get {
      guard let value = statValue(for: .totalDuration) else {
        return nil
      }
      return Int64(value)
    }
    set {
      setStatValue(Double(newValue), forStatType: .totalDuration)
    }
  }

  /// The number of zoom tiers for a sensor recording.
  var zoomPresenterTierCount: Int? {
    get {
      if let count = statValue(for: .zoomPresenterTierCount) {
        return Int(count)
      }
      return nil
    }
    set {
      setStatValue(Double(newValue), forStatType: .zoomPresenterTierCount)
    }
  }

  /// The zoom level between tiers.
  var zoomLevelBetweenTiers: Int? {
    get {
      if let zoomLevel = statValue(for: .zoomPresenterZoomLevelBetweenTiers) {
        return Int(zoomLevel)
      }
      return nil
    }
    set {
      setStatValue(Double(newValue), forStatType: .zoomPresenterZoomLevelBetweenTiers)
    }
  }

  /// The underlying proto.
  let proto: GSJSensorTrialStats

  /// Designated initializer.
  ///
  /// - Parameter proto: A sensor trial stats proto.
  init(proto: GSJSensorTrialStats) {
    self.proto = proto
  }

  /// Initializes trial stats with an empty proto.
  convenience init() {
    let proto = GSJSensorTrialStats()
    self.init(proto: proto)
  }

  /// Initializes trial stats with a sensor ID.
  convenience init(sensorID: String) {
    self.init()
    self.sensorID = sensorID
  }

  /// Adds min, max and average stats from a stat calculator.
  func addStatsFromStatCalculator(_ statCalculator: StatCalculator) {
    setStatValue(statCalculator.maximum, forStatType: .maximum)
    setStatValue(statCalculator.minimum, forStatType: .minimum)
    setStatValue(statCalculator.average, forStatType: .average)
    numberOfValues = statCalculator.numberOfValues
    totalDuration = statCalculator.duration
  }

  // MARK: - Private

  /// Returns the stat value for a given type.
  ///
  /// - Parameter type: The stat type.
  /// - Returns: The stat value.
  private func statValue(for type: GSJSensorStat_StatType) -> Double? {
    guard let index = index(for: type) else {
      return nil
    }

    let sensorStat = proto.sensorStatsArray[index] as! GSJSensorStat
    return sensorStat.statValue
  }

  private func index(for type: GSJSensorStat_StatType) -> Int? {
    let stats = proto.sensorStatsArray.compactMap { $0 as? GSJSensorStat }
    return stats.index(where: { $0.statType == type })
  }

  /// Sets a stat value for a given type.
  ///
  /// - Parameters:
  ///   - value: The stat value.
  ///   - statType: The stat type.
  private func setStatValue(_ value: Double?, forStatType statType: GSJSensorStat_StatType) {
    let existingIndex = index(for: statType)
    guard let value = value else {
      if let index = existingIndex {
        proto.sensorStatsArray.removeObject(at: index)
      }
      return
    }

    let sensorStat = GSJSensorStat(statValue: Double(value),
                                   statType: statType)
    if let index = existingIndex {
      proto.sensorStatsArray.replaceObject(at: index, with: sensorStat)
    } else {
      proto.sensorStatsArray.add(sensorStat)
    }
  }

}

// Extend Double with some initializers that take optionals.
fileprivate extension Double {
  /// Creates the closest representable value to the given Int64 or nil if the value is nil.
  init?(_ int64Value: Int64?) {
    guard let int64Value = int64Value else {
      return nil
    }
    self.init(int64Value)
  }

  /// Creates the closest representable value to the given Int or nil if the value is nil.
  init?(_ int64Value: Int?) {
    guard let int64Value = int64Value else {
      return nil
    }
    self.init(int64Value)
  }
}
