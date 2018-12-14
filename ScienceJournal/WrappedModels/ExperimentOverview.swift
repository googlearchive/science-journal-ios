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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_sciencejournal_ios_ScienceJournalProtos

/// A wrapper for GSJExperimentOverview. Describes the details of an experiment needed to list
/// experiments. The data contained in an overview is either a copy of experiment data for faster
/// display or user specific data that will never be shared with other users.
public class ExperimentOverview {

  /// The associated experiment's ID.
  public var experimentID: String {
    get {
      return proto.experimentId
    }
    set {
      proto.experimentId = newValue
    }
  }

  /// The experiment's title.
  var title: String? {
    get {
      return proto.hasTitle ? proto.title : nil
    }
    set {
      proto.title = newValue
    }
  }

  /// The path of the experiment's image.
  public var imagePath: String? {
    get {
      guard proto.hasImagePath else { return nil }
      return proto.imagePath
    }
    set {
      if let newValue = newValue {
        proto.imagePath = newValue
      } else {
        proto.imagePath = nil
      }
    }
  }

  /// The date the experiment was last used.
  var lastUsedDate: Date {
    get {
      return Date(milliseconds: proto.lastUsedTimeMs)
    }
    set {
      proto.lastUsedTimeMs = newValue.millisecondsSince1970
    }
  }

  /// The number of trials the experiment contains.
  var trialCount: Int {
    get {
      return Int(proto.trialCount)
    }
    set {
      proto.trialCount = Int32(newValue)
    }
  }

  /// Whether the experiment is archived.
  public var isArchived: Bool {
    get {
      return proto.isArchived
    }
    set {
      proto.isArchived = newValue
    }
  }

  /// The color palette of the experiment list card.
  var colorPalette: MDCPalette {
    get {
      return MDCPalette.experimentListCardColorPaletteOptions[Int(proto.colorIndex)]
    }
    set {
      proto.colorIndex =
          Int32(MDCPalette.experimentListCardColorPaletteOptions.index(of: newValue) ?? 0)
    }
  }

  /// The underlying proto.
  let proto: GSJExperimentOverview

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - proto: An experiment overview proto.
  init(proto: GSJExperimentOverview) {
    self.proto = proto
  }

  /// Initializes an experiment overview with an empty proto.
  ///
  /// - Parameters:
  ///   - experimentID: The experiment ID.
  convenience init(experimentID: String) {
    let proto = GSJExperimentOverview()
    self.init(proto: proto)
    self.experimentID = experimentID
  }

}
