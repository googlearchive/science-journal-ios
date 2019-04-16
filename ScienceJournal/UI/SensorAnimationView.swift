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

/// Animation view for sensor icons.
class SensorAnimationView: UIView {

  /// Sets the value which is translated into an appropriate image index. Minimum and maximum are
  /// used by some views to determine scale.
  ///
  /// - Parameters:
  ///   - value: A sensor value.
  ///   - minValue: A minimum used to scale the value.
  ///   - maxValue: A maximum used to scale the value.
  func setValue(_ value: Double, minValue: Double, maxValue: Double) {
    // Subclasses should override.
  }

  /// Resets the view.
  func reset() {
    // Subclasses should reset its views.
  }

}
