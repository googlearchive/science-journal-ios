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

extension UIView {

  /// Animates a circular mask to reveal/hide a view.
  ///
  /// - Parameters:
  ///   - fromView: The view from which to start (or end) the circle mask transition.
  ///   - hide: Whether or not the animation should go in reverse (hide rather than show).
  ///           Default is `false`.
  ///   - duration: Animation duration time interval. Default is `0.2`.
  ///   - completion: Optional closure to run once the animation is complete.
  func animateCircleMask(fromView: UIView,
                         hide: Bool = false,
                         duration: TimeInterval = 0.2,
                         completion: (() -> Void)? = nil) {

    let shortestDimension = min(fromView.bounds.width, fromView.bounds.height)
    let longestDimension = max(bounds.width, bounds.height)

    let fromRect = CGRect(x: fromView.frame.minX + (shortestDimension / 2),
                          y: convert(fromView.frame, from: fromView).minY - (shortestDimension / 2),
                          width: shortestDimension,
                          height: shortestDimension).integral
    let toRect = CGRect(x: frame.minX - (longestDimension / 2),
                        y: frame.minY - (longestDimension / 2),
                        width: longestDimension * 2,
                        height: longestDimension * 2).integral

    let startPath = UIBezierPath(ovalIn: hide ? toRect : fromRect)
    let endPath = UIBezierPath(ovalIn: hide ? fromRect : toRect)

    let maskLayer = CAShapeLayer()
    maskLayer.path = endPath.cgPath
    maskLayer.fillColor = UIColor(white: 1.0, alpha: 1.0).cgColor
    layer.mask = maskLayer

    if !hide {
      isHidden = false
    }

    CATransaction.begin()
    CATransaction.setCompletionBlock {
      self.layer.mask = nil
      if hide {
        self.isHidden = true
      }
      if let completion = completion {
        completion()
      }
    }

    let animation = CABasicAnimation()
    animation.keyPath = "path";
    animation.beginTime = CACurrentMediaTime()
    animation.fromValue = startPath.cgPath
    animation.toValue = endPath.cgPath
    animation.duration = duration
    animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    maskLayer.add(animation, forKey: "CircleMaskAnimation")
    CATransaction.commit()
  }

}
