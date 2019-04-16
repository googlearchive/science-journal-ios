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

/// A wrapper for GSJIconPath. Contains the information needed to fetch a sensor icon.
class IconPath {

  /// The path type determines how to use the string stored in `pathString`.
  var type: GSJIconPath_PathType {
    get {
      return proto.type
    }
    set {
      proto.type = newValue
    }
  }

  /// A string with a path or key for identifying an icon asset.
  var pathString: String? {
    get {
      guard proto.hasPathString else {
        return nil
      }
      return proto.pathString
    }
    set {
      proto.pathString = newValue
    }
  }

  /// The underlying proto.
  var proto: GSJIconPath

  /// Designated initializer.
  ///
  /// - Parameter: proto: An icon path proto.
  init(proto: GSJIconPath) {
    self.proto = proto
  }

  /// Convenience initializer.
  ///
  /// - Parameters:
  ///   - type: The type of icon path.
  ///   - pathString: A string with a path or key for identifying an icon asset.
  convenience init(type: GSJIconPath_PathType, pathString: String?) {
    let proto = GSJIconPath()
    proto.type = type
    proto.pathString = pathString
    self.init(proto: proto)
  }

  /// Convenience initializer with no parameters.
  convenience init() {
    self.init(proto: GSJIconPath())
  }

}
