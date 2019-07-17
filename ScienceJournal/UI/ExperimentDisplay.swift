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
import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// Provides the configuration for views under this controller's tree for various states.
enum ExperimentDisplay {

  /// Viewing an experiment, before or after recording.
  case normal

  /// Recording in progress.
  case recording  // Not implemented for app flow. Currently only used to provide values.

  /// Transient state for updating views for PDF export. Should enter from (and exit to) .normal
  case pdfExport

  var backgroundColor: UIColor {
    switch self {
    case .normal, .recording:
      return MDCPalette.grey.tint200
    case .pdfExport:
      return .white
    }
  }

  var maxDisplayNotes: Int? {
    // The default max notes to show when parsing trials into display trials.
    let defaultMaxDisplayNotes = 2

    switch self {
    case .normal:
      return defaultMaxDisplayNotes
    case .pdfExport, .recording:
      return nil
    }
  }

  func showCaptionButton(for experimentInteractionOptions: ExperimentInteractionOptions) -> Bool {
    switch self {
    case .normal, .recording:
      return experimentInteractionOptions.shouldAllowEdits
    case .pdfExport:
      return false
    }
  }

  var showMenuButton: Bool {
    switch self {
    case .normal, .recording:
      return true
    case .pdfExport:
      return false
    }
  }

  var chartViewHeightPadding: CGFloat {
    switch self {
    case .normal, .recording:
      return 0
    case .pdfExport:
      return ChartPlacementType.runReview.height - ChartPlacementType.previewReview.height
    }
  }

  var trialCardSensorViewHeight: CGFloat {
    switch self {
    case .normal, .recording:
      return ChartPlacementType.previewReview.height
    case .pdfExport:
      return ChartPlacementType.runReview.height
    }
  }

  var pictureContentMode: UIView.ContentMode {
    let defaultContentMode = UIView.ContentMode.scaleAspectFill

    switch self {
    case .normal, .recording:
      return defaultContentMode
    case .pdfExport:
      return .scaleAspectFit
    }
  }

  var trialPictureStyle: PictureStyle {
    switch self {
    case .normal, .recording:
      return .small
    case .pdfExport:
      return .large
    }
  }

  var trialPictureHeightPadding: CGFloat {
    switch self {
    case .normal, .recording:
      return PictureStyle.small.height
    case .pdfExport:
      return PictureStyle.large.height - PictureStyle.small.height
    }
  }

  var pictureBackgroundColor: UIColor {
    let defaultBackgroundColor = UIColor(red:  0.910, green: 0.914, blue: 0.929, alpha: 1)

    switch self {
    case .normal, .recording:
      return defaultBackgroundColor
    case .pdfExport:
      return .white
    }
  }

}
