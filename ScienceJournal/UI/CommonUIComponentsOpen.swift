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

/// An open source version of common UI components.
open class CommonUIComponentsOpen: CommonUIComponents {

  public func pullToRefreshController(forScrollView scrollView: UIScrollView,
                                      actionBlock: @escaping () -> Void) ->
      PullToRefreshController? {
    // Pull to refresh is nil because there is no Drive sync in open source.
    return nil
  }

}
