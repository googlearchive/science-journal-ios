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

/// A view whose layer is a shape layer.
class ShapeView: UIView {

  override class var layerClass: AnyClass {
    return CAShapeLayer.self
  }

  var shapeLayer: CAShapeLayer {
    return layer as! CAShapeLayer
  }

  /// The fill color of the shape layer.
  var color: UIColor? {
    get {
      guard let shapefillColor = shapeLayer.fillColor else {
        return nil
      }
      return UIColor(cgColor: shapefillColor)
    }
    set(newColor) {
      shapeLayer.fillColor = newColor?.cgColor
    }
  }

  /// The stroke color of the shape layer.
  var strokeColor: UIColor? {
    get {
      guard let shapeStrokeColor = shapeLayer.strokeColor else {
        return nil
      }
      return UIColor(cgColor: shapeStrokeColor)
    }
    set(newColor) {
      shapeLayer.strokeColor = newColor?.cgColor
    }
  }

  init(color: UIColor, frame: CGRect = .zero, coder aDecoder: NSCoder? = nil) {
    if let aDecoder = aDecoder {
      super.init(coder: aDecoder)!
    } else {
      super.init(frame: frame)
    }
    shapeLayer.fillColor = color.cgColor
  }

  override convenience init(frame: CGRect) {
    self.init(color: .black)
  }

  required convenience init?(coder aDecoder: NSCoder) {
    self.init(color: .black, frame: .zero, coder: aDecoder)
  }

}
