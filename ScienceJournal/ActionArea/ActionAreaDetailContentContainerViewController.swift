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

  /// A container for detail content view controllers in the Action Area.
  final class DetailContentContainerViewController: UIViewController, DetailContent {

    /// The mode for this content.
    var mode: ContentMode

    private let content: UIViewController
    private var shouldAddCloseButton = false

    // MARK: - Initializers

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - content: The content view controller.
    ///   - mode: The mode for this content.
    init(content: UIViewController, mode: ContentMode) {
      self.content = content
      self.mode = mode
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    /// Convenience initializer.
    ///
    /// - Parameters:
    ///   - content: The content view controller.
    ///   - mode: A block that returns the mode for this content.
    convenience init(content: UIViewController, mode: () -> ContentMode) {
      self.init(content: content, mode: mode())
    }

    // MARK: - API

    // TODO: Replace this with an API for content VCs to specify their close button.
    func addCloseButton() {
      shouldAddCloseButton = true
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
      super.viewDidLoad()

      addChild(content)
      view.addSubview(content.view)
      content.didMove(toParent: self)
      content.view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      if shouldAddCloseButton {
        content.navigationItem.leftBarButtonItem =
          // TODO: Use correct assets if we don't remove this.
          UIBarButtonItem(title: "X",
                          style: .plain,
                          target: self,
                          action: #selector(close))
      }
    }

    // MARK: - Implementation

    override var description: String {
      return "\(type(of: self))(content: \(String(describing: content)))"
    }

    @objc private func close() {
      if let navigationController = navigationController {
        navigationController.popViewController(animated: true)
      } else {
        dismiss(animated: true, completion: nil)
      }
    }

  }

}
