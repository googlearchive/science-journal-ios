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

/// Represents a position that the drawer can be open to.
open class DrawerPosition: Equatable {

  public static func ==(lhs: DrawerPosition, rhs: DrawerPosition) -> Bool {
    return lhs.panDistance == rhs.panDistance && lhs.canShowKeyboard == rhs.canShowKeyboard
  }

  /// The closure that calculates the position's content height.
  var contentHeightClosure: (() -> (CGFloat))?

  /// The visible content height of the position.
  var contentHeight: CGFloat {
    guard let contentHeightClosure = contentHeightClosure else { return 0 }
    return contentHeightClosure()
  }

  /// The pan distance that the drawer needs to be moved up the screen (negative view coordinate
  /// direction) to snap to this position. This is the negative of the content height.
  var panDistance: CGFloat {
    return -contentHeight
  }

  /// Whether or not a drawer position allows showing the keyboard.
  let canShowKeyboard: Bool

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - canShowKeyboard: Whether or not a drawer position allows showing the keyboard.
  ///   - contentHeightClosure: The closure that calculates the position's visible content height.
  public init(canShowKeyboard: Bool, contentHeightClosure: (() -> (CGFloat))? = nil) {
    self.canShowKeyboard = canShowKeyboard
    self.contentHeightClosure = contentHeightClosure
  }

}
