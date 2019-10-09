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

/// Observes a `UIScrollView`'s content size and offset properties,
/// to determine whether its content is outside its safeArea.
class ScrollViewContentObserver: NSObject {
  @objc dynamic private(set) var isContentOutsideOfSafeArea: Bool = false
  private weak var scrollView: UIScrollView?
  private var contentSizeObserver: NSKeyValueObservation?
  private var contentOffsetObserver: NSKeyValueObservation?

  init(scrollView: UIScrollView?) {
    super.init()
    self.scrollView = scrollView

    contentSizeObserver = scrollView?
      .observe(\.contentSize, options: [.new]) { [weak self] _, _ in
        self?.checkContentSafeArea()
    }

    contentOffsetObserver = scrollView?
      .observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
        self?.checkContentSafeArea()
    }
  }

  /// Sets `self.isContentOutsideOfSafeArea` to the appropriate value.
  private func checkContentSafeArea() {
    guard let scrollView = scrollView,
      scrollView.isContentOutsideOfSafeArea != isContentOutsideOfSafeArea else {
      return
    }
    isContentOutsideOfSafeArea = scrollView.isContentOutsideOfSafeArea
  }
}
