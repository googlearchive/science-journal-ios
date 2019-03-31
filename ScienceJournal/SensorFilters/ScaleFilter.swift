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

import ScienceJournalProtos

/// Filter that applies a linear function to the incoming value.
class ScaleFilter: ValueFilter {

  let sourceBottom: Double
  let destinationBottom: Double
  let sourceRange: Double
  let destinationRange: Double

  init(transform: GSJBleSensorConfig_ScaleTransform) {
    sourceBottom = transform.sourceBottom
    sourceRange = transform.sourceTop - sourceBottom
    destinationBottom = transform.destBottom
    destinationRange = transform.destTop - destinationBottom
  }

  func filterValue(timestamp: Int64, value: Double) -> Double {
    let ratio = (value - sourceBottom) / sourceRange
    return (ratio * destinationRange) + destinationBottom
  }

}
