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

extension ActionArea {

  /// An item to be displayed in the Action Area.
  final class BarButtonItem: NSObject {

    private(set) var title: String
    private(set) var image: UIImage?
    private(set) var action: () -> Void // TODO: Consider passing the AA controller here.

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - title: The title for the item.
    ///   - image: The image for the item.
    ///   - action: A block to execute when the item is tapped.
    init(title: String, image: UIImage?, action: @escaping () -> Void) {
      self.title = title
      self.image = image
      self.action = action
    }

    @objc func execute() {
      action()
    }

  }

}
