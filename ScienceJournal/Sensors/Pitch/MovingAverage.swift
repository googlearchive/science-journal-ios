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

/// Computes a moving average using a circular buffer.
final class MovingAverage {

  private let bufferSize: Int
  private var buffer: [Double]
  private var sum = 0.0
  private var size = 0
  private var next = 0

  /// Initializer with configurable buffer size.
  init (size: Int) {
    bufferSize = size
    buffer = [Double](repeating: 0.0, count: size)
  }

  /// Reset the moving average.
  func clear() {
    sum = 0
    size = 0
    next = 0
  }

  /// Inserts value and then returns the current moving average.
  func insertAndReturnAverage(_ n: Double) -> Double {
    if (size == bufferSize) {
      let removed = buffer[next]
      sum = sum - removed
    }
    buffer[next] = n
    sum += n
    next = (next + 1) % bufferSize
    if (size < bufferSize) {
      size = size + 1
    }
    return sum / Double(size)
  }

}
