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

import AVFoundation
import UIKit

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_TextFields_TextFields

class AddTrialNoteViewController: ScienceJournalViewController, UITextFieldDelegate {

  enum Metrics {
    static let viewInsets = UIEdgeInsets(top: 14.0, left: 0, bottom: 14.0, right: 0)
    static let verticalViewInsets = viewInsets.top + viewInsets.bottom
    static let horizontalPadding: CGFloat = 28
    static let horizontalButtonPadding: CGFloat = 10
    static let innerSpacing: CGFloat = 10
    static let verticalSpacing: CGFloat = 10
    static let textFieldHeight: CGFloat = 36
    static let imageHeight: CGFloat = 100
  }

  // MARK: - Properties

  /// The note text field.
  let textField = MDCTextField()
  /// The save button.
  let saveButton = MDCFlatButton()
  /// The cancel button.
  let cancelButton = MDCFlatButton()
  /// The add photo button.
  let photoButton = MDCFlatButton()
  /// The select timestamp button.
  let timestampButton = MDCFlatButton()
  /// The note image view.
  let imageView = UIImageView()

  private let scrollView = UIScrollView()
  private var stackView: UIStackView?

  /// The height required to display the view's contents.
  private var totalHeight: CGFloat {
    let timestampHeight =
        timestampButton.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let saveButtonHeight =
        saveButton.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

    var height = Metrics.textFieldHeight + timestampHeight + saveButtonHeight +
        Metrics.verticalViewInsets + Metrics.verticalSpacing * 4 +
        SeparatorView.Metrics.dimension * 2
    if imageView.image != nil {
      height += Metrics.imageHeight + Metrics.verticalSpacing
    }
    return height
  }

  private var isCameraButtonEnabled = true {
    didSet {
      guard oldValue != isCameraButtonEnabled else { return }
      photoButton.setImage(
          UIImage(named: isCameraButtonEnabled ? "ic_camera_alt" : "ic_camera_alt_disabled"),
          for: .normal)
      photoButton.isEnabled = isCameraButtonEnabled
    }
  }

  // MARK: - Public

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    textField.placeholder = String.addNoteHintText
    textField.translatesAutoresizingMaskIntoConstraints = false
    // MDCTextField does not provide a correct instrinsic size.
    textField.heightAnchor.constraint(equalToConstant: Metrics.textFieldHeight).isActive = true
    textField.underline?.color = .appBarReviewBackgroundColor

    photoButton.disabledAlpha = 1
    photoButton.setImage(UIImage(named: "ic_camera_alt"), for: .normal)
    photoButton.imageView?.contentMode = .center
    photoButton.translatesAutoresizingMaskIntoConstraints = false
    photoButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    photoButton.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    photoButton.accessibilityLabel = String.addPhotoContentDescription

    timestampButton.setImage(UIImage(named: "ic_access_time"), for: .normal)
    timestampButton.setTitleColor(.gray, for: .normal)
    timestampButton.setContentCompressionResistancePriority(.required,
                                                            for: .vertical)
    timestampButton.translatesAutoresizingMaskIntoConstraints = false
    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
      timestampButton.contentHorizontalAlignment = .right
      timestampButton.contentEdgeInsets.right = Metrics.horizontalPadding
      timestampButton.titleEdgeInsets.right = Metrics.innerSpacing
    } else {
      timestampButton.contentHorizontalAlignment = .left
      timestampButton.contentEdgeInsets.left = Metrics.horizontalPadding
      timestampButton.titleEdgeInsets.left = Metrics.innerSpacing
    }
    timestampButton.accessibilityLabel = String.editNoteTimeMenuItem

    cancelButton.setTitle(String.actionCancel, for: .normal)
    saveButton.setTitle(String.actionSave, for: .normal)
    let buttonWrapper = UIView()
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false

    [cancelButton, saveButton].forEach { (button) in
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setTitleColor(.appBarReviewBackgroundColor, for: .normal)
      button.setBackgroundColor(.clear, for: .normal)
      button.setContentCompressionResistancePriority(.required, for: .vertical)
      buttonWrapper.addSubview(button)
    }

    saveButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor,
                                         constant: -Metrics.horizontalButtonPadding).isActive = true
    saveButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor).isActive = true
    saveButton.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor).isActive = true
    cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor,
                                           constant: Metrics.innerSpacing).isActive = true
    cancelButton.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor).isActive = true

    // Horizontal stack for the text field and photo button.
    let textPhotoStack = UIStackView(arrangedSubviews: [textField, photoButton])
    textPhotoStack.translatesAutoresizingMaskIntoConstraints = false
    textPhotoStack.alignment = .top
    textPhotoStack.layoutMargins = UIEdgeInsets(top: 0,
                                                left: Metrics.horizontalPadding,
                                                bottom: 0,
                                                right: Metrics.horizontalButtonPadding)
    textPhotoStack.isLayoutMarginsRelativeArrangement = true

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.heightAnchor.constraint(equalToConstant: Metrics.imageHeight).isActive = true
    imageView.contentMode = .scaleAspectFit

    // Scroll view in case contents are larger than visible area.
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    view.addSubview(scrollView)

    // Separators
    let separator1 = SeparatorView(direction: .horizontal, style: .light)
    let separator2 = SeparatorView(direction: .horizontal, style: .light)
    [separator1, separator2].forEach { (view) in
      view.translatesAutoresizingMaskIntoConstraints = false
      view.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // Vertical stack to contain all of the other views.
    let outerStack = UIStackView(arrangedSubviews: [textPhotoStack,
                                                    separator1,
                                                    timestampButton,
                                                    separator2,
                                                    buttonWrapper])
    stackView = outerStack
    if imageView.image != nil {
      outerStack.insertArrangedSubview(imageView, at: 0)
    }
    outerStack.axis = .vertical
    outerStack.translatesAutoresizingMaskIntoConstraints = false
    outerStack.spacing = Metrics.verticalSpacing
    scrollView.addSubview(outerStack)

    outerStack.pinToEdgesOfView(scrollView)
    outerStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    outerStack.layoutMargins = Metrics.viewInsets
    outerStack.isLayoutMarginsRelativeArrangement = true

    scrollView.pinToEdgesOfView(view)

    setPreferredContentSize()

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionWasInterrupted(_:)),
                                           name: .AVCaptureSessionWasInterrupted,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionInterruptionEnded(_:)),
                                           name: .AVCaptureSessionInterruptionEnded,
                                           object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isCameraButtonEnabled = CaptureSessionInterruptionObserver.shared.isCameraUseAllowed
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // If there is no image data, make text field first responder.
    if imageView.image == nil {
      textField.becomeFirstResponder()
    }
  }

  /// Shows the image view.
  ///
  /// - Parameter image: An image.
  func showImage(_ image: UIImage) {
    imageView.image = image
    stackView?.insertArrangedSubview(imageView, at: 0)
    setPreferredContentSize()
  }

  /// Hides the image view.
  func hideImage() {
    imageView.image = nil
    stackView?.removeArrangedSubview(imageView)
    setPreferredContentSize()
  }

  // MARK: - Private

  private func setPreferredContentSize() {
    // When presented as a Material dialog, the preferred content size dictates its displayed size.
    preferredContentSize = CGSize(width: 200, height: totalHeight)
  }

  // MARK: - Notifications

  @objc private func captureSessionWasInterrupted(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionWasInterrupted(notification)
      }
      return
    }

    guard AVCaptureSession.InterruptionReason(notificationUserInfo: notification.userInfo) ==
        .videoDeviceNotAvailableWithMultipleForegroundApps else { return }
    isCameraButtonEnabled = false
  }

  @objc private func captureSessionInterruptionEnded(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionInterruptionEnded(notification)
      }
      return
    }

    isCameraButtonEnabled = !CaptureSessionInterruptionObserver.shared.isBrightnessSensorInUse
  }

}
