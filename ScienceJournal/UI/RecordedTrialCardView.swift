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

/// A view displaying data for a recorded trial, in a trial cell.
class RecordedTrialCardView: UIView {

  // MARK: - Properties

  /// The experiment card header view.
  let experimentCardHeaderView = ExperimentCardHeaderView()

  /// The trial card notes view.
  let trialCardNotesView = TrialCardNotesView()

  private let trialCardHeaderView = TrialCardHeaderView()
  private let trialCardSensorsView = TrialCardSensorsView()
  private let trialNotesSeparatorView = SeparatorView(direction: .horizontal, style: .dark)
  private let moreNotesSeparatorView = SeparatorView(direction: .horizontal, style: .dark)
  private let viewMoreNotesView = TrialCardMoreNotesView()

  private enum Metrics {
    static let dimmedAlpha: CGFloat = 0.3
    static let regularAlpha: CGFloat = 1
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    experimentCardHeaderView.frame = CGRect(x: 0,
                                            y: 0,
                                            width: bounds.width,
                                            height: ExperimentCardHeaderView.height)

    trialCardHeaderView.frame = CGRect(x: 0,
                                       y: experimentCardHeaderView.frame.maxY,
                                       width: bounds.width,
                                       height: TrialCardHeaderView.height)

    trialCardSensorsView.frame = CGRect(x: 0,
                                        y: trialCardHeaderView.frame.maxY,
                                        width: bounds.width,
                                        height: bounds.height)
    trialCardSensorsView.sizeToFit()

    var nextOriginY = trialCardSensorsView.frame.maxY

    if trialNotesSeparatorView.superview != nil && trialCardNotesView.superview != nil {
      trialNotesSeparatorView.frame = CGRect(x: 0,
                                             y: nextOriginY,
                                             width: bounds.width,
                                             height: SeparatorView.Metrics.dimension)

      trialCardNotesView.frame = CGRect(x: 0,
                                        y: trialNotesSeparatorView.frame.maxY,
                                        width: bounds.width,
                                        height: bounds.height)
      trialCardNotesView.sizeToFit()
      nextOriginY = trialCardNotesView.frame.maxY
    }

    moreNotesSeparatorView.frame = CGRect(x: 0,
                                          y: nextOriginY,
                                          width: bounds.width,
                                          height: SeparatorView.Metrics.dimension)
    viewMoreNotesView.frame = CGRect(x: 0,
                                     y: moreNotesSeparatorView.frame.maxY,
                                     width: bounds.width,
                                     height: TrialCardMoreNotesView.height)
  }

  /// Returns the height of the trial constrained to a width.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - width: The constrained width.
  /// - Returns: The height.
  static func heightOfTrial(_ trial: DisplayTrial,
                            constrainedToWidth width: CGFloat,
                            experimentDisplay: ExperimentDisplay = .normal) -> CGFloat {
    var height: CGFloat = 0
    height += ExperimentCardHeaderView.height
    height += TrialCardHeaderView.height

    // Sensors and separators for all but the last sensor.
    height += CGFloat(trial.sensors.count) *
      (TrialCardSensorView.height + experimentDisplay.chartViewHeightPadding)
    height += SeparatorView.Metrics.dimension * CGFloat(trial.sensors.count - 1)

    height += RecordedTrialCardView.heightOfNotes(inTrial: trial,
                                                  constrainedToWidth: width,
                                                  experimentDisplay: experimentDisplay)

    return height
  }

  /// Configures the recorded view for the trial.
  ///
  /// - Parameter trial: The trial.
  func configure(withTrial trial: DisplayTrial, experimentDisplay: ExperimentDisplay = .normal) {
    // Header view.
    experimentCardHeaderView.headerTimestampLabel.text = trial.timestamp.string
    experimentCardHeaderView.accessibilityLabel = experimentCardHeaderView.headerTimestampLabel.text
    experimentCardHeaderView.showMenuButton = experimentDisplay.showMenuButton

    // Title bar.
    trialCardHeaderView.configure(with: trial)
    trialCardHeaderView.isShowingArchiveFlag = trial.isArchived

    // Sensors view.
    trialCardSensorsView.sensors = trial.sensors
    trialCardSensorsView.experimentDisplay = experimentDisplay

    // Trial notes.
    if trial.displayNotesCount > 0 {
      addSubview(trialNotesSeparatorView)
      addSubview(trialCardNotesView)
      configureTrialNotes(trial, experimentDisplay: experimentDisplay)
    } else {
      trialNotesSeparatorView.removeFromSuperview()
      trialCardNotesView.removeFromSuperview()
    }
    if trial.hasMoreNotes {
      // Add the more notes separator and view.
      addSubview(moreNotesSeparatorView)
      addSubview(viewMoreNotesView)
    } else {
      moreNotesSeparatorView.removeFromSuperview()
      viewMoreNotesView.removeFromSuperview()
    }

    // Configure for archived state.
    subviews.filter { $0 != trialCardHeaderView }.forEach {
      $0.alpha = trial.isArchived ? Metrics.dimmedAlpha : Metrics.regularAlpha
    }

    setNeedsLayout()
  }

  // MARK: - Private

  private func configureView() {
    // Experiment card header view.
    experimentCardHeaderView.showCaptionButton = false
    addSubview(experimentCardHeaderView)

    // Trial card header view.
    addSubview(trialCardHeaderView)

    // Trial card sensors view.
    addSubview(trialCardSensorsView)
  }

  /// Returns the height of the trial's notes constrained to a width.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - width: The constrained width.
  /// - Returns: The height.
  private static func heightOfNotes(inTrial trial: DisplayTrial,
                                    constrainedToWidth width: CGFloat,
                                    experimentDisplay: ExperimentDisplay = .normal) -> CGFloat {
    guard trial.notes.count > 0 else { return 0 }

    var height: CGFloat = 0
    height += SeparatorView.Metrics.dimension

    for (index, trialNote) in trial.notes.enumerated() {
      // Only the display count of notes is shown.
      guard index < trial.displayNotesCount else { break }

      if index > 0 {
        // Separator before each note, except the first one.
        height += SeparatorView.Metrics.dimension
      }

      switch trialNote.noteType {
      case .textNote(let displayTextNote):
        height += TextNoteCardView.heightForTextNote(displayTextNote,
                                                     showingTimestamp: true,
                                                     inWidth: width)
      case .snapshotNote(let displaySnapshotNote):
        height += displaySnapshotNote.snapshots.reduce(0) { (result, snapshot) in
          result + SnapshotCardView.heightForSnapshot(snapshot, inWidth: width)
        }
        if let caption = displaySnapshotNote.caption {
          height += ExperimentCardCaptionView.heightWithCaption(caption, inWidth: width)
        }
      case .pictureNote(let displayPictureNote):
        height += experimentDisplay.trialPictureStyle.height
        if let caption = displayPictureNote.caption {
          height += ExperimentCardCaptionView.heightWithCaption(caption, inWidth: width)
        }
      case .triggerNote(let displayTriggerNote):
        height += TriggerCardView.heightForTriggerNote(displayTriggerNote,
                                                       showingTimestamp: true,
                                                       inWidth: width)
        if let caption = displayTriggerNote.caption {
          height += ExperimentCardCaptionView.heightWithCaption(caption, inWidth: width)
        }
      }
    }

    if trial.status == .final && trial.hasMoreNotes {
      height += SeparatorView.Metrics.dimension
      height += TrialCardMoreNotesView.height
    }

    return height
  }

  /// Loop through the trial notes and build views to add to the proper wrapper view. Also adds
  /// separators where appropriate.
  ///
  /// - Parameter: displayTrial: The trial.
  private func configureTrialNotes(_ displayTrial: DisplayTrial,
                                   experimentDisplay: ExperimentDisplay = .normal) {
    // Only the display count of notes is shown.
    for trialNote in displayTrial.notes[0..<displayTrial.displayNotesCount] {
      trialCardNotesView.addTrialNote(trialNote, experimentDisplay: experimentDisplay)
    }
  }

}
