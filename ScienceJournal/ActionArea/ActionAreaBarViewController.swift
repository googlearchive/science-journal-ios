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

// MARK: - ActionArea.BarViewController

extension ActionArea {

  /// The bar where items are displayed.
  final class BarViewController: UIViewController {

    enum Metrics {
      enum ActionButton {
        static let size: CGFloat = 48
        static let toLabelSpacing: CGFloat = 4
      }

      enum Bar {
        static let backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        static let buttonTitleColor: UIColor = .gray
        static let cornerRadius: CGFloat = 15
        static let defaultMargins = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
        static let disabledAlpha: CGFloat = 0.2
        static let padding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let shadow = MDCShadowMetrics(elevation: ShadowElevation.fabResting.rawValue)
        static let toFABSpacing: CGFloat = 8
      }
    }

    private func transition(
      before: () -> Void = {},
      during: @escaping () -> Void = {},
      after: @escaping () -> Void = {}
    ) {
      if let transitionCoordinator = transitionCoordinator, transitionCoordinator.isAnimated {
        before()
        transitionCoordinator.animateAlongsideTransition(in: view, animation: { _ in
          during()
        }) { _ in
          after()
        }
      } else {
        before()
        during()
        after()
      }
    }

    private var primaryConstraints: MutuallyExclusiveConstraints<UIUserInterfaceSizeClass>?

    /// The `ActionItem` to display in the Action Area Bar.
    var actionItem: ActionItem = .empty {
      didSet {
        // We can get an equivalent item when the AA is in the `modal` state in portrait orientation
        // and the modal content VC is hidden or re-shown, which will result in undesired animation.
        guard oldValue != actionItem else { return }

        primary = actionItem.primary.map(create(primary:))

        // TODO:
        //   Revisit this animation. The current approach performs much better than replacing the
        //   bar, but it won't handle transitions where the action descriptions have different
        //   numbers of lines.
        let snapshot = bar.snapshotView(afterScreenUpdates: false)
        transition(before: {
          if let snapshot = snapshot {
            bar.superview?.addSubview(snapshot)
            snapshot.frame = bar.frame
          }
          bar.alpha = 0
          bar.items = actionItem.items
        }, during: {
          snapshot?.alpha = 0
          self.bar.alpha = 1
        }, after: {
          snapshot?.removeFromSuperview()
        })
      }
    }

    private var primary: UIButton? {
      didSet {
        if let primary = primary {
          primary.layoutIfNeeded()
          view.addSubview(primary)
          primaryConstraints = MutuallyExclusiveConstraints { constraints in
            primary.snp.makeConstraints { make in
              make.bottom.equalTo(bar.snp.top).offset(-1 * Metrics.Bar.toFABSpacing)
            }
            constraints[.compact] = primary.snp.prepareConstraints { $0.centerX.equalToSuperview() }
            constraints[.regular] = primary.snp.prepareConstraints { $0.right.equalTo(bar) }
          }
          primaryConstraints?.activate(traitCollection.horizontalSizeClass)
        } else {
          primaryConstraints = nil
        }

        switch (oldValue, primary) {
        case (.none, .none):
          break
        case let (.some(from), .none):
          transition(during: {
            from.alpha = 0
          }, after: {
            from.removeFromSuperview()
          })
        case let (.none, .some(to)):
          transition(before: {
            to.alpha = 0
          }, during: {
            to.alpha = 1
          })
        case let (.some(from), .some(to)):
          transition(before: {
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
    }

    private func create(primary: BarButtonItem) -> UIButton {
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
      bar.alpha = 0
      updateAdditionalSafeAreaInsets()
    }

    /// Show the bar.
    func show() {
      primary?.alpha = 1
      bar.alpha = 1
      updateAdditionalSafeAreaInsets()
    }

    /// Enable or disable the bar.
    var isEnabled: Bool = true {
      didSet {
        if isEnabled {
          bar.alpha = 1
        } else {
          bar.alpha = Metrics.Bar.disabledAlpha
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
          toValue = Metrics.Bar.shadow.bottomShadowOpacity
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

    private var bar: Bar = {
      let view = Bar()
      view.clipsToBounds = false
      view.layer.shadowRadius = Metrics.Bar.shadow.bottomShadowRadius
      view.layer.shadowOffset = Metrics.Bar.shadow.bottomShadowOffset
      return view
    }()

    private let content: UIViewController

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

      // TODO: Figure out how to do this dynamically. Ideally we would get these from the margins
      // of the content view controller, but they're not what we want.
      view.layoutMargins = Metrics.Bar.defaultMargins
      // Ignore system mimimums because we want to use our custom margins.
      viewRespectsSystemMinimumLayoutMargins = false
      // Inset the layout margins from the edge, so we can keep the bar as close to the edge as
      // possible.
      view.insetsLayoutMarginsFromSafeArea = false
      view.snp.setLabel("root")

      content.view.snp.setLabel("content")
      addChild(content)
      view.addSubview(content.view)
      content.didMove(toParent: self)
      content.view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      bar.snp.setLabel("bar")
      view.addSubview(bar)
      bar.snp.makeConstraints { make in
        make.leading.greaterThanOrEqualTo(view.snp.leadingMargin)
        make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).priority(.high)
        make.trailing.lessThanOrEqualTo(view.snp.trailingMargin)
        make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).priority(.high)
        make.bottom.lessThanOrEqualTo(view.snp.bottomMargin)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).priority(.high)
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
        bar.transform = CGAffineTransform(translationX: 0, y: bar.bounds.height)
      case .raised:
        bar.transform = .identity
      }
      updateAdditionalSafeAreaInsets()
    }

    private func updateAdditionalSafeAreaInsets() {
      if position == .raised, bar.alpha > 0 {
        content.additionalSafeAreaInsets =
          UIEdgeInsets(top: 0, left: 0, bottom: bar.bounds.height, right: 0)
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

// MARK: - ActionArea.BarViewController+CustomTintable

extension ActionArea.BarViewController {
  override func setCustomTint(_ customTint: CustomTint) {
    super.setCustomTint(customTint)
    bar.setCustomTint(customTint)
  }
}

// MARK: - ActionArea.Bar

extension ActionArea {

  private final class Bar: UIView, CustomTintable {

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

    private var buttons: [BarButton] = [] {
      didSet {
        keyTint.apply(to: buttons)
      }
    }

    var items: [BarButtonItem] = [] {
      didSet {
        stackView.removeAllArrangedViews()
        buttons = items.map { BarButton(item: $0) }
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
      backgroundColor = BarViewController.Metrics.Bar.backgroundColor
      layer.cornerRadius = BarViewController.Metrics.Bar.cornerRadius
      layer.masksToBounds = true
      layoutMargins = BarViewController.Metrics.Bar.padding
      stackView.snp.makeConstraints { make in
        make.edges.equalTo(snp.margins)
      }
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

  }

}

// MARK: - ActionArea.BarButton

extension ActionArea {

  private final class BarButton: UIView, CustomTintable {

    override class var requiresConstraintBasedLayout: Bool {
      return true
    }

    private let button: UIButton = {
      let view = UIButton(type: .custom)
      view.layer.cornerRadius = BarViewController.Metrics.ActionButton.size / 2
      view.clipsToBounds = true
      return view
    }()

    private let label: UILabel = {
      let view = UILabel()
      view.numberOfLines = 2
      view.textColor = BarViewController.Metrics.Bar.buttonTitleColor
      return view
    }()

    private let item: BarButtonItem
    private var _intrinsicContentSize: CGSize = .zero

    init(item: BarButtonItem) {
      self.item = item
      super.init(frame: .zero)

      translatesAutoresizingMaskIntoConstraints = false
      snp.setLabel("action")
      accessibilityHint = item.accessibilityHint

      button.setImage(item.image?.withRenderingMode(.alwaysTemplate), for: .normal)
      button.addTarget(item, action: #selector(BarButtonItem.execute), for: .touchUpInside)
      addSubview(button)
      button.snp.setLabel("action.button")
      button.snp.makeConstraints { make in
        make.size.equalTo(BarViewController.Metrics.ActionButton.size)
        make.top.equalToSuperview()
        make.centerX.equalToSuperview()
        make.leading.greaterThanOrEqualToSuperview()
        make.trailing.lessThanOrEqualToSuperview()
      }

      label.text = item.title
      addSubview(label)
      label.snp.setLabel("action.label")
      label.snp.makeConstraints { make in
        make.top.equalTo(button.snp.bottom)
          .offset(BarViewController.Metrics.ActionButton.toLabelSpacing)
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
    v("barViewController.bar", bar, &message)
    vc("barViewController.content", content, &message)

    return message
  }

}
#endif
