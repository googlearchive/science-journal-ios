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

/// Positions in which the pop up menu can display itself.
///
/// - coveringView: Displays covering the view with the pop up menu's frame.
/// - sourceView: Displays near the button or view that is initiating showing the pop up.
/// - center: Displays in the center of the screen.
/// - topLeft: Displays in the top left corner.
/// - topRight: Displays in the top right corner.
/// - bottomLeft: Displays in the bottom left corner.
/// - bottomRight: Displays in the bottom right corner.
enum PopUpMenuPosition {
  case coveringView(UIView)
  case sourceView(UIView)
  case center
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight

  /// Returns the frame for the pop up menu view, based on the position.
  ///
  /// - Parameters:
  ///   - contentSize: The content size of the pop up menu view.
  ///   - bounds: The bounds the pop up menu view will be layed out in.
  ///   - insets: Content insets to adjust for within the bounds.
  /// - Returns: The frame for the pop up menu view.
  func frame(for contentSize: CGSize, in bounds: CGRect, with insets: UIEdgeInsets) -> CGRect {
    switch self {
    case .center:
      return CGRect(x: floor((bounds.size.width - contentSize.width) / 2),
                    y: floor((bounds.size.height - contentSize.height) / 2),
                    width: contentSize.width,
                    height: contentSize.height)
    case .topLeft:
      return CGRect(x: insets.left,
                    y: insets.top,
                    width: contentSize.width,
                    height: contentSize.height)
    case .topRight:
      return CGRect(x: bounds.size.width - insets.right - contentSize.width,
                    y: insets.top,
                    width: contentSize.width,
                    height: contentSize.height)

    case .bottomLeft:
      return CGRect(x: insets.left,
                    y: bounds.size.height - insets.bottom - contentSize.height,
                    width: contentSize.width,
                    height: contentSize.height)

    case .bottomRight:
      return CGRect(x: bounds.size.width - insets.right - contentSize.width,
                    y: bounds.size.height - insets.bottom - contentSize.height,
                    width: contentSize.width,
                    height: contentSize.height)
    default:
      return.zero
    }
  }

  /// Returns the pop up menu anchor for a position.
  var anchor: PopUpMenuAnchor {
    switch self {
    case .center:
      return .center
    case .topLeft:
      return .topLeft
    case .topRight:
      return .topRight
    case .bottomLeft:
      return .bottomLeft
    case .bottomRight:
      return .bottomRight
    default:
      return.topLeft
    }
  }
}
