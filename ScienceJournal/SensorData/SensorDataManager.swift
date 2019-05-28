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

import CoreData
import Foundation

import third_party_sciencejournal_ios_ScienceJournalProtos

enum SensorDataManagerError: Error {
  /// Adding sensor data failed.
  case addingSensorDataFailed
}

// swiftlint:disable type_body_length file_length
/// The data manager for Core Data.
open class SensorDataManager {

  /// The store file for different configurations of this class.
  enum StoreFile {
    /// The account-specific store.
    case account

    /// The root store when not logged in.
    case root

    /// The name of the store file.
    var name: String {
      switch self {
      case .account:
        return "sensor_data.sqlite"
      case .root:
        return "ScienceJournal.sqlite"
      }
    }
  }

  /// Type alias for the tuple returned when fetching stats.
  typealias StatsTuple = (firstTimestamp: Int64, lastTimestamp: Int64, numberOfDataPoints: Int)?

  /// Notification name for when trial stats calculation completes.
  static let TrialStatsCalculationDidComplete =
      NSNotification.Name("TrialStatsCalculationDidComplete")

  /// Notification user info dictionary key for the ID string of the trial that calculated stats.
  static let TrialStatsDidCompleteTrialIDKey = "TrialStatsDidCompleteTrialIDKey"

  /// Notification user info dictionary key for the ID string of the experiment that owns a trial.
  static let TrialStatsDidCompleteExperimentIDKey = "TrialStatsDidCompleteExperimentIDKey"

  /// Notification user info dictionary key for an array of trial stats.
  static let TrialStatsDidCompleteTrialStatsKey = "TrialStatsDidCompleteTrialStatsKey"

  /// The managed object context associated with the main queue. Use this for fetching and inserting
  /// objects. `writerContext` is its parent and manages saving for it, so it doesn't cause a main
  /// thread pause.
  let mainContext: NSManagedObjectContext
  /// The managed object context associated with a private queue. It is the parent of the main
  /// context and performs operations in the background.
  let privateContext: NSManagedObjectContext

  /// The URL location of the SQLite store.
  let storeURL: URL

  let persistentStoreCoordinator: NSPersistentStoreCoordinator

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - rootURL: The URL at which to create the SQLite store file.
  ///   - store: The SQLite store file.
  init(rootURL: URL, store: StoreFile = .account) {
    self.storeURL = rootURL.appendingPathComponent(store.name)

    // Initialize the Core Data stack.
    // Managed object model.
    let modelURL = Bundle.currentBundle.url(forResource: "DataModel", withExtension: "momd")
    let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)

    // Persistent store coordinator.
    persistentStoreCoordinator =
        NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)

    // Managed object contexts.
    privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    privateContext.persistentStoreCoordinator = persistentStoreCoordinator
    mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    mainContext.parent = privateContext

    // Store the data model.
    // NOTE: Apple recommends adding the persistent store on a background queue. However, because
    // this app's Core Data scheme is relatively simple and it's only used for sensor data, this
    // does not take much time and only happens once. To simplify the design of the Core Data stack
    // initialization, this happens synchronously on the main thread.
    do {
      try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                        configurationName: nil,
                                                        at: storeURL,
                                                        options: nil)
    } catch let error {
      fatalError("[SensorDataManager] Error adding persistent store: \(error)")
    }
  }

  /// Saves changes made to managed objects on all contexts.
  func saveAllContexts() {
    saveMainContext(andWait: true)
    savePrivateContext()
  }

  /// Saves changes made to managed objects on the main context.
  ///
  /// - Parameter wait: Whether to wait for the save to finish or not.
  func saveMainContext(andWait wait: Bool = false) {
    let block = {
      guard self.mainContext.hasChanges else { return }
      do {
        try self.mainContext.save()
      } catch {
        self.mainContext.rollback()
        sjlog_error("Failed to save the main context: \(error)", category: .coreData)
      }
    }

    if wait {
      mainContext.performAndWait(block)
    } else {
      mainContext.perform(block)
    }
  }

  /// Saves changes made to managed objects on the private context.
  ///
  /// - Parameter wait: Whether to wait for the save to finish or not.
  func savePrivateContext(andWait wait: Bool = false) {
    let block = {
      guard self.privateContext.hasChanges else {
        return
      }

      do {
        try self.privateContext.save()
      } catch {
        self.privateContext.rollback()
        sjlog_error("Failed to save the private context: \(error)", category: .coreData)
      }
    }

    if wait {
      privateContext.performAndWait(block)
    } else {
      privateContext.perform(block)
    }
  }

  /// Removes all sensor data associated with a trial ID.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - completion: An optional closure called when the removal is finished.
  open func removeData(forTrialID trialID: String, completion: (() -> Void)? = nil) {
    removeData(forTrialID: trialID, isBlocking: false, completion: completion)
  }

  /// Removes all sensor data associated with a trial ID. Blocks the calling thread until it is
  /// complete.
  ///
  /// - Parameter trialID: A trial ID.
  open func removeDataAndWait(forTrialID trialID: String) {
    removeData(forTrialID: trialID, isBlocking: true)
  }

  private func removeData(forTrialID trialID: String,
                          isBlocking: Bool,
                          completion: (() -> Void)? = nil) {
    let remove = {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: SensorData.entityName)
      fetchRequest.predicate = NSPredicate(format: "trialID = %@", trialID)
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

      do {
        try self.privateContext.execute(deleteRequest)
      } catch {
        sjlog_error("Error batch deleting sensor data for trial ID \(trialID): " +
                        error.localizedDescription,
                    category: .coreData)
      }
      completion?()
    }

    if isBlocking {
      privateContext.performAndWait(remove)
    } else {
      privateContext.perform(remove)
    }
  }

  /// Calls perform(_ block:) on the main context, calls the block supplied as an argument, and
  /// saves the context if specified. The call to perform makes sure we’re on the correct queue to
  /// access the context and its managed objects.
  ///
  /// - Parameters:
  ///   - wait: Whether or not to wait to finish before continuing execution.
  ///   - save: Whether or not to save after performing the block.
  ///   - block: The block to perform.
  func performChanges(andWait wait: Bool = false,
                      save: Bool = false,
                      block: @escaping () -> Void) {
    let changes = {
      block()
      if save {
        self.saveMainContext(andWait: true)
      }
    }

    if wait {
      mainContext.performAndWait(changes)
    } else {
      mainContext.perform(changes)
    }
  }

  /// Adds a sensor data point to the database.
  ///
  /// - Parameters:
  ///   - dataPoint: A data point.
  ///   - sensorID: A sensor ID.
  ///   - trialID: A trial ID.
  ///   - resolutionTier: The resolution tier the data point belongs to.
  func addSensorDataPoint(_ dataPoint: DataPoint,
                          sensorID: String,
                          trialID: String,
                          resolutionTier: Int16 = 0) {
    privateContext.perform {
      SensorData.insert(dataPoint: dataPoint,
                        forSensorID: sensorID,
                        trialID: trialID,
                        resolutionTier: resolutionTier,
                        context: self.privateContext)
    }
  }

  /// Fetches sensor data for one sensor in a trial.
  ///
  /// - Parameters:
  ///   - sensorID: A sensor ID.
  ///   - trialID: A trial ID.
  ///   - completion: A completion block called when the fetch is complete with an optional array
  ///                 of data points. The closure is called on the private context's queue.
  func fetchSensorData(forSensorID sensorID: String,
                       trialID: String,
                       resolutionTier: Int = 0,
                       startTimestamp: Int64? = nil,
                       endTimestamp: Int64? = nil,
                       completion: @escaping ([DataPoint]?) -> Void) {
    privateContext.perform {
      let fetchRequest = SensorData.fetchRequest(for: sensorID,
                                                 trialID: trialID,
                                                 resolutionTier: resolutionTier,
                                                 startTimestamp: startTimestamp,
                                                 endTimestamp: endTimestamp)
      let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest,
                                                    completionBlock: { (result) in
          completion(result.finalResult?.dataPoints)
      })
      do {
        try self.privateContext.execute(asyncRequest)
      } catch {
        sjlog_error("Error fetching sensor data for sensor: \(sensorID), " +
                        "trialID: \(trialID). \(error)",
                    category: .coreData)
        completion(nil)
      }
    }
  }

  /// Fetches all sensor data for a trial. If timestamps are given there must be both start and
  /// end timestamps, not just one.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - startTimestamp: The earliest timestamp to fetch.
  ///   - endTimestamp: The latest timestamp to fetch.
  ///   - completion: A completion block called when the fetch is complete with an optional array
  ///                 of sensor data. The closure is called on the private context's queue.
  func fetchSensorData(forTrialID trialID: String,
                       startTimestamp: Int64? = nil,
                       endTimestamp: Int64? = nil,
                       completion: @escaping ([SensorData]?) -> Void) {
    privateContext.perform {
      let fetchRequest = SensorData.fetchRequest(withTrialID: trialID,
                                                 startTimestamp: startTimestamp,
                                                 endTimestamp: endTimestamp)
      do {
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest,
                                                      completionBlock: { (result) in
          completion(result.finalResult)
        })
        try self.privateContext.execute(asyncRequest)
      } catch {
        sjlog_error("Error fetching sensor data for trialID: \(trialID), \(error)",
                    category: .coreData)
        completion(nil)
      }
    }
  }

  /// Fetches all sensor data for a trial, at all resolution tiers.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - completion: A completion block called when the fetch is complete with an optional array
  ///                 of sensor data and the context on which the data was fetched. The closure is
  ///                 called on a private context queue.
  func fetchAllSensorData(forTrialID trialID: String,
                          completion: @escaping ([SensorData]?, NSManagedObjectContext) -> Void) {
    performOnBackgroundContext { (context) in
      let fetchRequest = SensorData.fetchAllRequest(withTrialID: trialID)
      do {
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest,
                                                      completionBlock: { (result) in
          completion(result.finalResult, context)
        })
        try context.execute(asyncRequest)
      } catch {
        sjlog_error("Error fetching all sensor data for trialID: \(trialID), \(error)",
                    category: .coreData)
        completion(nil, context)
      }
    }
  }

  /// Gets the count of all sensor data for a trial, at all resolution tiers.
  ///
  /// - Parameters:
  ///   - trialID: A trial ID.
  ///   - completion: A completion block called with the count.
  func countOfAllSensorData(forTrialID trialID: String,
                            completion: @escaping (Int?) -> Void) {
    privateContext.perform {
      let fetchRequest = SensorData.countOfAllRequest(withTrialID: trialID)
      do {
        let count = try self.privateContext.count(for: fetchRequest)
        completion(count)
      } catch {
        sjlog_error("Error getting the count of all sensor data for trialID: \(trialID), \(error)",
                    category: .coreData)
        completion(nil)
      }
    }
  }

  /// Recalculates stats for the given trial. When complete a notification is posted so views
  /// and data sources can update. Handled by SensorDataManager because it will stay in memory.
  ///
  /// - Parameters:
  ///   - trial: A trial.
  ///   - experimentID: The ID of the experiment the trial belongs to.
  func recalculateStatsForTrial(_ trial: Trial, experimentID: String) {
    let range = trial.cropRange ?? trial.recordingRange
    fetchSensorData(forTrialID: trial.ID,
                    startTimestamp: range.min,
                    endTimestamp: range.max) { (sensorData) in
      guard let sensorData = sensorData else {
        // Fetch failed to return any data. Programmer error should be the only cause of this case.
        return
      }

      let statsAdjuster = TrialStatsAdjuster(trial: trial, sensorData: sensorData)
      statsAdjuster.recalculateStats { trialStats in
        trial.trialStats = trialStats
        trial.trialStats.forEach { $0.status = .valid }
        let userInfo: [String: Any] =
            [SensorDataManager.TrialStatsDidCompleteTrialIDKey: trial.ID,
             SensorDataManager.TrialStatsDidCompleteExperimentIDKey: experimentID,
             SensorDataManager.TrialStatsDidCompleteTrialStatsKey: trialStats]
        NotificationCenter.default.post(name: SensorDataManager.TrialStatsCalculationDidComplete,
                                        object: self,
                                        userInfo: userInfo)
      }
    }
  }

  /// Imports sensor data from a sensor data proto.
  ///
  /// - Parameters:
  ///   - sensorData: A sensor data proto.
  ///   - trialIDMap: An optional dictionary that maps IDs found in the sensor data (the keys) to
  ///                 the new trial IDs (the values).
  ///   - completion: A block that is called when the operation completes, with the IDs of the
  ///                 trials the sensor data is imported for.
  func importSensorData(_ sensorData: GSJScalarSensorData,
                        withTrialIDMap trialIDMap: [String: String]?,
                        completion: @escaping ([String]) -> Void) {
    performOnBackgroundContext { (context) in
      var trialIDs = Set<String>()
      for case let sensorDump as GSJScalarSensorDataDump in sensorData.sensorsArray {
        guard let trialID = trialIDMap?[sensorDump.trialId] ?? sensorDump.trialId else {
          // Invalid trial ID, skip to the next row.
          continue
        }

        // Convert the untyped NSMutableArray into a typed Swift array.
        guard let sensorRows = sensorDump.rowsArray as? [GSJScalarSensorDataRow] else {
          sjlog_error("Imported sensor data has unknown type.", category: .general)
          break
        }

        trialIDs.insert(trialID)
        let zoomRecorder = ZoomRecorder(
            sensorID: sensorDump.tag,
            trialID: trialID,
            bufferSize: Recorder.zoomBufferSize, addingDataPointBlock: {
                (dataPoint, sensorID, trialID, tier) in
              SensorData.insert(dataPoint: dataPoint,
                                forSensorID: sensorID,
                                trialID: trialID,
                                resolutionTier: tier,
                                context: context)
        })

        // Use an autorelease pool and chunk the imported data to control memory usage.
        autoreleasepool {
          let sensorRowChunks = sensorRows.chunks(ofSize: 1000)

          for sensorRowChunk in sensorRowChunks {
            for sensorRow in sensorRowChunk {
              let dataPoint = DataPoint(x: sensorRow.timestampMillis, y: sensorRow.value)
              SensorData.insert(dataPoint: dataPoint,
                                forSensorID: sensorDump.tag,
                                trialID: trialID,
                                resolutionTier: 0,
                                context: context)
              zoomRecorder.addDataPoint(dataPoint: dataPoint)
            }

            do {
              try context.save()
            } catch {
              let errorMessage = error.localizedDescription
              sjlog_error("Failed to save context when importing data points: \(errorMessage)",
                          category: .coreData)
            }

            // Calling reset will clear the inserted objects from memory. This is necessary due to
            // the potentially high volume of sensor data rows in a sensor recording.
            context.reset()
          }
        }
      }
      completion(Array(trialIDs))
    }
  }

  /// Adds sensor data points to the database.
  ///
  /// - Parameters:
  ///   - sensorData: The sensor data.
  ///   - completion: Called when complete.
  func addSensorDataPoints(_ sensorData: [SensorData],
                           completion: @escaping (Result<Int, SensorDataManagerError>) -> Void) {
    let sensorDataPoints = sensorData.map { SensorDataPoint(sensorData: $0) }
    performOnBackgroundContext { (context) in
      autoreleasepool {
        let sensorDataChunks = sensorDataPoints.chunks(ofSize: 1000)
        for sensorDataChunk in sensorDataChunks {
          for sensorDataPoint in sensorDataChunk {
            SensorData.insert(dataPoint: sensorDataPoint.dataPoint,
                              forSensorID: sensorDataPoint.sensorID,
                              trialID: sensorDataPoint.trialID,
                              resolutionTier: sensorDataPoint.resolutionTier,
                              context: context)
          }

          do {
            try context.save()
          } catch {
            let errorMessage = error.localizedDescription
            sjlog_error("Failed to save context when adding data points: \(errorMessage)",
                        category: .coreData)
            completion(.failure(.addingSensorDataFailed))
            return
          }
          context.reset()
        }
      }
      completion(.success(sensorData.count))
    }
  }

  /// Returns a subset of stats for a recording. The stats returned (first timestamp,
  /// last timestamp, and number of data points) are the ones required for a migration to fill in
  /// missing stats. See MetadataManager.upgradeExperimentStatsForiOSPlatform705.
  ///
  /// - Parameters:
  ///   - sensorID: A sensor ID.
  ///   - trialID: A trial ID.
  /// - Returns: A tuple containing the first timestamp, last timestamp, and number of data points.
  func statsForRecording(withSensorID sensorID: String, trialID: String) -> StatsTuple {
    var stats: StatsTuple
    privateContext.performAndWait {
      let fetchRequest = NSFetchRequest<NSDictionary>(entityName: SensorData.entityName)
      // Setting the result type to dictionary allows returning values like count that are not
      // sensor data objects.
      fetchRequest.resultType = .dictionaryResultType

      let firstTimestampKey = "firstTimestamp"
      let lastTimestampKey = "lastTimestamp"
      let numberOfDataPointsKey = "numberOfDataPoints"

      let timestampExpression = NSExpression(forKeyPath: "timestamp")
      let firstTimestampExpression = NSExpression(forFunction: "min:",
                                                  arguments: [timestampExpression])
      let firstTimestampExpressionDescription = NSExpressionDescription()
      firstTimestampExpressionDescription.name = firstTimestampKey
      firstTimestampExpressionDescription.expression = firstTimestampExpression
      firstTimestampExpressionDescription.expressionResultType = .integer64AttributeType

      let lastTimestampExpression = NSExpression(forFunction: "max:",
                                                 arguments: [timestampExpression])
      let lastTimestampExpressionDescription = NSExpressionDescription()
      lastTimestampExpressionDescription.name = lastTimestampKey
      lastTimestampExpressionDescription.expression = lastTimestampExpression
      lastTimestampExpressionDescription.expressionResultType = .integer64AttributeType

      let countExpression = NSExpression(forFunction: "count:", arguments: [timestampExpression])
      let countExpressionDescription = NSExpressionDescription()
      countExpressionDescription.name = numberOfDataPointsKey
      countExpressionDescription.expression = countExpression
      countExpressionDescription.expressionResultType = .integer32AttributeType

      fetchRequest.propertiesToFetch = [
        firstTimestampExpressionDescription,
        lastTimestampExpressionDescription,
        countExpressionDescription
      ]

      // Limit query to just one recording.
      fetchRequest.predicate =
          NSPredicate(format: "sensor = %@ AND trialID = %@ AND resolutionTier = 0",
                      argumentArray: [sensorID, trialID])

      let results = try? self.privateContext.fetch(fetchRequest)
      if let dictionary = results?.first,
          let firstTimestamp = dictionary[firstTimestampKey] as? Int64,
          let lastTimestamp = dictionary[lastTimestampKey] as? Int64,
          let numberOfDataPoints = dictionary[numberOfDataPointsKey] as? Int {
        stats = (firstTimestamp, lastTimestamp, numberOfDataPoints)
      }
    }
    return stats
  }

  /// Returns the max available tier for a recording.
  ///
  /// - Parameters:
  ///   - sensorID: A sensor ID.
  ///   - trialID: A trial ID.
  /// - Returns: The max available tier.
  func maxTierForRecording(withSensorID sensorID: String, trialID: String) -> Int? {
    var maxTier: Int?
    privateContext.performAndWait {
      let fetchRequest = NSFetchRequest<NSDictionary>(entityName: SensorData.entityName)
      // Setting the result type to dictionary allows returning values like count that are not
      // sensor data objects.
      fetchRequest.resultType = .dictionaryResultType

      let maxResolutionTierKey = "maxResolutionTier"

      let resolutionTierExpression = NSExpression(forKeyPath: "resolutionTier")
      let maxTierExpression = NSExpression(forFunction: "max:",
                                           arguments: [resolutionTierExpression])
      let maxTierExpressionDescription = NSExpressionDescription()
      maxTierExpressionDescription.name = maxResolutionTierKey
      maxTierExpressionDescription.expression = maxTierExpression
      maxTierExpressionDescription.expressionResultType = .integer32AttributeType

      fetchRequest.propertiesToFetch = [maxTierExpressionDescription]

      // Limit query to just one recording.
      fetchRequest.predicate =
          NSPredicate(format: "sensor = %@ AND trialID = %@", argumentArray: [sensorID, trialID])

      let results = try? self.privateContext.fetch(fetchRequest)
      if let dictionary = results?.first,
          let maxResolutionTier = dictionary[maxResolutionTierKey] as? Int {
        maxTier = maxResolutionTier
      }
    }
    return maxTier
  }

  /// Removes the persistent store, allowing the DB file to safely be removed from disk.
  func removeStore() {
    privateContext.persistentStoreCoordinator?.performAndWait {
      do {
        try privateContext.persistentStoreCoordinator?.destroyPersistentStore(
            at: storeURL, ofType: NSSQLiteStoreType, options: nil)
      } catch {
        sjlog_error("Failed to destroy the persistent store: \(error)", category: .coreData)
      }
    }
  }

  /// Whether sensor data exists for each trial in an experiment.
  ///
  /// - Parameters:
  ///   - experiment: An experiment.
  ///   - completion: Called with whether sensor data exists.
  func sensorDataExists(forExperiment experiment: Experiment,
                        completion: @escaping (Bool) -> Void) {
    func sensorDataExists(forTrialID trialID: String, completion: @escaping (Bool) -> Void) {
      countOfAllSensorData(forTrialID: trialID) { (count) in
        guard let count = count else {
          completion(false)
          return
        }

        completion(count > 0)
      }
    }

    let dispatchGroup = DispatchGroup()
    let trialIDs = experiment.trials.map { $0.ID }
    var dataExists = true
    for trialID in trialIDs {
      dispatchGroup.enter()
      sensorDataExists(forTrialID: trialID) { (exists) in
        if !exists {
          dataExists = false
        }
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(qos: .userInitiated, queue: .main) {
      completion(dataExists)
    }
  }

  // MARK: - Private

  /// Performs a given block on a new private context.
  ///
  /// - Parameter block: A block to perform with a reference to the managed object context.
  private func performOnBackgroundContext(block: @escaping (NSManagedObjectContext) -> Void) {
    let importContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    importContext.persistentStoreCoordinator = persistentStoreCoordinator
    importContext.perform {
      block(importContext)
    }
  }

  // MARK: - SensorDataPoint

  /// A data object used to allow sensor data to be portable between managed object contexts.
  private struct SensorDataPoint {
    let dataPoint: DataPoint
    let sensorID: String
    let trialID: String
    let resolutionTier: Int16

    init(sensorData: SensorData) {
      dataPoint = DataPoint(x: sensorData.timestamp, y: sensorData.value)
      sensorID = sensorData.sensor
      trialID = sensorData.trialID
      resolutionTier = sensorData.resolutionTier
    }
  }

}
// swiftlint:enable type_body_length file_length
