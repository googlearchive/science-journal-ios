/*
 *  Copyright 2019 Google Inc. All Rights Reserved.
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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// A one point separator view that can be horizontal or vertical. The style determines its
/// background color.
class SeparatorView: UIView {

  // MARK: - Properties

  /// Metrics for the separator view.
  enum Metrics {
    /// The dimension of the separator view (height for horizontal direction and width for vertical
    /// direction).
    static let dimension: CGFloat = 1
  }

  private let direction: Direction
  private let style: Style

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - direction: The direction.
  ///   - style: The style.
  init(direction: Direction, style: Style) {
    self.direction = direction
    self.style = style
    super.init(frame: .zero)
    configureView()
  }

  override init(frame: CGRect) {
    fatalError("init(frame:) is not supported")
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var intrinsicContentSize: CGSize {
    switch direction {
    case .horizontal: return CGSize(width: UIView.noIntrinsicMetric, height: Metrics.dimension)
    case .vertical: return CGSize(width: Metrics.dimension, height: UIView.noIntrinsicMetric)
    }
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    switch direction {
    case .horizontal: return CGSize(width: size.width, height: Metrics.dimension)
    case .vertical: return CGSize(width: Metrics.dimension, height: size.height)
    }
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = style.backgroundColor

    let axis: NSLayoutConstraint.Axis
    switch direction {
    case .horizontal:
      axis = .vertical
      frame.size.height = Metrics.dimension
    case .vertical:
      axis = .horizontal
      frame.size.width = Metrics.dimension
    }
    setContentHuggingPriority(.required, for: axis)
  }

  // MARK: - Nested Types

  /// An enum to describe a separator's direction.
  enum Direction {
    /// A separator that is horizontal.
    case horizontal
    /// A separator that is vertical.
    case vertical
  }

  /// An enum to describe a separator's style to determine its color.
  enum Style {
    /// A separator that is a dark color.
    case dark
    /// A separator that is a light color.
    case light

    fileprivate var backgroundColor: UIColor {
      switch self {
      case .dark: return MDCPalette.grey.tint300
      case .light: return MDCPalette.grey.tint200
      }
    }
  }

}
