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

import ScienceJournalProtos

/// A wrapper for GSJChange. Represents a change to an experiment.
class ExperimentChange: Equatable, Hashable {

  private(set) var changeID: String
  private(set) var element: ChangedElement
  private(set) var type: GSJChange_ChangeType

  private let backingProto: GSJChange

  /// A proto representation of an experiment change.
  var proto: GSJChange {
    backingProto.changeId = changeID
    backingProto.changedData = element.proto
    backingProto.type = type
    return backingProto
  }

  /// Convenience constructor that returns an add change.
  ///
  /// - Parameters:
  ///   - elementType: The type of element that changed.
  ///   - elementID: The ID of the changed element.
  /// - Returns: An experiment change.
  static func addChange(forElement elementType: GSJChangedElement_ElementType,
                        withID elementID: String) -> ExperimentChange {
    let element = ChangedElement(type: elementType, ID: elementID)
    return ExperimentChange(element: element, type: .add)
  }

  /// Convenience constructor that returns a delete change.
  ///
  /// - Parameters:
  ///   - elementType: The type of element that changed.
  ///   - elementID: The ID of the changed element.
  /// - Returns: An experiment change.
  static func deleteChange(forElement elementType: GSJChangedElement_ElementType,
                           withID elementID: String) -> ExperimentChange {
    let element = ChangedElement(type: elementType, ID: elementID)
    return ExperimentChange(element: element, type: .delete)
  }

  /// Convenience constructor that returns a modify change.
  ///
  /// - Parameters:
  ///   - elementType: The type of element that changed.
  ///   - elementID: The ID of the changed element.
  /// - Returns: An experiment change.
  static func modifyChange(forElement elementType: GSJChangedElement_ElementType,
                           withID elementID: String) -> ExperimentChange {
    let element = ChangedElement(type: elementType, ID: elementID)
    return ExperimentChange(element: element, type: .modify)
  }

  /// Convenience initializer that automatically assigns a unique change ID.
  ///
  /// - Parameters:
  ///   - element: A changed element.
  ///   - type: A change type.
  convenience init(element: ChangedElement, type: GSJChange_ChangeType) {
    self.init(proto: GSJChange())
    changeID = UUID().uuidString
    self.element = element
    self.type = type
  }

  /// Designated initializer.
  ///
  /// - Parameter proto: A `GSJChange` proto.
  init(proto: GSJChange) {
    changeID = proto.changeId
    element = ChangedElement(proto: proto.changedData)
    type = proto.type
    backingProto = proto
  }

  // MARK: - Equatable

  static func ==(lhs: ExperimentChange, rhs: ExperimentChange) -> Bool {
    if lhs === rhs {
      return true
    }

    return lhs.changeID == rhs.changeID
  }

  // MARK: - Hashable

  var hashValue: Int {
    return changeID.hashValue
  }

}

/// A wrapper for GSJChangedElement. Represents an element in an experiment change.
class ChangedElement {
  private(set) var type: GSJChangedElement_ElementType
  private(set) var ID: String

  private let backingProto: GSJChangedElement

  /// A proto representation of a changed element.
  var proto: GSJChangedElement {
    backingProto.type = type
    backingProto.id_p = ID
    return backingProto
  }

  /// Designated initializer.
  ///
  /// - Parameter proto: A `GSJChangedElement` proto.
  init(proto: GSJChangedElement) {
    type = proto.type
    ID = proto.id_p
    backingProto = proto
  }

  convenience init(type: GSJChangedElement_ElementType, ID: String) {
    self.init(proto: GSJChangedElement())
    self.type = type
    self.ID = ID
  }

}

// MARK: - CustomDebugStringConvertible

extension ExperimentChange: CustomDebugStringConvertible {
  var debugDescription: String {
    return "<ExperimentChange, ID: \(changeID), elementType: \(element.type), type: \(type)>"
  }
}

extension GSJChangedElement_ElementType: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .experiment: return ".experiment"
    case .trial: return ".trial"
    case .note: return ".note"
    case .caption: return ".caption"
    case .unknown: return ".unknown"
    }
  }
}

extension GSJChange_ChangeType: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .add: return ".add"
    case .delete: return ".delete"
    case .modify: return ".modify"
    case .merge: return ".merge"
    case .unknown: return ".unknown"
    }
  }
}
