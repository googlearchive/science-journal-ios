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

/// The transition controller for view controllers that present immediately, and fade their alpha
/// during dismissial.
class AlphaFadeTransitionController: NSObject, UIViewControllerAnimatedTransitioning,
    UIViewControllerTransitioningDelegate {

  // MARK: - Properties

  // Whether or not the view controller is presenting (otherwise it is dismissing).
  private var isPresenting: Bool?

  private enum Metrics {
    static let alphaHidden: CGFloat = 0
    static let animationDuration: TimeInterval = 0.2
  }

  // MARK: - Public

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let isPresenting = isPresenting else { return }

    if isPresenting {
      guard let toView = transitionContext.viewController(forKey: .to)?.view else {
        transitionContext.completeTransition(false)
        return
      }

      let containerView = transitionContext.containerView
      toView.frame = containerView.bounds
      containerView.addSubview(toView)
      transitionContext.completeTransition(true)
    } else {
      guard let fromView = transitionContext.viewController(forKey: .from)?.view else {
        transitionContext.completeTransition(false)
        return
      }

      UIView.animate(withDuration: transitionDuration(using: transitionContext),
                     animations: {
                       fromView.alpha = Metrics.alphaHidden
      },
                     completion: { (_) in
                        fromView.removeFromSuperview()
                        transitionContext.completeTransition(true)
      })
    }
  }

  func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    isPresenting = true
    return self
  }

  func animationController(
      forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    isPresenting = false
    return self
  }

  func transitionDuration(
      using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return Metrics.animationDuration
  }
}
