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

@objc protocol _ActionAreaUIKitExtensions {

  /// The `actionAreaController` of the nearest parent.
  var actionAreaController: ActionArea.Controller? { get }

}

extension UIViewController: _ActionAreaUIKitExtensions {

  /// The `actionAreaController` of the nearest parent.
  ///
  /// Containers or Flow Controllers that create an `ActionArea.Controller` can override this
  /// property and return their instance, otherwise this property would be `nil`, despite an
  /// `ActionArea.Controller` being avilable in that scope.
  var actionAreaController: ActionArea.Controller? {
    var candidate: UIViewController? = parent
    while candidate != nil {
      if let aac = candidate as? ActionArea.Controller {
        return aac
      }
      candidate = candidate?.parent
    }
    return nil
  }

}

// MARK: - Debugging

#if DEBUG

extension UINavigationController.Operation: CustomStringConvertible {

  public var description: String {
    switch self {
    case .none:
      return "none"
    case .push:
      return "push"
    case .pop:
      return "pop"
    }
  }

}

extension UIViewController {
  var viewControllerDepth: Int {
    var depth = 0
    var optionalParent = parent
    while let parent = optionalParent {
      depth += 1
      optionalParent = parent.parent
    }
    return depth
  }

  var depthWithinActionArea: Int {
    guard let actionAreaController = actionAreaController else { return 0 }
    return viewControllerDepth - actionAreaController.viewControllerDepth
  }

  var aaPrefix: String {
    return (0 ..< depthWithinActionArea).reduce(into: "|") { s, _ in s.write("-") }
  }
}
#endif
