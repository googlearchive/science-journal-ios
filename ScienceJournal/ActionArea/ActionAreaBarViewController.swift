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
import third_party_objective_c_material_components_ios_components_ShadowLayer_ShadowLayer

extension ActionArea {

  // TODO: Extract to separate file after implementing custom bar items.
  struct ActionItem {
    static let empty: ActionItem = ActionItem(primary: nil, items: [])

    var isEmpty: Bool { return primary == nil && items.isEmpty }

    let primary: UIButton?
    let items: [BarButtonItem]

    // We need to retain this item, so it won't get deallocated.
    private let _primary: BarButtonItem?

    init(primary: BarButtonItem? = nil, items: [BarButtonItem]) {
      self._primary = primary

      func create(primary: BarButtonItem) -> UIButton {
        let button = MDCFloatingButton()
        button.mode = .expanded
        button.setTitle(primary.title, for: .normal)
        button.setImage(primary.image, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setBackgroundColor(.white, for: .normal)
        let insets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        button.setContentEdgeInsets(insets, for: .default, in: .expanded)
        button.addTarget(primary, action: #selector(BarButtonItem.execute), for: .touchUpInside)
        return button
      }

      self.primary = primary.map(create(primary:))
      self.items = items
    }
  }

  /// The bar where items are displayed.
  final class BarViewController: UIViewController {

    private enum Metrics {
      static let defaultAnimationDuration: TimeInterval = 0.4
      static let actionButtonSize: CGFloat = 48
      static let actionButtonToLabelSpacing: CGFloat = 4
      static let barPadding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
      static let barBackgroundColor = UIColor(white: 0.98, alpha: 1.0)
      static let barButtonTitleColor: UIColor = .gray
      static let barCornerRadius: CGFloat = 15
      static let barDefaultMargins = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
      static let barToFABSpacing: CGFloat = 8
      static let disabledAlpha: CGFloat = 0.2
      static let barShadow = MDCShadowMetrics(elevation: ShadowElevation.fabResting.rawValue)
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

      convenience init(bar: Bar, to newItems: [BarButtonItem]) {
        let snapshot = bar.snapshotView(afterScreenUpdates: false)
        self.init(
          before: {
            if let snapshot = snapshot {
              bar.superview?.addSubview(snapshot)
              snapshot.frame = bar.frame
            }
            bar.alpha = 0
            bar.items = newItems
          },
          during: {
            snapshot?.alpha = 0
            bar.alpha = 1
          },
          after: {
            snapshot?.removeFromSuperview()
          }
        )
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

        // TODO:
        //   Revisit this animation. The current approach performs much better than replacing the
        //   bar, but it won't handle transitions where the action descriptions have different
        //   numbers of lines.
        let transition = Transition(bar: bar, to: actionItem.items)
        transition.perform(in: view, with: transitionCoordinator)
      }
    }

    private var primary: UIButton? {
      didSet {
        if let primary = primary {
          primary.layoutIfNeeded()
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

        let transition = Transition(from: oldValue, to: primary)
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
      primary?.alpha = 0
      barWrapper.alpha = 0
      updateAdditionalSafeAreaInsets()
    }

    /// Show the bar.
    func show() {
      primary?.alpha = 1
      barWrapper.alpha = 1
      updateAdditionalSafeAreaInsets()
    }

    /// Enable or disable the bar.
    var isEnabled: Bool = true {
      didSet {
        if isEnabled {
          bar.alpha = 1
        } else {
          bar.alpha = Metrics.disabledAlpha
        }
        bar.isUserInteractionEnabled = isEnabled
      }
    }

    /// Elevate or flatten the bar.
    var barIsElevated: Bool = true {
      didSet {
        guard oldValue != barIsElevated else { return }

        let barAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        let toValue: Float
        if barIsElevated {
          toValue = Metrics.barShadow.bottomShadowOpacity
        } else {
          toValue = 0
        }
        barAnimation.fromValue = bar.layer.shadowOpacity
        barAnimation.toValue = toValue
        bar.layer.shadowOpacity = toValue
        bar.layer.add(barAnimation, forKey: "barAnimation")
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

    private final class Bar: UIView, CustomTintable {

      // swiftlint:disable:next nesting
      private final class Button: UIView, CustomTintable {

        override class var requiresConstraintBasedLayout: Bool {
          return true
        }

        private let button: UIButton = {
          let view = UIButton(type: .custom)
          view.layer.cornerRadius = Metrics.actionButtonSize / 2
          view.clipsToBounds = true
          return view
        }()

        private let label: UILabel = {
          let view = UILabel()
          view.numberOfLines = 2
          view.textColor = Metrics.barButtonTitleColor
          return view
        }()

        private let item: BarButtonItem
        private var _intrinsicContentSize: CGSize = .zero

        init(frame: CGRect, item: BarButtonItem) {
          self.item = item
          super.init(frame: frame)

          accessibilityHint = item.accessibilityHint

          button.setImage(item.image?.withRenderingMode(.alwaysTemplate), for: .normal)
          button.addTarget(item, action: #selector(BarButtonItem.execute), for: .touchUpInside)
          addSubview(button)
          button.snp.makeConstraints { make in
            make.size.equalTo(Metrics.actionButtonSize)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
          }

          label.text = item.title
          label.layoutIfNeeded()
          addSubview(label)
          label.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(Metrics.actionButtonToLabelSpacing)
            make.centerX.equalTo(button)
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
          }

          self._intrinsicContentSize = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }

        required init?(coder aDecoder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
          return _intrinsicContentSize
        }

        func setCustomTint(_ customTint: CustomTint) {
          button.imageView?.tintColor = customTint.primary
          button.backgroundColor = customTint.secondary
        }

      }

      override class var requiresConstraintBasedLayout: Bool {
        return true
      }

      private let keyTint = KeyTint()

      func setCustomTint(_ customTint: CustomTint) {
        keyTint.customTint = customTint
        keyTint.apply(to: buttons)
      }

      private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillEqually
        return view
      }()

      private var buttons: [Button] = [] {
        didSet {
          keyTint.apply(to: buttons)
        }
      }

      var items: [BarButtonItem] = [] {
        didSet {
          stackView.removeAllArrangedViews()
          buttons = items.map { Button(frame: frame, item: $0) }
          buttons.forEach { button in
            stackView.addArrangedSubview(button)
          }
          (stackView.arrangedSubviews.count ..< 4).forEach { _ in
            stackView.addArrangedSubview(UIView())
          }
        }
      }

      override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        backgroundColor = Metrics.barBackgroundColor
        layer.cornerRadius = Metrics.barCornerRadius
        layer.masksToBounds = true
        layoutMargins = Metrics.barPadding
        stackView.snp.makeConstraints { make in
          make.edges.equalTo(snp.margins)
        }
      }

      required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }

    }

    private var bar: Bar = {
      let view = Bar()
      view.clipsToBounds = false
      view.layer.shadowRadius = Metrics.barShadow.bottomShadowRadius
      view.layer.shadowOffset = Metrics.barShadow.bottomShadowOffset
      return view
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

      configure(bar: bar)

      // TODO: Figure out how to do this dynamically. Ideally we would get these from the margins
      // of the content view controller, but they're not what we want.
      barWrapper.safeMargins = Metrics.barDefaultMargins
    }

    private func configure(bar: Bar) {
      bar.snp.setLabel("bar")
      barWrapper.contentView.addSubview(bar)
      bar.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
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

extension ActionArea.BarViewController {
  override func setCustomTint(_ customTint: CustomTint) {
    super.setCustomTint(customTint)
    bar.setCustomTint(customTint)
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
    v("barViewController.buttonBar", bar, &message)
    vc("barViewController.content", content, &message)

    return message
  }

}
#endif
