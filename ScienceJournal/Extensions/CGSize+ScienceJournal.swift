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

/// Extends CGSize to allow scaling the width and height.
extension CGSize {

  /// Scales a `CGSize` by multiplying width and height by `scale`.
  ///
  /// - Parameter scale: The scale.
  /// - Returns: The scaled `CGSize`.
  func applying(scale: CGFloat) -> CGSize {
    return CGSize(width: width * scale, height: height * scale)
  }

  /// Determines if a CGSize's width is greater than its height. Useful when determining if views
  /// are in landscape or portrait mode.
  var isWiderThanTall: Bool {
    return width > height
  }

}
