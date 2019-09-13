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

  // TODO: Extract to separate file after implementing custom bar items.
  struct ActionItem {
    static let empty: ActionItem = ActionItem(primary: nil, items: [])

    var isEmpty: Bool { return primary == nil && items.isEmpty }

    let primary: UIButton?
    let items: [UIBarButtonItem]

    // We need to retain this item, so it won't get deallocated.
    private let _primary: BarButtonItem?

    init(primary: BarButtonItem? = nil, items: [BarButtonItem]) {
      self._primary = primary

      func create(primary: BarButtonItem) -> UIButton {
        // TODO: Remove when we have real assets.
        let resizedImage = primary.image?.sizedWithAspect(to: CGSize(width: 44, height: 44))

        let button = MDCFloatingButton()
        button.mode = .expanded
        button.setTitle(primary.title, for: .normal)
        button.setImage(resizedImage, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setBackgroundColor(.white, for: .normal)
        let insets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        button.setContentEdgeInsets(insets, for: .default, in: .expanded)
        button.addTarget(primary, action: #selector(BarButtonItem.execute), for: .touchUpInside)
        return button
      }

      func create(items: [BarButtonItem]) -> [UIBarButtonItem] {
        return items.map(createBarButtonItem(from:))
      }

      func createBarButtonItem(from item: BarButtonItem) -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(title: item.title,
                                            style: .plain,
                                            target: item,
                                            action: #selector(BarButtonItem.execute))
        barButtonItem.image = item.image
        return barButtonItem
      }

      self.primary = primary.map(create(primary:))
      self.items = create(items: items)
    }
  }

  /// The bar where items are displayed.
  final class BarViewController: UIViewController {

    private enum Metrics {
      static let defaultAnimationDuration: TimeInterval = 0.4
      static let barHeight: CGFloat = 88
      static let barBackgroundColor = UIColor(white: 0.98, alpha: 1.0)
      static let barButtonTitleColor: UIColor = .gray
      static let barCornerRadius: CGFloat = 15
      static let barDefaultMargins = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
      static let barToFABSpacing: CGFloat = 8
      static let disabledAlpha: CGFloat = 0.2
    }

    private final class Transition {
      private let before: () -> Void
      private let during: () -> Void
      private let after: () -> Void

      init(before: (() -> Void)? = nil, during: (() -> Void)? = nil, after: (() -> Void)? = nil) {
        self.before = before ?? {}
        self.during = during ?? {}
        self.after = after ?? {}
      }

      convenience init(from: UIButton?, to: UIButton?) {
        switch (from, to) {
        case (.none, .none):
          self.init()
        case let (.some(from), .none):
          self.init(during: {
            from.alpha = 0
          }, after: {
            from.removeFromSuperview()
          })
        case let (.none, .some(to)):
          self.init(before: {
            to.alpha = 0
          }, during: {
            to.alpha = 1
          }, after: nil)
        case let (.some(from), .some(to)):
          self.init(before: {
            to.alpha = 0
            to.layoutIfNeeded()
          }, during: {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
              UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                from.titleLabel?.alpha = 0
                from.imageView?.alpha = 0
              }
              UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.4) {
                let x = to.bounds.width / from.bounds.width
                from.transform = CGAffineTransform(scaleX: x, y: 1)
              }
              UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
                from.alpha = 0
                to.alpha = 1
              }
            })
          }, after: {
            from.removeFromSuperview()
          })
        }
      }

      convenience init(from: MDCButtonBar, to: [UIBarButtonItem]) {
        self.init(during: { from.items = to })
      }

      func perform(
        in view: UIView,
        with transitionCoordinator: UIViewControllerTransitionCoordinator?
      ) {
        if let transitionCoordinator = transitionCoordinator, transitionCoordinator.isAnimated {
          before()
          transitionCoordinator.animateAlongsideTransition(in: view, animation: { _ in
            self.during()
          }) { _ in
            self.after()
          }
        } else {
          before()
          during()
          after()
        }
      }
    }

    private final class PrimaryConstraints {
      private let compact: Constraint
      private let regular: Constraint

      init(barWrapper: SafeMarginWrapperView, primary: UIView, spacing: CGFloat) {
        primary.snp.makeConstraints { make in
          make.bottom.equalTo(barWrapper.snp.top).offset(-1 * spacing)
        }
        let constraints = primary.snp.prepareConstraints { prepare in
          prepare.centerX.equalToSuperview()
          prepare.right.equalTo(barWrapper.contentView)
        }
        precondition(constraints.count == 2, "Failed to prepare constraints.")
        compact = constraints[0]
        regular = constraints[1]
      }

      func activate(for traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .compact {
          regular.deactivate()
          compact.activate()
        } else {
          regular.deactivate()
          compact.activate()
        }
      }
    }

    private var primaryConstraints: PrimaryConstraints?

    /// The `ActionItem` to display in the Action Area Bar.
    var actionItem: ActionItem = .empty {
      didSet {
        primary = actionItem.primary

        let transition = Transition(from: buttonBar, to: actionItem.items)
        transition.perform(in: view, with: transitionCoordinator)
      }
    }

    private var primary: UIButton? {
      didSet {
        if let primary = primary {
          view.addSubview(primary)
          primaryConstraints = PrimaryConstraints(
            barWrapper: barWrapper,
            primary: primary,
            spacing: Metrics.barToFABSpacing
          )
          primaryConstraints?.activate(for: traitCollection)
        } else {
          primaryConstraints = nil
        }

        let transition =  Transition(from: oldValue, to: primary)
        transition.perform(in: view, with: transitionCoordinator)
      }
    }

    /// Lower the bar.
    func lower() {
      position = .lowered
    }

    /// Raise the bar.
    func raise() {
      position = .raised
    }

    /// Hide the bar.
    func hide() {
      barWrapper.alpha = 0
      updateAdditionalSafeAreaInsets()
    }

    /// Show the bar.
    func show() {
      barWrapper.alpha = 1
      updateAdditionalSafeAreaInsets()
    }

    /// Enable or disable the bar.
    var isEnabled: Bool = true {
      didSet {
        if isEnabled {
          buttonBar.alpha = 1
        } else {
          buttonBar.alpha = Metrics.disabledAlpha
        }
        buttonBar.isUserInteractionEnabled = isEnabled
      }
    }

    private enum Position {
      case raised
      case lowered
    }

    // This view is configured so that its margins will be the smaller of its explicitly configured
    // margins or the margins enforced by the safe area.
    private final class SafeMarginWrapperView: UIView {

      override class var requiresConstraintBasedLayout: Bool {
        return true
      }

      let contentView = UIView()

      // Without a wrapper, we'd have to set `viewRespectsSystemMinimumLayoutMargins` to `false`
      // and reduce the margins of the root view of whatever view controller this view is used in.
      private let wrapper: UIView = {
        let view = UIView()
        // Set `preservesSuperviewLayoutMargins` to `true`, so that this view's margins will be
        // increased if the superview's margins are increased to accomodate the safe area.
        view.preservesSuperviewLayoutMargins = true

        // Set `insetsLayoutMarginsFromSafeArea` to `false`, so this view's local margins will be
        // relative to the edge the frame, as opposed to the safe area.
        view.insetsLayoutMarginsFromSafeArea = false
        return view
      }()

      // The desired margins, which will be increased to at most the safe area margins.
      var safeMargins: UIEdgeInsets = .zero {
        didSet {
          wrapper.layoutMargins = safeMargins
        }
      }

      // MARK: - Lifecycle

      override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layoutMargins = .zero

        wrapper.snp.setLabel("wrapper")
        addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
          make.edges.equalToSuperview()
        }

        contentView.snp.setLabel("contentView")
        wrapper.addSubview(contentView)
        contentView.snp.makeConstraints { make in
          make.edges.equalTo(wrapper.snp.margins)
        }
      }

    }

    private let buttonBar: MDCButtonBar = {
      let buttonBar = MDCButtonBar()
      buttonBar.backgroundColor = Metrics.barBackgroundColor
      buttonBar.setButtonsTitleColor(Metrics.barButtonTitleColor, for: .normal)
      buttonBar.layer.cornerRadius = Metrics.barCornerRadius
      buttonBar.layer.masksToBounds = true
      return buttonBar
    }()

    private let content: UIViewController
    private let barWrapper = SafeMarginWrapperView()

    private var position: Position = .lowered {
      didSet {
        updatePosition()
      }
    }

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - content: The content view controller on which to overlay the bar.
    init(content: UIViewController) {
      self.content = content
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
      super.viewDidLoad()

      view.snp.setLabel("bar")

      content.view.snp.setLabel("content")
      addChild(content)
      view.addSubview(content.view)
      content.didMove(toParent: self)
      content.view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      barWrapper.snp.setLabel("barWrapper")
      view.addSubview(barWrapper)
      barWrapper.snp.makeConstraints { make in
        make.leading.bottom.equalToSuperview()
        make.trailing.greaterThanOrEqualToSuperview()
      }

      buttonBar.snp.setLabel("buttonBar")
      barWrapper.contentView.addSubview(buttonBar)
      buttonBar.snp.makeConstraints { make in
        make.edges.equalToSuperview()
        make.height.equalTo(Metrics.barHeight)
      }

      // TODO: Figure out how to do this dynamically. Ideally we would get these from the margins
      // of the content view controller, but they're not what we want.
      barWrapper.safeMargins = Metrics.barDefaultMargins
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()

      // Lowering and raising the bar uses a `transform` based on a subview height, so we need to
      // update the transform after layout changes because the height may have changed.
      updatePosition()
    }

    override var transitionCoordinator: UIViewControllerTransitionCoordinator? {
      return super.transitionCoordinator ?? content.transitionCoordinator
    }

    // MARK: - Implementation

    private func updatePosition() {
      switch position {
      case .lowered:
        barWrapper.transform = CGAffineTransform(translationX: 0, y: barWrapper.bounds.height)
      case .raised:
        barWrapper.transform = .identity
      }
      updateAdditionalSafeAreaInsets()
    }

    private func updateAdditionalSafeAreaInsets() {
      if position == .raised, barWrapper.alpha > 0 {
        content.additionalSafeAreaInsets =
          UIEdgeInsets(top: 0, left: 0, bottom: barWrapper.bounds.height, right: 0)
      } else {
        content.additionalSafeAreaInsets = .zero
      }
    }

    override var description: String {
      return "ActionArea.\(type(of: self))"
    }

    override var debugDescription: String {
      return "ActionArea.\(type(of: self))(content: \(content))"
    }

  }

}

// MARK: - Debugging

#if DEBUG
extension ActionArea.BarViewController {

  func layoutDebuggingInfo() -> String {
    func v(_ name: String, _ v: UIView, _ message: inout String) {
      message += "  \(name).frame: \(v.frame)\n"
      message += "  \(name).bounds: \(v.bounds)\n"
      message += "  \(name).layoutMargins: \(v.layoutMargins)\n"
      message += "  \(name).safeAreaInsets: \(v.safeAreaInsets)\n"
      message += "  \(name).preservesSuperviewLayoutMargins: \(v.preservesSuperviewLayoutMargins)\n"
      message += "  \(name).insetsLayoutMarginsFromSafeArea: \(v.insetsLayoutMarginsFromSafeArea)\n"
    }

    func vc(_ name: String, _ vc: UIViewController, _ message: inout String) {
      v("\(name).view", vc.view, &message)
      message += "  \(name).viewRespectsSystemMinimumLayoutMargins: " +
        "\(vc.viewRespectsSystemMinimumLayoutMargins)\n"
      message += "  \(name).additionalSafeAreaInsets: \(vc.additionalSafeAreaInsets)\n"
    }

    var message = "\(type(of: self)).\(#function)\n"
    if let window = view.window {
      message += "  window.safeAreaInsets: \(window.safeAreaInsets)\n"
    }
    vc("barViewController", self, &message)
    v("barViewController.barWrapper", barWrapper, &message)
    v("barViewController.buttonBar", buttonBar, &message)
    vc("barViewController.content", content, &message)

    return message
  }

}
#endif
