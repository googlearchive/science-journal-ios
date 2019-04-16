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

/// Writes trial sensor data to a CSV file.
class TrialDataWriter {

  private let csvWriter: CSVWriter
  private var currentRow: Row?
  private let sensorIDs: [String]
  private let trialID: String
  private let isRelativeTime: Bool
  private let trialRange: ChartAxis<Int64>
  private var firstTimeStampWritten: Int64?
  private let sensorDataManager: SensorDataManager

  /// The file URL of the CSV file.
  var fileURL: URL {
    return csvWriter.fileURL
  }

  /// Designated initializer. Returns nil if there is a problem creating a valid file.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - filename: A filename for the CSV file.
  ///   - isRelativeTime: True if output timestamps should be relative to the trial start,
  ///                     otherwise false.
  ///   - sensorIDs: The IDs of the sensors to include.
  ///   - range: The range of timestamps to export.
  ///   - sensorDataManager: The sensor data manager.
  init?(trialID: String,
        filename: String,
        isRelativeTime: Bool,
        sensorIDs: [String],
        range: ChartAxis<Int64>,
        sensorDataManager: SensorDataManager) {
    self.trialID = trialID
    self.isRelativeTime = isRelativeTime
    self.sensorIDs = sensorIDs
    self.trialRange = range
    self.sensorDataManager = sensorDataManager
    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    let fileURL = tempDirectory.appendingPathComponent(filename)
    var titles = sensorIDs
    titles.insert(isRelativeTime ? "relative_time" : "timestamp", at: 0)
    if let writer = CSVWriter(fileURL: fileURL, columnTitles: titles) {
      csvWriter = writer
    } else {
      return nil
    }
  }

  /// Begins the writing to disk. Calls completion when writing is complete.
  ///
  /// - Parameters:
  ///   - progress: A block called with a progress value between 0 and 1. Called on the main queue.
  ///   - completion: Called when writing is complete with a Bool parameter indicating
  ///                 success or failure. Called on the main queue.
  func write(progress: @escaping (Double) -> Void, completion: @escaping (Bool) -> Void) {
    sensorDataManager.fetchSensorData(forTrialID: trialID,
                                      startTimestamp: trialRange.min,
                                      endTimestamp: trialRange.max,
                                      completion: { (sensorData) in
        if let sensorData = sensorData {
          for data in sensorData {
            self.addSensorData(data)
            DispatchQueue.main.async {
              progress(Double(data.timestamp - self.trialRange.min) /
                  Double(self.trialRange.length))
            }
          }
          self.finish()
          DispatchQueue.main.async { completion(true) }
        } else {
          DispatchQueue.main.async { completion(false) }
        }
    })
  }

  // MARK: - Private

  /// Adds sensor data to the output file.
  ///
  /// - Parameter sensorData: A sensor data reading.
  private func addSensorData(_ sensorData: SensorData) {
    // Ignore sensor data that is not for one of the exported sensor IDs.
    guard sensorIDs.contains(sensorData.sensor) else {
      return
    }

    var timestamp: Int64
    if isRelativeTime {
      // If the timestamps are relative,
      if let firstTimeStampWritten = firstTimeStampWritten {
        timestamp = sensorData.timestamp - firstTimeStampWritten
      } else {
        timestamp = 0
        self.firstTimeStampWritten = sensorData.timestamp
      }
    } else {
      timestamp = sensorData.timestamp
    }
    if timestamp != currentRow?.timestamp {
      writeRow()
    }

    // If timestamp matches current row, add to it, otherwise create a new row.
    var row: Row
    if let currentRow = currentRow {
      row = currentRow
    } else {
      row = Row(timestamp: timestamp)
    }

    row.addValue(sensorData.value, for: sensorData.sensor)
    currentRow = row
  }

  /// Writes any pending rows to the CSV file. Must be called to ensure all data is exported.
  private func finish() {
    writeRow()
    csvWriter.finish()
  }

  /// Writes the current row to the CSV file.
  private func writeRow() {
    guard let currentRow = currentRow else { return }

    // First column is timestamp.
    var values = [String(currentRow.timestamp)]

    // Then append sensor columns.
    values.append(contentsOf: sensorIDs.map { (sensorID) in
      if let value = currentRow.values[sensorID] {
        return String(value)
      } else {
        return ""
      }
    })
    csvWriter.addValues(values)

    // Clear current row once it has been written.
    self.currentRow = nil
  }

  // MARK: - Sub types

  /// Represents one row of trial sensor data.
  struct Row {
    var timestamp: Int64
    var values: [String: Double]

    init(timestamp: Int64) {
      self.timestamp = timestamp
      self.values = [:]
    }

    mutating func addValue(_ value: Double, for sensorID: String) {
      values[sensorID] = value
    }
  }

}
