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

import AVFoundation
import UIKit

import third_party_objective_c_material_components_ios_components_Buttons_Buttons

/// View subclass for the camera including a preview layer.
class CameraView: UIView {

  /// The photo preview view.
  let previewView = UIView()

  /// The photo preview layer.
  var previewLayer: CALayer? {
    didSet {
      guard let previewLayer = previewLayer else { return }
      previewView.layer.addSublayer(previewLayer)
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = previewView.bounds
  }

  init() {
    super.init(frame: .zero)
    addSubview(previewView)
    previewView.translatesAutoresizingMaskIntoConstraints = false
    // `previewView`'s height constraint will be set by `AddPhotoViewController`, so it can be
    // equal to `drawerView`'s height.
    previewView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    previewView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    previewView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

}

/// Stub subclass of the camera view controller for analytics purposes.
class StandaloneCameraViewController: CameraViewController {}

/// Manages the view that lets a user add photos.
open class CameraViewController: ScienceJournalViewController, DrawerItemViewController,
                                 PhotoCapturerDelegate {

  /// The photo capturer. (Uses a lazy property to avoid the camera permissions alert from showing
  /// on app launch)
  lazy var photoCapturer = PhotoCapturer()

  /// The delegate.
  weak var delegate: ImageSelectorDelegate?

  /// The photo preview view.
  let cameraView = CameraView()

  /// The switch camera button.
  let switchCameraButton = MDCFlatButton(type: .custom)

  /// The fullscreen button.
  let fullscreenButton = MDCFlatButton(type: .custom)

  /// A wrapper for the fullscreen button so the button can be hidden without affecting layout.
  let fullscreenButtonWrapper = UIView()

  /// The close button when presented full screen.
  private let closeButton = MDCFlatButton(type: .custom)

  /// The overlay buttons stack view.
  let overlayButtonsStackView = UIStackView()

  // The constraint for overlay buttons stack view.
  var overlayButtonsStackViewTopConstraint: NSLayoutConstraint?

  // The camera's action bar.
  private let actionBar = CameraActionBar()

  // The disabled camera view. Shown when permissions are disabled or the camera can't be used due
  // to a brightness sensor.
  private let disabledView = DisabledInputView()

  /// The preview height constraint, configured to be used when presented as a standalone view (i.e.
  /// not in the drawer). Call `setPreviewHeightAnchor(equalTo:)` to change it.
  private var previewHeightConstraint: NSLayoutConstraint?

  private let actionBarWrapper = UIView()
  private var actionBarWrapperHeightConstraint: NSLayoutConstraint?

  // View constants.
  let overlayButtonsStackViewTopConstant: CGFloat = 10
  let overlayButtonsStackViewPresentedTopConstant: CGFloat = 30
  let overlayButtonsStackViewLeftConstant: CGFloat = 5
  let overlayButtonsStackViewRightConstant: CGFloat = -5

  // The overlay view that gives a visual flash effect when a photo is taken.
  private let overlayFlashView = UIView()

  // MARK: - Public

  override open func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black

    photoCapturer.delegate = self

    actionBar.takePhotoButton.addTarget(
        self, action: #selector(takePhotoViewButtonPressed), for: .touchUpInside)
    switchCameraButton.addTarget(
        self, action: #selector(switchCameraButtonPressed), for: .touchUpInside)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(deviceOrientationDidChange),
                                           name: UIDevice.orientationDidChangeNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillResignActive),
                                           name: UIApplication.willResignActiveNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationDidBecomeActive),
                                           name: UIApplication.didBecomeActiveNotification,
                                           object: nil)

    // The flash view for taking photos.
    overlayFlashView.backgroundColor = .white
    overlayFlashView.translatesAutoresizingMaskIntoConstraints = false
    overlayFlashView.isUserInteractionEnabled = false
    overlayFlashView.alpha = 0

    view.addSubview(cameraView)
    cameraView.translatesAutoresizingMaskIntoConstraints = false
    cameraView.pinToEdgesOfView(view)
    cameraView.previewLayer = photoCapturer.previewLayer

    // Switch camera button.
    switchCameraButton.setImage(UIImage(named: "ic_switch_camera_shadowed"), for: .normal)
    switchCameraButton.tintColor = .white
    switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
    switchCameraButton.accessibilityLabel = String.switchCameraContentDescription

    // Buttons stack view.
    overlayButtonsStackView.addArrangedSubview(switchCameraButton)
    overlayButtonsStackView.axis = .horizontal
    overlayButtonsStackView.distribution = .equalCentering
    overlayButtonsStackView.alignment = .center
    overlayButtonsStackView.isLayoutMarginsRelativeArrangement = true
    view.addSubview(overlayButtonsStackView)
    overlayButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
    overlayButtonsStackViewTopConstraint = overlayButtonsStackView.topAnchor.constraint(
        equalTo: view.topAnchor, constant: overlayButtonsStackViewTopConstant)
    overlayButtonsStackViewTopConstraint?.isActive = true
    overlayButtonsStackView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor, constant: overlayButtonsStackViewLeftConstant).isActive = true
    overlayButtonsStackView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: overlayButtonsStackViewRightConstant).isActive = true

    // Action bar.
    actionBar.translatesAutoresizingMaskIntoConstraints = false
    actionBarWrapper.addSubview(actionBar)
    actionBar.topAnchor.constraint(equalTo: actionBarWrapper.topAnchor).isActive = true
    actionBar.leadingAnchor.constraint(equalTo: actionBarWrapper.leadingAnchor).isActive = true
    actionBar.trailingAnchor.constraint(equalTo: actionBarWrapper.trailingAnchor).isActive = true

    actionBarWrapper.backgroundColor = DrawerView.actionBarBackgroundColor
    actionBarWrapper.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(actionBarWrapper)
    actionBarWrapper.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    actionBarWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    actionBarWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    actionBarWrapperHeightConstraint =
        actionBarWrapper.heightAnchor.constraint(equalTo: actionBar.heightAnchor)
    actionBarWrapperHeightConstraint?.isActive = true

    // Disabled view.
    view.addSubview(disabledView)
    disabledView.translatesAutoresizingMaskIntoConstraints = false
    disabledView.pinToEdgesOfView(view)
    disabledView.isHidden = true

    // When presented, the preview view needs a proper height constraint. It can be changed by
    // calling `setPreviewHeightAnchor(equalTo:)`.
    previewHeightConstraint = cameraView.previewView.heightAnchor.constraint(
        equalTo: cameraView.heightAnchor)
    previewHeightConstraint?.isActive = true
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    photoCapturer.startCaptureSessionIfNecessary()

    // Adjust the layout depending on whether the view was presented or not.
    if isPresented {
      closeButton.setImage(UIImage(named: "ic_close_shadowed"), for: .normal)
      closeButton.tintColor = .white
      closeButton.translatesAutoresizingMaskIntoConstraints = false
      closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
      closeButton.accessibilityLabel = String.closeBtnContentDescription
      overlayButtonsStackViewTopConstraint?.constant = overlayButtonsStackViewPresentedTopConstant
      overlayButtonsStackView.addArrangedSubview(closeButton)
    } else {
      // Fullscreen button.
      fullscreenButton.setImage(UIImage(named: "ic_crop_free_shadowed"), for: .normal)
      fullscreenButton.tintColor = .white
      fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
      fullscreenButtonWrapper.addSubview(fullscreenButton)
      fullscreenButton.pinToEdgesOfView(fullscreenButtonWrapper)
      fullscreenButton.addTarget(
          self, action: #selector(fullscreenButtonButtonPressed), for: .touchUpInside)
      fullscreenButton.accessibilityLabel = String.fullscreenContentDescription
      overlayButtonsStackViewTopConstraint?.constant = overlayButtonsStackViewTopConstant
      overlayButtonsStackView.addArrangedSubview(fullscreenButtonWrapper)
    }

    updateDisabledView(
        forCameraUseAllowed: CaptureSessionInterruptionObserver.shared.isCameraUseAllowed)
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard let rootView = UIApplication.shared.keyWindow?.rootViewController?.view else {
      overlayFlashView.removeFromSuperview()
      return
    }
    rootView.addSubview(overlayFlashView)
    overlayFlashView.removeConstraints(overlayFlashView.constraints)
    overlayFlashView.pinToEdgesOfView(rootView)

    // Update the preview layer's orientation.
    deviceOrientationDidChange()
    photoCapturer.configureFrontFacingCameraIfNecessary()
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    overlayFlashView.removeFromSuperview()
    photoCapturer.stopCaptureSessionIfNecessary()
  }

  override open var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Hide `fullscreenButton` via alpha, because hiding it with `isHidden` will cause its stack
    // view to layout `switchCameraButton` centered.
    fullscreenButton.alpha =
        traitCollection.verticalSizeClass == .compact ? 0 : 1
  }

  override open func viewSafeAreaInsetsDidChange() {
    actionBarWrapperHeightConstraint?.constant = view.safeAreaInsetsOrZero.bottom
  }

  /// Sets the preview height anchor equal to a layout dimension.
  ///
  /// - Parameter layoutDimension: The layout dimension to set the preview height anchor equal to.
  func setPreviewHeightAnchor(equalTo layoutDimension: NSLayoutDimension) {
    previewHeightConstraint?.isActive = false
    previewHeightConstraint =
        cameraView.previewView.heightAnchor.constraint(equalTo: layoutDimension)
    previewHeightConstraint?.isActive = true
  }

  /// Update the state and contents of the disabled view based on permissions or camera allowance.
  ///
  /// - Parameter isCameraUseAllowed: Is the camera usable?
  func updateDisabledView(forCameraUseAllowed isCameraUseAllowed: Bool) {
    // Verify the user gave permission to use the camera first.
    if !photoCapturer.isCameraPermissionGranted {
      disabledView.isHidden = false
      disabledView.shouldDisplayActionButton = true
      disabledView.messageLabel.text = String.inputCameraPermissionDenied
      disabledView.actionButton.setTitle(String.inputBlockedOpenSettingsButton, for: .normal)
      disabledView.actionButton.addTarget(self,
                                          action: #selector(openCameraSettingsPressed),
                                          for: .touchUpInside)
    } else if !isCameraUseAllowed {
      // Verify the camera can be used (we're not in record mode with a brightness sensor, using the
      // app in split screen or watching a picture in picture video).
      disabledView.isHidden = false
      if CaptureSessionInterruptionObserver.shared.isBrightnessSensorInUse {
        disabledView.shouldDisplayActionButton = true
        disabledView.messageLabel.text = String.inputCameraBlockedByBrightnessSensor
        disabledView.actionButton.setTitle(String.inputCameraBlockedViewSensorsButton, for: .normal)
        disabledView.actionButton.addTarget(self,
                                            action: #selector(switchToSensorsPressed),
                                            for: .touchUpInside)
      } else {
        disabledView.shouldDisplayActionButton = false
        disabledView.messageLabel.text = String.inputCameraBlockedByInterruption
      }
    } else {
      disabledView.isHidden = true
    }

    let shouldHideAccessibilityElements = !disabledView.isHidden
    switchCameraButton.accessibilityElementsHidden = shouldHideAccessibilityElements
    fullscreenButtonWrapper.accessibilityElementsHidden = shouldHideAccessibilityElements
    closeButton.accessibilityElementsHidden = shouldHideAccessibilityElements
    actionBar.takePhotoButton.accessibilityElementsHidden = shouldHideAccessibilityElements
  }

  // MARK: - DrawerItemViewController

  public func setUpDrawerPanner(with drawerViewController: DrawerViewController) {}

  public func reset() {
    photoCapturer.camera = .back
  }

  // MARK: - PhotoCapturerDelegate

  func photoCapturerCameraPermissionsDidChange(accessGranted: Bool) {
    updateDisabledView(
        forCameraUseAllowed: CaptureSessionInterruptionObserver.shared.isCameraUseAllowed)
  }

  func photoCapturerCaptureSessionDidBegin() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionWasInterrupted(_:)),
                                           name: .AVCaptureSessionWasInterrupted,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionInterruptionEnded(_:)),
                                           name: .AVCaptureSessionInterruptionEnded,
                                           object: nil)
  }

  func photoCapturerCaptureSessionWillEnd() {
    NotificationCenter.default.removeObserver(self,
                                              name: .AVCaptureSessionWasInterrupted,
                                              object: nil)
    NotificationCenter.default.removeObserver(self,
                                              name: .AVCaptureSessionInterruptionEnded,
                                              object: nil)
  }

  func photoCapturerDidCapturePhotoData(_ photoData: Data?, metadata: NSDictionary?) {
    guard let photoData = photoData else { return }
    handleImageDataSelected(photoData, metadata: metadata)
  }

  // MARK: - PhotoLibraryViewControllerDelegate

  func photoLibraryViewController(_ photoLibraryViewController: PhotoLibraryViewController,
                                  didSelectImageData imageData: Data,
                                  metadata: NSDictionary?) {
    handleImageDataSelected(imageData, metadata: metadata)
  }

  // MARK: - Private

  private func handleImageDataSelected(_ imageData: Data, metadata: NSDictionary?) {
    delegate?.imageSelectorDidCreateImageData(imageData, metadata: metadata)
    drawerViewController?.minimizeFromFull()

    // TODO: Consider AA-specific API.
    navigationController?.popViewController(animated: true)
  }

  @objc private func enableUserInteraction() {
    view.isUserInteractionEnabled = true
  }

  private func resumePhotoCapturerIfNeeded() {
    // Only start the camera capture session if camera use is allowed and the camera is being used.
    let isViewOnScreen = view.superview != nil
    if CaptureSessionInterruptionObserver.shared.isCameraUseAllowed && isViewOnScreen {
      photoCapturer.configureFrontFacingCameraIfNecessary()
      photoCapturer.startCaptureSessionIfNecessary()
    }
  }

  // MARK: - User actions

  @objc private func takePhotoViewButtonPressed() {
    // Temporarily disable user interaction.
    view.isUserInteractionEnabled = false
    perform(#selector(enableUserInteraction), with: nil, afterDelay: 0.25)

    // Flash the screen white so the user knows a photo was taken.
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.autoreverses = true
    animation.repeatCount = 1
    animation.toValue = 1.0
    animation.fromValue = 0
    animation.duration = 0.15
    overlayFlashView.layer.add(animation, forKey: "GSJAnimatedFlashEffect")

    var isCropping = false
    if let drawerViewController = drawerViewController, drawerViewController.isOpenHalf {
      isCropping = true
    }
    photoCapturer.captureImageData(isCropping: isCropping)
  }

  @objc private func switchCameraButtonPressed() {
    photoCapturer.toggleCamera()
  }

  @objc private func fullscreenButtonButtonPressed() {
    guard let drawerViewController = drawerViewController else { return }

    if !drawerViewController.isDisplayedAsSidebar {
      if drawerViewController.isOpenHalf {
        drawerViewController.setPositionToFull()
      } else {
        drawerViewController.setPositionToHalf()
      }
    }

    // TODO: Switch the button asset.
  }

  @objc private func closeButtonPressed() {
    delegate?.imageSelectorDidCancel()
  }

  @objc private func openCameraSettingsPressed() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(settingsURL)
  }

  @objc private func switchToSensorsPressed() {
    guard let drawerViewController = drawerViewController else { return }
    drawerViewController.selectObserve()
  }

  // MARK: - Notifications

  @objc private func deviceOrientationDidChange() {
    // Set the orientation of the video preview.
    photoCapturer.setPreviewOrientation(from: UIDevice.current.orientation)
  }

  @objc private func captureSessionWasInterrupted(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionWasInterrupted(notification)
      }
      return
    }

    guard AVCaptureSession.InterruptionReason(notificationUserInfo: notification.userInfo) ==
        .videoDeviceNotAvailableWithMultipleForegroundApps else { return }
    updateDisabledView(forCameraUseAllowed: false)
  }

  @objc private func captureSessionInterruptionEnded(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionInterruptionEnded(notification)
      }
      return
    }

    updateDisabledView(
        forCameraUseAllowed: !CaptureSessionInterruptionObserver.shared.isBrightnessSensorInUse)
    resumePhotoCapturerIfNeeded()
  }

  @objc private func applicationWillResignActive() {
    photoCapturer.stopCaptureSessionIfNecessary()
  }

  @objc private func applicationDidBecomeActive() {
    resumePhotoCapturerIfNeeded()
  }

}
