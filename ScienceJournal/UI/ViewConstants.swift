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
import MaterialComponents

/// Shared view constants for Science Journal.
struct ViewConstants {

  /// The height to use for Science Journal toolbars.
  /// MDCFlexibleHeaderView's height (76) minus statusBar height (20).
  static let toolbarHeight: CGFloat = 56

  /// The height of the MDCFlexibleHeaderView's.
  static let headerHeight: CGFloat = 76

  /// The width of the drawer on iPad.
  static let iPadDrawerSidebarWidth: CGFloat = 375

  /// The total (half left, half right) horizontal inset for collection view cells in regular
  /// display type.
  static let cellHorizontalInsetRegularDisplayType: CGFloat = 200

  /// The total (half left, half right) horizontal inset for collection view cells in regular
  /// display type.
  static let cellHorizontalInsetRegularWideDisplayType: CGFloat = 300

  // MARK: - Color schemes

  /// The color scheme for alerts.
  static let alertColorScheme = MDCBasicColorScheme(primaryColor: .black)

  /// The color scheme for feature highlights.
  static var featureHighlightColorScheme: MDCSemanticColorScheme {
    let scheme = MDCSemanticColorScheme()
    scheme.primaryColor = MDCPalette.blue.tint500
    scheme.backgroundColor = .appBarDefaultBackgroundColor
    return scheme
  }

}
