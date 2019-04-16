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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view that displays a timestamp and a value in a rounded rect with a bottom arrow.
class DataPointFlagView: UIView {

  // MARK: Constants

  let innerPadding: CGFloat = 8

  // MARK: Nested types.

  // A view with a solid rounded rect background used as the body of the flag view.
  class BackgroundView: ShapeView {
    override func layoutSubviews() {
      super.layoutSubviews()
      let path = UIBezierPath(roundedRect: bounds, cornerRadius: 4)
      shapeLayer.path = path.cgPath
    }
  }

  // A view with a triangle used as the arrow of the flag view.
  class ArrowView: ShapeView {
    override var intrinsicContentSize: CGSize {
      return CGSize(width: 8, height: 5)
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 0, y: 0))
      path.addLine(to: CGPoint(x: bounds.size.width, y: 0))
      path.addLine(to: CGPoint(x: floor(bounds.size.width / 2), y: bounds.size.height))
      path.close()
      shapeLayer.path = path.cgPath
    }
  }

  class SeparatorView: UIView {
    override var intrinsicContentSize: CGSize {
      return CGSize(width: 1, height: 12)
    }
  }

  // MARK: DataPointFlagView

  let backgroundView = BackgroundView()
  let arrowView = ArrowView()
  let separatorView = SeparatorView()
  let timestampLabel = UILabel()
  let valueLabel = UILabel()

  var color: UIColor? {
    get {
      return backgroundView.color
    }
    set(newColor) {
      backgroundView.color = newColor
      arrowView.color = newColor
    }
  }

  var arrowCenterConstraint: NSLayoutConstraint!

  var arrowOffset: CGFloat = 0 {
    didSet {
      arrowCenterConstraint.constant = arrowOffset
    }
  }

  init(color: UIColor, frame: CGRect) {
    super.init(frame: frame)

    separatorView.backgroundColor = .white
    backgroundView.color = color
    arrowView.color = color

    addSubview(backgroundView)
    addSubview(arrowView)
    addSubview(separatorView)
    addSubview(timestampLabel)
    addSubview(valueLabel)

    let fontSize: CGFloat = 10.0
    timestampLabel.font = MDCTypography.fontLoader().regularFont(ofSize: fontSize)
    timestampLabel.textColor = .white
    valueLabel.font = MDCTypography.fontLoader().boldFont?(ofSize: fontSize)
    valueLabel.textColor = .white

    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    arrowView.translatesAutoresizingMaskIntoConstraints = false
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    timestampLabel.translatesAutoresizingMaskIntoConstraints = false
    valueLabel.translatesAutoresizingMaskIntoConstraints = false

    backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    backgroundView.bottomAnchor.constraint(equalTo: arrowView.topAnchor).isActive = true

    arrowView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    arrowCenterConstraint = arrowView.centerXAnchor.constraint(equalTo: centerXAnchor)
    arrowCenterConstraint.isActive = true

    timestampLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor,
                                        constant: innerPadding).isActive = true
    timestampLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor,
                                           constant: -innerPadding).isActive = true
    timestampLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor,
                                            constant: innerPadding).isActive = true
    timestampLabel.trailingAnchor.constraint(equalTo: separatorView.leadingAnchor,
                                             constant: -innerPadding).isActive = true

    separatorView.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor,
                                            constant: -innerPadding).isActive = true
    separatorView.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor).isActive = true

    valueLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor,
                                         constant: -innerPadding).isActive = true
    valueLabel.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor).isActive = true
  }

  override convenience init(frame: CGRect) {
    self.init(color: .black, frame: .zero)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
