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

/// A cell class containing the wrapping views needed to create a material card cell. However, it
/// does not lay them out and should not be directly subclassed. Instead, subclass
/// AutoLayoutMaterialCardCell or FrameLayoutMaterialCardCell based on which layout the cell will
/// use.
class MaterialCardCell: UICollectionViewCell {

  /// The interitem spacing for cards.
  static let cardInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)

  /// The view in which to place all of your subviews.
  let cellContentView = UIView()

  /// The shadow surrounding the cell.
  let shadow = UIImageView()

  /// The borders to include in the cell.
  var border = Border(options: .all) {
    didSet {
      updateShadowImage()
      setNeedsLayout()
      setNeedsUpdateConstraints()
    }
  }

  private let contentCornerRadii = CGSize(width: 2, height: 2)
  private let cellContentViewMask = CAShapeLayer()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureWrappingViews()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureWrappingViews()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let cellContentViewMaskRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    cellContentViewMask.path = UIBezierPath(roundedRect: cellContentViewMaskRect,
                                            byRoundingCorners: border.roundedCorners,
                                            cornerRadii: contentCornerRadii).cgPath
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    border = Border(options: .all)
  }

  /// Configures the wrapping views.
  func configureWrappingViews() {
    // Shadow.
    contentView.addSubview(shadow)
    updateShadowImage()

    // Add the inner wrapper, which is what all subclasses use to lay out their subviews.
    cellContentView.backgroundColor = .white
    cellContentView.layer.masksToBounds = true
    cellContentView.layer.mask = cellContentViewMask
    contentView.addSubview(cellContentView)
  }

  // MARK: - Private

  private func updateShadowImage() {
    shadow.image = border.shadowImage
  }

  // MARK: - Nested types

  /// The borders to show on the cell.
  struct Border {

    /// The border option set for the cell.
    struct Options: OptionSet {

      let rawValue: Int

      /// Shows a top border.
      static let top = Options(rawValue: 1 << 0)

      /// Shows a bottom border.
      static let bottom = Options(rawValue: 1 << 1)

      /// Shows no borders.
      static let none: Options = []

      /// Shows top and bottom borders
      static let all: Options = [.top, .bottom]

    }

    /// The cell's border options.
    let options: Options

    /// Whether or not to show a top border.
    var shouldShowTopBorder: Bool {
      return options.contains(.top)
    }

    /// Whether or not to show a bottom border.
    var shouldShowBottomBorder: Bool {
      return options.contains(.bottom)
    }

    /// The corners to round.
    var roundedCorners: UIRectCorner {
      var roundedCorners = UIRectCorner()
      if shouldShowTopBorder {
        roundedCorners.update(with: .topLeft)
        roundedCorners.update(with: .topRight)
      }
      if shouldShowBottomBorder {
        roundedCorners.update(with: .bottomLeft)
        roundedCorners.update(with: .bottomRight)
      }
      return roundedCorners
    }

    /// The image to use for the shadow.
    var shadowImage: UIImage? {
      let imageName: String
      if shouldShowTopBorder && shouldShowBottomBorder {
        imageName = "shadow_layer_white"
      } else if shouldShowTopBorder {
        imageName = "shadow_layer_top_white"
      } else if shouldShowBottomBorder {
        imageName = "shadow_layer_bottom_white"
      } else {
        imageName = "shadow_layer_middle_white"
      }
      return UIImage(named: imageName)
    }

    /// The insets for the cell shadow.
    var shadowInsets: UIEdgeInsets {
      var shadowInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
      if shouldShowTopBorder {
        shadowInsets.top = -2
      }
      if shouldShowBottomBorder {
        shadowInsets.bottom = -6
      }
      return shadowInsets
    }

  }

}

/// A base collection view cell with a card style that has proper shadow, corner radius and content
/// insets. Mimicks the MDCCollectionViewCell .card style cell, but has accurate content view area
/// when using `cellContentView` in subclasses. All subviews placed inside `cellContentView` can
/// be pinned to edges using Auto Layout, and will be properly masked and clipped to the inner
/// bounding box.
///
/// All subclasses using autolayout should use this cell with the standard init and layout
/// methodology (see TrialCard for example), but lay their subviews out inside `cellContentView`
/// instead of `contentView`.
class AutoLayoutMaterialCardCell: MaterialCardCell {

  private var shadowTopConstraint: NSLayoutConstraint?
  private var shadowBottomConstraint: NSLayoutConstraint?

  override func configureWrappingViews() {
    super.configureWrappingViews()

    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    contentView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

    // Shadow.
    shadow.translatesAutoresizingMaskIntoConstraints = false
    shadowTopConstraint = shadow.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                      constant: border.shadowInsets.top)
    shadowTopConstraint?.isActive = true
    shadow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                    constant: border.shadowInsets.left).isActive = true
    shadow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                     constant: -border.shadowInsets.right).isActive = true
    shadowBottomConstraint = shadow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                            constant: -border.shadowInsets.bottom)
    shadowBottomConstraint?.isActive = true

    // Cell content view.
    cellContentView.translatesAutoresizingMaskIntoConstraints = false
    cellContentView.pinToEdgesOfView(contentView)
  }

  override func updateConstraints() {
    super.updateConstraints()

    shadowTopConstraint?.constant = border.shadowInsets.top
    shadowBottomConstraint?.constant = -border.shadowInsets.bottom
  }

}

/// A base collection view cell with a card style that has proper shadow, corner radius and content
/// insets. Mimicks the MDCCollectionViewCell .card style cell, but has accurate content view area
/// when using `cellContentView` in subclasses. All subviews placed inside `cellContentView` can
/// be layed out up to the edges, and will be properly masked and clipped to the inner bounding
/// box.
///
/// All subclasses using frame based layout should use this cell with the standard init and layout
/// methodology (see TrialCard for example), but lay their subviews out inside `cellContentView`
/// instead of `contentView`.
class FrameLayoutMaterialCardCell: MaterialCardCell {

  override func layoutSubviews() {
    super.layoutSubviews()

    shadow.frame = CGRect(x: border.shadowInsets.left,
                          y: border.shadowInsets.top,
                          width: contentView.bounds.width - border.shadowInsets.left -
                                     border.shadowInsets.right,
                          height: contentView.bounds.height - border.shadowInsets.top -
                                      border.shadowInsets.bottom)

    cellContentView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: contentView.bounds.width,
                                   height: contentView.bounds.height)
  }

}

