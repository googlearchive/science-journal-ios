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

extension UIViewController {

  /// Is this view controller presented modally?
  var isPresented: Bool {
    if self.presentingViewController != nil {
      // This VC is presented directly.
      return true
    } else if self.navigationController?.presentingViewController != nil {
      // This VC is in a navigation controller that was presented.
      return true
    }
    return false
  }

  /// Whether this view controller presented another view controller modally.
  var hasPresentedViewController: Bool {
    return presentedViewController != nil
  }

  /// Transitions from one view controller to another.
  ///
  /// - Parameters:
  ///   - viewController: The view controller to transition to.
  ///   - animated: Should the transition be animated? Default is true.
  ///   - completion: Optional block to fire once the transition is complete.
  func transitionToViewController(_ viewController: UIViewController,
                                  animated: Bool = true,
                                  completion: (() -> Void)? = nil) {
    let currentVC = children.last

    viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    viewController.view.frame = view.bounds
    addChild(viewController)

    let duration = animated ? 0.4 : 0

    if let currentVC = currentVC {
      currentVC.willMove(toParent: nil)
      transition(from: currentVC,
                 to: viewController,
                 duration: duration,
                 options: [.transitionCrossDissolve],
                 animations: {},
                 completion: { (_) in
        currentVC.removeFromParent()
        viewController.didMove(toParent: self)
        self.setNeedsStatusBarAppearanceUpdate()
        completion?()
      })
    } else {
      view.addSubview(viewController.view)
      UIView.animate(withDuration: duration,
                     delay: 0,
                     options: [.transitionCrossDissolve],
                     animations: {},
                     completion: { (_) in
        viewController.didMove(toParent: self)
        self.setNeedsStatusBarAppearanceUpdate()
        completion?()
      })
    }
  }

  /// Dismisses the view controller that was presented modally by the view controller, if there is
  /// one, otherwise calls completion immediately.
  ///
  /// - Parameters:
  ///   - animated: True if the transition should animate, otherwise false.
  ///   - completion: The block to execute after the view controller is dismissed, or immediately if
  ///                 dismissal is not required.
  func dismissPresentedVCIfNeeded(animated: Bool, completion: @escaping () -> Void) {
    if hasPresentedViewController {
      dismiss(animated: animated, completion: completion)
    } else {
      completion()
    }
  }

}
