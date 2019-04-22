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

extension UIView {

  /// Pin one view's anchors to the edges of another's.
  ///
  /// - Parameters:
  ///   - toView: The view to pin to.
  ///   - insets: Insets to apply to constant values for constraints.
  func pinToEdgesOfView(_ toView: UIView, withInsets insets: UIEdgeInsets = .zero) {
    self.topAnchor.constraint(equalTo: toView.topAnchor,
                              constant: insets.top).isActive = true
    self.leadingAnchor.constraint(equalTo: toView.leadingAnchor,
                                  constant: insets.left).isActive = true
    self.trailingAnchor.constraint(equalTo: toView.trailingAnchor,
                                   constant: -insets.right).isActive = true
    self.bottomAnchor.constraint(equalTo: toView.bottomAnchor,
                                 constant: -insets.bottom).isActive = true
  }

  /// Animates the rotation transform of a view.
  ///
  /// - Parameters:
  ///   - rotationAngle: The rotation transform, in radians, to animate to.
  ///   - fromAngle: The rotation transform, in radians, to animate from.
  ///   - duration: The duration of the rotation.
  func animateRotationTransform(to rotationAngle: CGFloat,
                                from fromAngle: CGFloat,
                                duration: TimeInterval) {
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    rotateAnimation.fromValue = fromAngle
    rotateAnimation.toValue = rotationAngle
    rotateAnimation.duration = duration
    rotateAnimation.isRemovedOnCompletion = false
    rotateAnimation.fillMode = .forwards
    rotateAnimation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
    layer.add(rotateAnimation, forKey: "rotate")
  }

  /// Creates a rotate and move animation that simulates a view rolling along a horizontal distance.
  /// Assumes view's constraints will reflect final position.
  ///
  /// - Parameters:
  ///   - distance: The distance to roll.
  ///   - duration: The duration of the roll.
  func animateRollRotationTransform(forDistance distance: CGFloat,
                                    duration: TimeInterval) {
    let percentCircumference = Double(abs(distance)) / (.pi * Double(frame.width))
    let radiansToRotate = 2 * .pi * percentCircumference

    var fromRadians: CGFloat
    var toRadians: CGFloat
    if distance <= 0 {
      fromRadians = CGFloat(radiansToRotate)
      toRadians = 0
    } else {
      fromRadians = 0
      toRadians = CGFloat(radiansToRotate)
    }

    let moveAnimation = CABasicAnimation(keyPath: "transform.translation.x")
    moveAnimation.fromValue = -distance
    moveAnimation.duration = duration
    moveAnimation.fillMode = .forwards
    moveAnimation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
    layer.add(moveAnimation, forKey: "rollRotationMove")

    animateRotationTransform(to: toRadians,
                             from: fromRadians,
                             duration: duration)
  }

  /// Configures an accessibility wrapping view.
  ///
  /// - Parameters:
  ///   - view: The view to configure.
  ///   - label: The accessibility label.
  ///   - hint: The optional accessibility hint.
  ///   - traits: The optional accessibility traits. Defaults to UIAccessibilityTraitButton if not
  ///             provided.
  func configureAccessibilityWrappingView(_ view: UIView,
                                          withLabel label: String? = nil,
                                          hint: String? = nil,
                                          traits: UIAccessibilityTraits = .button) {
    addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isAccessibilityElement = true
    view.accessibilityLabel = label
    view.accessibilityHint = hint
    view.accessibilityTraits = traits
    view.pinToEdgesOfView(self)
    sendSubviewToBack(view)
  }

  /// Returns the safe area insets if available, otherwise zero.
  var safeAreaInsetsOrZero: UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    if #available(iOS 11.0, *) {
      insets = safeAreaInsets
    }
    return insets
  }

  /// Adjusts the frame for user interface layout direction, if needed for RTL, assuming the frame
  /// is set for LTR. If there is no container width passed in, the width of the superview's bounds
  /// will be used, unless superview is nil, in which case this method does nothing.
  ///
  /// - Parameter containerWidth: The width of the containing bounds.
  func adjustFrameForLayoutDirection(inWidth containerWidth: CGFloat? = nil) {
    var containerWidth: CGFloat? {
      if let containerWidth = containerWidth {
        return containerWidth
      } else {
        // Use the width of the superview's bounds if there is no container width passed in.
        return superview?.bounds.width
      }
    }

    // If a container width was not passed in and the view does not have a superview, return.
    guard UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft,
        let width = containerWidth else { return }
    frame.origin.x = width - frame.origin.x - frame.width
  }

  /// Returns an image snapshot of a view.
  var imageSnapshot: UIImage? {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
    defer { UIGraphicsEndImageContext() }
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    layer.render(in: context)
    return UIGraphicsGetImageFromCurrentImageContext()
  }

}
