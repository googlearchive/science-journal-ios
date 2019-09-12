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

extension ActionArea {

  /// Manages presentation and adaptivity for the Action Area.
  final class Controller: UIViewController {

    private enum Metrics {
      static let defaultAnimationDuration: TimeInterval = 0.4

      // The fractional width of the master content area.
      static let preferredPrimaryColumnWidthFraction: CGFloat = 0.6
    }

    /// The state of the Action Area.
    enum State {

      /// In the `normal` state, content can be shown and dismissed without restriction.
      case normal

      /// In the `modal` state, the primary content cannot be changed, and detail content is
      /// hidden and re-shown instead of being dismissed.
      case modal

    }

    /// If the Action Area is using the expanded layout.
    var isExpanded: Bool { return !svController.isCollapsed }

    /// The navigation controller that displays content in a master context.
    /// This is currently here for backwards compatibility. Consider using `show` if appropriate.
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

    private let masterBarViewController: BarViewController
    private let detailBarViewController: BarViewController
    private let svController = UISplitViewController()
    private var presentedMasterViewController: MasterContent? {
      return navController.topViewController as? MasterContent
    }

    private var presentedDetailViewController: DetailContent?
    private let preferredPrimaryColumnWidthFractionWhenDetailIsHidden: CGFloat = 1.0
    private var isDetailVisible: Bool = false
    private typealias TargetAction = (target: AnyObject?, action: Selector)
    private var masterTargetsAndActions: [TargetAction] = []
    private var transitionType: MasterTransitionType = .external

    private(set) var state: State = .normal {
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
            self.presentedDetailViewController = nil
          }
        case .modal:
          break
        }
        presentedDetailViewController.actionAreaStateDidChange(self)
        updateBarButtonItems()
      }
    }

    private weak var actionEnabler: ActionEnabler? {
      didSet {
        oldValue?.unobserve()

        actionEnabler?.observe(animateActionEnablement(actionsAreEnabled:))
      }
    }

    private var emptyStates: [EmptyState] {
      return navController.viewControllers.reduce(into: []) { emptyStates, vc in
        if let master = vc as? ActionArea.MasterContent {
          emptyStates.append(master.emptyState)
        }
      }
    }

    // MARK: - Initializers

    init() {
      precondition(FeatureFlags.isActionAreaEnabled,
                   "This class can only be used when Action Area is enabled.")
      self.masterBarViewController = BarViewController(content: navController)
      self.detailBarViewController = BarViewController(content: detailNavController)
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
      super.viewDidLoad()

      navController.delegate = self
      detailNavController.delegate = self

      // Set `viewControllers` first to avoid warnings.
      svController.viewControllers = [masterBarViewController, detailBarViewController]
      svController.presentsWithGesture = false
      // When set to `automatic`, iPad uses `primaryOverlay` in portrait orientations, which
      // can result in `viewDidAppear` not being called on detail view controllers.
      svController.preferredDisplayMode = .allVisible
      svController.delegate = self

      let longestDimension = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
      svController.minimumPrimaryColumnWidth =
        floor(longestDimension * Metrics.preferredPrimaryColumnWidthFraction)
      svController.maximumPrimaryColumnWidth = longestDimension

      addChild(svController)
      view.addSubview(svController.view)
      svController.didMove(toParent: self)
      svController.view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      updateSplitViewTraits()
      updateSplitViewDetailVisibility()
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
      // Update traits *before* calling `super`, which will delegate this call to children.
      updateSplitViewTraits()
      super.viewWillTransition(to: size, with: coordinator)
    }

    private func updateSplitViewTraits() {
      let horizontallyCompact = UITraitCollection(horizontalSizeClass: .compact)
      let horizontallyRegular = UITraitCollection(horizontalSizeClass: .regular)

      // On iPad, we use a horizontally compact layout to keep the split view collapsed until we
      // have detail content to show.
      if traitCollection.userInterfaceIdiom == .pad {
        if UIScreen.main.bounds.size.isWiderThanTall, isDetailVisible {
          setOverrideTraitCollection(nil, forChild: svController)
          svController.setOverrideTraitCollection(nil, forChild: masterBarViewController)
        } else {
          setOverrideTraitCollection(horizontallyCompact, forChild: svController)
          // Overriding the master content ensures it can still use an appropriate layout.
          svController.setOverrideTraitCollection(
            horizontallyRegular, forChild: masterBarViewController
          )
        }
      } else {
        // On iPhone, we use a horizontally compact layout to prevent expansion on plus/max devices.
        setOverrideTraitCollection(horizontallyCompact, forChild: svController)
      }
    }

    // Expand or contract the primary content area. This should usually be animated.
    private func updateSplitViewDetailVisibility() {
      let preferredPrimaryColumnWidthFraction: CGFloat
      if isDetailVisible {
        preferredPrimaryColumnWidthFraction = Metrics.preferredPrimaryColumnWidthFraction
      } else {
        preferredPrimaryColumnWidthFraction = preferredPrimaryColumnWidthFractionWhenDetailIsHidden
      }

      svController.preferredPrimaryColumnWidthFraction = preferredPrimaryColumnWidthFraction
    }

    // We don't have a way to detect a detail dismissal when it happens, so we clear our local
    // reference to `presentedDetailViewController` when it's no longer in either of the navigation
    // controllers.
    private func removeDismissedDetailViewController() {
      let detailContent: [DetailContent] =
        (navController.viewControllers + detailNavController.viewControllers)
          .reduce(into: []) { (detailContent, aVC) in
            if let detail = aVC as? DetailContent {
              detailContent.append(detail)
            }
      }

      switch state {
      case .normal:
        self.presentedDetailViewController = detailContent.last
      case .modal:
        if isExpanded {
          if detailContent.isEmpty {
            fatalError("The detailViewController cannot be dismissed in the modal state.")
          }
        }

        if let lastDetail = detailContent.last {
          self.presentedDetailViewController = lastDetail
        }
      }
    }

    // Update the bar button items outside of a view controller transition.
    // This is needed for the `normal` <-> `modal` state transition.
    func updateBarButtonItems() {
      let newBarButtonItems = createBarButtonItems()

      UIView.animate(withDuration: Metrics.defaultAnimationDuration) {
        if self.svController.isCollapsed {
          self.masterBarViewController.items = newBarButtonItems
        } else {
          self.detailBarViewController.items = newBarButtonItems
        }
      }
    }

    // Create bar button items for the appropriate content.
    func createBarButtonItems() -> [UIBarButtonItem] {
      func items(for content: Content) -> [UIBarButtonItem] {
        switch content.mode {
        case let .stateless(items):
          return items.map(createBarButtonItem(from:))
        case let .stateful(nonModal, modal):
          switch state {
          case .normal:
            return nonModal.items
              .map(createBarButtonItem(from:)) + [wrapBarButtonItem(from: nonModal.primary)]
          case .modal:
            return modal.items
              .map(createBarButtonItem(from:)) + [wrapBarButtonItem(from: modal.primary)]
          }
        }
      }

      if let detail = presentedDetailViewController {
        // Use the presented detail content if it exists.
        return items(for: detail)
      } else if let master = presentedMasterViewController {
        // Otherwise the top-most master content.
        return items(for: master)
      } else {
        return []
      }
    }

    private func createBarButtonItem(from item: BarButtonItem) -> UIBarButtonItem {
      let barButtonItem = UIBarButtonItem(title: item.title,
                                          style: .plain,
                                          target: item,
                                          action: #selector(BarButtonItem.execute))
      barButtonItem.accessibilityHint = item.accessibilityHint
      barButtonItem.image = item.image
      return barButtonItem
    }

    // TODO: Figure out when/where to nil this out
    private var wrapper: BarButtonItem?

    private func wrapBarButtonItem(from item: BarButtonItem) -> UIBarButtonItem {
      let wrapper = BarButtonItem(
        title: item.title,
        accessibilityHint: item.accessibilityHint,
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

    // MARK: - API

    /// Present content in a master context.
    ///
    /// - Parameters:
    ///   - vc: The view controller to show.
    ///   - sender: The object calling this method.
    override func show(_ vc: UIViewController, sender: Any?) {
      guard state == .normal else {
        fatalError("View controllers cannot be pushed during a modal detail presentation.")
      }

      svController.show(vc, sender: sender)
    }

    /// Present content in a master context.
    ///
    /// - Parameters:
    ///   - vc: The view controller to show.
    ///   - sender: The object calling this method.
    func show(_ vc: MasterContent, sender: Any?) {
      guard state == .normal else {
        fatalError("View controllers cannot be pushed during a modal detail presentation.")
      }

      svController.show(vc, sender: sender)
    }

    /// Present content in a detail context.
    ///
    /// - Parameters:
    ///   - vc: The view controller to show.
    ///   - sender: The object calling this method.
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
      svController.showDetailViewController(vc, sender: sender)
    }

    /// Re-present detail content that was dismissed in the `modal` state.
    ///
    /// Calling this method when no detail content was presented or the Action Area is not in the
    /// `modal` state is an error.
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

  }

}

// MARK: - UISplitViewControllerDelegate

extension ActionArea.Controller: UISplitViewControllerDelegate {

  func primaryViewController(
    forCollapsing splitViewController: UISplitViewController
  ) -> UIViewController? {
    return nil // nil for default behavior
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    collapseSecondary secondaryViewController: UIViewController,
    onto primaryViewController: UIViewController
  ) -> Bool {
    detailNavController.setViewControllers([], animated: false)
    if let presentedDetailViewController = presentedDetailViewController {
      navController.pushViewController(presentedDetailViewController, animated: false)
    }
    return true // false for default behavior
  }

  func primaryViewController(
    forExpanding splitViewController: UISplitViewController
  ) -> UIViewController? {
    return nil // nil for default behavior
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    separateSecondaryFrom primaryViewController: UIViewController
  ) -> UIViewController? {
    detailNavController.setViewControllers(emptyStates, animated: false)
    if let presentedDetailViewController = presentedDetailViewController {
      navController.popViewController(animated: false)
      detailNavController.pushViewController(presentedDetailViewController, animated: false)
    }
    return detailBarViewController // nil for default behavior
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    show vc: UIViewController, sender: Any?
  ) -> Bool {
    navController.pushViewController(vc, animated: true)

    if let master = vc as? ActionArea.MasterContent {
      actionEnabler = master.actionEnabler
      if isExpanded {
        detailNavController.pushViewController(master.emptyState, animated: true)
      }
    }
    return true // false for default behavior
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    showDetail vc: UIViewController, sender: Any?
  ) -> Bool {
    // Wrap the detail content in the default container if it isn't already. This ensures we can
    // enforce behaviors like swapping the close button with a hide button in the `modal` state.
    // It also lets us make `presentedDetailViewController` be `DetailContent`, which avoids
    // casting later.
    let detail: ActionArea.DetailContent
    if let vc = vc as? ActionArea.DetailContent {
      detail = vc
    } else {
      detail = ActionArea.DetailContentContainerViewController(
        content: vc,
        mode: .stateless(items: [])
      )
    }

    // Retain a reference to the detail content, so we can re-show it if needed when in the `modal`
    // state.
    presentedDetailViewController = detail
    if splitViewController.isCollapsed {
      navController.pushViewController(detail, animated: true)
    } else {
      detailNavController.pushViewController(detail, animated: true)
    }
    return true // false for default behavior
  }

}

// MARK: - Transitions

private extension ActionArea.Controller {

  enum Layout {
    case portrait
    case landscape
  }

  // The layout of the Action Area, regardless of what it currently looks like.
  var layout: Layout {
    if traitCollection.userInterfaceIdiom == .pad {
      if UIScreen.main.bounds.size.isWiderThanTall {
        return .landscape
      }
    }
    return .portrait
  }

  /// The master transition type.
  enum MasterTransitionType {
    /// Entering the Action Area from external content.
    case enter
    /// Transitioning between master content within the Action Area.
    case `internal`
    /// Leaving the Action Area to external content.
    case leave
    /// Transitions outside of the Action Area that are using its master navigation controller.
    case external

    /// The next transition type.
    ///
    /// This method is called during the various transition phases to determine the next transition
    /// type. The transition type will not always change.
    ///
    /// - Parameters:
    ///   - phase: The current transition phase.
    ///   - contentCount: The number of master content view controllers.
    func next(
      for phase: MasterTransitionPhase,
      and contentCount: Int
    ) -> MasterTransitionType {
      switch (self, phase) {
      case (.external, .willShow) where contentCount > 0:
        return .enter
      case (.external, .willShow) where contentCount == 0:
        return .external
      case (.enter, .didShow):
        return .internal
      case (.internal, .willShow) where contentCount > 0:
        return .internal
      case (.internal, .back) where contentCount == 1:
        return .leave
      case (.leave, .didShow):
        return .external
      default:
        return self
      }
    }
  }

  /// The master transition phase.
  ///
  /// These values represent where transition-related operations take place, and they are used
  /// as part of the input to determine when to change the `MasterTransitionType`.
  enum MasterTransitionPhase {
    case willShow
    case back
    case didShow
  }

  /// The detail transition type, which specifies how the bar animates.
  enum DetailTransitionType {
    case none
    case hide
    case show
    case update

    init(before: [UIBarButtonItem], after: [UIBarButtonItem]) {
      switch (before.isEmpty, after.isEmpty) {
      case (true, true):
        self = .none
      case (false, true):
        self = .hide
      case (true, false):
        self = .show
      case (false, false):
        self = .update
      }
    }
  }

  /// The master transition source.
  ///
  /// Transitions can be initiated from either a user action or a navgiation controller transition.
  enum TransitionSource {
    /// Either a back-button tap or swipe gesture.
    case backAction
    /// A `UINavigationControllerDelegate` call.
    case delegate
  }

  /// Coordinate a master content transition.
  ///
  /// - Parameters:
  ///   - layout: The layout for this transition.
  ///   - type: The type of this transition.
  ///   - source: The source of the current phase of the transition.
  func transition(layout: Layout, type: MasterTransitionType, source: TransitionSource) {
    switch (layout, type, source) {
    case (.portrait, .enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.portrait, .enter, .delegate):
      masterBarViewController.items = createBarButtonItems()
      masterBarViewController.isEnabled = actionsAreEnabled
      navController.transitionCoordinator?.animate(alongsideTransition: { _ in
        self.masterBarViewController.raise()
      })
    case (.portrait, .internal, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.portrait, .internal, .delegate):
      let oldItems = masterBarViewController.items
      let newItems = createBarButtonItems()
      let type = DetailTransitionType(before: oldItems, after: newItems)
      transition(
        masterBarViewController,
        to: newItems,
        type: type,
        with: navController.transitionCoordinator
      )
    case (.portrait, .leave, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.portrait, .leave, .delegate):
      navController.transitionCoordinator?.animate(alongsideTransition: { _ in
        self.masterBarViewController.lower()
      }, completion: { _ in
        self.masterBarViewController.items = []
      })
    case (.landscape, .enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.landscape, .enter, .delegate):
      isDetailVisible = true
      updateSplitViewTraits()
      detailBarViewController.items = createBarButtonItems()
      detailBarViewController.raise()
      detailBarViewController.isEnabled = actionsAreEnabled

      navController.transitionCoordinator?.animate(alongsideTransition: nil) { context in
        UIView.animate(withDuration: context.transitionDuration) {
          self.updateSplitViewDetailVisibility()
        }
      }
    case (.landscape, .internal, .backAction):
      sendOverriddenMasterBackButtonAction()
      detailNavController.popViewController(animated: true)
    case (.landscape, .internal, .delegate):
      // There is currently nothing to do here, but we may refactor pushing detail empty state
      // or animating the detail bar change here in the future.
      break
    case (.landscape, .leave, .backAction):
      isDetailVisible = false

      UIView.animate(withDuration: Metrics.defaultAnimationDuration, animations: {
        self.updateSplitViewDetailVisibility()
      }, completion: { _ in
        self.updateSplitViewTraits()
        self.detailBarViewController.lower()
        self.detailBarViewController.items = []

        self.sendOverriddenMasterBackButtonAction()
      })
    case (.landscape, .leave, .delegate):
      // The back action portion of this transition above currently handles everything that is
      // needed.
      break
    case (_, .external, _):
      // There is nothing to do here for external transitions.
      break
    }
  }

  /// Transition the content of the Action Area Bar during a detail content presentation.
  func transition(
    _ bar: ActionArea.BarViewController,
    to newItems: [UIBarButtonItem],
    type: DetailTransitionType,
    with transitionCoordinator: UIViewControllerTransitionCoordinator?
  ) {
    if type == .show {
      bar.items = newItems
    }
    transitionCoordinator?.animate(alongsideTransition: { _ in
      switch type {
      case .none:
        break
      case .hide:
        bar.hide()
      case .show:
        bar.show()
      case .update:
        bar.items = newItems
      }

      bar.isEnabled = self.actionsAreEnabled
    }, completion: { _ in
      if type == .hide {
        bar.items = newItems
      }
    })
  }

  var actionsAreEnabled: Bool {
    return presentedMasterViewController?.actionEnabler?.isEnabled ?? true
  }

  func animateActionEnablement(actionsAreEnabled: Bool) {
    guard let master = presentedMasterViewController else { return }

    func animate() {
      if isExpanded {
        detailBarViewController.isEnabled = actionsAreEnabled
        master.emptyState.isEnabled = actionsAreEnabled
      } else {
        masterBarViewController.isEnabled = actionsAreEnabled
      }
    }

    UIView.animate(withDuration: Metrics.defaultAnimationDuration) {
      animate()
    }
  }

  func overrideMasterBackBarButtonItem(of vc: UIViewController) {
    if let item = vc.navigationItem.leftBarButtonItem {
      guard let action = item.action else { preconditionFailure("Expected an action selector.") }

      masterTargetsAndActions.append((item.target, action))
      item.target = self
      item.action = #selector(didTapMasterBack)
    }
  }

  func sendOverriddenMasterBackButtonAction() {
    guard let ta = masterTargetsAndActions.popLast() else {
      preconditionFailure("Expected a valid target and action pair.")
    }

    UIApplication.shared.sendAction(ta.action, to: ta.target, from: nil, for: nil)
  }

  @objc func didTapMasterBack() {
    transitionType = transitionType.next(for: .back, and: emptyStates.count)
    transition(layout: layout, type: transitionType, source: .backAction)
  }

}

// MARK: - UINavigationControllerDelegate

extension ActionArea.Controller: UINavigationControllerDelegate {

  func navigationController(
    _ navigationController: UINavigationController,
    willShow viewController: UIViewController,
    animated: Bool
  ) {
    removeDismissedDetailViewController()

    if navigationController == navController {
      transitionType = transitionType.next(for: .willShow, and: emptyStates.count)
      transition(layout: layout, type: transitionType, source: .delegate)
    }

    if navigationController == detailNavController {
      presentedMasterViewController?.emptyState.isEnabled = actionsAreEnabled

      let oldItems = detailBarViewController.items
      let newItems = createBarButtonItems()
      let type = DetailTransitionType(before: oldItems, after: newItems)
      transition(
        detailBarViewController,
        to: newItems,
        type: type,
        with: navigationController.transitionCoordinator
      )
    }
  }

  func navigationController(
    _ navigationController: UINavigationController,
    didShow viewController: UIViewController,
    animated: Bool
  ) {
    if navigationController == navController {
      transitionType = transitionType.next(for: .didShow, and: emptyStates.count)
      if viewController is ActionArea.MasterContent {
        overrideMasterBackBarButtonItem(of: viewController)
      }
    }
  }

  func navigationController(
    _ navigationController: UINavigationController,
    animationControllerFor operation: UINavigationController.Operation,
    from fromVC: UIViewController,
    to toVC: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    let viewControllers = [fromVC, toVC]
    if viewControllers.contains(where: { $0 is ActionArea.DetailContent }) {
      return FauxdalTransitionAnimation(
        operation: operation,
        transitionDuration: Metrics.defaultAnimationDuration
      )
    } else if viewControllers.contains(where: { $0 is ActionArea.EmptyState }) {
      return CrossDissolveTransitionAnimation(
        operation: operation,
        transitionDuration: Metrics.defaultAnimationDuration
      )
    } else {
      return nil
    }
  }

}

// MARK: - UIViewController Extensions

extension UIViewController {

  var actionAreaController: ActionArea.Controller? {
    var candidate: UIViewController? = parent
    while candidate != nil {
      if let aac = candidate as? ActionArea.Controller {
        return aac
      }
      candidate = candidate?.parent
    }
    return nil
  }

}

// MARK: - Speculative Types

// TODO: Ensure this handles existing issues or use one of the other superclasses.
// TODO: Consider making this private and wrapping content VCs that are not subclasses
//       of the other material header types.
final class MaterialHeaderContainerViewController: UIViewController {

  private let appBar = MDCAppBar()
  private let content: UIViewController

  init(content: UIViewController) {
    self.content = content
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChild(content)
    view.addSubview(content.view)
    content.didMove(toParent: self)

    if let collectionViewController = content as? UICollectionViewController {
      appBar.configure(attachTo: self, scrollView: collectionViewController.collectionView)
    } else {
      appBar.configure(attachTo: self)
    }

    content.view.snp.makeConstraints { make in
      make.top.equalTo(appBar.navigationBar.snp.bottom)
      make.leading.bottom.trailing.equalToSuperview()
    }
  }

  override var description: String {
    return "\(type(of: self))(content: \(String(describing: content)))"
  }

  override var navigationItem: UINavigationItem {
    return content.navigationItem
  }

}

// MARK: - Debugging

#if DEBUG
extension ActionArea.Controller {

  private func log(debuggingInfoFor svc: UISplitViewController?,
                   verbose: Bool = false,
                   function: String = #function) {
    guard let svc = svc else { return }
    var message = "ActionArea.\(type(of: self)).\(function)"
    message += " - vcs: \(svc.viewControllers.map(vcName(_:)))"
    message += ", isCollapsed: \(svc.isCollapsed)"
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
      if d.contains("third_party_sciencejournal") {
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

extension UINavigationController.Operation: CustomStringConvertible {

  public var description: String {
    switch self {
    case .none:
      return "none"
    case .push:
      return "push"
    case .pop:
      return "pop"
    }
  }

}
#endif
