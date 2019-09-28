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

import UIKit

import third_party_objective_c_material_components_ios_components_AppBar_AppBar

/// Custom tint colors.
class CustomTint: NSObject {
  let primary: UIColor
  let secondary: UIColor

  init(primary: UIColor, secondary: UIColor) {
    self.primary = primary
    self.secondary = secondary
  }
}

/// Types that provide custom tint colors.
@objc protocol CustomTintProvider {
  var customTint: CustomTint? { get }
}

/// Types that can be tinted with custom tint colors.
@objc protocol CustomTintable {
  func setCustomTint(_ customTint: CustomTint)
}

/// The default custom tinting implementation for `UIViewController`s.
///
/// These implementations propogate custom tints. View controllers that use custom tinting should
/// override these methods as needed to tint their views.
extension UIViewController: CustomTintProvider, CustomTintable {

  /// The custom tint of the first child view controller. Call `super` if overriding this property.
  var customTint: CustomTint? {
    return children.first(where: { $0.customTint != nil })?.customTint
  }

  /// Propogate the tint to all child view controllers. Call `super` if overriding this property.
  func setCustomTint(_ customTint: CustomTint) {
    children.forEach { $0.setCustomTint(customTint) }
  }
}

/// The default custom tinting implementation for `UINavigationController`s.
///
/// These implementations propogate custom tints to and from the `topViewController`.
extension UINavigationController {
  override var customTint: CustomTint? { return topViewController?.customTint }

  override func setCustomTint(_ customTint: CustomTint) {
    topViewController?.setCustomTint(customTint)
  }
}

extension MaterialHeaderViewController {
  override var customTint: CustomTint? {
    let primary =
      appBar.headerViewController.headerView.backgroundColor ?? .appBarDefaultBackgroundColor
    let secondary = primary.adjusted(by: .standardAdjustment)
    return CustomTint(primary: primary, secondary: secondary)
  }
}

extension MaterialHeaderCollectionViewController {
  override var customTint: CustomTint? {
    let primary =
      appBar.headerViewController.headerView.backgroundColor ?? .appBarDefaultBackgroundColor
    let secondary = primary.adjusted(by: .standardAdjustment)
    return CustomTint(primary: primary, secondary: secondary)
  }
}

/// A `KeyTint` can be used to store, update and apply a `customTint`.
final class KeyTint {

  typealias Provider = () -> CustomTint?

  /// The `customTint`.
  var customTint: CustomTint?

  private let provide: Provider
  private let tintables: [CustomTintable]

  init(provider provide: @escaping Provider = { return nil }, tintables: [CustomTintable] = []) {
    self.provide = provide
    self.tintables = tintables
  }

  /// Update the `customTint` with the provider that was supplied at creation time.
  func update() {
    customTint = provide()
  }

  /// Apply the `customTint` to the specified `tintables`.
  ///
  /// If no `tintables` are specified, the collection provided at creation time is used instead.
  ///
  /// - Parameters:
  ///   - tintables: The tintables to tint.
  func apply(to tintables: [CustomTintable]? = nil) {
    guard let customTint = customTint else { return }
    let tintablesToTint = tintables ?? self.tintables
    tintablesToTint.forEach { $0.setCustomTint(customTint) }
  }

  /// Update and apply the `customTint`.
  func updateAndApply() {
    update()
    apply()
  }
}
