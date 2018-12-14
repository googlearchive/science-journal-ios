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

/// Stores data at multiple granularities. For each run of N*2 data points in tier X, there are 2
/// data points in tier X+1, and those are the max and min data points over that run.
///
/// This seems to allow us to capture the general shape of the graph better than trying to, for
/// example, synthesize an "average" data point for the run.
class ZoomRecorder {

  /// A block type called when the zoom recorder has a reading to add.
  ///
  /// - Paramters:
  ///   - dataPoint: A data point.
  ///   - sensorID: A sensor ID.
  ///   - trialID: A trial ID.
  ///   - tier: A resolution tier.
  typealias AddingDataPointBlock = (DataPoint, String, String, Int16) -> Void

  private let sensorID: String
  private let trialID: String
  private let bufferSize: Int
  private let addingDataPointBlock: AddingDataPointBlock
  private let tier: Int16
  private var seenThisPass = 0
  private var minDataPointSeen: DataPoint?
  private var maxDataPointSeen: DataPoint?
  private var nextTierUp: ZoomRecorder?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorID: The sensor ID for the recorded sensor.
  ///   - bufferSize: How many data points we can store before sending summary data points to
  ///                 the next tier up.
  ///   - addingDataPointBlock: A block called every time the zoom recorder wants to add a new
  ///                           data point.
  ///   - tier: The resolution tier. Should start at 1.
  init(sensorID: String,
       trialID: String,
       bufferSize: Int,
       addingDataPointBlock: @escaping AddingDataPointBlock,
       tier: Int16 = 1) {
    self.sensorID = sensorID
    self.trialID = trialID
    self.bufferSize = bufferSize
    self.addingDataPointBlock = addingDataPointBlock
    self.tier = tier
  }

  /// Adds a data point to the zoom recorder. Minimum and maximum data points for each buffer will
  /// be recorded for the current tier.
  ///
  /// - Parameter dataPoint: A data point.
  func addDataPoint(dataPoint: DataPoint) {
    seenThisPass += 1

    // Check for new max.
    if let maxDataPointSeen = maxDataPointSeen, dataPoint.y > maxDataPointSeen.y {
      self.maxDataPointSeen = dataPoint
    } else if maxDataPointSeen == nil {
      maxDataPointSeen = dataPoint
    }

    // Check for new min.
    if let minDataPointSeen = minDataPointSeen, dataPoint.y < minDataPointSeen.y {
      self.minDataPointSeen = dataPoint
    } else if minDataPointSeen == nil {
      minDataPointSeen = dataPoint
    }

    if seenThisPass == bufferSize {
      flush()
    }
  }

  /// Removes all data and all tiers.
  func flushAllTiers() {
    nextTierUp?.flushAllTiers()
    nextTierUp = nil
    flush()
  }

  /// The number of tiers above the reciever including this one.
  var tierCount: Int {
    if let nextTierUp = nextTierUp {
      return nextTierUp.tierCount
    }
    return Int(tier)
  }

  // MARK: - Private

  /// Adds readings for the current buffer and resets the buffer.
  private func flush() {
    guard seenThisPass > 0,
        let maxDataPointSeen = maxDataPointSeen,
        let minDataPointSeen = minDataPointSeen else {
      return
    }

    addReadingAtThisTier(minDataPointSeen)
    addReadingAtThisTier(maxDataPointSeen)
    resetBuffer()
  }

  /// Commits a data point to the database at the current tier.
  ///
  /// - Parameter dataPoint: A data point.
  private func addReadingAtThisTier(_ dataPoint: DataPoint) {
    addingDataPointBlock(dataPoint, sensorID, trialID, tier)
    getNextTierUp().addDataPoint(dataPoint: dataPoint)
  }

  /// Returns the zoom recorder for the next tier or creates it if it doesn't exist.
  private func getNextTierUp() -> ZoomRecorder {
    if let nextTierUp = nextTierUp {
      return nextTierUp
    }

    let nextTier = ZoomRecorder(sensorID: sensorID,
                                trialID: trialID,
                                bufferSize: bufferSize,
                                addingDataPointBlock: addingDataPointBlock,
                                tier: tier + 1)
    nextTierUp = nextTier
    return nextTier
  }

  private func resetBuffer() {
    seenThisPass = 0
    minDataPointSeen = nil
    maxDataPointSeen = nil
  }

}
