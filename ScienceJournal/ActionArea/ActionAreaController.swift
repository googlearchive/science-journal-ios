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

import third_party_objective_c_material_components_ios_components_AppBar_AppBar
import third_party_objective_c_material_components_ios_components_ButtonBar_ButtonBar

final class ActionAreaBarItem: NSObject {
  private(set) var title: String
  private(set) var image: UIImage?
  private(set) var action: () -> Void

  init(title: String, image: UIImage?, action: @escaping () -> Void) {
    self.title = title
    self.image = image
    self.action = action
  }

  @objc
  fileprivate func execute() {
    action()
  }
}

final class ActionAreaController: UIViewController {

  let navController = UINavigationController()

  private let buttonBar: MDCButtonBar = {
    let buttonBar = MDCButtonBar()
    buttonBar.backgroundColor = .white
    buttonBar.setButtonsTitleColor(.gray, for: .normal)
    return buttonBar
  }()

  private var buttonBarTopEqualToSuperviewBottomConstraint: Constraint?
  private var buttonBarBottomEqualToSuperviewBottomConstraint: Constraint?
  private var detailNavController: UINavigationController?
  private let defaultAnimationDuration: TimeInterval = 0.4
  private var viewControllerBarItems: [UIViewController: [ActionAreaBarItem]] = [:]

  override func viewDidLoad() {
    super.viewDidLoad()

    addChild(navController)
    view.addSubview(navController.view)
    navController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
    navController.didMove(toParent: self)

    view.addSubview(buttonBar)
    buttonBar.snp.makeConstraints { (make) in
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(88)

      buttonBarTopEqualToSuperviewBottomConstraint = make.top.equalTo(view.snp.bottom).constraint
    }

    buttonBar.snp.prepareConstraints { (make) in
      buttonBarBottomEqualToSuperviewBottomConstraint =
        make.bottom.equalTo(view.snp.bottom).constraint
    }
  }

  private var isButtonBarVisible: Bool = false {
    willSet {
      // TODO: Pull this out and coordinate transition animations
      func animate() {
        UIView.animate(withDuration: defaultAnimationDuration) {
          self.view.layoutIfNeeded()
        }
      }

      switch (isButtonBarVisible, newValue) {
      case (false, true):
        buttonBarTopEqualToSuperviewBottomConstraint?.deactivate()
        buttonBarBottomEqualToSuperviewBottomConstraint?.activate()
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: buttonBar.bounds.height, right: 0)
        navController.additionalSafeAreaInsets = insets
        detailNavController?.additionalSafeAreaInsets = insets
        animate()
      case (true, false):
        buttonBarTopEqualToSuperviewBottomConstraint?.activate()
        buttonBarBottomEqualToSuperviewBottomConstraint?.deactivate()
        navController.additionalSafeAreaInsets = .zero
        detailNavController?.additionalSafeAreaInsets = .zero
        animate()
      default:
        break
      }
    }
  }

  func push(_ vc: UIViewController, animated: Bool, with items: [ActionAreaBarItem]) {
    if FeatureFlags.isActionAreaEnabled {
      viewControllerBarItems[vc] = items
      updateActionAreaBar(for: vc)
    }
    navController.pushViewController(vc, animated: animated)
  }

  private func updateActionAreaBar(for vc: UIViewController?) {
    guard let vc = vc else { return }

    let items = viewControllerBarItems[vc, default: []].map(createBarButtonItem(from:))
    buttonBar.items = items
    isButtonBarVisible = !items.isEmpty
  }

  func pop(to vc: UIViewController, animated: Bool) {
    if FeatureFlags.isActionAreaEnabled {
      viewControllerBarItems.removeValue(forKey: vc)
      updateActionAreaBar(for: vc)
    }
    navController.popToViewController(vc, animated: animated)
  }

  func pop(animated: Bool) {
    guard let vc = navController.topViewController else { return }

    if FeatureFlags.isActionAreaEnabled {
      viewControllerBarItems.removeValue(forKey: vc)
      updateActionAreaBar(for: vc)
    }
    navController.popViewController(animated: animated)
  }

  func show(detail detailViewController: UIViewController, with items: [ActionAreaBarItem]) {
    assert(self.detailNavController == nil, "a detailViewController is already shown")

    let detailNavController = UINavigationController(rootViewController: detailViewController)
    detailNavController.isNavigationBarHidden = true
    self.detailNavController = detailNavController

    viewControllerBarItems[detailViewController] = items
    // TODO: This has to be called after the detail nav is set - remove ordering dependency
    updateActionAreaBar(for: detailViewController)

    addChild(detailNavController)

    view.insertSubview(detailNavController.view, belowSubview: buttonBar)
    detailNavController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    positionBelowScreen(detailViewController)

    UIView.animate(withDuration: defaultAnimationDuration, animations: {
      detailViewController.view.transform = .identity
    }) { (_) in
      detailNavController.didMove(toParent: self)
    }
  }

  private func positionBelowScreen(_ vc: UIViewController) {
    let height = vc.view.bounds.height
    vc.view.transform = CGAffineTransform(translationX: 0, y: height)
  }

  func dismissDetail() {
    guard
      let detailNavController = detailNavController,
      let detailViewController = detailNavController.topViewController else { return }

    viewControllerBarItems.removeValue(forKey: detailViewController)
    updateActionAreaBar(for: navController.topViewController)

    detailNavController.willMove(toParent: nil)

    UIView.animate(withDuration: defaultAnimationDuration, animations: {
      self.positionBelowScreen(detailNavController)
    }) { (_) in
      detailNavController.view.removeFromSuperview()
      detailNavController.removeFromParent()
      self.detailNavController = nil
    }
  }

  private func createBarButtonItem(from item: ActionAreaBarItem) -> UIBarButtonItem {
    let barButtonItem = UIBarButtonItem(title: item.title,
                                        style: .plain,
                                        target: item,
                                        action: #selector(ActionAreaBarItem.execute))
    barButtonItem.image = item.image
    return barButtonItem
  }

}

extension UIViewController {
  var actionAreaController: ActionAreaController? {
    var candidate: UIViewController? = parent
    while candidate != nil {
      if let aac = candidate as? ActionAreaController {
        return aac
      }
      candidate = candidate?.parent
    }
    return nil
  }
}

// TODO: Ensure this handles existing issues or use one of the other superclasses.
class MaterialHeaderContainerViewController: UIViewController {

  private let appBar = MDCAppBar()
  private let contentViewController: UICollectionViewController

  init(contentViewController: UICollectionViewController) {
    self.contentViewController = contentViewController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChild(contentViewController)
    view.addSubview(contentViewController.view)
    contentViewController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
    contentViewController.didMove(toParent: self)

    navigationItem.leftBarButtonItem =
      UIBarButtonItem(title: "Close",
                      style: .plain,
                      target: self,
                      action: #selector(close))

    appBar.configure(attachTo: self, scrollView: contentViewController.collectionView)
  }

  @objc
  private func close() {
    actionAreaController?.dismissDetail()
  }

}
