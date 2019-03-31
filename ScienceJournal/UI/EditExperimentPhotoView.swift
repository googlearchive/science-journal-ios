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

import MaterialComponents

protocol EditExperimentPhotoViewDelegate: class {
  func choosePhotoButtonPressed()
}

/// A view allowing a user to choose a photo for an experiment.
class EditExperimentPhotoView: UIView {

  // MARK: - Properties

  private let buttonStack = UIStackView()
  private let changeButton = MDCFlatButton()
  private let chooseButton = MDCFlatButton()
  weak var delegate: EditExperimentPhotoViewDelegate?
  private let imageView = UIImageView()
  private let placeholderImageView = UIImageView(image: UIImage(named: "ic_landscape_large"))
  private let placeholderStack = UIStackView()

  var photo: UIImage? {
    didSet {
      if photo == nil && photo != oldValue {
        imageView.image = nil
        addSubview(placeholderStack)
        placeholderStack.pinToEdgesOfView(self)
        buttonStack.removeFromSuperview()
        return
      }
      // Clean up the view.
      placeholderStack.removeFromSuperview()
      // Set the image.
      imageView.image = photo
      // Add the buttons.
      addSubview(buttonStack)
      buttonStack.pinToEdgesOfView(self)
    }
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: 140.0)
  }

  // MARK: - Private

  private func configureView() {
    layer.cornerRadius = 6.0
    clipsToBounds = true
    backgroundColor = UIColor(red: 0.808, green: 0.808, blue: 0.808, alpha: 1.0)

    // The image view, which shows the photo for the experiment if/when it exists.
    addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.isUserInteractionEnabled = false
    imageView.isOpaque = false
    imageView.pinToEdgesOfView(self)
    if #available(iOS 11.0, *) {
      imageView.accessibilityIgnoresInvertColors = true
    }

    // The placeholder image view which shows an icon.
    placeholderImageView.contentMode = .center
    placeholderImageView.tintColor = UIColor(red: 0.420, green: 0.416, blue: 0.424, alpha: 1.0)
    placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
    placeholderImageView.setContentHuggingPriority(.defaultLow, for: .vertical)

    // The choose photo button.
    chooseButton.setTitleColor(.appBarReviewBackgroundColor, for: .normal)
    chooseButton.setBackgroundColor(.clear, for: .normal)
    chooseButton.setTitle(String.choosePhotoButtonText.uppercased(), for: .normal)

    // Change button.
    changeButton.setBackgroundColor(.white, for: .normal)
    changeButton.setTitleColor(.black, for: .normal)
    changeButton.setTitle(String.editExperimentChangePhoto.uppercased(), for: .normal)

    [chooseButton, changeButton].forEach { (button) in
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setContentHuggingPriority(.defaultHigh, for: .vertical)
      button.addTarget(self, action: #selector(choosePhotoButtonPressed), for: .touchUpInside)
    }

    // The outer stack view.
    placeholderStack.addArrangedSubview(placeholderImageView)
    placeholderStack.addArrangedSubview(chooseButton)
    placeholderStack.axis = .vertical
    placeholderStack.alignment = .center
    placeholderStack.translatesAutoresizingMaskIntoConstraints = false
    placeholderStack.layoutMargins = UIEdgeInsets(top: 30, left: 0, bottom: 20, right: 0)
    placeholderStack.isLayoutMarginsRelativeArrangement = true
    addSubview(placeholderStack)
    placeholderStack.pinToEdgesOfView(self)

    // Configure the button stack but don't add it to the view yet.
    let innerButtonStack = UIStackView(arrangedSubviews: [changeButton])
    innerButtonStack.axis = .vertical
    innerButtonStack.alignment = .center
    innerButtonStack.spacing = 10.0
    innerButtonStack.translatesAutoresizingMaskIntoConstraints = false
    innerButtonStack.setContentHuggingPriority(.defaultHigh, for: .vertical)

    buttonStack.addArrangedSubview(innerButtonStack)
    buttonStack.alignment = .center
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - User actions

  @objc private func choosePhotoButtonPressed() {
    delegate?.choosePhotoButtonPressed()
  }

}
