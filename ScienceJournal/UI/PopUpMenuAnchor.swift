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

/// The position in the view to which the pop up menu's animation anchors.
enum PopUpMenuAnchor {
  case center
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight

  /// Returns the transform to set for the pop up menu pre-transition, causing it to animate in from
  /// its corner (or center).
  ///
  /// - Parameters:
  ///   - endFrame: The frame the pop up menu transition will end in.
  ///   - scale: The starting scale of the pop up menu transition.
  /// - Returns: The transform to set pre-transition.
  func transformForTransition(to endFrame: CGRect, with scale: CGFloat) -> CGAffineTransform {
    let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
    switch self {
    case .center:
      return scaleTransform
    case .topLeft:
      return scaleTransform.concatenating(
          CGAffineTransform(translationX: -endFrame.size.width * (scale / 2),
                            y: -endFrame.size.height * (scale / 2)))
    case .topRight:
      return scaleTransform.concatenating(
          CGAffineTransform(translationX: endFrame.size.width * (scale / 2),
                            y: -endFrame.size.height * (scale / 2)))
    case .bottomLeft:
      return scaleTransform.concatenating(
          CGAffineTransform(translationX: -endFrame.size.width * (scale / 2),
                            y: endFrame.size.height * (scale / 2)))
    case .bottomRight:
      return scaleTransform.concatenating(
          CGAffineTransform(translationX: endFrame.size.width * (scale / 2),
                            y: endFrame.size.height * (scale / 2)))
    }
  }

}
