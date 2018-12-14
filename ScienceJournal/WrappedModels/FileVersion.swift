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

/// A wrapper for GSJFileVersion. Defines the version of a proto instance. Can be compared with
/// `<`, `>`, or `==`, but note that platform and platform version are not considered in these
/// comparisons.
public class FileVersion: Comparable {

  /// The version code of this proto. Has a default value of 1 therefore is not an optional.
  public var version: Int32 {
    get {
      return proto.version
    }
    set {
      proto.version = newValue
    }
  }

  /// The minor verion code for this proto. Has a default value of 1 therefore is not an optional.
  public var minorVersion: Int32 {
    get {
      return proto.minorVersion
    }
    set {
      proto.minorVersion = newValue
    }
  }

  /// A platform specific version. Used to identify the version of the app that wrote
  /// the proto to disk. Has a default value of 1 therefore is not an optional.
  public var platformVersion: Int32 {
    get {
      return proto.platformVersion
    }
    set {
      proto.platformVersion = newValue
    }
  }

  /// The platform that last wrote this file (Android or iOS).
  public var platform: GSJGadgetInfo_Platform {
    get {
      return proto.platform
    }
    set {
      proto.platform = newValue
    }
  }

  /// The underlying proto.
  public var proto: GSJFileVersion

  /// Designated initializer.
  ///
  /// - Parameter: proto: A sensor entry proto.
  public init(proto: GSJFileVersion) {
    self.proto = proto
  }

  /// Convenience initializer. Sets platform to iOS.
  ///
  /// - Parameters:
  ///   - version: The major version number.
  ///   - minor: The minor version number.
  ///   - platform: The platform version number.
  public convenience init(major: Int32, minor: Int32, platform: Int32) {
    self.init(proto: GSJFileVersion())
    version = major
    minorVersion = minor
    platformVersion = platform
    self.platform = .ios
  }

  // MARK: - Comparable

  public static func <(lhs: FileVersion, rhs: FileVersion) -> Bool {
    return lhs.version < rhs.version ||
        (lhs.version == rhs.version && lhs.minorVersion < rhs.minorVersion)
  }

  public static func ==(lhs: FileVersion, rhs: FileVersion) -> Bool {
    return lhs.version == rhs.version && lhs.minorVersion == rhs.minorVersion
  }

}
