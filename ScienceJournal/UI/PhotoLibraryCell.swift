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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

protocol PhotoLibraryCellDelegate: class {
  /// Called when a photo is selected.
  func photoLibraryCellDidSelectImage(_ photoLibraryCell: PhotoLibraryCell)
}

/// A cell containing a thumbnail for an image in a photo picker.
class PhotoLibraryCell: UICollectionViewCell {

  // MARK: - Properties

  override var isSelected: Bool {
    didSet {
      guard oldValue != isSelected else { return }
      // Show or hide the selection border highlight.
      if self.isSelected {
        self.layer.borderWidth = 4
      } else {
        self.layer.borderWidth = 0
      }
    }
  }

  // The image.
  var image: UIImage? {
    get {
      return imageButton.image(for: .normal)
    }
    set {
      imageButton.setImage(newValue, for: .normal)
    }
  }

  /// Photo library cell delegate.
  weak var delegate: PhotoLibraryCellDelegate?

  private let imageButton = UIButton(type: .custom)
  private var imageButtonWidthConstraint: NSLayoutConstraint?
  private var imageButtonHeightConstraint: NSLayoutConstraint?
  private let spinner = MaterialFloatingSpinner()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    image = nil
    stopSpinner()
  }

  /// Sets the height and width of the image to a size.
  ///
  /// - Parameter size: The size.
  func setImageDimensionConstraints(with size: CGSize) {
    imageButtonWidthConstraint?.isActive = false
    imageButtonHeightConstraint?.isActive = false

    imageButtonWidthConstraint = imageButton.widthAnchor.constraint(equalToConstant: size.width)
    imageButtonWidthConstraint?.isActive = true
    imageButtonHeightConstraint = imageButton.heightAnchor.constraint(equalToConstant: size.height)
    imageButtonHeightConstraint?.isActive = true
  }

  /// Shows and starts animating the spinner.
  ///
  /// - Parameter progress: The progress to start the spinner at.
  func startSpinner(withProgress progress: Double = 0) {
    setSpinnerProgress(progress)
    spinner.isHidden = false
    spinner.startAnimating()
  }

  /// Stops animating and hides the spinner.
  func stopSpinner() {
    spinner.stopAnimating()
    spinner.isHidden = true
  }

  /// Sets the spinner's progress.
  func setSpinnerProgress(_ progress: Double) {
    spinner.progress = Float(progress)
  }

  // MARK: - User actions

  @objc private func imageButtonPressed() {
    delegate?.photoLibraryCellDidSelectImage(self)
  }

  // MARK: - Private

  private func configureView() {
    isAccessibilityElement = true
    accessibilityTraits = .button
    accessibilityLabel = String.photoSelectContentDescription
    accessibilityHint = String.doubleTapToSelect

    layer.borderColor = MDCPalette.blue.tint600.cgColor

    imageButton.addTarget(self, action: #selector(imageButtonPressed), for: .touchUpInside)
    imageButton.adjustsImageWhenHighlighted = false
    imageButton.clipsToBounds = true
    imageButton.imageView?.contentMode = .scaleAspectFill
    addSubview(imageButton)
    imageButton.translatesAutoresizingMaskIntoConstraints = false
    imageButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    imageButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    if #available(iOS 11.0, *) {
      imageButton.accessibilityIgnoresInvertColors = true
    }

    // Spinner
    spinner.isHidden = true
    spinner.indicatorMode = .determinate
    addSubview(spinner)
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    spinner.isAccessibilityElement = false
  }

}
