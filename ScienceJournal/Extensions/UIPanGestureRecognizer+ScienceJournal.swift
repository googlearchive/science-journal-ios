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

extension UIPanGestureRecognizer {

  /// Whether or not the pan gesture in a view was downward on the screen.
  ///
  /// - Parameter view: The view the gesture occured in.
  /// - Returns: Whether or not the pan was downward.
  func isPanDownward(in view: UIView) -> Bool {
    return velocity(in: view).y > 0
  }

}
