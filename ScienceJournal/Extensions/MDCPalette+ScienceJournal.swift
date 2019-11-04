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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

extension MDCPalette {

  // MARK: - Experiment list card colors

  /// Color palette options for experiment list cards.
  static let experimentListCardColorPaletteOptions = [MDCPalette.deepPurple,
                                                      MDCPalette.blue,
                                                      MDCPalette.green,
                                                      MDCPalette.orange,
                                                      MDCPalette.red,
                                                      MDCPalette.grey]

  /// Returns the next experiment list card color palette that is least used.
  ///
  /// - Parameter usedPalettes: Color palettes that are already in use by experiment list cards.
  /// - Returns: The next experiment list card color palette to use.
  static func nextExperimentListCardColorPalette(
      withUsedPalettes usedPalettes: [MDCPalette]) -> MDCPalette {
    return nextColorPalette(from: experimentListCardColorPaletteOptions,
                            withUsedPalettes: usedPalettes)
  }

  // MARK: - Sensor card colors

  /// Color palette options for sensor cards.
  static let sensorCardColorPaletteOptions = [MDCPalette.blue,
                                              MDCPalette.green,
                                              MDCPalette.orange,
                                              MDCPalette.red,
                                              MDCPalette.grey]

  /// Returns the next sensor card color palette that is least used.
  ///
  /// - Parameter usedPalettes: Color palettes that are already in use by sensor cards.
  /// - Returns: The next sensor card color palette to use.
  static func nextSensorCardColorPalette(
      withUsedPalettes usedPalettes: [MDCPalette]) -> MDCPalette {
    return nextColorPalette(from: sensorCardColorPaletteOptions, withUsedPalettes: usedPalettes)
  }

  // MARK: - Private

  // Returns the color palette that is least used out of an array of colors. (Matches Android's code
  // for choosing card colors.)
  private static func nextColorPalette(from colorPalettes: [MDCPalette],
                                       withUsedPalettes usedPalettes: [MDCPalette]) -> MDCPalette {
    // Set up a dictionary for each palette to keep track of used count.
    var paletteIndexUsedCountDict = [Int : Int]()
    if !usedPalettes.isEmpty {
      for palette in usedPalettes {
        guard let index = colorPalettes.firstIndex(of: palette) else { continue }
        if paletteIndexUsedCountDict[index] == nil {
          paletteIndexUsedCountDict[index] = 1
        } else {
          paletteIndexUsedCountDict[index]! += 1
        }
      }
    }

    // Loop each palette, and if it is used fewer times than the current least used color, use it.
    // Each time around the loop increment the least used count threshold.
    var foundColor: MDCPalette?
    var leastUsed = 0
    while foundColor == nil {
      for palette in colorPalettes {
        guard let index = colorPalettes.firstIndex(of: palette),
            let paletteCount = paletteIndexUsedCountDict[index],
            paletteCount > leastUsed else {
          foundColor = palette
          break
        }
      }
      if foundColor == nil {
        leastUsed += 1
      } else {
        break
      }
    }
    return foundColor!
  }

}
