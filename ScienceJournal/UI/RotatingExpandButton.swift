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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons

/// A button with an animating arrow, showing that content can be expanded.
class RotatingExpandButton: MDCFlatButton {

  /// Directions the button's arrow can point in.
  enum ArrowDirection {
    case up
    case down

    /// The angle of the asset for the direction.
    var angle: CGFloat {
      let arrowUp = CGFloat(-Double.pi)
      let arrowDown: CGFloat = 0
      switch self {
      case .up:
        return arrowUp
      case .down:
        return arrowDown
      }
    }
  }

  /// The direction for the button's arrow to point in.
  var direction: ArrowDirection {
    didSet {
      transform = CGAffineTransform(rotationAngle: direction.angle)
      accessibilityLabel = direction == ArrowDirection.up ?
          String.sensorsListExpandContentDescription : String.sensorsListCollapseContentDescription
    }
  }

  /// Designated initializer.
  ///
  /// - Parameter arrowDirection: The direction for the arrow to point in.
  init(arrowDirection: ArrowDirection) {
    direction = arrowDirection
    super.init(frame: .zero)
    setImage(UIImage(named: "ic_expand_more"), for: .normal)
    transform = CGAffineTransform(rotationAngle: direction.angle)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Sets the direction property by animating the change.
  ///
  /// - Parameter direction: The direction to animate to.
  func setDirectionAnimated(_ direction: ArrowDirection) {
    animateRotationTransform(to: direction.angle, from: self.direction.angle, duration: 0.2)
    self.direction = direction
  }

}
