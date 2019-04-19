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

import UIKit

fileprivate extension BasicSensorAppearance {

  /// Returns true if the sensor spec is for the pitch sensor.
  var isPitch: Bool {
    return iconPath?.type == .builtin && iconPath?.pathString == PitchSensor.ID
  }

}

/// The parser for experiment data.
class ExperimentDataParser {

  // MARK: - Constants

  private static let genericLargeIconName = "ic_sensor_generic_full_color"
  private static let largeIconSuffix = "_full_color"

  private let experimentID: String
  private let metadataManager: MetadataManager
  private let sensorController: SensorController

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - experimentID: An experiment ID.
  ///   - metadataManager: The metadata manager.
  init(experimentID: String, metadataManager: MetadataManager, sensorController: SensorController) {
    self.experimentID = experimentID
    self.metadataManager = metadataManager
    self.sensorController = sensorController
  }

  // MARK: - Trials

  /// Parses a trial array into an array of display trials.
  ///
  /// - Parameters:
  ///   - trials: The array of trial objects.
  /// - Returns: An array of display trial objects.
  func parsedTrials(_ trials: [Trial]) -> [DisplayTrial] {
    return trials.map { parseTrial($0, maxNotes: 2) }
  }

  /// Parses a trial into a display trial.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - maxNotes: The maximum number of trial notes to show before hiding the rest. Defaults to
  ///               showing all notes.
  ///   - isRecording: Whether the trial is in an active recording state.
  /// - Returns: A display trial.
  func parseTrial(_ trial: Trial,
                  maxNotes: Int? = nil,
                  isRecording: Bool = false) -> DisplayTrial {
    let sensorIds = trial.sensorLayouts.map { $0.sensorID }

    // Trial sensors.
    let trialSensors = sensorIds.compactMap { (sensorID) -> DisplaySensor? in
      // Sensor appearance.
      guard let sensorAppearance = trial.sensorAppearance(for: sensorID) else { return nil }

      // Sensor layout.
      let sensorLayout = trial.sensorLayout(forSensorID: sensorID)

      // Stats.
      let sensorTrialStats = trial.sensorTrialStats(for: sensorID)
      let stats =
          DisplaySensorStats(minValue: sensorTrialStats?.minimumValue,
                             averageValue: sensorTrialStats?.averageValue,
                             maxValue: sensorTrialStats?.maximumValue,
                             numberOfValues: sensorTrialStats?.numberOfValues,
                             totalDuration: sensorTrialStats?.totalDuration,
                             zoomPresenterTierCount: sensorTrialStats?.zoomPresenterTierCount,
                             zoomLevelBetweenTiers: sensorTrialStats?.zoomLevelBetweenTiers)

      return DisplaySensor(title: sensorAppearance.name,
                           ID: sensorID,
                           stats: stats,
                           pointsAfterDecimal: sensorAppearance.pointsAfterDecimal,
                           icon: smallIconForIconPath(sensorAppearance.iconPath),
                           colorPalette: sensorLayout?.colorPalette,
                           chartPresentationView: nil)
    }

    let timestamp = Timestamp(trial.creationDate.millisecondsSince1970)
    var trialNotes = trial.notes.compactMap {
      parseNote($0, forTrial: trial)
    }
    trialNotes.sort { (note1, note2) -> Bool in
      // Sort oldest to newest.
      return note1.timestamp.milliseconds < note2.timestamp.milliseconds
    }

    let alternateTitle = String.localizedUntitledTrial(withIndex: trial.trialNumberInExperiment)
    return DisplayTrialViewData(ID: trial.ID,
                                status: isRecording ? .recording : .final,
                                title: trial.title,
                                alternateTitle: alternateTitle,
                                notes: trialNotes,
                                maxDisplayNotes: maxNotes,
                                sensors: trialSensors,
                                duration: trial.durationInterval.durationString,
                                cropRange: trial.cropRange,
                                accessibleDuration: trial.durationInterval.accessibleDurationString,
                                isArchived: trial.isArchived,
                                caption: trial.caption?.text,
                                timestamp: timestamp)
  }

  // MARK: - Notes

  /// Parses a notes array into an array of display notes.
  ///
  /// - Parameter notes: An array of notes.
  /// - Returns: An array of display notes.
  func parseNotes(_ notes: [Note]) -> [DisplayNote] {
    // `parseNote` returns an optional, so flapMap filters those out.
    return notes.map { parseNote($0) }.compactMap { $0 }
  }

  /// Parses a note into view data.
  ///
  /// - Parameters:
  ///   - note: A note.
  ///   - trial: A trial if the note is in a trial.
  /// - Returns: A display note.
  func parseNote(_ note: Note, forTrial trial: Trial? = nil) -> DisplayNote? {
    var timestamp: Timestamp
    if let trial = trial {
      let startTime = trial.cropRange?.min ?? trial.recordingRange.min
      timestamp = Timestamp(note.timestamp, relativeTo: startTime)
    } else {
      timestamp = Timestamp(note.timestamp)
    }

    switch note {
    case let textNote as TextNote:
      return DisplayTextNoteModel(ID: note.ID,
                                  trialID: trial?.ID,
                                  text: textNote.text,
                                  valueSnapshots: nil,
                                  timestamp: timestamp)
    case let pictureNote as PictureNote:
      var imagePath: String?
      if let filePath = pictureNote.filePath {
        imagePath = metadataManager.pictureFileURL(for: filePath,
                                                   experimentID: experimentID).path
      }
      return DisplayPictureNoteViewData(ID: note.ID,
                                        trialID: trial?.ID,
                                        imagePath: imagePath,
                                        timestamp: timestamp,
                                        caption: pictureNote.caption?.text?.trimmedOrNil)
    case let snapshotNote as SnapshotNote:
      let snapshots = snapshotNote.snapshots.map { (sensorSnapshot) -> DisplaySnapshotValue in
        let appearance = sensorSnapshot.sensorSpec.rememberedAppearance
        var snapshotTimestamp: Timestamp
        if let trial = trial {
          let startTime = trial.cropRange?.min ?? trial.recordingRange.min
          snapshotTimestamp = Timestamp(sensorSnapshot.timestamp, relativeTo: startTime)
        } else {
          snapshotTimestamp = Timestamp(sensorSnapshot.timestamp)
        }
        let snapshotValue = Sensor.string(for: sensorSnapshot.value,
                                          units: appearance.units,
                                          pointsAfterDecimal: appearance.pointsAfterDecimal)
        let (sensorIcon, sensorIconAccessibilityLabel) =
            imageAttributesForAppearance(sensorSnapshot.sensorSpec.rememberedAppearance,
                                         size: SnapshotCardView.sensorIconSize,
                                         value: sensorSnapshot.value)
        return DisplaySnapshotValue(value: snapshotValue,
                                    valueType: appearance.name,
                                    sensorIcon: sensorIcon,
                                    sensorIconAccessibilityLabel: sensorIconAccessibilityLabel,
                                    timestamp: snapshotTimestamp)
      }
      return DisplaySnapshotNoteViewData(ID: note.ID,
                                         trialID: trial?.ID,
                                         snapshots: snapshots,
                                         timestamp: timestamp,
                                         caption: snapshotNote.caption?.text?.trimmedOrNil)
    case let triggerNote as TriggerNote:
      guard let triggerInformation = triggerNote.triggerInformation,
          let sensorSpec = triggerNote.sensorSpec else { return nil }

      let noteText = triggerInformation.noteText
      let descriptionText = triggerNoteTextForTriggerInformation(triggerInformation,
                                                                 sensorSpec: sensorSpec)
      let valueText =
          Sensor.string(for: triggerInformation.valueToTrigger,
                        units: sensorSpec.rememberedAppearance.units,
                        pointsAfterDecimal: sensorSpec.rememberedAppearance.pointsAfterDecimal)
      let (sensorIcon, sensorIconAccessibilityLabel) =
          imageAttributesForAppearance(sensorSpec.rememberedAppearance,
                                       size: TriggerCardView.sensorIconSize,
                                       value: triggerInformation.valueToTrigger)
      return DisplayTriggerNoteViewData(ID: note.ID,
                                        trialID: trial?.ID,
                                        descriptionText: descriptionText,
                                        noteText: noteText,
                                        valueText: valueText,
                                        timestamp: timestamp,
                                        icon: sensorIcon,
                                        iconAccessibilityLabel: sensorIconAccessibilityLabel,
                                        caption: triggerNote.caption?.text?.trimmedOrNil)
    default:
      return nil
    }
  }

  // MARK: Private

  private func triggerNoteTextForTriggerInformation(_ triggerInformation: TriggerInformation,
                                                    sensorSpec: SensorSpec) -> String {
    let sensorName = sensorSpec.rememberedAppearance.name
    let triggerWhenText = triggerInformation.triggerWhen.triggerWhenText
    return "\(sensorName) \(triggerWhenText)"
  }

  private func smallIconForIconPath(_ iconPath: IconPath?) -> UIImage? {
    var imageName: String?
    if let iconPath = iconPath {
      switch iconPath.type {
      case .builtin:
        // For built-in sensors the path string is the sensor id.
        if let pathString = iconPath.pathString,
            let sensor = sensorController.sensor(for: pathString) {
          imageName = sensor.iconName
        }
        break
      default: break
      }
    }

    if let imageName = imageName {
      return UIImage(named: imageName)
    } else {
      // If no image name was set, use the default.
      return UIImage(named: "ic_sensor_generic")
    }
  }

  /// Returns a large size icon for the given sensor appearance. Optionally a value can be passed
  /// for icons that change based on a sensor value. If no icon can be found the default icon is
  /// returned. In some cases, an accessibility label is also returned.
  ///
  /// - Parameters:
  ///   - appearance: The appearance to parse an icon image from.
  ///   - size: The icon size for icons that need it. Optional.
  ///   - value: A sensor value for icons that need it. Optional.
  /// - Returns: A tuple containing an optional image and an optional accessibility label.
  private func imageAttributesForAppearance(_ appearance: BasicSensorAppearance,
                                            size: CGSize?,
                                            value: Double?) -> (UIImage?, String?) {
    guard let iconPath = appearance.largeIconPath, iconPath.type == .builtin else {
      return (UIImage(named: ExperimentDataParser.genericLargeIconName), nil)
    }

    guard let pathString = iconPath.pathString,
        let sensor = sensorController.sensor(for: pathString) else {
      return (UIImage(named: ExperimentDataParser.genericLargeIconName), nil)
    }

    if appearance.isPitch, let value = value, let size = size {
      return PitchSensorAnimationView.imageAttributes(atSize: size, withValue: value)
    }

    switch iconPath.type {
    case .builtin:
      return (UIImage(named: sensor.iconName + ExperimentDataParser.largeIconSuffix), nil)
    default: return (UIImage(named: ExperimentDataParser.genericLargeIconName), nil)
    }
  }

}
