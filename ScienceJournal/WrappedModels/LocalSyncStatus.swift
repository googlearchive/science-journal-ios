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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJLocalSyncStatus. The sync status of every locally known experiment.
public class LocalSyncStatus {

  public var experimentStatuses: [ExperimentStatus]

  /// A proto representation of a sync experiment.
  var proto: GSJLocalSyncStatus {
    backingProto.experimentStatusArray = NSMutableArray(array: experimentStatuses.map { $0.proto })
    return backingProto
  }

  /// The private backing proto.
  private let backingProto: GSJLocalSyncStatus

  private let experimentStatusesQueue =
      DispatchQueue(label: "com.google.ScienceJournal.LocalSyncStatus")

  /// Designated initializer.
  ///
  /// - Parameter proto: A `GSJLocalSyncStatus` proto.
  init(proto: GSJLocalSyncStatus) {
    experimentStatuses =
        proto.experimentStatusArray.map { ExperimentStatus(proto: $0 as! GSJExperimentStatus) }
    backingProto = proto
  }

  /// Convenience initializer. Initializes with an empty proto.
  convenience init() {
    self.init(proto: GSJLocalSyncStatus())
  }

  /// Whether the experiment exists in the local sync status.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: True if the experiment exists, otherwise false.
  public func hasExperiment(withID experimentID: String) -> Bool {
    return experimentStatus(forID: experimentID) != nil
  }

  /// Adds an experiment if it has not already been added.
  ///
  /// - Parameter experimentID: The experiment ID.
  public func addExperiment(withID experimentID: String) {
    experimentStatusesQueue.sync {
      guard experimentStatuses.firstIndex(where: { $0.experimentID == experimentID }) == nil else {
        return
      }
      let status = ExperimentStatus(experimentID: experimentID)
      experimentStatuses.append(status)
    }
  }

  /// Removes an experiment's local sync status.
  ///
  /// - Parameter experimentID: An experiment ID.
  public func removeExperiment(withID experimentID: String) {
    experimentStatusesQueue.sync {
      guard let index = experimentStatuses.firstIndex(where: { $0.experimentID == experimentID }) else {
        return
      }
      experimentStatuses.remove(at: index)
    }
  }

  /// Sets an experiment's dirty state.
  ///
  /// - Parameters:
  ///   - isDirty: Whether the experiment is dirty.
  ///   - experimentID: The experiment ID.
  public func setExperimentDirty(_ isDirty: Bool, withID experimentID: String) {
    guard let status = experimentStatus(forID: experimentID) else {
      return
    }
    status.isDirty = isDirty
  }

  /// Returns an experiment's dirty state.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: True if the experiment is dirty, otherwise false.
  public func isExperimentDirty(withID experimentID: String) -> Bool? {
    guard let status = experimentStatus(forID: experimentID) else {
      return nil
    }
    return status.isDirty
  }

  /// Sets an experiment's last synced Drive version.
  ///
  /// - Parameters:
  ///   - lastSyncedVersion: The last synced Drive version.
  ///   - experimentID: The experiment ID.
  public func setExperimentLastSyncedVersion(_ lastSyncedVersion: Int64,
                                      withID experimentID: String) {
    guard let status = experimentStatus(forID: experimentID) else {
      return
    }
    status.lastSyncedVersion = lastSyncedVersion
  }

  /// Returns an experiment's last synced Drive version.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: The experiment's last synced Drive version.
  public func experimentLastSyncedVersion(withID experimentID: String) -> Int64? {
    guard let status = experimentStatus(forID: experimentID) else {
      return nil
    }
    return status.lastSyncedVersion
  }

  /// Sets an experiment's server archived state.
  ///
  /// - Parameters:
  ///   - isServerArchived: Whether the server experiment is archived.
  ///   - experimentID: The experiment ID.
  public func setExperimentServerArchived(_ isServerArchived: Bool, withID experimentID: String) {
    guard let status = experimentStatus(forID: experimentID) else {
      return
    }
    status.isServerArchived = isServerArchived
  }

  /// Returns an experiment's server archived state.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: True if the server experiment is archived, otherwise false.
  public func isExperimentServerArchived(withID experimentID: String) -> Bool? {
    guard let status = experimentStatus(forID: experimentID) else {
      return nil
    }
    return status.isServerArchived
  }

  /// Sets an experiment's downloaded state.
  ///
  /// - Parameters:
  ///   - isDownloaded: Whether the experiment is downloaded.
  ///   - experimentID: The experiment ID.
  public func setExperimentDownloaded(_ isDownloaded: Bool, withID experimentID: String) {
    guard let status = experimentStatus(forID: experimentID) else {
      return
    }
    status.isDownloaded = isDownloaded
  }

  /// Returns an experiment's downloaded state.
  ///
  /// - Parameter experimentID: The experiment ID.
  /// - Returns: True if the experiment is downloaded, otherwise false.
  public func isExperimentDownloaded(withID experimentID: String) -> Bool {
    guard let status = experimentStatus(forID: experimentID) else {
      return false
    }
    return status.isDownloaded
  }

  // MARK: - Private

  private func experimentStatus(forID experimentID: String) -> ExperimentStatus? {
    var experimentStatus: ExperimentStatus?
    experimentStatusesQueue.sync {
      guard let index = experimentStatuses.firstIndex(where: { $0.experimentID == experimentID }) else {
        return
      }
      experimentStatus = experimentStatuses[index]
    }
    return experimentStatus
  }

}

/// A wrapper for `GSJExperimentStatus`. The sync status of a single experiment.
public class ExperimentStatus {

  /// The Experiment ID.
  public let experimentID: String

  /// Whether or not the experiment has any local changes.
  public var isDirty: Bool

  /// The last synced version from Drive.
  var lastSyncedVersion: Int64?

  /// The status we last saw on drive for whether or not the experiment is
  /// archived.
  var isServerArchived: Bool

  /// Whether or not the experiment is locally downloaded.
  var isDownloaded: Bool

  /// A proto representation of an experiment status.
  var proto: GSJExperimentStatus {
    backingProto.experimentId = experimentID
    backingProto.dirty = isDirty
    if let lastSyncedVersion = lastSyncedVersion {
      backingProto.lastSyncedVersion = lastSyncedVersion
    } else {
      backingProto.hasLastSyncedVersion = false
    }
    backingProto.serverArchived = isServerArchived
    backingProto.downloaded = isDownloaded
    return backingProto
  }

  /// The private backing proto.
  private let backingProto: GSJExperimentStatus

  /// Designated initializer.
  ///
  /// - Parameter proto: A `GSJExperimentStatus` proto.
  init(proto: GSJExperimentStatus) {
    experimentID = proto.experimentId
    isDirty = proto.dirty
    lastSyncedVersion = proto.hasLastSyncedVersion ? proto.lastSyncedVersion : nil
    isServerArchived = proto.serverArchived
    isDownloaded = proto.downloaded
    backingProto = proto
  }

  /// Convenience initializer. Defaults all Bool values to false.
  convenience init(experimentID: String) {
    let proto = GSJExperimentStatus()
    proto.experimentId = experimentID
    proto.dirty = false
    proto.serverArchived = false
    proto.downloaded = false
    self.init(proto: proto)
  }

}
