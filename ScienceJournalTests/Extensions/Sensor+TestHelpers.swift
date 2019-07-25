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

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

extension Sensor {

  /// Returns a sensor used for testing.
  ///
  /// - Parameters:
  ///   - sensorId: The sensor ID.
  ///   - name: The sensor name.
  ///   - textDescription: The text description of the sensor.
  ///   - iconName: The icon name for the sensor.
  ///   - unitDescription: The description of the sensor measurement unit. Optional.
  /// - Returns: The sensor.
  class func mock(sensorId: String,
                  name: String = "",
                  textDescription: String = "",
                  iconName: String = "",
                  unitDescription: String? = nil) -> Sensor {
    return Sensor(sensorId: sensorId,
                  name: name,
                  textDescription: textDescription,
                  iconName: iconName,
                  animatingIconView: SensorAnimationView(),
                  unitDescription: unitDescription,
                  learnMore: LearnMore(firstParagraph: "", secondParagraph: "", imageName: ""),
                  sensorTimer: UnifiedSensorTimer())
  }

}
