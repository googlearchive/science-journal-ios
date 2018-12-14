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

/// Protocol for common UI components.
public protocol CommonUIComponents: class {

  /// Returns a pull to refresh controller for a scroll view that calls an action block.
  ///
  /// - Parameters:
  ///   - scrollView: A scroll view.
  ///   - actionBlock: The action block.
  /// - Returns: A pull to refresh controller.
  func pullToRefreshController(forScrollView scrollView: UIScrollView,
                               actionBlock: @escaping () -> Void) -> PullToRefreshController?

}
