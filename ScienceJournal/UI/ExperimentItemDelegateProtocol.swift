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

/// Informs trials and experiments that items are being changed or deleted. Called from note detail
/// view controllers and the trial detail view controller.
protocol ExperimentItemDelegate: class {

  /// Informs the delegate a note was added to a trial.
  ///
  /// - Parameters:
  ///   - note: The added note.
  ///   - trialID: The ID of the trial that owns this note.
  func detailViewControllerDidAddNote(_ note: Note, forTrialID trialID: String?)

  /// Informs the delegate a note's caption was updated.
  ///
  /// - Parameter updatedDisplayNote: The updated display note.
  func detailViewControllerDidUpdateCaptionForNote(_ updatedDisplayNote: CaptionableNote)

  /// Informs the delegate a note's text was updated.
  ///
  /// - Parameter updatedDisplayTextNote: The updated display text note.
  func detailViewControllerDidUpdateTextForNote(_ updatedDisplayTextNote: DisplayTextNote)

  /// Informs the delegate a note was deleted.
  ///
  /// - Parameter deletedDisplayNote: The deleted display note.
  func detailViewControllerDidDeleteNote(_ deletedDisplayNote: DisplayNote)

  /// Informs the delegate a trial was updated.
  ///
  /// - Parameter trialID: The trial ID.
  func trialDetailViewControllerDidUpdateTrial(cropRange: ChartAxis<Int64>?,
                                               name trialName: String?,
                                               caption: String?,
                                               withID trialID: String)

  /// Informs the delegate that delete trial was requested. The delegate is responsible for
  /// performing the delete.
  ///
  /// - Parameter: trialID The ID of the trial to delete.
  func trialDetailViewControllerDidRequestDeleteTrial(withID trialID: String)

  /// Informs the delegate that a trial was un/archived.
  ///
  /// - Parameters:
  ///   - trialDetailViewController: The trial detail view controller.
  ///   - trial: The trial.
  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateChanged trial: Trial)

  /// Informs the delegate a trial's archive state should be toggled.
  ///
  /// - Parameters:
  ///   - trialDetailViewController: The trial detail view controller.
  ///   - trialID: The trial ID.
  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateToggledForTrialID trialID: String)

}
