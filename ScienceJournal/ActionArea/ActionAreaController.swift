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

      enum Mode: Equatable, CustomDebugStringConvertible {
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

      case portrait(CGSize, Mode)
      case landscape(CGSize, Mode)

      init(_ size: CGSize, and masterContentCount: Int = 0) {
        if UIDevice.current.userInterfaceIdiom == .pad {
          if size.isWiderThanTall {
            if masterContentCount > 0 {
              self = .landscape(size, .expanded)
            } else {
              self = .landscape(size, .collapsed)
            }
          } else {
            self = .portrait(size, .collapsed)
          }
        } else {
          self = .portrait(size, .collapsed)
        }
      }

      var isExpanded: Bool {
        switch self {
        case .landscape(_, .expanded):
          return true
        case .portrait, .landscape(_, .collapsed):
          return false
        }
      }

      var isCollapsed: Bool {
        return isExpanded == false
      }

      var mode: Mode {
        switch self {
        case let .portrait(_, mode), let .landscape(_, mode):
          return mode
        }
      }

      var divider: CGFloat { return 0.5 }
      var detailWidth: CGFloat { return 476 }
      var detailOffset: CGFloat { return detailWidth + divider }
      private var minMasterWidth: CGFloat { return maxMasterWidth - detailWidth - divider }
      private var maxMasterWidthInset: CGFloat { return maxMasterWidth - minMasterWidth }
      private var masterWidthInset: CGFloat { return (maxMasterWidth - minMasterWidth) / 2 }

      private var maxMasterWidth: CGFloat {
        switch self {
        case let .portrait(size, _), let .landscape(size, _):
          return size.width
        }
      }

      func masterLayoutMargins(
        including systemMinimumLayoutMargins: NSDirectionalEdgeInsets
      ) -> UIEdgeInsets {
        return UIEdgeInsets(
          top: 0,
          left: masterWidthInset,
          bottom: 0,
          right: masterWidthInset + systemMinimumLayoutMargins.leading
        )
      }

      func expand() -> Layout {
        switch self {
        case .portrait:
          preconditionFailure("Expansion is not supported in portrait.")
        case .landscape(_, .expanded):
          preconditionFailure("The layout is already expanded.")
        case let .landscape(size, .collapsed):
          return .landscape(size, .expanded)
        }
      }

      func collapse() -> Layout {
        switch self {
        case .portrait:
          preconditionFailure("Expansion is not supported in portrait.")
        case .landscape(_, .collapsed):
          preconditionFailure("The layout is already collapsed.")
        case let .landscape(size, .expanded):
          return .landscape(size, .collapsed)
        }
      }

      var debugDescription: String {
        switch self {
        case .portrait:
          return "portrait(\(mode))"
        case let .landscape(mode):
          return "landscape(\(mode))"
        }
      }
    }

    private var layout: Layout = Layout(UIScreen.main.bounds.size) {
      didSet {
        // The modal VC may need to update its bar button items when the layout changes.
        modalDetailViewController?.actionAreaStateDidChange(self)
      }
    }

    /// If the Action Area is using the expanded layout.
    var isExpanded: Bool { return layout.isExpanded }

    /// If the master content is currently visible.
    var isMasterVisible: Bool {
      if isExpanded { return true }
      return presentedDetailViewController == nil
    }

    /// The navigation controller that displays content in a master context.
    /// This is currently here for backwards compatibility. Consider using `show` if appropriate.
    private(set) lazy var navController: UINavigationController = {
      let nc = UINavigationController()
      nc.isNavigationBarHidden = true
      nc.delegate = self
      return nc
    }()

    private lazy var detailNavController: UINavigationController = {
      let nc = UINavigationController()
      nc.isNavigationBarHidden = true
      nc.delegate = self
      return nc
    }()

    private lazy var masterBarViewController = BarViewController(content: navController)
    private lazy var detailBarViewController = BarViewController(content: detailNavController)

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
        updateBarButtonItems(with: transitionCoordinator)
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
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    private lazy var layoutConstraints = MutuallyExclusiveConstraints<Layout.Mode> { constraints in
      constraints[.collapsed] = masterBarViewController.view.snp.prepareConstraints { prepare in
        prepare.bottom.trailing.equalToSuperview()
      }
      constraints[.expanded] = detailBarViewController.view.snp.prepareConstraints { prepare in
        prepare.bottom.trailing.equalToSuperview()
      }
    }

    private lazy var transitioningNavigationController: UINavigationController = {
      let vc = UINavigationController()
      vc.isNavigationBarHidden = true
      vc.view.isHidden = true
      return vc
    }()

    private lazy var actionAreaContent: UIViewController = {
      let vc = UIViewController()
      vc.view.backgroundColor = .black
      return vc
    }()

    override func viewDidLoad() {
      super.viewDidLoad()

      addChild(actionAreaContent)
      view.addSubview(actionAreaContent.view)
      actionAreaContent.didMove(toParent: self)

      actionAreaContent.addChild(masterBarViewController)
      actionAreaContent.view.addSubview(masterBarViewController.view)
      masterBarViewController.didMove(toParent: actionAreaContent)
      masterBarViewController.view.snp.makeConstraints { make in
        make.top.leading.equalToSuperview()
      }

      actionAreaContent.addChild(detailBarViewController)
      actionAreaContent.view.addSubview(detailBarViewController.view)
      detailBarViewController.didMove(toParent: actionAreaContent)
      detailBarViewController.view.snp.makeConstraints { make in
        make.width.equalTo(layout.detailWidth)
        make.top.bottom.equalTo(masterBarViewController.view)
        make.leading.equalTo(masterBarViewController.view.snp.trailing).offset(layout.divider)
      }

      addChild(transitioningNavigationController)
      view.addSubview(transitioningNavigationController.view)
      transitioningNavigationController.didMove(toParent: self)

      updateTraitCollectionOverrides()
      layoutConstraints.activate(layout.mode)
    }

    override func viewWillTransition(
      to size: CGSize,
      with coordinator: UIViewControllerTransitionCoordinator
    ) {
      transitionType.update(
        for: .willTransition(to: size),
        and: masterContent.count
      )
      transition(
        layout: layout,
        type: transitionType,
        source: .viewWillTransition,
        with: coordinator
      )

      super.viewWillTransition(to: size, with: coordinator)
    }

    private func updateTraitCollectionOverrides() {
      let horizontallyCompact = UITraitCollection(horizontalSizeClass: .compact)
      let horizontallyRegular = UITraitCollection(horizontalSizeClass: .regular)

      if UIDevice.current.userInterfaceIdiom == .pad {
        // Overriding the master content ensures it can still use an appropriate layout.
        actionAreaContent.setOverrideTraitCollection(
          horizontallyRegular, forChild: masterBarViewController
        )

        // Detail content in the expanded layout should always be horizontally compact.
        actionAreaContent.setOverrideTraitCollection(
          horizontallyCompact, forChild: detailBarViewController
        )
      } else {
        // On iPhone, we use a horizontally compact layout to prevent expansion on plus/max devices.
        actionAreaContent
          .setOverrideTraitCollection(horizontallyCompact, forChild: masterBarViewController)
      }
    }

    private func updateBarButtonItems(with coordinator: UIViewControllerTransitionCoordinator?) {
      let newActionItem = currentActionItem()

      if isExpanded == false {
        masterBarViewController
          .transition(.update(with: newActionItem, isEnabled: actionsAreEnabled), with: coordinator)
      } else {
        detailBarViewController
          .transition(.update(with: newActionItem, isEnabled: actionsAreEnabled), with: coordinator)
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
      // TODO: Consider integrating this validation logic into the transition types.
      guard vc is ActionArea.MasterContent, masterContent.isEmpty, case .landscape = layout else {
        navController.pushViewController(vc, animated: true)
        return
      }

      navController.pushViewController(vc, animated: false)
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
  private enum MasterTransitionType {
    /// Entering the Action Area from external content.
    case enter
    /// Transitioning between master content within the Action Area.
    case `internal`
    /// Leaving the Action Area to external content.
    case leave
    /// Transitions outside of the Action Area that are using its master navigation controller.
    case external
    /// Layout transitions related to size changes or rotation.
    case size(Layout)

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
      case let (_, .willTransition(to: newSize)):
        self = .size(Layout(newSize, and: contentCount))
      case (.size, .didTransition):
        self = contentCount > 0 ? .internal : .external
      default:
        break
      }
    }
  }

  /// The master transition phase.
  ///
  /// These values represent where transition-related operations take place, and they are used
  /// as part of the input to determine when to change the `MasterTransitionType`.
  private enum MasterTransitionPhase {
    case back
    case willShow
    case didShow
    case willTransition(to: CGSize)
    case didTransition
  }

  /// The master transition source.
  ///
  /// Transitions can be initiated from either a user action or a navgiation controller transition.
  private enum TransitionSource {
    /// Either a back-button tap or swipe gesture.
    case backAction
    /// A `UINavigationControllerDelegate` call.
    case delegate
    /// A `viewWillTransition(to:with:)` call.
    case viewWillTransition
  }

  /// Coordinate a master content transition.
  ///
  /// - Parameters:
  ///   - layout: The layout for this transition.
  ///   - type: The type of this transition.
  ///   - source: The source of the current phase of the transition.
  ///   - coordinator: The coordinator of the transition.
  private func transition(
    layout: Layout,
    type: MasterTransitionType,
    source: TransitionSource,
    with coordinator: UIViewControllerTransitionCoordinator?
  ) {
    switch (layout, type, source) {
    case (_, .external, _):
      // There is nothing to do here for external transitions.
      break
    case let (_, .size(newLayout), _):
      transition(from: layout, to: newLayout, source: source, with: coordinator)
    case (.portrait, _, _):
      transition(portrait: layout, type: type, source: source, with: coordinator)
    case (.landscape, _, _):
      transition(landscape: layout, type: type, source: source, with: coordinator)

    }
  }

  private func transition(
    portrait: Layout,
    type: MasterTransitionType,
    source: TransitionSource,
    with coordinator: UIViewControllerTransitionCoordinator?
  ) {
    guard case .portrait = portrait else {
      preconditionFailure("This method only handle portrait transitions.")
    }

    switch (type, source) {
    case (.enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.enter, .delegate):
      masterBarViewController.transition(
        .raise(with: currentActionItem(), isEnabled: actionsAreEnabled),
        with: coordinator
      )
    case (.internal, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.internal, .delegate):
      masterBarViewController.transition(
        .update(with: currentActionItem(), isEnabled: actionsAreEnabled),
        with: coordinator
      )
    case (.leave, .backAction):
      sendOverriddenMasterBackButtonAction()
    case (.leave, .delegate):
      masterBarViewController.transition(.lower, with: coordinator)
    case (.external, _), (.size, _), (_, .viewWillTransition):
      preconditionFailure("This method only handle portrait transitions.")
    }
  }

  private func transition(
    landscape: Layout,
    type: MasterTransitionType,
    source: TransitionSource,
    with coordinator: UIViewControllerTransitionCoordinator?
  ) {
    guard case .landscape = landscape else {
      preconditionFailure("This method only handle landscape transitions.")
    }

    switch (type, source) {
    case (.enter, .backAction):
      preconditionFailure("The Action Area cannot be entered through a back action.")
    case (.enter, .delegate):
      guard let presentedMasterViewController = presentedMasterViewController else {
        preconditionFailure("Expected a presentedMasterViewController.")
      }

      // Snapshot current content.
      let fromSnapshot = UIViewController()
      fromSnapshot.view = actionAreaContent.view.snapshotView(afterScreenUpdates: false)!

      // Cover current content.
      transitioningNavigationController.setViewControllers([fromSnapshot], animated: false)
      transitioningNavigationController.view.isHidden = false

      // Update layout.
      let newLayout = layout.expand()
      layoutConstraints.activate(newLayout.mode)
      layout = newLayout

      // Prepare new content under snapshot.
      actionEnabler = presentedMasterViewController.actionEnabler
      detailNavController
        .pushViewController(presentedMasterViewController.emptyState, animated: false)
      detailBarViewController.transition(
        .raise(with: currentActionItem(), isEnabled: actionsAreEnabled),
        with: coordinator
      )
      view.layoutIfNeeded()

      // Snapshot new content.
      let toSnapshot = UIViewController()
      toSnapshot.view = actionAreaContent.view.snapshotView(afterScreenUpdates: true)!

      // Transition content snapshots.
      transitioningNavigationController.pushViewController(toSnapshot, animated: true)
      transitioningNavigationController.transitionCoordinator?.animate(
        alongsideTransition: nil,
        completion: { _ in
          // Clean up snapshots.
          self.transitioningNavigationController.view.isHidden = true
          self.transitioningNavigationController.setViewControllers([], animated: false)
        }
      )
    case (.internal, .backAction):
      sendOverriddenMasterBackButtonAction()
      if let master = masterContent.last {
        detailNavController.popToViewController(master.emptyState, animated: true)
      }
    case (.internal, .delegate):
      actionEnabler = presentedMasterViewController?.actionEnabler
      detailNavController.setViewControllers(emptyStates, animated: true)
    case (.leave, .backAction):
      // Snapshot current content.
      let fromSnapshot = UIViewController()
      fromSnapshot.view = actionAreaContent.view.snapshotView(afterScreenUpdates: false)!

      // Cover current content.
      transitioningNavigationController.setViewControllers([fromSnapshot], animated: false)
      transitioningNavigationController.view.isHidden = false

      // Update layout.
      let newLayout = layout.collapse()
      layoutConstraints.activate(newLayout.mode)
      layout = newLayout

      // Prepare new content under snapshot.
      navController.popViewController(animated: false)
      view.layoutIfNeeded()

      // Snapshot new content.
      let toSnapshot = UIViewController()
      toSnapshot.view = actionAreaContent.view.snapshotView(afterScreenUpdates: true)!

      // Prepare transition controller.
      transitioningNavigationController
        .setViewControllers([toSnapshot, fromSnapshot], animated: false)

      // Transition content snapshots.
      transitioningNavigationController.popViewController(animated: true)
      transitioningNavigationController.transitionCoordinator?.animate(
        alongsideTransition: nil,
        completion: { _ in
          // Clean up snapshots and detail content.
          self.transitioningNavigationController.view.isHidden = true
          self.transitioningNavigationController.setViewControllers([], animated: false)
          self.detailNavController.setViewControllers([], animated: false)
        }
      )
    case (.leave, .delegate):
      coordinator?.animate(alongsideTransition: nil, completion: { _ in
        self.presentedMasterViewController?.view.layoutMargins = .zero
      })
    case (.external, _), (.size, _), (_, .viewWillTransition):
      preconditionFailure("This method only handle landscape transitions.")
    }
  }

  private func transition(
    from oldLayout: Layout,
    to newLayout: Layout,
    source: TransitionSource,
    with coordinator: UIViewControllerTransitionCoordinator?
  ) {
    func createCurrentSizeConstraint() -> Constraint? {
      var sizeConstraint: Constraint?
      masterBarViewController.view.snp.makeConstraints { make in
        sizeConstraint = make.size.equalTo(masterBarViewController.view.bounds.size).constraint
      }
      return sizeConstraint
    }

    switch (oldLayout, newLayout, source) {
    case let (oldLayout, newLayout, .viewWillTransition)
      where oldLayout.isCollapsed && newLayout.isExpanded: // Expand.
      guard let topMasterContent = masterContent.last else {
        preconditionFailure("The layout cannot be expanded without any master content.")
      }

      // Prepare new content.
      var detailNavViewControllers: [UIViewController] = emptyStates
      switch state {
      case .normal:
        // normal state:
        //   - [master]
        //   - [master, detail]
        detailNavViewControllers.append(contentsOf: detailContent)
      case .modal:
        // TODO: Consider storing the `modalDetailViewController` in the state itself.
        guard let modalDetailViewController = modalDetailViewController else {
          preconditionFailure("A modalDetailViewController must be set in the modal state.")
        }
        // TODO: Handle the case where the modal detail is interleaved within the detail content.
        //       Currently detail content that can enter the modal state is only shown directly
        //       between master and other detail content, but nothing prevents that possibility.
        //
        // modal state:
        //   - [master]
        //   - [master, modal]
        //   - [master, detail] (modal was hidden)
        //   - [master, modal, detail]
        if detailContent.contains(where: { $0 === modalDetailViewController }) == false {
          detailNavViewControllers.append(modalDetailViewController)
        }
        detailNavViewControllers.append(contentsOf: detailContent)
      }

      // Update layout.
      self.layout = newLayout
      layoutConstraints.deactivateAll()
      let sizeConstraint = createCurrentSizeConstraint()
      view.layoutIfNeeded()

      // Snapshot existing content.
      var navControllerSnapshot: UIView?
      if navController.topViewController != topMasterContent {
        navControllerSnapshot =
          navController.topViewController?.view.snapshotView(afterScreenUpdates: false)
        navControllerSnapshot.map { navController.view.addSubview($0) }
      }

      detailNavController.setViewControllers(emptyStates, animated: false)
      var detailNavControllerSnapshot: UIView?
      if detailNavController.topViewController != detailNavViewControllers.last {
        detailNavControllerSnapshot =
          detailNavController.topViewController?.view.snapshotView(afterScreenUpdates: false)
        detailNavControllerSnapshot.map { detailNavController.view.addSubview($0) }
      }

      // Replace content.
      navController.popToViewController(topMasterContent, animated: false)
      detailNavController.setViewControllers(detailNavViewControllers, animated: false)

      coordinator?.animate(alongsideTransition: { _ in
        sizeConstraint?.deactivate()
        self.layoutConstraints.activate(newLayout.mode)
        self.view.layoutIfNeeded()

        self.masterBarViewController
          .transition(.update(with: .empty, isEnabled: self.actionsAreEnabled), with: coordinator)
        self.detailBarViewController.transition(
          .update(with: self.currentActionItem(), isEnabled: self.actionsAreEnabled),
          with: coordinator
        )
        navControllerSnapshot?.alpha = 0
        detailNavControllerSnapshot?.alpha = 0
      }) { _ in
        // TODO: Rotating in the middle of a transition results in the final frame value from the
        // transition being set after the rotation animations complete, which leaves the frame with
        // the wrong size. This fixes the problem, but it seems like there should be some way to
        // serialize the animations or handle this more gracefully.
        self.navController.topViewController?.view.frame = self.navController.view.frame

        navControllerSnapshot?.removeFromSuperview()
        detailNavControllerSnapshot?.removeFromSuperview()
        self.transitionType.update(for: .didTransition, and: self.masterContent.count)
      }
    case let (oldLayout, newLayout, .viewWillTransition)
      where oldLayout.isExpanded && newLayout.isCollapsed: // Collapse.
      guard let topEmptyState = emptyStates.last else {
        preconditionFailure("The layout cannot be collapsed without any empty states.")
      }

      // Prepare new content.
      var navViewControllers = navController.viewControllers
      navViewControllers.append(contentsOf: detailContent)

      // Update layout.
      self.layout = newLayout
      layoutConstraints.deactivateAll()
      let sizeConstraint = createCurrentSizeConstraint()
      view.layoutIfNeeded()

      // Snapshot existing content.
      var navControllerSnapshot: UIView?
      if navController.topViewController != navViewControllers.last {
        navControllerSnapshot =
          navController.topViewController?.view.snapshotView(afterScreenUpdates: false)
        navControllerSnapshot.map { navController.view.addSubview($0) }
      }

      var detailNavControllerSnapshot: UIView?
      if detailNavController.topViewController != topEmptyState {
        detailNavControllerSnapshot =
          detailNavController.topViewController?.view.snapshotView(afterScreenUpdates: false)
        detailNavControllerSnapshot.map { detailNavController.view.addSubview($0) }
      }

      // Replace content.
      detailNavController.popToViewController(topEmptyState, animated: false)
      navController.setViewControllers(navViewControllers, animated: false)

      coordinator?.animate(alongsideTransition: { _ in
        sizeConstraint?.deactivate()
        self.layoutConstraints.activate(newLayout.mode)
        self.view.layoutIfNeeded()

        self.masterBarViewController.transition(
          .update(with: self.currentActionItem(), isEnabled: self.actionsAreEnabled),
          with: coordinator
        )
        self.detailBarViewController
          .transition(.update(with: .empty, isEnabled: self.actionsAreEnabled), with: coordinator)
        navControllerSnapshot?.alpha = 0
        detailNavControllerSnapshot?.alpha = 0
      }) { _ in
        self.detailNavController.setViewControllers([], animated: false)
        navControllerSnapshot?.removeFromSuperview()
        detailNavControllerSnapshot?.removeFromSuperview()
        self.transitionType.update(for: .didTransition, and: self.masterContent.count)
      }
    case let (_, newLayout, .viewWillTransition):
      self.layout = newLayout
      self.transitionType.update(for: .didTransition, and: self.masterContent.count)
    case (_, _, .backAction):
      preconditionFailure("Back actions should never initiate a layout transition.")
    case (_, _, .delegate):
      // There is nothing to do here for delegate calls during a transitions.
      break
    }
  }

  var actionsAreEnabled: Bool {
    return presentedMasterViewController?.actionEnabler?.isEnabled ?? true
  }

  func animateActionEnablement(actionsAreEnabled: Bool) {
    guard let master = presentedMasterViewController else { return }

    let coordinator = initiateLocalTransition()
    if isExpanded {
      detailBarViewController.transition(.enable(actionsAreEnabled), with: coordinator)
      master.emptyState.isEnabled = actionsAreEnabled
    } else {
      masterBarViewController.transition(.enable(actionsAreEnabled), with: coordinator)
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

}

// MARK: - Back Action Handling

extension ActionArea.Controller: UIGestureRecognizerDelegate {

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
    handleBackAction()
  }

  private func handleBackAction() {
    transitionType.update(for: .back, and: masterContent.count)
    transition(layout: layout, type: transitionType, source: .backAction, with: nil)
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if masterTargetsAndActions.isEmpty {
      return true
    } else {
      handleBackAction()
      return false
    }
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
      transition(
        layout: layout,
        type: transitionType,
        source: .delegate,
        with: navigationController.transitionCoordinator
      )
    }

    if navigationController == detailNavController {
      keyTint.apply()

      presentedMasterViewController?.emptyState.isEnabled = actionsAreEnabled

      // Non-animated detail transitions are handled by the main transition method.
      guard animated else { return }

      detailBarViewController.transition(
        .update(with: currentActionItem(), isEnabled: actionsAreEnabled),
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
      if viewController is ActionArea.MasterContent {
        overrideMasterBackBarButtonItem(of: viewController)
        navController.interactivePopGestureRecognizer?.delegate = self
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

// swiftlint:enable file_length
