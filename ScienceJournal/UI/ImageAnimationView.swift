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

/// Animation view for sensors that use a sequence of images or a fixed set of images that represent
/// a range of values.
class ImageAnimationView: SensorAnimationView {

  // MARK: - Properties

  /// The sequence of images that represent the range of values.
  var images = [UIImage]()

  /// The default image to use when no values have been set.
  private var defaultImage: UIImage? {
    guard images.count > 0 else { return nil }
    // Use an approximate middle image so the view isn't blank.
    let middleIndex = images.count / 2
    return images[middleIndex]
  }

  /// The prefix for the image files that represent the animation's range.
  private var imagePrefix: String? {
    didSet {
      setupImages()
    }
  }

  private let imageView = UIImageView()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter iconName: The animating icon name.
  init(iconName: String) {
    imagePrefix = iconName
    super.init(frame: .zero)
    setupImages()
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not been supported")
  }

  override func setValue(_ value: Double, minValue: Double, maxValue: Double) {
    imageView.image = image(forValue: value, minValue: minValue, maxValue: maxValue)
  }

  override func reset() {
    imageView.image = nil
  }

  /// Returns the image for value, which is translated into an appropriate image index. Minimum and
  /// maximum can be used to determine scale.
  ///
  /// - Parameters:
  ///   - value: A sensor value.
  ///   - minValue: A minimum used to scale the value.
  ///   - maxValue: A maximum used to scale the value.
  func image(forValue value: Double, minValue: Double, maxValue: Double) -> UIImage? {
    // Make sure there is at least one image.
    guard images.count > 0 else {
      return nil
    }

    return images[imageIndex(forValue: value, minValue: minValue, maxValue: maxValue)]
  }

  /// Returns the image index for value, which is translated into an appropriate image index.
  /// Minimum and maximum can be used to determine scale.
  ///
  /// - Parameters:
  ///   - value: A sensor value.
  ///   - minValue: A minimum used to scale the value.
  ///   - maxValue: A maximum used to scale the value.
  func imageIndex(forValue value: Double, minValue: Double, maxValue: Double) -> Int {
    fatalError("Subclasses must implement.")
  }

  // MARK: - Private

  private func configureView() {
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.frame = bounds
    addSubview(imageView)
  }

  private func setupImages() {
    guard let imagePrefix = imagePrefix else { return }

    images.removeAll()

    var imageIndex = 0
    var stop = false
    while !stop {
      let imageName = imagePrefix + "_\(imageIndex)"
      if let image = UIImage(named: imageName) {
        images.append(image)
        imageIndex += 1
      } else {
        stop = true
      }
    }
    imageView.image = defaultImage
  }

}
