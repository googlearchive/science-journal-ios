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

import CoreData
import Foundation

/// A Science Journal sensor data model object that is stored in Core Data.
final class SensorData: NSManagedObject {
  /// The sensor tag of the sensor that this data was recored by.
  @NSManaged var sensor: String
  /// The timestamp this sensor data was recorded at.
  @NSManaged var timestamp: Int64
  /// The value of the sensor data.
  @NSManaged var value: Double
  /// The resolution tier of the data.
  @NSManaged var resolutionTier: Int16
  /// The ID of the trial this sensor data is associated with.
  @NSManaged var trialID: String

  /// Inserts a new sensor data object into Core Data.
  ///
  /// - Parameters:
  ///   - dataPoint: The data point to store.
  ///   - sensorID: The ID of the sensor the data was recorded by.
  ///   - trialID: The ID of the trial this data was recored for.
  ///   - resolutionTier: The resolution tier to which the data point belongs.
  ///   - context: The managed object context to perform the insert on. If nil it will use the main
  ///              context.
  @discardableResult static func insert(dataPoint: DataPoint,
                                        forSensorID sensorID: String,
                                        trialID: String,
                                        resolutionTier: Int16,
                                        context: NSManagedObjectContext) -> SensorData {
    let sensorData: SensorData = context.insertObject()
    sensorData.value = dataPoint.y
    sensorData.timestamp = dataPoint.x
    sensorData.sensor = sensorID
    sensorData.trialID = trialID
    sensorData.resolutionTier = resolutionTier
    return sensorData
  }

  /// Returns a fetch request for all sensor data with unique sensor IDs in a trial. If timestamps
  /// are given there must be both start and end timestamps, not just one.
  ///
  /// - Parameters:
  ///   - trialID: The trial ID.
  ///   - startTimestamp: The earliest timestamp to fetch.
  ///   - endTimestamp: The latest timestamp to fetch.
  /// - Returns: The fetch request.
  static func fetchRequest(withTrialID trialID: String,
                           startTimestamp: Int64? = nil,
                           endTimestamp: Int64? = nil) -> NSFetchRequest<SensorData> {
    let fetchRequest = sortedFetchRequest

    if let startTimestamp = startTimestamp, let endTimestamp = endTimestamp {
      let format = "trialID = %@ AND resolutionTier = 0 AND timestamp BETWEEN { %@, %@ }"
      fetchRequest.predicate = NSPredicate(format: format,
                                           argumentArray: [trialID, startTimestamp, endTimestamp])
    } else {
      fetchRequest.predicate = NSPredicate(format: "trialID = %@ AND resolutionTier = 0", trialID)
    }
    return fetchRequest
  }

  /// Returns a fetch request for all sensor data with unique sensor IDs in a trial, at all
  /// resolution tiers.
  ///
  /// - Parameter trialID: The trial ID.
  /// - Returns: The fetch request.
  static func fetchAllRequest(withTrialID trialID: String) -> NSFetchRequest<SensorData> {
    let fetchRequest = sortedFetchRequest
    fetchRequest.predicate = NSPredicate(format: "trialID = %@", trialID)
    return fetchRequest
  }

  /// Returns a fetch request for the count of all sensor data with unique sensor IDs in a trial, at
  /// all resolution tiers.
  ///
  /// - Parameter trialID: The trial ID.
  /// - Returns: The fetch request.
  static func countOfAllRequest(withTrialID trialID: String) -> NSFetchRequest<SensorData> {
    let fetchRequest = NSFetchRequest<SensorData>(entityName: entityName)
    fetchRequest.predicate = NSPredicate(format: "trialID = %@", trialID)
    fetchRequest.resultType = .countResultType
    return fetchRequest
  }

  /// Returns a fetch request for all data points for a sensor in a trial. If timestamps
  /// are given there must be both start and end timestamps, not just one.
  ///
  /// - Parameters:
  ///   - sensorID: The sensor ID.
  ///   - trialID: The trial ID.
  ///   - resolutionTier: The resolution tier to fetch, defaults to 0.
  ///   - startTimestamp: The earliest timestamp to fetch.
  ///   - endTimestamp: The latest timestamp to fetch.
  /// - Returns: The fetch request.
  static func fetchRequest(for sensorID: String,
                           trialID: String,
                           resolutionTier: Int = 0,
                           startTimestamp: Int64? = nil,
                           endTimestamp: Int64? = nil) -> NSFetchRequest<SensorData> {
    let fetchRequest = SensorData.sortedFetchRequest

    if let startTimestamp = startTimestamp, let endTimestamp = endTimestamp {
      let format =
          "sensor = %@ AND trialID = %@ AND resolutionTier = %@ AND timestamp BETWEEN { %@, %@ }"
      fetchRequest.predicate = NSPredicate(
          format: format,
          argumentArray: [sensorID, trialID, resolutionTier, startTimestamp, endTimestamp])
    } else {
      fetchRequest.predicate =
          NSPredicate(format: "sensor = %@ AND trialID = %@ AND resolutionTier = %d",
                      sensorID,
                      trialID,
                      resolutionTier)
    }
    return fetchRequest
  }

}

extension SensorData: Managed {
  static var entityName: String {
    return "SensorData"
  }

  static var defaultSortDescriptors: [NSSortDescriptor] {
    return [NSSortDescriptor(key: "timestamp", ascending: true)]
  }
}

extension Array where Element:SensorData {
  /// Returns an array, `[DataPoint]` (one for each `SensorData` object.
  var dataPoints: [DataPoint] {
    return map { DataPoint(x: $0.timestamp, y: $0.value) }
  }

}
