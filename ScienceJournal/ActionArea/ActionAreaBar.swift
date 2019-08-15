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

import SnapKit
import UIKit

import third_party_objective_c_material_components_ios_components_ButtonBar_ButtonBar

extension ActionArea {

  /// The bar where items are displayed.
  final class Bar: UIViewController {

    private struct Metrics {
      static let defaultAnimationDuration: TimeInterval = 0.4
      static let buttonBarHeight: CGFloat = 88
      static let buttonBarBackgroundColor = UIColor(white: 0.98, alpha: 1.0)
      static let buttonBarButtonTitleColor: UIColor = .gray
      static let buttonBarCornerRadius: CGFloat = 15
    }

    private struct VisibilityConstraints {
      let hidden: Constraint
      let visible: Constraint

      func hide() {
        visible.deactivate()
        hidden.activate()
      }

      func show() {
        hidden.deactivate()
        visible.activate()
      }
    }

    private let buttonBar: MDCButtonBar = {
      let buttonBar = MDCButtonBar()
      buttonBar.backgroundColor = Metrics.buttonBarBackgroundColor
      buttonBar.setButtonsTitleColor(Metrics.buttonBarButtonTitleColor, for: .normal)
      buttonBar.layer.cornerRadius = Metrics.buttonBarCornerRadius
      buttonBar.layer.masksToBounds = true
      return buttonBar
    }()

    /// The items to display in the Action Area bar.
    var items: [UIBarButtonItem] = [] {
      didSet {
        buttonBar.items = items
        isButtonBarVisible = !items.isEmpty
      }
    }

    private var visibilityConstraints: VisibilityConstraints! // set in viewDidLoad
    private let contentViewController: UIViewController

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - contentViewController: The content on which to overlay the button bar.
    init(contentViewController: UIViewController) {
      self.contentViewController = contentViewController
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
      super.viewDidLoad()

      addChild(contentViewController)
      view.addSubview(contentViewController.view)
      contentViewController.view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      contentViewController.didMove(toParent: self)

      view.addSubview(buttonBar)
      buttonBar.snp.makeConstraints { make in
        make.leadingMargin.trailingMargin.equalToSuperview()
        make.height.equalTo(Metrics.buttonBarHeight)
      }
      buttonBar.snp.prepareConstraints { make in
        let hidden = make.top.equalTo(view.snp.bottom).constraint
        let visible = make.bottomMargin.equalToSuperview().constraint
        self.visibilityConstraints = VisibilityConstraints(hidden: hidden, visible: visible)
      }

      visibilityConstraints.hide()
    }

    // MARK: - Implementation

    private var isButtonBarVisible: Bool = false {
      willSet {
        switch (isButtonBarVisible, newValue) {
        case (false, true):
          visibilityConstraints.show()
          additionalSafeAreaInsets =
            UIEdgeInsets(top: 0, left: 0, bottom: Metrics.buttonBarHeight, right: 0)
        case (true, false):
          visibilityConstraints.hide()
          additionalSafeAreaInsets = .zero
        default:
          break
        }
      }
    }

  }

}
