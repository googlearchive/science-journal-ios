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

/// Describes the display type for the view controller.
///
/// - compact: A compact display type, taller than wide.
/// - compactWide: A compact display type, wider than tall.
/// - regular: A regular display type, taller than wide.
/// - regularWide: A regular display type, wider than tall.
enum DisplayType {
  case compact
  case compactWide
  case regular
  case regularWide
}

extension UITraitCollection {

  /// Returns the display type for the trait collection and view size.
  func displayType(with viewSize: CGSize) -> DisplayType {
    let regular = horizontalSizeClass == .regular && verticalSizeClass == .regular
    if !regular {
      if viewSize.isWiderThanTall {
        return .compactWide
      } else {
        return .compact
      }
    } else if viewSize.isWiderThanTall {
      return .regularWide
    } else {
      return .regular
    }
  }

}

extension UIViewController {

  /// Returns the display type for the trait collection and view size.
  var displayType: DisplayType {
    return traitCollection.displayType(with: view.bounds.size)
  }

}
