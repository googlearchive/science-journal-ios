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

enum DisplayTrialStatus {
  case recording
  case final
}

/// Protocol for a trial view data.
protocol DisplayTrial: DisplayItem, Captionable {
  var ID: String { get set }
  var status: DisplayTrialStatus { get set }
  var title: String? { get set }
  var alternateTitle: String { get set }
  var notes: [DisplayNote] { get set }
  var maxDisplayNotes: Int? { get set }
  var displayNotesCount: Int { get }
  var hasMoreNotes: Bool { get }
  var sensors: [DisplaySensor] { get set }
  var duration: String? { get set }
  var cropRange: ChartAxis<Int64>? { get set }
  var accessibleDuration: String? { get set }
  var isArchived: Bool { get set }
}

/// View data for a trial.
struct DisplayTrialViewData: DisplayTrial {
  var ID: String
  var status: DisplayTrialStatus
  var title: String?
  var alternateTitle: String
  var notes: [DisplayNote]
  var maxDisplayNotes: Int?
  var sensors: [DisplaySensor]
  var duration: String?
  var cropRange: ChartAxis<Int64>?
  var accessibleDuration: String?
  var isArchived: Bool
  var caption: String?
  var timestamp: Timestamp
  var itemType: DisplayItemType { return .trial(self) }

  /// The number of notes to display, based on maxDisplayNotes.
  var displayNotesCount: Int {
    if let maxDisplayNotes = maxDisplayNotes {
      return min(maxDisplayNotes, notes.count)
    } else {
      return notes.count
    }
  }

  /// True if the trial has more notes than the display note count, otherwise false.
  var hasMoreNotes: Bool {
    return notes.count > displayNotesCount
  }
}

/// View data for a trial's sensor data.
struct DisplaySensor {
  let title: String
  let ID: String
  let stats: DisplaySensorStats
  let pointsAfterDecimal: Int32
  let icon: UIImage?
  let colorPalette: MDCPalette?
  var chartPresentationView: UIView?

  /// Returns a formatted min value string.
  var minValueString: String {
    if let minValue = stats.minValue {
      return Sensor.string(for: minValue, units: nil, pointsAfterDecimal: pointsAfterDecimal)
    } else {
      // There should always be a min value but in case of a bug default to `-`.
      return "-"
    }
  }

  /// Returns a formatted average value string.
  var averageValueString: String {
    if let averageValue = stats.averageValue {
      return Sensor.string(for: averageValue, units: nil, pointsAfterDecimal: pointsAfterDecimal)
    } else {
      // There should always be an average value but in case of a bug default to `-`.
      return "-"
    }
  }

  /// Returns a formatted max value string.
  var maxValueString: String {
    if let maxValue = stats.maxValue {
      return Sensor.string(for: maxValue, units: nil, pointsAfterDecimal: pointsAfterDecimal)
    } else {
      // There should always be a max value but in case of a bug default to `-`.
      return "-"
    }
  }
}

/// View data for sensor stats.
struct DisplaySensorStats {
  let minValue: Double?
  let averageValue: Double?
  let maxValue: Double?
  let numberOfValues: Int?
  var totalDuration: Int64?
  var zoomPresenterTierCount: Int?
  var zoomLevelBetweenTiers: Int?
}
