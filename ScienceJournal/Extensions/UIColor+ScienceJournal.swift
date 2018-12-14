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

import UIKit

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// UIColor extension for Science Journal with commonly-used static colors.
extension UIColor {

  // MARK: - App bar

  /// The default background color for the app bar.
  static let appBarDefaultBackgroundColor = MDCPalette.deepPurple.tint500

  /// The default background color for the darkend area under the status bar.
  static let appBarDefaultStatusBarBackgroundColor = UIColor(red: 0.267,
                                                             green: 0.094,
                                                             blue: 0.525,
                                                             alpha: 1.0)

  /// The background color for the app bar while reviewing trials and notes.
  static let appBarReviewBackgroundColor = UIColor(red: 0.282,
                                                   green: 0.569,
                                                   blue: 0.894,
                                                   alpha: 1.0)

  /// The background color for the darkened area under the status bar while reviewing trials and
  /// notes.
  static let appBarReviewStatusBarBackgroundColor = UIColor(red: 0.165,
                                                            green: 0.341,
                                                            blue: 0.529,
                                                            alpha: 1.0)

  /// The background color for the app bar while editing a text note in a detail view.
  static let appBarTextEditingBarBackgroundColor = UIColor(red: 0.608,
                                                           green: 0.608,
                                                           blue: 0.608,
                                                           alpha: 1.0)

  /// The background color for the darkened area under the status bar while editing a text note in
  /// a detail view.
  static let appBarTextEditingStatusBarBackgroundColor = UIColor(red: 0.365,
                                                                 green: 0.361,
                                                                 blue: 0.361,
                                                                 alpha: 1.0)

  // MARK: - Trial headers

  /// The background color for the trial cell header when not recording.
  static let trialHeaderDefaultBackgroundColor: UIColor = .appBarReviewBackgroundColor

  /// The background color for the trial cell header while recording.
  static let trialHeaderRecordingBackgroundColor = MDCPalette.red.tint600

  /// The background color for the trial cell header when archived. It is the same as
  /// `trialHeaderDefaultBackgroundColor`, but its alpha is 0.3.
  static let trialHeaderArchivedBackgroundColor = UIColor(red: 0.282,
                                                          green: 0.569,
                                                          blue: 0.894,
                                                          alpha: 0.3)

}
