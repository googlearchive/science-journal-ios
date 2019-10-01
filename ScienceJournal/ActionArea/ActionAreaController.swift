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

// swiftlint:disable file_length

import SnapKit
import UIKit

import third_party_objective_c_material_components_ios_components_AppBar_AppBar
import third_party_objective_c_material_components_ios_components_Buttons_Buttons

extension ActionArea {

  /// Manages presentation and adaptivity for the Action Area.
  final class Controller: UIViewController, ActionAreaBarButtonItemDelegate {

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

    private enum Layout: Equatable, CustomDebugStringConvertible {

      struct Sizes {
        let size: CGSize

        let divider: CGFloat = 0.5
        private var maxMasterWidth: CGFloat { return size.width }
        private var minMasterWidth: CGFloat { return maxMasterWidth - detailWidth - divider }
        private var maxMasterWidthInset: CGFloat { return maxMasterWidth - minMasterWidth }
        private var masterWidthInset: CGFloat { return (maxMasterWidth - minMasterWidth) / 2 }
        var masterLayoutMargins: UIEdgeInsets {
          return UIEdgeInsets(top: 0, left: masterWidthInset, bottom: 0, right: masterWidthInset)
        }

        var detailWidth: CGFloat { return 476 }
        var detailOffset: CGFloat { return detailWidth + divider }
      }

      enum Mode: CustomDebugStringConvertible {
        case collapsed
        case expanded

        var debugDescription: String {
          switch self {
          case .collapsed:
            return "collapsed"
          case .expanded:
            return "expanded"
          }
        }
      }

      case portrait(CGSize)
      case landscape(CGSize, Mode)

      var isExpanded: Bool {
        switch self {
        case .landscape(_, .expanded):
          return true
        case .portrait, .landscape(_, .collapsed):
          return false
        }
      }

      var sizes: Sizes {
        switch self {
        case let .portrait(size), let .landscape(size, _):
          return Sizes(size: size)
        }
      }

      mutating func expand() {
        switch self {
        case .portrait:
          preconditionFailure("Expansion is not supported in portrait.")
        case .landscape(_, .expanded):
          preconditionFailure("The layout is already expanded.")
        case let .landscape(size, .collapsed):
          self = .landscape(size, .expanded)
        }
      }

      mutating func collapse() {
        switch self {
        case .portrait:
          preconditionFailure("Expansion is not supported in portrait.")
        case .landscape(_, .collapsed):
          preconditionFailure("The layout is already collapsed.")
        case let .landscape(size, .expanded):
          self = .landscape(size, .collapsed)
        }
      }

      @discardableResult
      mutating func update(
        for size: CGSize = UIScreen.main.bounds.size,
        with masterContentCount: Int = 0
      ) -> Layout? {
        let previousLayout = self
        if UIDevice.current.userInterfaceIdiom == .pad {
          if size.isWiderThanTall {
            if masterContentCount > 0 {
              self = .landscape(size, .expanded)
            } else {
              self = .landscape(size, .collapsed)
            }
          } else {
            self = .portrait(size)
          }
        } else {
          self = .portrait(size)
        }
        // Return the previous layout, if it changed.
        return previousLayout != self ? previousLayout : nil
      }

      var debugDescription: String {
        switch self {
        case .portrait:
          return "portrait"
        case let .landscape(mode):
          return "landscape(\(mode))"
        }
      }
    }

    private var layout: Layout = .portrait(UIScreen.main.bounds.size)

    /// If the Action Area is using the expanded layout.
    var isExpanded: Bool { return layout.isExpanded }

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
    private typealias TargetAction = (target: AnyObject?, action: Selector)
    private var masterTargetsAndActions: [TargetAction] = []
    private var transitionType: MasterTransitionType = .external
    private lazy var keyTint = KeyTint(
      provider: { self.masterContent.last?.customTint },
      tintables: [masterBarViewController, detailBarViewController]
    )

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

        switch state {
        case .normal:
          modalDetailViewController?.actionAreaStateDidChange(self)
          modalDetailViewController = nil
        case .modal:
          modalDetailViewController = presentedDetailViewController
          modalDetailViewController?.actionAreaStateDidChange(self)
        }
        updateBarButtonItems()
        transitionCoordinator?.animate(alongsideTransition: { _ in
          self.keyTint.updateAndApply()
        })
      }
    }

    // Initiate a transition by presenting a hidden view controller. This ensures we use the
    // same duration and easing curves, and it simplifies animation code because it doesn't have
    // to handle animating without a `transitionCoordinator`.
    @discardableResult
    private func initiateLocalTransition(
      completion: @escaping () -> Void = {}
    ) -> UIViewControllerTransitionCoordinator {
      let hidden = UIViewController()
      // Hide the view, so the currently visible content won't be affected.
      hidden.view.isHidden = true
      // Use an `over` presentation style, so the presenting view won't be removed.
      hidden.modalPresentationStyle = .overFullScreen
      present(hidden, animated: true) {
        // Dismiss the view controller to return things to the previous state.
        hidden.dismiss(animated: false) {
          completion()
        }
      }
      guard let transitionCoordinator = hidden.transitionCoordinator else {
        preconditionFailure("Initiating a presentation should create a transition coordinator.")
      }
      return transitionCoordinator
    }

    private weak var actionEnabler: FeatureEnabler? {
      didSet {
        oldValue?.unobserve()

        actionEnabler?.observe(animateActionEnablement(actionsAreEnabled:))
      }
    }

    private weak var barElevator: FeatureEnabler? {
      didSet {
        oldValue?.unobserve()

        barElevator?.observe(animateBarElevation(barIsElevated:))
      }
    }

    private var masterContent: [MasterContent] {
      return navController.viewControllers.reduce(into: []) { masterContent, vc in
        if let master = vc as? ActionArea.MasterContent {
          masterContent.append(master)
        }
      }
    }

    private var emptyStates: [EmptyState] {
      return masterContent.map { $0.emptyState }
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

    private var detailTrailingEdgeConstraint: Constraint! // set in viewDidLoad

    override func viewDidLoad() {
      super.viewDidLoad()

      navController.delegate = self
      detailNavController.delegate = self

      addChild(masterBarViewController)
      view.addSubview(masterBarViewController.view)
      masterBarViewController.didMove(toParent: self)
      masterBarViewController.view.snp.makeConstraints { make in
        make.top.leading.bottom.equalToSuperview()
      }

      addChild(detailBarViewController)
      view.addSubview(detailBarViewController.view)
      detailBarViewController.didMove(toParent: self)
      detailBarViewController.view.snp.makeConstraints { make in
        make.top.bottom.equalToSuperview()
        make.width.equalTo(layout.sizes.detailWidth)
        make.leading.equalTo(masterBarViewController.view.snp.trailing).offset(layout.sizes.divider)
        detailTrailingEdgeConstraint = make.trailing.equalToSuperview().constraint
      }

      layout.update()
      updateTraitCollectionOverrides()
      updateLayoutConstraints()
    }

    override func viewWillTransition(
      to size: CGSize,
      with coordinator: UIViewControllerTransitionCoordinator
    ) {
      super.viewWillTransition(to: size, with: coordinator)
      if let oldLayout = layout.update(for: size, with: masterContent.count) {
        transition(from: oldLayout, to: layout, with: coordinator)
      }
    }

    private func transition(
      from oldLayout: Layout,
      to newLayout: Layout,
      with coordinator: UIViewControllerTransitionCoordinator
    ) {
      // TODO: Handle all cases and improve animations.
      switch (oldLayout.isExpanded, newLayout.isExpanded) {
      case (false, true):
        detailNavController.setViewControllers(emptyStates, animated: false)
        if let presentedDetailViewController = presentedDetailViewController {
          navController.popViewController(animated: false)
          detailNavController.pushViewController(presentedDetailViewController, animated: false)
        }
      case (true, false):
        detailNavController.setViewControllers([], animated: false)
        if let presentedDetailViewController = presentedDetailViewController {
          navController.pushViewController(presentedDetailViewController, animated: false)
        }
      default:
        break
      }
      coordinator.animate(alongsideTransition: { _ in
        self.updateLayoutConstraints()
        self.view.layoutIfNeeded()
      })
    }

    private func updateTraitCollectionOverrides() {
      let horizontallyCompact = UITraitCollection(horizontalSizeClass: .compact)
      let horizontallyRegular = UITraitCollection(horizontalSizeClass: .regular)

      if UIDevice.current.userInterfaceIdiom == .pad {
        // Overriding the master content ensures it can still use an appropriate layout.
        setOverrideTraitCollection(
          horizontallyRegular, forChild: masterBarViewController
        )

        // Detail content in the expanded layout should always be horizontally compact.
        setOverrideTraitCollection(
          horizontallyCompact, forChild: detailBarViewController
        )
      } else {
        // On iPhone, we use a horizontally compact layout to prevent expansion on plus/max devices.
        setOverrideTraitCollection(horizontallyCompact, forChild: masterBarViewController)
      }
    }

    // Expand or contract the primary content area. This should usually be animated.
    private func updateLayoutConstraints() {
      if layout.isExpanded {
        detailTrailingEdgeConstraint.update(offset: 0)
      } else {
        detailTrailingEdgeConstraint.update(offset: layout.sizes.detailOffset)
      }
    }

    private func updateBarButtonItems() {
      let newActionItem = currentActionItem()

      if isExpanded == false {
        masterBarViewController
          .transition(.update(with: newActionItem, isEnabled: actionsAreEnabled))
      } else {
        detailBarViewController
          .transition(.update(with: newActionItem, isEnabled: actionsAreEnabled))
      }
    }

    // The current `ActionItem` for the appropriate content.
    private func currentActionItem() -> ActionItem {
      if let detail = presentedDetailViewController ?? modalDetailViewController {
        // Use the presented detail content if it exists.
        return detail.currentActionItem(for: state, delegatingTo: self)
      } else if let master = presentedMasterViewController {
        // Otherwise the top-most master content.
        return master.currentActionItem(for: state, delegatingTo: self)
      } else {
        return .empty
      }
    }

    func barButtonItemWillExecuteAction(_ item: ActionArea.BarButtonItem) {
      initiateLocalTransition()
    }

    func barButtonItemDidExecuteAction(_ item: ActionArea.BarButtonItem) {
      toggleState()
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

      navController.pushViewController(vc, animated: true)

      if let master = vc as? ActionArea.MasterContent {
        actionEnabler = master.actionEnabler
        if isExpanded {
          detailNavController.pushViewController(master.emptyState, animated: true)
        }
      }
    }

    /// Present content in a detail context.
    ///
    /// - Parameters:
    ///   - vc: The view controller to show.
    ///   - sender: The object calling this method.
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
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
          mode: .stateless(actionItem: .empty)
        )
      }

      if isExpanded == false {
        navController.pushViewController(detail, animated: true)
      } else {
        detailNavController.pushViewController(detail, animated: true)
      }
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

      if isExpanded == false {
        showDetailViewController(modalDetailViewController, sender: self)
      }
      // Otherwise the detailViewController is already on screen.
    }

    func revealMaster() {
      guard let firstDetail = detailContent.first else {
        preconditionFailure("A detailViewController is not currently being shown.")
      }
      guard isExpanded == false else { return }

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

// MARK: - ActionItem

private extension ActionArea.Content {

  func currentActionItem(
    for state: ActionArea.Controller.State,
    delegatingTo delegate: ActionAreaBarButtonItemDelegate
  ) -> ActionArea.ActionItem {
    switch (state, mode) {
    case let (_, .stateless(actionItem)),
         let (.normal, .stateful(actionItem, _)),
         let (.modal, .stateful(_, actionItem)):
      actionItem.primary?.delegate = delegate
      return actionItem
    }
  }

}

// MARK: - Transitions

private extension ActionArea.Controller {

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
    mutating func update(
      for phase: MasterTransitionPhase,
      and contentCount: Int
    ) {
      switch (self, phase) {
      case (.external, .willShow) where contentCount > 0:
        self = .enter
      case (.external, .willShow) where contentCount == 0:
        self = .external
      case (.enter, .didShow):
        self = .internal
      case (.internal, .willShow) where contentCount > 0:
        self = .internal
      case (.internal, .back) where contentCount == 1:
        self = .leave
      case (.leave, .didShow):
        self = .external
      default:
        break
      }
    }
  }

  /// The master transition phase.
  ///
  /// These values represent where transition-related operations take place, and they are used
  /// as part of the input to determine when to change the `MasterTransitionType`.
  enum MasterTransitionPhase {
    case back
    case willShow
    case didShow
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
  private func transition(layout: Layout, type: MasterTransitionType, source: TransitionSource) {
    switch (layout, type, source) {
    case (.portrait, .enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.portrait, .enter, .delegate):
      masterBarViewController
        .transition(.raise(with: currentActionItem(), isEnabled: actionsAreEnabled))
    case (.portrait, .internal, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.portrait, .internal, .delegate):
      masterBarViewController
        .transition(.update(with: currentActionItem(), isEnabled: actionsAreEnabled))
    case (.portrait, .leave, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.portrait, .leave, .delegate):
      masterBarViewController.transition(.lower)
    case (.landscape, .enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.landscape, .enter, .delegate):
      guard let presentedMasterViewController = presentedMasterViewController else {
        preconditionFailure("Expected a presentedMasterViewController.")
      }

      self.layout.expand()

      // expansion
      detailNavController.setViewControllers(emptyStates, animated: false)

      detailBarViewController.transition(
        .raise(with: currentActionItem(), isEnabled: actionsAreEnabled),
        animated: false
      )

      presentedMasterViewController.view.layoutMargins = layout.sizes.masterLayoutMargins
      navController.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
        self.initiateLocalTransition().animateAlongsideTransition(in: self.view, animation: { _ in
          self.updateLayoutConstraints()
          // Using a nested animation block ensures that the frame change of the master content
          // area animates smoothly. The duration value is inherited and thus ignored.
          UIView.animate(withDuration: 0) {
            presentedMasterViewController.view.layoutMargins = .zero
            self.view.layoutIfNeeded()
          }
        })
      }
    case (.landscape, .internal, .backAction):
      sendOverriddenMasterBackButtonAction()
      if let master = masterContent.last {
        detailNavController.popToViewController(master.emptyState, animated: true)
      }
    case (.landscape, .internal, .delegate):
      // There is currently nothing to do here, but we may refactor pushing detail empty state
      // or animating the detail bar change here in the future.
      break
    case (.landscape, .leave, .backAction):
      self.layout.collapse()

      initiateLocalTransition(completion: sendOverriddenMasterBackButtonAction)
        .animateAlongsideTransition(in: view, animation: { _ in
          self.updateLayoutConstraints()
          // Using a nested animation block ensures that the frame change of the master content
          // area animates smoothly. The duration value is inherited and thus ignored.
          UIView.animate(withDuration: 0) {
            self.presentedMasterViewController?.view.layoutMargins =
              self.layout.sizes.masterLayoutMargins
            self.view.layoutIfNeeded()
          }
        }, completion: { _ in
          self.detailBarViewController.transition(.lower, animated: false)

          // collapse
          self.detailNavController.setViewControllers([], animated: false)
        })
    case (.landscape, .leave, .delegate):
      transitionCoordinator?.animate(alongsideTransition: nil, completion: { _ in
        self.presentedMasterViewController?.view.layoutMargins = .zero
      })
    case (_, .external, _):
      // There is nothing to do here for external transitions.
      break
    }
  }

  var actionsAreEnabled: Bool {
    return presentedMasterViewController?.actionEnabler?.isEnabled ?? true
  }

  func animateActionEnablement(actionsAreEnabled: Bool) {
    guard let master = presentedMasterViewController else { return }

    func animate() {
      if isExpanded {
        detailBarViewController.transition(.enable(actionsAreEnabled))
        master.emptyState.isEnabled = actionsAreEnabled
      } else {
        masterBarViewController.transition(.enable(actionsAreEnabled))
      }
    }

    UIView.animate(withDuration: Metrics.defaultAnimationDuration) {
      animate()
    }
  }

  var barIsElevated: Bool {
    let defaultBarIsElevated = false
    if isExpanded {
      return presentedDetailViewController?.barElevator?.isEnabled ?? defaultBarIsElevated
    } else {
      return presentedMasterViewController?.barElevator?.isEnabled ?? defaultBarIsElevated
    }
  }

  func animateBarElevation(barIsElevated: Bool) {
    guard let master = presentedMasterViewController else { return }

    func animate() {
      if isExpanded {
        detailBarViewController.barIsElevated = barIsElevated
      } else {
        masterBarViewController.barIsElevated = barIsElevated
      }
    }

    UIView.animate(withDuration: Metrics.defaultAnimationDuration) {
      animate()
    }
  }

  private func updateBarElevator() {
    if isExpanded {
      barElevator = presentedDetailViewController?.barElevator
    } else {
      barElevator = presentedMasterViewController?.barElevator
    }
  }

  func overrideMasterBackBarButtonItem(of vc: UIViewController) {
    if let item = vc.navigationItem.leftBarButtonItem {
      guard let action = item.action else { preconditionFailure("Expected an action selector.") }
      if let target = item.target {
        // If `target` is the same instance as `self`, we already overrode this one.
        guard target !== self else { return }
        // TODO: This happens when an internal transition is a result of a back action. Consider
        // improving the transition related states to track the initial source of each transition.
      }

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
    transitionType.update(for: .back, and: masterContent.count)
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
    updateBarElevator()

    if navigationController == navController {
      keyTint.updateAndApply()

      transitionType.update(for: .willShow, and: masterContent.count)
      transition(layout: layout, type: transitionType, source: .delegate)
    }

    if navigationController == detailNavController {
      keyTint.apply()

      presentedMasterViewController?.emptyState.isEnabled = actionsAreEnabled

      // Non-animated detail transitions are handled by the main transition method.
      guard animated else { return }

      detailBarViewController
        .transition(.update(with: currentActionItem(), isEnabled: actionsAreEnabled))
    }
  }

  func navigationController(
    _ navigationController: UINavigationController,
    didShow viewController: UIViewController,
    animated: Bool
  ) {
    if navigationController == navController {
      if viewController is ActionArea.MasterContent {
        overrideMasterBackBarButtonItem(of: viewController)
      }

      // The `transitionType` must be updated last.
      transitionType.update(for: .didShow, and: masterContent.count)
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
final class MaterialHeaderContainerViewController: ContentContainerViewController {

  private let appBar = MDCAppBar()

  override func viewDidLoad() {
    super.viewDidLoad()

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

}

extension MaterialHeaderContainerViewController {
  override func setCustomTint(_ customTint: CustomTint) {
    appBar.headerViewController.headerView.backgroundColor = customTint.primary
    super.setCustomTint(customTint)
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

// swiftlint:enable file_length
