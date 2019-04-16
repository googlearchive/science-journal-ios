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

/// Pans the drawer when a scroll view is dragged.
class DrawerPanner {

  // MARK: - Properties

  // Whether or not a pan gesture is currently being handled. Decides whether or not to handle a pan
  // gesture in the upward direction, as well as knowing when to pan the drawer or pan to the next
  // position.
  var isHandlingPanGesture = false

  // Whether or not a downward pan gesture should be handled. Decides whether or not to handle the
  // gesture. Decided by the scroll view delegate. Only true when the drag starts from a 0 content
  // offset.
  var shouldHandleDownwardPanGesture = false

  // Whether or not an upward pan gesture should be handled. Decides whether or not to handle the
  // gesture. Decided by the scroll view delegate. Only true when the drag starts from a 0 content
  // offset.
  var shouldHandleUpwardPanGesture = false

  private let allowsPanningUp: Bool
  private weak var drawerViewController: DrawerViewController?
  private weak var scrollView: UIScrollView?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - drawerViewController: The drawer view controller.
  ///   - scrollView: The scroll view.
  ///   - allowsPanningUp: Whether or not the drawer panner will pan upward.
  init(drawerViewController: DrawerViewController,
       scrollView: UIScrollView,
       allowsPanningUp: Bool = false) {
    self.drawerViewController = drawerViewController
    self.scrollView = scrollView
    self.allowsPanningUp = allowsPanningUp
  }

  /// Forward scroll view delegate calls to this object to decide whether or not to handle the
  /// scroll view pan gesture.
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if !shouldHandleDownwardPanGesture {
      shouldHandleDownwardPanGesture = scrollView.contentOffset.y == 0
    }
    shouldHandleUpwardPanGesture = allowsPanningUp
  }

  /// Forward scroll view delegate calls to this object to decide whether or not to handle the
  /// scroll view pan gesture.
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !isHandlingPanGesture {
      shouldHandleDownwardPanGesture = false
      shouldHandleUpwardPanGesture = false
    }
  }

  /// Forward pan gesture recognizer calls to this object to handle the scroll view pan gesture.
  func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    guard let drawerViewController = drawerViewController,
        let scrollView = scrollView,
        !drawerViewController.isDisplayedAsSidebar,
        isHandlingPanGesture ||
        (panGestureRecognizer.isPanDownward(in: scrollView) && shouldHandleDownwardPanGesture ||
        !panGestureRecognizer.isPanDownward(in: scrollView) && shouldHandleUpwardPanGesture) else {
      return
    }

    switch panGestureRecognizer.state {
    case .began:
      isHandlingPanGesture = true
    case .changed:
      if isHandlingPanGesture {
        drawerViewController.drawerView.pan(
            distance: panGestureRecognizer.translation(in: scrollView).y)

        // Ensure the content offset stays fixed.
        scrollView.contentOffset.y = 0
      }
    case .ended:
      if isHandlingPanGesture {
        drawerViewController.drawerView.completePan(
            withVelocity: panGestureRecognizer.velocity(in: scrollView).y)
      }
      isHandlingPanGesture = false
      shouldHandleDownwardPanGesture = false
    default:
      break
    }
  }

}
