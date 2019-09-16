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
    let mode: ContentMode

    /// The close button item, if the content view controller has one.
    let closeButtonItem: UIBarButtonItem?

    private let content: UIViewController
    private var originalContentHidesBackButton: Bool = false

    // MARK: - MaterialHeader

    override var hasMaterialHeader: Bool { return true }

    // MARK: - Initializers

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - content: The content view controller.
    ///   - closeButtonItem: The content view controller's close button item.
    ///   - mode: The mode for this content.
    init(content: UIViewController, closeButtonItem: UIBarButtonItem? = nil, mode: ContentMode) {
      self.content = content
      self.closeButtonItem = closeButtonItem
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
    ///   - closeButtonItem: The content view controller's close button item.
    ///   - mode: A block that returns the mode for this content.
    convenience init(
      content: UIViewController, closeButtonItem: UIBarButtonItem? = nil, mode: () -> ContentMode
    ) {
      self.init(content: content, closeButtonItem: closeButtonItem, mode: mode())
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
      super.viewDidLoad()

      addContent()
    }

    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)

      if closeButtonItem == nil {
        assert(
          navigationItem.leftBarButtonItem == nil,
          "Found existing leftBarButtonItem. " +
            "Specify the content's close button via `DetailContent.closeButtonItem`."
        )
        navigationItem.leftBarButtonItem = defaultCloseButtonItem
      }

      // The AA detail should never show a back button.
      originalContentHidesBackButton = content.navigationItem.hidesBackButton
      content.navigationItem.hidesBackButton = true
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)

      navigationItem.leftBarButtonItem = closeButtonItem
      content.navigationItem.hidesBackButton = originalContentHidesBackButton
    }

    private func addContent() {
      let vc: UIViewController
      if content.hasMaterialHeader {
        vc = content
      } else {
        let header = MaterialHeaderContainerViewController(content: content)
        vc = header
      }

      addChild(vc)
      view.addSubview(vc.view)
      vc.didMove(toParent: self)
      vc.view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }

    // MARK: - Implementation

    override var navigationItem: UINavigationItem {
      return content.navigationItem
    }

    override var description: String {
      return "ActionArea.DetailContentContainerViewController(content: \(content))"
    }

    func actionAreaStateDidChange(_ actionAreaController: ActionArea.Controller) {
      // Do not modify the `navigationItem` unless we're currently being shown.
      guard parent != nil else { return }

      let item: UIBarButtonItem?
      switch actionAreaController.state {
      case .normal:
        item = closeButtonItem ?? defaultCloseButtonItem
      case .modal:
        item = actionAreaController.isExpanded ? nil : hideButtonItem
      }
      navigationItem.leftBarButtonItem = item
    }

    private lazy var defaultCloseButtonItem: UIBarButtonItem = {
      UIBarButtonItem(image: UIImage(named: "ic_close"),
                      style: .plain,
                      target: self,
                      action: #selector(close))
    }()

    private lazy var hideButtonItem: UIBarButtonItem = {
      UIBarButtonItem(image: UIImage(named: "ic_expand_more"),
                      style: .plain,
                      target: self,
                      action: #selector(close))
    }()

    @objc private func close() {
      if let navigationController = navigationController {
        navigationController.popViewController(animated: true)
      } else {
        dismiss(animated: true, completion: nil)
      }
    }

  }

}
