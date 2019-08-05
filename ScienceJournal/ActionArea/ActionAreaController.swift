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

  private struct Metrics {
    static let defaultAnimationDuration: TimeInterval = 0.4
  }

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
    return nc
  }()

  // TODO: Make these non-optional
  private var buttonBarViewController: ActionAreaButtonBarViewController?
  private var svController: UISplitViewController?

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
        if detailNavController.parent == nil {
          // If there's no `parent`, the detail was dismissed, so we need to clean up.
          viewControllerBarItems.removeValue(forKey: detailViewController)
          detailNavController.setViewControllers([], animated: false)
          updateActionAreaBar(for: navController.topViewController)
        } else {
          // Otherwise just update the actions
          updateActionAreaBar(for: detailViewController)
        }
      case .modal:
        updateActionAreaBar(for: detailViewController)
      }
    }
  }

  init() {
    precondition(FeatureFlags.isActionAreaEnabled,
                 "This class can only be used when Action Area is enabled.")
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navController.delegate = self

    let svController = UISplitViewController()
    svController.presentsWithGesture = false
    svController.viewControllers = [navController, detailNavController]
    svController.delegate = self
    self.svController = svController

    let buttonBarViewController =
      ActionAreaButtonBarViewController(contentViewController: svController)
    addChild(buttonBarViewController)
    view.addSubview(buttonBarViewController.view)
    buttonBarViewController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
    buttonBarViewController.didMove(toParent: self)
    self.buttonBarViewController = buttonBarViewController
  }

  func show(_ vc: UIViewController, with items: [ActionAreaBarItem]) {
    guard state == .normal else {
      fatalError("View controllers cannot be pushed during a modal detail presentation.")
    }

    viewControllerBarItems[vc] = .persistent(items)
    navController.pushViewController(vc, animated: true)
  }

  private func updateActionAreaBar(for vc: UIViewController?) {
    guard vc != detailNavController else {
      // If the `UISplitViewController` is collapsed, we may get the `detailNavController`
      // being presented within the `navController`. In this case we've already updated
      // the actions, so there's nothing more to do.
      return
    }

    let items: [UIBarButtonItem]
    if let vc = vc {
      switch viewControllerBarItems[vc] {
      case .none:
        items = []
      case .some(.persistent(let itemDefinitions)):
        switch state {
        case .normal:
          items = itemDefinitions.map(createBarButtonItem(from:))
        case .modal:
          return
        }
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

    buttonBarViewController?.items = items
  }

  private func removeUnusedBarItems() {
    viewControllerBarItems = viewControllerBarItems.filter { (key, _) -> Bool in
      return navController.viewControllers.contains(key) ||
        detailNavController.viewControllers.contains(key)
    }
  }

  func show(detail detailViewController: UIViewController, with items: [ActionAreaBarItem]) {
    guard detailNavController.topViewController == nil else {
      fatalError("A detailViewController is already being shown.")
    }

    detailNavController.setViewControllers([detailViewController], animated: false)
    svController?.showDetailViewController(detailNavController, sender: self)

    viewControllerBarItems[detailViewController] = .persistent(items)
    updateActionAreaBar(for: detailViewController)
  }

  func show(detail detailViewController: UIViewController,
            toggle passive: ToggleState,
            and active: ToggleState) {
    guard detailNavController.topViewController == nil else {
      fatalError("A detailViewController is already being shown.")
    }

    detailNavController.setViewControllers([detailViewController], animated: false)
    svController?.showDetailViewController(detailNavController, sender: self)

    viewControllerBarItems[detailViewController] = .toggle(passive, active)
    updateActionAreaBar(for: detailViewController)
  }

  func dismissDetail() {
    guard let detailViewController = detailNavController.topViewController else {
      fatalError("A detailViewController is not currently being shown.")
    }

    switch state {
    case .normal:
      viewControllerBarItems.removeValue(forKey: detailViewController)

      updateActionAreaBar(for: navController.topViewController)

      navController.popViewController(animated: true)
      detailNavController.setViewControllers([], animated: false)
    case .modal:
      navController.popViewController(animated: true)
    }
  }

  func reshowDetail() {
    guard detailNavController.topViewController != nil else {
      fatalError("A detailViewController is not currently being shown.")
    }
    guard state == .modal else {
      fatalError("The Action Area can only reshow in the modal state.")
    }

    svController?.showDetailViewController(detailNavController, sender: self)
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

// TODO: Remove print statements after implementing the tablet, landscape layout.
extension ActionAreaController: UISplitViewControllerDelegate {
  func primaryViewController(
    forCollapsing splitViewController: UISplitViewController
  ) -> UIViewController? {
    print("\(type(of: self)) \(#function) - vcs: \(splitViewController.viewControllers)")
    return nil // nil for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           collapseSecondary secondaryViewController: UIViewController,
                           onto primaryViewController: UIViewController) -> Bool {
    print("\(type(of: self)) \(#function) - vcs: \(splitViewController.viewControllers)")
    return false // false for default behavior
  }

  func primaryViewController(
    forExpanding splitViewController: UISplitViewController
  ) -> UIViewController? {
    print("\(type(of: self)) \(#function) - vcs: \(splitViewController.viewControllers)")
    return nil // nil for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           separateSecondaryFrom primaryViewController: UIViewController
  ) -> UIViewController? {
    print("\(type(of: self)) \(#function) - vcs: \(splitViewController.viewControllers)")
    return nil // nil for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           show vc: UIViewController, sender: Any?) -> Bool {
    print("\(type(of: self)) \(#function) - vcs: \(splitViewController.viewControllers)")
    return false // false for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           showDetail vc: UIViewController, sender: Any?) -> Bool {
    print("\(type(of: self)) \(#function) - vcs: \(splitViewController.viewControllers)")
    return false // false for default behavior
  }
}

extension ActionAreaController: UINavigationControllerDelegate {

  func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool) {
    updateActionAreaBar(for: viewController)
  }

  func navigationController(_ navigationController: UINavigationController,
                            didShow viewController: UIViewController, animated: Bool) {
    removeUnusedBarItems()
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
// TODO: Consider making this private and wrapping content VCs that are not subclasses
//       of the other material header types.
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
