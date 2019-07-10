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

  private enum State {
    case normal
    case modal
  }

  private enum BarItemMode {
    case persistent([ActionAreaBarItem])
    case toggle(ToggleState, ToggleState)
  }

  typealias ToggleState = (ActionAreaBarItem, [ActionAreaBarItem])

  let navController: UINavigationController = {
    let nc = UINavigationController()
    nc.isNavigationBarHidden = true
    return nc
  }()

  private let detailNavController: UINavigationController = {
    let nc = UINavigationController()
    nc.isNavigationBarHidden = true
    nc.view.isHidden = true
    return nc
  }()

  private let buttonBar: MDCButtonBar = {
    let buttonBar = MDCButtonBar()
    buttonBar.backgroundColor = .white
    buttonBar.setButtonsTitleColor(.gray, for: .normal)
    return buttonBar
  }()

  private var buttonBarTopEqualToSuperviewBottomConstraint: Constraint?
  private var buttonBarBottomEqualToSuperviewBottomConstraint: Constraint?
  private let defaultAnimationDuration: TimeInterval = 0.4
  private var viewControllerBarItems: [UIViewController: BarItemMode] = [:]

  private var state: State = .normal {
    willSet {
      guard state != newValue else {
        fatalError("Setting the state to the existing state is not allowed.")
      }
    }

    didSet {
      guard let detailViewController = detailNavController.topViewController else {
        fatalError("The state can only be changed when a detailViewController is shown.")
      }

      switch state {
      case .normal:
        if detailNavController.view.isHidden {
          viewControllerBarItems.removeValue(forKey: detailViewController)
          detailNavController.setViewControllers([], animated: false)
          updateActionAreaBar(for: navController.topViewController)
        } else {
          updateActionAreaBar(for: detailNavController.topViewController)
        }
      case .modal:
        updateActionAreaBar(for: detailNavController.topViewController)
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if FeatureFlags.isActionAreaEnabled {
      navController.delegate = self
    }

    addChild(navController)
    view.addSubview(navController.view)
    navController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
    navController.didMove(toParent: self)

    addChild(detailNavController)
    view.addSubview(detailNavController.view)
    detailNavController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
    detailNavController.didMove(toParent: self)

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
        updateAdditionalSafeAreaInsets(isButtonBarVisible: newValue)
        animate()
      case (true, false):
        buttonBarTopEqualToSuperviewBottomConstraint?.activate()
        buttonBarBottomEqualToSuperviewBottomConstraint?.deactivate()
        updateAdditionalSafeAreaInsets(isButtonBarVisible: newValue)
        animate()
      default:
        break
      }
    }
  }

  private func updateAdditionalSafeAreaInsets(isButtonBarVisible: Bool) {
    if isButtonBarVisible {
      let insets = UIEdgeInsets(top: 0, left: 0, bottom: buttonBar.bounds.height, right: 0)
      navController.additionalSafeAreaInsets = insets
      detailNavController.additionalSafeAreaInsets = insets
    } else {
      navController.additionalSafeAreaInsets = .zero
      detailNavController.additionalSafeAreaInsets = .zero
    }
  }

  func push(_ vc: UIViewController, animated: Bool, with items: [ActionAreaBarItem]) {
    guard state == .normal else {
      fatalError("View controllers cannot be pushed during a modal detail presentation.")
    }

    if FeatureFlags.isActionAreaEnabled {
      viewControllerBarItems[vc] = .persistent(items)
    }
    navController.pushViewController(vc, animated: animated)
  }

  private func updateActionAreaBar(for vc: UIViewController?) {
    let items: [UIBarButtonItem]
    if let vc = vc {
      switch viewControllerBarItems[vc] {
      case .none:
        items = []
      case .some(.persistent(let itemDefinitions)):
        items = itemDefinitions.map(createBarButtonItem(from:))
      case .some(let .toggle(passive, active)):
        switch state {
        case .normal:
          items = passive.1.map(createBarButtonItem(from:)) + [wrapBarButtonItem(from: passive.0)]
        case .modal:
          items = active.1.map(createBarButtonItem(from:)) + [wrapBarButtonItem(from: active.0)]
        }
      }
    } else {
      items = []
    }
    buttonBar.items = items
    isButtonBarVisible = !items.isEmpty
  }

  func pop(to vc: UIViewController, animated: Bool) {
    guard state == .normal else {
      fatalError("View controllers cannot be popped during a modal detail presentation.")
    }

    if FeatureFlags.isActionAreaEnabled {
      viewControllerBarItems.removeValue(forKey: vc)
    }
    navController.popToViewController(vc, animated: animated)
  }

  func pop(animated: Bool) {
    guard state == .normal else {
      fatalError("View controllers cannot be popped during a modal detail presentation.")
    }

    guard let vc = navController.topViewController else { return }

    if FeatureFlags.isActionAreaEnabled {
      viewControllerBarItems.removeValue(forKey: vc)
    }
    navController.popViewController(animated: animated)
  }

  func show(detail detailViewController: UIViewController, with items: [ActionAreaBarItem]) {
    guard detailNavController.topViewController == nil else {
      fatalError("A detailViewController is already being shown.")
    }

    detailNavController.setViewControllers([detailViewController], animated: false)

    viewControllerBarItems[detailViewController] = .persistent(items)

    positionBelowScreen(detailNavController)
    detailNavController.view.isHidden = false

    updateActionAreaBar(for: detailViewController)
    UIView.animate(withDuration: defaultAnimationDuration) {
      self.detailNavController.view.transform = .identity
    }
  }

  private func positionBelowScreen(_ vc: UIViewController) {
    let height = vc.view.bounds.height
    vc.view.transform = CGAffineTransform(translationX: 0, y: height)
  }

  func show(detail detailViewController: UIViewController,
            toggle passive: ToggleState,
            and active: ToggleState) {
    guard detailNavController.topViewController == nil else {
      fatalError("A detailViewController is already being shown.")
    }

    detailNavController.setViewControllers([detailViewController], animated: false)

    viewControllerBarItems[detailViewController] = .toggle(passive, active)

    positionBelowScreen(detailNavController)
    detailNavController.view.isHidden = false

    updateActionAreaBar(for: detailViewController)
    UIView.animate(withDuration: defaultAnimationDuration) {
      self.detailNavController.view.transform = .identity
    }
  }

  func dismissDetail() {
    guard let detailViewController = detailNavController.topViewController else {
      fatalError("A detailViewController is not currently being shown.")
    }

    switch state {
    case .normal:
      viewControllerBarItems.removeValue(forKey: detailViewController)

      updateActionAreaBar(for: navController.topViewController)
      UIView.animate(withDuration: defaultAnimationDuration, animations: {
        self.positionBelowScreen(self.detailNavController)
      }) { (_) in
        self.detailNavController.setViewControllers([], animated: false)
        self.detailNavController.view.isHidden = true
      }
    case .modal:
      UIView.animate(withDuration: defaultAnimationDuration, animations: {
        self.positionBelowScreen(self.detailNavController)
      }) { (_) in
        self.detailNavController.view.isHidden = true
      }
    }
  }

  func reshowDetail() {
    guard detailNavController.topViewController != nil else {
      fatalError("A detailViewController is not currently being shown.")
    }
    guard detailNavController.view.isHidden else {
      fatalError("A detailViewController is not currently hidden.")
    }
    guard state == .modal else {
      fatalError("The Action Area can only reshow in the modal state.")
    }

    positionBelowScreen(detailNavController)
    detailNavController.view.isHidden = false

    UIView.animate(withDuration: defaultAnimationDuration) {
      self.detailNavController.view.transform = .identity
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

  // TODO: Figure out when/where to nil this out
  private var wrapper: ActionAreaBarItem?

  private func wrapBarButtonItem(from item: ActionAreaBarItem) -> UIBarButtonItem {
    let wrapper = ActionAreaBarItem(
      title: item.title,
      image: item.image
    ) {
      item.action()
      self.toggleState()
    }
    self.wrapper = wrapper
    return createBarButtonItem(from: wrapper)
  }

  private func toggleState() {
    state = state == .normal ? .modal : .normal
  }

}

extension ActionAreaController: UINavigationControllerDelegate {

  func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool) {
    updateActionAreaBar(for: viewController)
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
final class MaterialHeaderContainerViewController: UIViewController {

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
