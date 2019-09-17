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
import third_party_objective_c_material_components_ios_components_Buttons_Buttons

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

    /// If the master content is currently visible.
    var isMasterVisible: Bool {
      if isExpanded { return true }
      return presentedDetailViewController == nil
    }

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

    private var presentedDetailViewController: DetailContent? {
      if isExpanded, detailNavController.topViewController is ActionArea.EmptyState {
        return nil
      }
      return detailContent.last
    }

    private var modalDetailViewController: DetailContent?
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
        guard presentedDetailViewController != nil || modalDetailViewController != nil else {
          fatalError("The state can only be changed when a detailViewController is shown.")
        }

        initiateLocalTransition()
        switch state {
        case .normal:
          modalDetailViewController?.actionAreaStateDidChange(self)
          modalDetailViewController = nil
        case .modal:
          modalDetailViewController = presentedDetailViewController
          modalDetailViewController?.actionAreaStateDidChange(self)
        }
        updateBarButtonItems()
      }
    }

    // Initiate a transition by presenting a hidden view controller. This ensures we use the
    // same duration and easing curves, and it simplifies animation code because it doesn't have
    // to handle animating without a `transitionCoordinator`.
    private func initiateLocalTransition() {
      let hidden = UIViewController()
      // Hide the view, so the currently visible content won't be affected.
      hidden.view.isHidden = true
      // Use an `over` presentation style, so the presenting view won't be removed.
      hidden.modalPresentationStyle = .overFullScreen
      svController.present(hidden, animated: true) {
        // Dismiss the view controller to return things to the previous state.
        hidden.dismiss(animated: false)
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

    private var detailContent: [DetailContent] {
      return (navController.viewControllers + detailNavController.viewControllers)
        .reduce(into: []) { detailContent, aVC in
          if let detail = aVC as? DetailContent {
            detailContent.append(detail)
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
      // have detail content to show. Do *not* use `traitCollection.userInterfaceIdom` here
      // because it is not always set.
      if UIDevice.current.userInterfaceIdiom == .pad {
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
        // Detail content in the expanded layout should always be horizontally compact.
        svController.setOverrideTraitCollection(
          horizontallyCompact, forChild: detailBarViewController
        )
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

    private func updateBarButtonItems() {
      let newActionItem = createActionItem()

      if svController.isCollapsed {
        masterBarViewController.actionItem = newActionItem
      } else {
        detailBarViewController.actionItem = newActionItem
      }
    }

    // Create `ActionItem` for the appropriate content.
    private func createActionItem() -> ActionItem {
      func items(for content: Content) -> ActionItem {
        switch (state, content.mode) {
        case let (.normal, .stateless(items)), let (.modal, .stateless(items)):
          return ActionItem(items: items)
        case let (.normal, .stateful(nonModal, _)):
          return ActionItem(primary: wrap(primary: nonModal.primary), items: nonModal.items)
        case let (.modal, .stateful(_, modal)):
          return ActionItem(primary: wrap(primary: modal.primary), items: modal.items)
        }
      }

      if let detail = presentedDetailViewController ?? modalDetailViewController {
        // Use the presented detail content if it exists.
        return items(for: detail)
      } else if let master = presentedMasterViewController {
        // Otherwise the top-most master content.
        return items(for: master)
      } else {
        return .empty
      }
    }

    private func wrap(primary: BarButtonItem) -> BarButtonItem {
      return BarButtonItem(
        title: primary.title,
        accessibilityHint: primary.accessibilityHint,
        image: primary.image
      ) {
        primary.action()
        self.toggleState()
      }
    }

    @objc private func toggleState() {
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
      guard let modalDetailViewController = modalDetailViewController else {
        fatalError("A detailViewController is not currently being shown.")
      }
      guard state == .modal else {
        fatalError("The Action Area can only reshow in the modal state.")
      }

      if svController.isCollapsed {
        svController.showDetailViewController(modalDetailViewController, sender: self)
      }
      // Otherwise the detailViewController is already on screen.
    }

    func revealMaster() {
      guard let firstDetail = detailContent.first else {
        preconditionFailure("A detailViewController is not currently being shown.")
      }
      guard svController.isCollapsed else { return }

      guard let index = navController.viewControllers.index(of: firstDetail) else {
        preconditionFailure("Expected detail content in navController.")
      }
      precondition(index > navController.viewControllers.startIndex,
                   "Expected master content under detail content.")
      let before = navController.viewControllers.index(before: index)
      guard let newTop = navController.viewControllers[before] as? MasterContent else {
        preconditionFailure("Expected new top view controller to be master content.")
      }
      navController.popToViewController(newTop, animated: true)
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

    init(
      before: ActionArea.ActionItem,
      after: ActionArea.ActionItem
    ) {
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
      masterBarViewController.actionItem = createActionItem()
      masterBarViewController.isEnabled = actionsAreEnabled
      navController.transitionCoordinator?.animate(alongsideTransition: { _ in
        self.masterBarViewController.raise()
      })
    case (.portrait, .internal, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.portrait, .internal, .delegate):
      transition(
        bar: masterBarViewController,
        with: navController.transitionCoordinator
      )
    case (.portrait, .leave, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.portrait, .leave, .delegate):
      navController.transitionCoordinator?.animate(alongsideTransition: { _ in
        self.masterBarViewController.lower()
      }, completion: { _ in
        self.masterBarViewController.actionItem = .empty
      })
    case (.landscape, .enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.landscape, .enter, .delegate):
      guard let presentedMasterViewController = presentedMasterViewController else {
        preconditionFailure("Expected a presentedMasterViewController.")
      }

      isDetailVisible = true
      updateSplitViewTraits()
      detailBarViewController.actionItem = createActionItem()
      detailBarViewController.raise()
      detailBarViewController.isEnabled = actionsAreEnabled

      // TODO: This is temporary for upcoming usability testing. Clean this up and figure out
      // the animation judder that currently happens.
      let oldMargins = presentedMasterViewController.view.layoutMargins
      var newMargins: UIEdgeInsets {
        let totalWidth = view.bounds.width
        let masterWidth = totalWidth * Metrics.preferredPrimaryColumnWidthFraction
        let detailWidth = totalWidth - masterWidth
        let inset = ceil(detailWidth / 2)
        return UIEdgeInsets(
          top: oldMargins.top,
          left: oldMargins.left + inset,
          bottom: oldMargins.bottom,
          right: oldMargins.right + inset
        )
      }

      presentedMasterViewController.view.layoutMargins = newMargins
      navController.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
        self.initiateLocalTransition()
        self.navController.transitionCoordinator?.animate(alongsideTransition: { _ in
          self.presentedMasterViewController?.view.layoutMargins = oldMargins
          self.updateSplitViewDetailVisibility()
        })
      }
    case (.landscape, .internal, .backAction):
      sendOverriddenMasterBackButtonAction()
      detailNavController.popViewController(animated: true)
    case (.landscape, .internal, .delegate):
      // There is currently nothing to do here, but we may refactor pushing detail empty state
      // or animating the detail bar change here in the future.
      break
    case (.landscape, .leave, .backAction):
      // TODO: Fix this properly. Currently collapsing the AA reduces the size of the detail content
      // area, which can create constraint conflicts and/or invalid collection view layouts.
      if let presentedDetailViewController = presentedDetailViewController {
        let snapshot = presentedDetailViewController.view.snapshotView(afterScreenUpdates: false)
        let cover = UIViewController()
        cover.view = snapshot
        detailNavController.setViewControllers([cover], animated: false)
      }

      isDetailVisible = false

      UIView.animate(withDuration: Metrics.defaultAnimationDuration, animations: {
        self.updateSplitViewDetailVisibility()
      }, completion: { _ in
        self.updateSplitViewTraits()
        self.detailBarViewController.lower()
        self.detailBarViewController.actionItem = .empty
        self.detailBarViewController.show()

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
    bar: ActionArea.BarViewController,
    with transitionCoordinator: UIViewControllerTransitionCoordinator?
  ) {
    let oldActionItem = bar.actionItem
    let newActionItem = createActionItem()
    let type = DetailTransitionType(before: oldActionItem, after: newActionItem)

    if [.show, .update].contains(type) {
      bar.actionItem = newActionItem
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
        break
      }

      bar.isEnabled = self.actionsAreEnabled
    }, completion: { _ in
      if type == .hide {
        bar.actionItem = newActionItem
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
    if navigationController == navController {
      transitionType = transitionType.next(for: .willShow, and: emptyStates.count)
      transition(layout: layout, type: transitionType, source: .delegate)
    }

    if navigationController == detailNavController {
      presentedMasterViewController?.emptyState.isEnabled = actionsAreEnabled

      transition(
        bar: detailBarViewController,
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
    switch operation {
    case .push where toVC is ActionArea.EmptyState,
         .pop where fromVC is ActionArea.EmptyState:
      return CrossDissolveTransitionAnimation(
        operation: operation,
        transitionDuration: Metrics.defaultAnimationDuration
      )
    case .push where toVC is ActionArea.DetailContent,
         .pop where fromVC is ActionArea.DetailContent:
      return FauxdalTransitionAnimation(
        operation: operation,
        transitionDuration: Metrics.defaultAnimationDuration
      )
    case .push, .pop, .none:
      return nil
    }
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
