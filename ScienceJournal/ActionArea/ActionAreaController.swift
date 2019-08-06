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

    // The fractional width of the master content area.
    static let preferredPrimaryColumnWidthFraction: CGFloat = 0.6
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
    let detail = DetailEmptyStateViewController()
    let header = MaterialHeaderContainerViewController(contentViewController: detail)
    header.showCloseButton = false
    nc.setViewControllers([header], animated: false)
    return nc
  }()

  // TODO: Make this non-optional
  private var buttonBarViewController: ActionAreaButtonBarViewController?
  private let svController = UISplitViewController()
  private var viewControllerBarItems: [UIViewController: BarItemMode] = [:]
  private var presentedDetailViewController: UIViewController?
  private let preferredPrimaryColumnWidthFractionWhenDetailIsHidden: CGFloat = 1.0

  private var state: State = .normal {
    willSet {
      guard state != newValue else {
        fatalError("Setting the state to the existing state is not allowed.")
      }
    }

    didSet {
      guard let presentedDetailViewController = presentedDetailViewController else {
        fatalError("The state can only be changed when a detailViewController is shown.")
      }

      switch state {
      case .normal:
        if presentedDetailViewController.parent == nil {
          // If there's no `parent`, the detail was already dismissed, so we need to clean up.
          viewControllerBarItems.removeValue(forKey: presentedDetailViewController)
          updateActionAreaBar(for: navController.topViewController)
        } else {
          // Otherwise just update the actions
          updateActionAreaBar(for: presentedDetailViewController)
        }
      case .modal:
        updateActionAreaBar(for: presentedDetailViewController)
      }
    }
  }

  // MARK: - Initializers

  init() {
    precondition(FeatureFlags.isActionAreaEnabled,
                 "This class can only be used when Action Area is enabled.")
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    navController.delegate = self

    // Set `viewControllers` first to avoid warnings.
    svController.viewControllers = [navController, detailNavController]
    svController.presentsWithGesture = false
    // When set to `automatic`, iPad uses `primaryOverlay` in portrait orientations, which
    // can result in `viewDidAppear` not being called on detail view controllers.
    svController.preferredDisplayMode = .allVisible
    svController.delegate = self

    let longestDimension = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
    svController.minimumPrimaryColumnWidth =
      floor(longestDimension * Metrics.preferredPrimaryColumnWidthFraction)
    svController.maximumPrimaryColumnWidth = longestDimension

    let buttonBarViewController =
      ActionAreaButtonBarViewController(contentViewController: svController)
    addChild(buttonBarViewController)
    view.addSubview(buttonBarViewController.view)
    buttonBarViewController.view.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
    buttonBarViewController.didMove(toParent: self)
    self.buttonBarViewController = buttonBarViewController

    updateSplitViewDetailVisibility(for: nil, animated: false)
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    // Update traits *before* calling `super`, which will delegate this call to children.
    updateSplitViewTraits(for: size)
    super.viewWillTransition(to: size, with: coordinator)
  }

  private func updateSplitViewTraits(for size: CGSize) {
    guard let buttonBarViewController = buttonBarViewController else { return }

    func overrideHorizontalSizeClassToCompact(_ vc: UIViewController) {
      let horizontallyCompact = UITraitCollection(horizontalSizeClass: .compact)
      setOverrideTraitCollection(horizontallyCompact, forChild: vc)
    }

    if traitCollection.userInterfaceIdiom == .pad {
      if size.isWiderThanTall {
        setOverrideTraitCollection(nil, forChild: buttonBarViewController)
      } else {
        overrideHorizontalSizeClassToCompact(buttonBarViewController)
      }
    } else {
      overrideHorizontalSizeClassToCompact(buttonBarViewController)
    }
  }

  private func updateSplitViewDetailVisibility(for vc: UIViewController?, animated: Bool) {
    let duration = animated ? Metrics.defaultAnimationDuration : 0
    let shouldShowDetail = vc.map { viewControllerBarItems.keys.contains($0) } ?? false
    let preferredPrimaryColumnWidthFraction: CGFloat
    if shouldShowDetail {
      preferredPrimaryColumnWidthFraction = Metrics.preferredPrimaryColumnWidthFraction
    } else {
      preferredPrimaryColumnWidthFraction = preferredPrimaryColumnWidthFractionWhenDetailIsHidden
    }

    // If we're going to hide the detail, we must first pop any presented VCs to avoid reducing
    // their width. Failing to do so can result in autolayout warnings or crashes with some
    // MDC collection view layouts.
    if !shouldShowDetail && presentedDetailViewController != nil {
      detailNavController.popViewController(animated: false)
      presentedDetailViewController = nil
    }

    UIView.animate(withDuration: duration) {
      self.svController.preferredPrimaryColumnWidthFraction = preferredPrimaryColumnWidthFraction
    }
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

    updateSplitViewDetailVisibility(for: vc, animated: true)
    buttonBarViewController?.items = items
  }

  private func removeUnusedBarItems() {
    viewControllerBarItems = viewControllerBarItems.filter { (key, _) -> Bool in
      return navController.viewControllers.contains(key) ||
        detailNavController.viewControllers.contains(key)
    }
  }

  func show(detail detailViewController: UIViewController, with items: [ActionAreaBarItem]) {
    guard presentedDetailViewController == nil else {
      fatalError("A detailViewController is already being shown.")
    }

    svController.showDetailViewController(detailViewController, sender: self)

    viewControllerBarItems[detailViewController] = .persistent(items)
    updateActionAreaBar(for: detailViewController)
  }

  func show(detail detailViewController: UIViewController,
            toggle passive: ToggleState,
            and active: ToggleState) {
    guard presentedDetailViewController == nil else {
      fatalError("A detailViewController is already being shown.")
    }

    svController.showDetailViewController(detailViewController, sender: self)

    viewControllerBarItems[detailViewController] = .toggle(passive, active)
    updateActionAreaBar(for: detailViewController)
  }

  func dismissDetail() {
    guard let presentedDetailViewController = presentedDetailViewController else {
      fatalError("A detailViewController is not currently being shown.")
    }

    switch state {
    case .normal:
      viewControllerBarItems.removeValue(forKey: presentedDetailViewController)

      updateActionAreaBar(for: navController.topViewController)

      if svController.isCollapsed {
        navController.popViewController(animated: true)
      } else {
        detailNavController.popViewController(animated: true)
      }

      self.presentedDetailViewController = nil
    case .modal:
      if svController.isCollapsed {
        navController.popViewController(animated: true)
      } else {
        fatalError("The detailViewController cannot be dismissed in the modal state.")
      }
    }
  }

  func reshowDetail() {
    guard let presentedDetailViewController = presentedDetailViewController else {
      fatalError("A detailViewController is not currently being shown.")
    }
    guard state == .modal else {
      fatalError("The Action Area can only reshow in the modal state.")
    }

    if svController.isCollapsed {
      svController.showDetailViewController(presentedDetailViewController, sender: self)
    }
    // Otherwise the detailViewController is already on screen.
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

extension ActionAreaController: UISplitViewControllerDelegate {

  func primaryViewController(
    forCollapsing splitViewController: UISplitViewController
  ) -> UIViewController? {
    return nil // nil for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           collapseSecondary secondaryViewController: UIViewController,
                           onto primaryViewController: UIViewController) -> Bool {
    if presentedDetailViewController != nil {
      // Return `false` to delegate to the primary navigation controller, which will push the
      // `navDetailController` onto its navigation stack.
      return false
    } else {
      // Otherwise the empty state of the detail view would cover the primary content, so return
      // `true` to do nothing.
      return true
    }
    // false for default behavior
  }

  func primaryViewController(
    forExpanding splitViewController: UISplitViewController
  ) -> UIViewController? {
    return nil // nil for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           separateSecondaryFrom primaryViewController: UIViewController
  ) -> UIViewController? {
    if presentedDetailViewController != nil {
      // Return `nil` to delegate to the primary navigation controller, which will pop the
      // `navDetailController` and return it to be installed as the secondary view controller.
      return nil
    } else {
      // Otherwise return the `detailNavController` directly.
      return detailNavController
    }
    // nil for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           show vc: UIViewController, sender: Any?) -> Bool {
    return false // false for default behavior
  }

  func splitViewController(_ splitViewController: UISplitViewController,
                           showDetail vc: UIViewController, sender: Any?) -> Bool {
    presentedDetailViewController = vc
    if splitViewController.isCollapsed {
      navController.pushViewController(vc, animated: true)
    } else {
      detailNavController.pushViewController(vc, animated: true)
    }
    return true // false for default behavior
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

  var showCloseButton = true

  private let appBar = MDCAppBar()
  private let contentViewController: UIViewController

  init(contentViewController: UIViewController) {
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

    if showCloseButton {
      navigationItem.leftBarButtonItem =
        UIBarButtonItem(title: "Close",
                        style: .plain,
                        target: self,
                        action: #selector(close))
    }

    if let collectionViewController = contentViewController as? UICollectionViewController {
      appBar.configure(attachTo: self, scrollView: collectionViewController.collectionView)
    } else {
      appBar.configure(attachTo: self)
    }
  }

  @objc
  private func close() {
    actionAreaController?.dismissDetail()
  }

  override var description: String {
    return "\(type(of: self))(content: \(String(describing: contentViewController)))"
  }

}

// TODO: We have at least two empty states, so the API is going to need to provide a way
//       to specify them or possibly provide a custom VC, as one displays a timestamp
//       from the primary view controller.
private class DetailEmptyStateViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let label = UILabel()
    // TODO: Verify this string and localize the final version.
    label.text = "Add more observation notes"
    label.textColor = .lightGray
    view.addSubview(label)
    label.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
    }
  }

  override var description: String {
    return "\(type(of: self))"
  }
}

// MARK: - Debugging

extension ActionAreaController {
  private func log(debuggingInfoFor svc: UISplitViewController?,
                   verbose: Bool = false,
                   function: String = #function) {
    guard let svc = svc else { return }
    var message = "\(type(of: self)).\(function)"
    message += " - vcs: \(svc.viewControllers.map(vcName(_:)))"
    message += ", isCollapsed: \(svc.isCollapsed)"
    message += ", displayMode: \(svc.displayMode)"
    if verbose {
      message += ", navController.vcs: \(navController.viewControllers.map(vcName(_:)))"
      message += ", detailNavController.vcs: \(detailNavController.viewControllers.map(vcName(_:)))"
    }
    print(message)
  }

  private func vcName(_ vc: UIViewController) -> String {
    if vc === navController {
      return "navController"
    } else if vc === detailNavController {
      return "detailNavController"
    } else {
      let d = String(describing: vc)
      if d.starts(with: "<third_party_sciencejournal") {
        return d.split(separator: ":").first?
          .split(separator: ".").last
          .map(String.init) ?? d
      } else {
        return d
      }
    }
  }

  private func logAsync(debuggingInfoFor svc: UISplitViewController?,
                        function: String = #function) {
    DispatchQueue.main.async {
      self.log(debuggingInfoFor: svc, verbose: true, function: function)
    }
  }
}

extension UISplitViewController.DisplayMode: CustomStringConvertible {
  public var description: String {
    switch self {
    case .automatic:
      return "automatic"
    case .primaryHidden:
      return "primaryHidden"
    case .allVisible:
      return "allVisible"
    case .primaryOverlay:
      return "primaryOverlay"
    }
  }
}
