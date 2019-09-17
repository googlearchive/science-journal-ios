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

/// A bar button item that can be used throughout Science Journal navigation bars as a back or left
/// button.
class MaterialLeftBarButtonItem: UIBarButtonItem {

  init(target: Any, action: Selector) {
    super.init()
    style = .plain
    tintColor = .white
    self.target = target as AnyObject
    self.action = action
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

}

/// A subclass of the left bar button item that can be used for a back button.
class MaterialBackBarButtonItem: MaterialLeftBarButtonItem {

  override init(target: Any, action: Selector) {
    super.init(target: target, action: action)
    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
      image = UIImage(named: "ic_arrow_forward", in: Bundle.currentBundle, compatibleWith: nil)
    } else {
      image = UIImage(named: "ic_arrow_back", in: Bundle.currentBundle, compatibleWith: nil)
    }
    accessibilityLabel = String.backBtnContentDescription
    accessibilityHint = String.backBtnContentDetails
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

}

/// A subclass of the left bar button item that can be used for a close button.
class MaterialCloseBarButtonItem: MaterialLeftBarButtonItem {

  override init(target: Any, action: Selector) {
    super.init(target: target, action: action)
    image = UIImage(named: "ic_close")
    accessibilityLabel = String.closeBtnContentDescription
    accessibilityHint = String.closeBtnContentDetails
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

}
