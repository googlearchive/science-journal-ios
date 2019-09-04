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

// A custom cross dissolve transition for `UINavigationController`.
final class CrossDissolveTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {

  private let operation: UINavigationController.Operation
  private let transitionDuration: TimeInterval

  init(operation: UINavigationController.Operation, transitionDuration: TimeInterval) {
    self.operation = operation
    self.transitionDuration = transitionDuration
  }

  func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
    return transitionDuration
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    switch operation {
    case .none:
      // TODO: When does this happen?
      transitionContext.completeTransition(true)
    case .push:
      animatePush(using: transitionContext)
    case .pop:
      animatePop(using: transitionContext)
    }
  }

  func animatePush(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromView = transitionContext.view(forKey: .from),
      let toView = transitionContext.view(forKey: .to) else {
      transitionContext.completeTransition(false)
      return
    }

    let duration = transitionDuration(using: transitionContext)
    transitionContext.containerView.addSubview(toView)
    UIView.transition(
      from: fromView,
      to: toView,
      duration: duration,
      options: .transitionCrossDissolve
    ) { completed in
      transitionContext.completeTransition(completed)
    }
  }

  func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromView = transitionContext.view(forKey: .from),
      let toView = transitionContext.view(forKey: .to) else {
      transitionContext.completeTransition(false)
      return
    }

    let duration = transitionDuration(using: transitionContext)
    transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
    UIView.transition(
      from: fromView,
      to: toView,
      duration: duration,
      options: .transitionCrossDissolve
    ) { completed in
      transitionContext.completeTransition(completed)
    }
  }
}
