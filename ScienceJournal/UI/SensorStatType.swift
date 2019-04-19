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

/// Enum for the different sensor stat types, to establish titles and colors.
enum SensorStatType {
  /// The stat type for the minimum value.
  case min
  /// The stat type for the average value.
  case average
  /// The stat type for the maximum value.
  case max

  /// The title for the stat type.
  var title: String {
    switch self {
    case .min: return String.statMin
    case .average: return String.statAverage
    case .max: return String.statMax
    }
  }

  /// The text color for the stat type.
  var textColor: UIColor {
    switch self {
    case .min, .max: return MDCPalette.green.tint600
    case .average: return MDCPalette.grey.tint600
    }
  }
}
