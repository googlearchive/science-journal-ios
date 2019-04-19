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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJSensorLayout. Represents the visual appearance of a sensor chart.
class SensorLayout: Equatable, Hashable {

  /// The sensor ID associated with this layout.
  var sensorID: String {
    get {
      return proto.sensorId
    }
    set {
      proto.sensorId = newValue
    }
  }

  /// True if audio playback of data is enabled, otherwise false.
  var isAudioEnabled: Bool {
    get {
      return proto.audioEnabled
    }
    set {
      proto.audioEnabled = newValue
    }
  }

  /// True if the chart is displaying stats overlays, otherwise false.
  var shouldShowStatsOverlay: Bool {
    get {
      return proto.showStatsOverlay
    }
    set {
      proto.showStatsOverlay = newValue
    }
  }

  /// The color palette of the sensor card.
  var colorPalette: MDCPalette {
    get {
      return MDCPalette.sensorCardColorPaletteOptions[Int(proto.colorIndex)]
    }
    set {
      proto.colorIndex = Int32(MDCPalette.sensorCardColorPaletteOptions.index(of: newValue) ?? 0)
    }
  }

  /// Extra options for the sensor's chart.
  var extras: [String: String]

  /// The visible Y-axis for the chart.
  var visibleYAxis: ChartAxis<Double> {
    get {
      return ChartAxis(min: proto.minimumYaxisValue, max: proto.maximumYaxisValue)
    }
    set {
      proto.minimumYaxisValue = newValue.min
      proto.maximumYaxisValue = newValue.max
    }
  }

  /// The IDs of the active triggers.
  var activeSensorTriggerIDs: [String]

  var proto: GSJSensorLayout {
    backingProto.extras = NSMutableDictionary(dictionary: extras)
    backingProto.activeSensorTriggerIdsArray = NSMutableArray(array: activeSensorTriggerIDs)
    return backingProto
  }

  /// Designated initializer.
  ///
  /// - Parameter proto: A sensor layout proto.
  init(proto: GSJSensorLayout) {
    // swiftlint:disable force_cast
    backingProto = proto.copy() as! GSJSensorLayout
    extras = backingProto.extras as! [String: String]
    activeSensorTriggerIDs = backingProto.activeSensorTriggerIdsArray as! [String]
    // swiftlint:enable force_cast
  }

  /// Initializes a sensor layout.
  ///
  /// - Parameters:
  ///   - sensorID: The sensor ID.
  ///   - colorPalette: The color palette.
  convenience init(sensorID: String, colorPalette: MDCPalette) {
    let proto = GSJSensorLayout()
    self.init(proto: proto)
    self.sensorID = sensorID
    self.colorPalette = colorPalette
  }

  /// Tests a trigger id for active state.
  ///
  /// - Parameter triggerId: The ID of a trigger.
  /// - Returns: True if the triggerID is active, otherwise false.
  func isTriggerActive(_ triggerID: String) -> Bool {
    return activeSensorTriggerIDs.contains(triggerID)
  }

  // MARK: - Equatable

  static func ==(lhs: SensorLayout, rhs: SensorLayout) -> Bool {
    return lhs.proto.isEqual(rhs.proto)
  }

  // MARK: - Hashable

  var hashValue: Int {
    return proto.hash
  }

  // MARK: - Private

  /// The private backing proto.
  private let backingProto: GSJSensorLayout

}
