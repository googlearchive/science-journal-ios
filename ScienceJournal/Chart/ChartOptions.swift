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

/// ChartPlacementType represents the purpose of the chart which dictates style and behavior.
///
/// - observe: Used for recording a data stream. Scrolls to keep the current data point in view.
/// - runReview: Used to display a previously recorded trial. Allows scrolling and zooming.
/// - previewReview: Used to display a preview of a trial within an experiment. Does not allow
///                  scrolling or zooming.
enum ChartPlacementType {
  case observe
  case runReview
  case previewReview

  /// The height of the chart for the placement type.
  var height: CGFloat {
    switch self {
    case .observe: return 130
    case .previewReview: return 100
    case .runReview: return 150
    }
  }
}

/// ChartOptions describes the style and behavior of a chart.
struct ChartOptions {
  let placementType: ChartPlacementType

  // Colors
  var lineColor = UIColor.black
  let yAxisLineColor = MDCPalette.grey.tint300

  /// Whether the view can scroll.
  let canScrollX: Bool
  let canScrollY: Bool
  var canScroll: Bool {
    return canScrollX || canScrollY
  }

  /// Whether the view can zoom.
  let canZoomX: Bool
  let canZoomY: Bool
  var canZoom: Bool {
    return canZoomX || canZoomY
  }

  /// Whether the view should scroll to display newly added data points.
  var isPinnedToNow: Bool

  var isYAxisVisible: Bool {
    return placementType != .previewReview
  }

  init(placementType: ChartPlacementType, lineColor: UIColor) {
    self.lineColor = lineColor
    self.placementType = placementType
    switch placementType {
    case .observe:
      canScrollX = true
      canScrollY = false
      canZoomX = false
      canZoomY = true
      isPinnedToNow = true
    case .runReview:
      canScrollX = true
      canScrollY = true
      canZoomX = true
      canZoomY = true
      isPinnedToNow = false
    case .previewReview:
      canScrollX = false
      canScrollY = false
      canZoomX = false
      canZoomY = false
      isPinnedToNow = false
    }
  }
}
