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

/// A wrapper for GSJUserMetadata. Collects data specific to the current user. Will not be shared
/// with other users when syncing with Drive.
class UserMetadata {

  /// The latest user metadata file version.
  enum Version {
    // The current version number we expect from user metadata.
    static let major: Int32 = 1

    // The current minor version number we expect from user metadata.
    static let minor: Int32 = 1

    // The current platform version number for user metadata we write.
    // This is implementation-specific; it _shouldn't_ affect future readers of the data, but it
    // will allow us to detect files written by buggy versions if needed.
    //
    // Set to the current build number. Previous to Science Journal 2.1 the platform version
    // was set to 1.
    // (NOTE: In development platform is set to a fixed value.)
    static let platform: Int32 = Bundle.buildVersion
  }

  // An array of experiment overviews.
  var experimentOverviews: [ExperimentOverview] {
    return _experimentOverviews
  }

  /// Identifies the intended format version of this file, and the app that wrote it.
  var fileVersion: FileVersion

  var proto: GSJUserMetadata {
    var proto: GSJUserMetadata!
    overviewQueue.sync {
      backingProto.experimentsArray = NSMutableArray(array: experimentOverviews.map { $0.proto })
      backingProto.fileVersion = fileVersion.proto
      proto = backingProto
    }
    return proto
  }

  private let overviewQueue = DispatchQueue(label: "com.google.ScienceJournal.UserMetadata")
  private var _experimentOverviews: [ExperimentOverview]

  /// Designated initializer.
  ///
  /// - Parameter proto: A user metadata proto.
  init(proto: GSJUserMetadata) {
    _experimentOverviews = proto.experimentsArray.map {
      // swiftlint:disable force_cast
      ExperimentOverview(proto: $0 as! GSJExperimentOverview)
      // swiftlint:enable force_cast
    }
    fileVersion = FileVersion(proto: proto.fileVersion)
    backingProto = proto
  }

  /// Initializes a sensor layout with an empty proto.
  convenience init() {
    let proto = GSJUserMetadata()
    self.init(proto: proto)
  }

  /// Returns an overview for a given experiment ID.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: An experiment overview.
  func experimentOverview(with experimentID: String) -> ExperimentOverview? {
    var experimentOverview: ExperimentOverview?
    overviewQueue.sync {
      guard let index =
          _experimentOverviews.index(where: { $0.experimentID == experimentID }) else {
        return
      }
      experimentOverview = _experimentOverviews[index]
    }
    return experimentOverview
  }

  /// Adds an overview.
  ///
  /// - Parameter experimentOverview: An experiment overview.
  func addExperimentOverview(_ experimentOverview: ExperimentOverview) {
    overviewQueue.sync {
      guard !_experimentOverviews.contains(where: {
          $0.experimentID == experimentOverview.experimentID }) else {
        // There shouldn't be any overviews for the same ID we're adding now.
        return
      }

      _experimentOverviews.append(experimentOverview)
    }
  }

  /// Deletes an experiment overview for an experiment ID.
  ///
  /// - Parameter experimentID: An experiment ID.
  /// - Returns: The removed experiment overview.
  func removeExperimentOverview(with experimentID: String) -> ExperimentOverview? {
    var experimentOverview: ExperimentOverview?
    overviewQueue.sync {
      guard let index =
          _experimentOverviews.index(where: { $0.experimentID == experimentID }) else {
        return
      }
      experimentOverview = _experimentOverviews.remove(at: index)
    }
    return experimentOverview
  }

  /// Deletes all experiment overviews with an experiment ID.
  ///
  /// - Parameter experimentID: An experiment ID.
  func removeAllExperimentOverviews(withExperimentID experimentID: String) {
    overviewQueue.sync {
      _experimentOverviews.removeAll(where: { $0.experimentID == experimentID })
    }
  }

  // MARK: - Private

  /// The underlying proto.
  private let backingProto: GSJUserMetadata

}
