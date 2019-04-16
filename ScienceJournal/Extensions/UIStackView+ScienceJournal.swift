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

extension UIStackView {

  /// Removes all arranged views from a stack view, optionally leaving them in their superviews if
  /// necessary.
  ///
  /// - Parameters:
  ///   - exceptViews: An array of views to leave in the stack view. Can be nil.
  ///   - leaveInSuperview: Should removed views be left in their superviews? Default is false.
  func removeAllArrangedViews(exceptViews: [UIView]? = nil, leaveInSuperview: Bool = false) {
    let arrangedViews = self.arrangedSubviews
    for arragedView in arrangedViews {
      if let exceptViews = exceptViews, exceptViews.contains(arragedView) {
        continue
      }
      self.removeArrangedSubview(arragedView)
      if !leaveInSuperview {
        arragedView.removeFromSuperview()
      }
    }
  }

}
