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

/// A base class for content containers with a single child.
class ContentContainerViewController: UIViewController {

  private let content: UIViewController

  // MARK: - Initializers

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - content: The content view controller.
  init(content: UIViewController) {
    self.content = content
    super.init(nibName: nil, bundle: nil)
    addChild(content)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(content.view)
    content.didMove(toParent: self)
    content.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    content.view.frame = view.bounds
  }

  // MARK: - Implementation

  override var navigationItem: UINavigationItem {
    return content.navigationItem
  }

}
