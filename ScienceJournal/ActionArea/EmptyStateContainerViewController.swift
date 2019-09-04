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

  /// A container for detail empty state view controllers in the Action Area.
  final class EmptyStateContainerViewController: ContentContainerViewController, EmptyState {

    private enum Metrics {
      static let disabledAlpha: CGFloat = 0.2
    }

    private let emptyState: UIViewController

    // MARK: - Initializers

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - emptyState: The empty state view controller. Cannot have a material header.
    init(emptyState: UIViewController) {
      guard emptyState is EmptyState == false else {
        preconditionFailure("Empty state view controllers cannot be nested.")
      }
      guard !emptyState.hasMaterialHeader else {
        // The empty state content cannot have its own header because it would be affected by the
        // disabled appearance.
        preconditionFailure("Empty state view controllers cannot have a material header.")
      }

      self.emptyState = emptyState
      let content: UIViewController
      if emptyState.hasMaterialHeader {
        content = emptyState
      } else {
        content = MaterialHeaderContainerViewController(content: emptyState)
      }
      super.init(content: content)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ActionArea.EmptyState

    var isEnabled: Bool = true {
      didSet {
        switch isEnabled {
        case true:
          emptyState.view.alpha = 1
        case false:
          emptyState.view.alpha = Metrics.disabledAlpha
        }
      }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
      super.viewDidLoad()

      // Copy the `emptyState` background color, so it is still visible when the content's alpha
      // is reduced.
      view.backgroundColor = emptyState.view.backgroundColor
    }

    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)

      // Empty state content in the Action Area should never have a back button.
      navigationItem.hidesBackButton = true
    }

    // MARK: - Implementation

    override var description: String {
      return "ActionArea.EmptyStateContainerViewController(content: \(emptyState))"
    }

  }

}
