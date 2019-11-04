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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJExperimentLibrary. Represents one experiment library.
public class ExperimentLibrary: CustomDebugStringConvertible {

  /// The Drive file ID of the "Science Journal" folder that contains experiments.
  public var folderID: String?

  /// The overall collection of Experiments known to the user.
  public var syncExperiments: [SyncExperiment]

  /// A proto representation of an experiment library.
  public var proto: GSJExperimentLibrary {
    let proto = GSJExperimentLibrary()
    proto.folderId = folderID
    proto.syncExperimentArray = NSMutableArray(array: syncExperiments.map { $0.proto })
    return proto
  }

  /// Whether the experiment library has any local changes. Defaults to true to assume there could
  /// be changes.
  public var isDirty = true

  private let syncExperimentsQueue =
      DispatchQueue(label: "com.google.ScienceJournal.ExperimentLibrary")

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: A `GSJExperimentLibrary` proto.
  ///   - clock: A clock.
  public init(proto: GSJExperimentLibrary, clock: Clock = Clock()) {
    self.clock = clock
    folderID = proto.hasFolderId ? proto.folderId : nil
    // swiftlint:disable force_cast
    syncExperiments =
        proto.syncExperimentArray.map { SyncExperiment(proto: $0 as! GSJSyncExperiment) }
    // swiftlint:enable force_cast
  }

  /// The clock used for modified and opened dates.
  private let clock: Clock

  /// Convenience initializer. Initializes with an empty proto and optional local overviews.
  ///
  /// - Parameters:
  ///   - localExperimentOverviews: An array of experiment overviews.
  ///   - clock: A clock.
  public convenience init(localExperimentOverviews: [ExperimentOverview] = [],
                          clock: Clock = Clock()) {
    self.init(proto: GSJExperimentLibrary(), clock: clock)
    for overview in localExperimentOverviews {
      let experimentID = overview.experimentID
      addExperiment(withID: experimentID)
      setExperimentDeleted(false, experimentID: experimentID)
      setExperimentArchived(overview.isArchived, experimentID: experimentID)
      setExperimentLastOpened(atTimestamp: overview.lastUsedDate.millisecondsSince1970,
                              experimentID: experimentID)
      setExperimentLastModified(atTimestamp: overview.lastUsedDate.millisecondsSince1970,
                                withExperimentID: experimentID)
    }
  }

  /// Whether the experiment is in the experiment library.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: True if the experiment exists, otherwise false.
  public func hasExperiment(withID experimentID: String) -> Bool {
    return syncExperiments.firstIndex(where: { $0.experimentID == experimentID }) != nil
  }

  /// Sets the Drive file ID for an experiment.
  ///
  /// - Parameters:
  ///   - fileID: A Drive file ID.
  ///   - experimentID: An experiment ID.
  public func setFileID(_ fileID: String, forExperimentID experimentID: String) {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return
    }
    isDirty = true
    experiment.fileID = fileID
  }

  /// Returns the Drive file ID, if it exists, for the given experiment ID.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: A Drive file ID.
  public func fileID(forExperimentID experimentID: String) -> String? {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return nil
    }
    return experiment.fileID
  }

  /// Whether the experiment has a Drive file ID.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: True if the experiment has a Drive file ID, otherwise false.
  public func hasFileIDForExperiment(withID experimentID: String) -> Bool {
    return fileID(forExperimentID: experimentID) != nil
  }

  /// Adds an experiment to the experiment library if it doesn't already exist.
  ///
  /// - Parameters:
  ///   - experimentID: The experiment ID.
  ///   - fileID: The Drive file ID.
  ///   - isArchived: Whether the experiment is archived.
  ///   - lastModifiedTimestamp: The last modified timestamp for the experiment.
  public func addExperiment(withID experimentID: String,
                            fileID: String? = nil,
                            isArchived: Bool = false,
                            lastModifiedTimestamp: Int64? = nil) {
    syncExperimentsQueue.sync {
      guard !hasExperiment(withID: experimentID) else {
        return
      }
      isDirty = true
      let experiment = SyncExperiment(experimentID: experimentID, fileID: fileID, clock: clock)
      if let lastModifiedTimestamp = lastModifiedTimestamp {
        experiment.lastModifiedTimestamp = lastModifiedTimestamp
      }
      experiment.isArchived = isArchived
      syncExperiments.append(experiment)
    }
  }

  /// Adds an experiment to the experiment library if it doesn't already exist.
  ///
  /// - Parameter syncExperiment: A sync experiment.
  func addExperiment(_ syncExperiment: SyncExperiment) {
    isDirty = true
    let addedSyncExperiment = SyncExperiment(experimentID: syncExperiment.experimentID,
                                             fileID: syncExperiment.fileID,
                                             clock: clock)
    addedSyncExperiment.lastOpenedTimestamp = syncExperiment.lastOpenedTimestamp
    addedSyncExperiment.lastModifiedTimestamp = syncExperiment.lastModifiedTimestamp
    addedSyncExperiment.isDeleted = syncExperiment.isDeleted
    addedSyncExperiment.isArchived = syncExperiment.isArchived
    syncExperiments.append(addedSyncExperiment)
  }

  /// Sets an experiment's archived state.
  ///
  /// - Parameters:
  ///   - isArchived: Whether the experiment is archived.
  ///   - experimentID: The experiment ID.
  public func setExperimentArchived(_ isArchived: Bool, experimentID: String) {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return
    }
    isDirty = true
    experiment.isArchived = isArchived
  }

  /// Returns the archived state of an experiment.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: True if the experiment is archived, otherwise false.
  public func isExperimentArchived(withID experimentID: String) -> Bool? {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return nil
    }
    return experiment.isArchived
  }

  /// Sets an experiment's deleted state.
  ///
  /// - Parameters:
  ///   - isDeleted: Whether the experiment is deleted.
  ///   - experimentID: The experiment ID.
  public func setExperimentDeleted(_ isDeleted: Bool, experimentID: String) {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return
    }
    isDirty = true
    experiment.isDeleted = isDeleted
  }

  /// Returns the deleted state of an experiment.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: True if the experiment is deleted, otherwise false.
  public func isExperimentDeleted(withID experimentID: String) -> Bool? {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return nil
    }
    return experiment.isDeleted
  }

  /// Sets an experiment's last opened timestamp to now.
  ///
  /// - Parameter experimentID: The experiment ID.
  public func setExperimentOpened(withExperimentID experimentID: String) {
    setExperimentLastOpened(atTimestamp: clock.millisecondsSince1970, experimentID: experimentID)
  }

  /// Sets an experiment's last opened timestamp.
  ///
  /// - Parameters:
  ///   - lastOpenedTimestamp: The last opened timestamp.
  ///   - experimentID: The experiment ID.
  public func setExperimentLastOpened(atTimestamp lastOpenedTimestamp: Int64,
                                      experimentID: String) {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return
    }
    isDirty = true
    experiment.lastOpenedTimestamp = lastOpenedTimestamp
  }

  /// Returns an experiment's last opened timestamp.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: The experiment's last opened timestamp.
  public func experimentLastOpened(withID experimentID: String) -> Int64? {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return nil
    }
    return experiment.lastOpenedTimestamp
  }

  /// Sets an experiment's last modified timestamp to now.
  ///
  /// - Parameter experimentID: The experiment ID.
  public func setExperimentModified(withExperimentID experimentID: String) {
    setExperimentLastModified(atTimestamp: clock.millisecondsSince1970,
                              withExperimentID: experimentID)
  }

  /// Sets an experiment's last modified timestamp.
  ///
  /// - Parameters:
  ///   - lastModifiedTimestamp: The last modified timestamp.
  ///   - experimentID: The experiment ID.
  public func setExperimentLastModified(atTimestamp lastModifiedTimestamp: Int64,
                                        withExperimentID experimentID: String) {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return
    }
    isDirty = true
    experiment.lastModifiedTimestamp = lastModifiedTimestamp
  }

  /// Returns an experiment's last modified timestamp.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: The experiment's last modified timestamp.
  public func experimentLastModified(withID experimentID: String) -> Int64? {
    guard let experiment = syncExperiment(forID: experimentID) else {
      return nil
    }
    return experiment.lastModifiedTimestamp
  }

  func syncExperiment(forID experimentID: String) -> SyncExperiment? {
    var syncExperiment: SyncExperiment?
    syncExperimentsQueue.sync {
      syncExperiment = syncExperiments.first(where: { $0.experimentID == experimentID })
    }
    return syncExperiment
  }

  public var debugDescription: String {
    var description = "{\n"
    for experiment in syncExperiments {
      let ID = experiment.experimentID
      let fileID = experiment.fileID ?? "nil"
      let deleted = experiment.isDeleted ? "deleted" : "not deleted"
      let archived = experiment.isArchived ? "archived" : "not archived"
      description += "\t\(ID) - \(deleted) - \(archived) - fileID: \(fileID)\n"
    }
    description += "}"
    return description
  }

}

/// A wrapper for GSJSyncExperiment. Represents one experiment's sync state.
public class SyncExperiment {

  /// The Drive fileId.
  public var fileID: String?

  /// The experimentId from the experiment.
  public let experimentID: String

  /// The timestamp of the last time the experiment was opened.
  var lastOpenedTimestamp: Int64

  /// The timestamp of the last time the experiment was modified.
  var lastModifiedTimestamp: Int64

  /// The date of the last time the experiment was modified.
  public var lastModifiedDate: Date {
    return Date(milliseconds: lastModifiedTimestamp)
  }

  /// Whether the experiment has been deleted.
  public var isDeleted: Bool

  /// Whether the experiment has been archived.
  public var isArchived: Bool

  /// A proto representation of a sync experiment.
  var proto: GSJSyncExperiment {
    backingProto.fileId = fileID
    backingProto.experimentId = experimentID
    backingProto.lastOpened = lastOpenedTimestamp
    backingProto.lastModified = lastModifiedTimestamp
    backingProto.deleted = isDeleted
    backingProto.archived = isArchived
    return backingProto
  }

  /// The private backing proto.
  private let backingProto: GSJSyncExperiment

  /// Designatecd initializer.
  ///
  /// - Parameter proto: A `GSJSyncExperiment` proto.
  init(proto: GSJSyncExperiment) {
    fileID = proto.hasFileId ? proto.fileId : nil
    experimentID = proto.experimentId
    lastOpenedTimestamp = proto.lastOpened
    lastModifiedTimestamp = proto.lastModified
    isDeleted = proto.deleted
    isArchived = proto.archived
    backingProto = proto
  }

  /// Convenience initializer. Sets all date properties to now, and archived and deleted to false.
  ///
  /// - Parameters:
  ///   - experimentID: The experiment ID.
  ///   - fileID: The Drive file ID, optional.
  convenience init(experimentID: String, fileID: String? = nil, clock: Clock) {
    let proto = GSJSyncExperiment()
    proto.fileId = fileID
    proto.experimentId = experimentID
    proto.lastOpened = clock.millisecondsSince1970
    proto.lastModified = clock.millisecondsSince1970
    proto.deleted = false
    proto.archived = false
    self.init(proto: proto)
  }

}
