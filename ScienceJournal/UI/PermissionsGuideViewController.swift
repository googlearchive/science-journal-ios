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
import Photos
import UIKit

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

protocol PermissionsGuideDelegate: class {
  /// Informs the delegate the guide was completed and should be closed.
  func permissionsGuideDidComplete(_ viewController: PermissionsGuideViewController)
}

/// An animated, multi-step guide to walk the user through granting Science Journal all the various
/// permissions needed.
class PermissionsGuideViewController: OnboardingViewController {

  enum Metrics {
    static let headerTopPaddingNarrow: CGFloat = 140.0
    static let headerTopPaddingNarrowSmallScreen: CGFloat = 80.0
    static let headerTopPaddingWide: CGFloat = 40.0
    static let headerTopPaddingWideSmallScreen: CGFloat = 20.0
    static let individualMessageTopPaddingNarrow: CGFloat = 80.0
    static let individualMessageTopPaddingNarrowSmallScreen: CGFloat = 60.0
    static let individualMessageTopPaddingWide: CGFloat = 40.0
    static let individualMessageTopPaddingWideSmallScreen: CGFloat = 20.0
    static let checkPadding: CGFloat = 6.0
    static let doneYOffset: CGFloat = 10.0
    static let continueYOffset: CGFloat = 10.0
  }

  // MARK: - Properties

  private weak var delegate: PermissionsGuideDelegate?
  private let doneView = UIView()
  private let headerTitle = UILabel()
  private let initialMessage = UILabel()
  private let finalMessage = UILabel()
  private let notificationsMessage = UILabel()
  private let microphoneMessage = UILabel()
  private let cameraMessage = UILabel()
  private let photoLibraryMessage = UILabel()
  private let completeButton = MDCFlatButton()
  private let continueButton = MDCFlatButton()
  private let startButton = MDCFlatButton()
  private let devicePreferenceManager: DevicePreferenceManager

  // Used to store label constrains that will be modified on rotation.
  private var labelLeadingConstraints = [NSLayoutConstraint]()
  private var labelTrailingConstraints = [NSLayoutConstraint]()
  private var labelTopConstraints = [NSLayoutConstraint]()
  private var headerTopConstraint: NSLayoutConstraint?
  private var continueTopConstraint: NSLayoutConstraint?
  private var doneViewTopConstraint: NSLayoutConstraint?

  // The duration to animate the permission check button in.
  private var permissionCheckDuration: TimeInterval {
    return UIAccessibility.isVoiceOverRunning ? 0.3 : 0
  }

  // The interval to wait before moving to the next step.
  private var nextStepDelayInterval: TimeInterval {
    return UIAccessibility.isVoiceOverRunning ? 0.8 : 0.5
  }

  // Steps in order.
  private var steps = [stepNotifications, stepMicrophone, stepCamera, stepPhotoLibrary]

  private let showWelcomeView: Bool

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - delegate: The permissions guide delegate.
  ///   - analyticsReporter: The analytics reporter.
  ///   - devicePreferenceManager: The device preference manager.
  ///   - showWelcomeView: Whether to show the welcome view first.
  init(delegate: PermissionsGuideDelegate,
       analyticsReporter: AnalyticsReporter,
       devicePreferenceManager: DevicePreferenceManager,
       showWelcomeView: Bool) {
    self.delegate = delegate
    self.devicePreferenceManager = devicePreferenceManager
    self.showWelcomeView = showWelcomeView
    super.init(analyticsReporter: analyticsReporter)

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(notificationRegistrationComplete),
        name: LocalNotificationManager.PushNotificationRegistrationComplete,
        object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureView()
    if showWelcomeView {
      stepWelcome()
    } else {
      performNextStep()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateConstraintsForSize(view.bounds.size)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // If a user sees this VC, we consider them to have completed the permissions guide. This
    // is because there are certain types of permissions we cannot check the state of without
    // popping, which means it would be difficult to show/hide only the permissions they need.
    // Therefore, we mark them complete once they start, and we ask for permissions in key places
    // of the app just in case.
    devicePreferenceManager.hasAUserCompletedPermissionsGuide = true
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { (context) in
      self.updateConstraintsForSize(size)
      self.view.layoutIfNeeded()
    })
  }

  // MARK: - Private

  override func configureView() {
    super.configureView()

    configureSplashImagesPinnedToBottom()

    // Header label.
    wrappingView.addSubview(headerTitle)
    headerTitle.translatesAutoresizingMaskIntoConstraints = false
    headerTopConstraint = headerTitle.topAnchor.constraint(equalTo: wrappingView.topAnchor,
                                                           constant: Metrics.headerTopPaddingNarrow)
    headerTopConstraint?.isActive = true
    headerTitle.textColor = .white
    headerTitle.font = MDCTypography.headlineFont()
    headerTitle.textAlignment = .center
    headerTitle.text = String.permissionsGuideWelcomeTitle
    headerTitle.adjustsFontSizeToFitWidth = true
    headerTitle.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor).isActive = true
    headerTitle.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor).isActive = true

    // Shared label config.
    [initialMessage, finalMessage, notificationsMessage, microphoneMessage, cameraMessage,
         photoLibraryMessage].forEach {
      wrappingView.addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
      labelLeadingConstraints.append(
          $0.leadingAnchor.constraint(equalTo: wrappingView.leadingAnchor))
      labelTrailingConstraints.append(
          $0.trailingAnchor.constraint(equalTo: wrappingView.trailingAnchor))
      $0.font = Metrics.bodyFont
      $0.textColor = UIColor(red: 0.816, green: 0.714, blue: 0.980, alpha: 1.0)
      $0.textAlignment = .center
      $0.alpha = 0
      $0.numberOfLines = 0
    }
    NSLayoutConstraint.activate(labelLeadingConstraints)
    NSLayoutConstraint.activate(labelTrailingConstraints)

    // Initial into message and final message.
    initialMessage.alpha = 1
    initialMessage.text = String.permissionsGuideMessageIntro
    initialMessage.topAnchor.constraint(equalTo: headerTitle.bottomAnchor,
                                        constant: Metrics.innerSpacing).isActive = true

    finalMessage.text = String.permissionsGuideAllDoneMessage
    finalMessage.topAnchor.constraint(equalTo: initialMessage.topAnchor).isActive = true

    // Individual messages.
    notificationsMessage.text = String.permissionsGuideNotificationsInfo
    microphoneMessage.text = String.permissionsGuideMicrophoneInfo
    cameraMessage.text = String.permissionsGuideCameraInfo
    photoLibraryMessage.text = String.permissionsGuidePhotoLibraryInfo

    // Shared individual message config.
    [notificationsMessage, microphoneMessage, cameraMessage, photoLibraryMessage].forEach {
      labelTopConstraints.append($0.topAnchor.constraint(equalTo: wrappingView.topAnchor))
    }
    NSLayoutConstraint.activate(labelTopConstraints)

    // Shared button config.
    [startButton, completeButton, continueButton].forEach {
      wrappingView.addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.centerXAnchor.constraint(equalTo: wrappingView.centerXAnchor).isActive = true
      $0.setBackgroundColor(.white, for: .normal)
      $0.setTitleColor(view.backgroundColor, for: .normal)
      $0.disabledAlpha = 0
      $0.isEnabled = false
      $0.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
      $0.setElevation(ShadowElevation.raisedButtonPressed, for: [.selected, .highlighted])
    }

    // Start button.
    startButton.isEnabled = true
    startButton.setTitle(String.permissionsGuideStartButtonTitle.uppercased(), for: .normal)
    startButton.topAnchor.constraint(equalTo: initialMessage.bottomAnchor,
                                     constant: Metrics.buttonSpacing).isActive = true
    startButton.addTarget(self, action: #selector(startGuideButtonPressed), for: .touchUpInside)

    // Complete button.
    completeButton.setTitle(String.permissionsGuideFinishButtonTitle.uppercased(), for: .normal)
    completeButton.topAnchor.constraint(equalTo: finalMessage.bottomAnchor,
                                        constant: Metrics.buttonSpacing).isActive = true
    completeButton.addTarget(self,
                             action: #selector(completeGuideButtonPressed),
                             for: .touchUpInside)

    // The continue button, to start each step's system prompt after a user has read the message.
    continueButton.setTitle(String.permissionsGuideContinueButtonTitle.uppercased(), for: .normal)
    continueButton.centerXAnchor.constraint(equalTo: wrappingView.centerXAnchor).isActive = true
    continueTopConstraint =
        continueButton.topAnchor.constraint(equalTo: notificationsMessage.bottomAnchor,
                                            constant: Metrics.buttonSpacing)
    continueTopConstraint?.isActive = true

    // Done message with check, used after each step completes.
    doneView.alpha = 0
    let doneCheck = UIImageView(image: UIImage(named: "ic_check"))
    doneCheck.tintColor = MDCPalette.green.accent200
    let doneLabel = UILabel()
    doneLabel.font = Metrics.bodyFont
    doneLabel.text = String.permissionsGuideCheckComplete
    doneLabel.textColor = .white

    wrappingView.addSubview(doneView)
    doneView.addSubview(doneCheck)
    doneView.addSubview(doneLabel)
    doneView.translatesAutoresizingMaskIntoConstraints = false
    doneView.centerXAnchor.constraint(equalTo: wrappingView.centerXAnchor).isActive = true
    doneViewTopConstraint =
        doneView.topAnchor.constraint(equalTo: notificationsMessage.bottomAnchor,
                                      constant: Metrics.buttonSpacing)
    doneViewTopConstraint?.isActive = true

    doneCheck.translatesAutoresizingMaskIntoConstraints = false
    doneCheck.topAnchor.constraint(equalTo: doneView.topAnchor).isActive = true
    doneCheck.leadingAnchor.constraint(equalTo: doneView.leadingAnchor).isActive = true
    doneCheck.bottomAnchor.constraint(equalTo: doneView.bottomAnchor).isActive = true
    doneLabel.translatesAutoresizingMaskIntoConstraints = false
    doneLabel.leadingAnchor.constraint(equalTo: doneCheck.trailingAnchor,
                                       constant: Metrics.checkPadding).isActive = true
    doneLabel.trailingAnchor.constraint(equalTo: doneView.trailingAnchor).isActive = true
    doneLabel.centerYAnchor.constraint(equalTo: doneCheck.centerYAnchor).isActive = true
  }

  // Updates constraints for labels. Used in rotation to ensure the best fit for various screen
  // sizes.
  private func updateConstraintsForSize(_ size: CGSize) {
    guard UIDevice.current.userInterfaceIdiom != .pad else { return }

    var headerTopPadding: CGFloat
    var labelTopPadding: CGFloat
    if size.isWiderThanTall {
      if size.width <= 568 {
        headerTopPadding = Metrics.headerTopPaddingWideSmallScreen
        labelTopPadding = Metrics.individualMessageTopPaddingWideSmallScreen
      } else {
        headerTopPadding = Metrics.headerTopPaddingWide
        labelTopPadding = Metrics.individualMessageTopPaddingWide
      }
    } else {
      if size.width <= 320 {
        headerTopPadding = Metrics.headerTopPaddingNarrowSmallScreen
        labelTopPadding = Metrics.individualMessageTopPaddingNarrowSmallScreen
      } else {
        headerTopPadding = Metrics.headerTopPaddingNarrow
        labelTopPadding = Metrics.individualMessageTopPaddingNarrow
      }
    }

    headerTopConstraint?.constant = headerTopPadding
    labelTopConstraints.forEach { $0.constant = labelTopPadding }
    labelLeadingConstraints.forEach {
      $0.constant = size.isWiderThanTall ? Metrics.outerPaddingWide : Metrics.outerPaddingNarrow
    }
    labelTrailingConstraints.forEach {
      $0.constant = size.isWiderThanTall ? -Metrics.outerPaddingWide : -Metrics.outerPaddingNarrow
    }
  }

  // Animates to a step and fires a completion once done.
  private func animateToStep(animations: @escaping () -> Void,
                             completion: (() -> Void)? = nil) {
    UIView.animate(withDuration: 1.0, animations: animations) { (_) in
      guard let completion = completion else { return }
      // Delay the completion block by a second to give the user a moment to read the tutorial
      // text. In practice, requesting permission from the system takes a moment as well, so this
      // ends up with a reasonable delay to read the tutorial before being prompted.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion()
      }
    }
  }

  // MARK: - Steps

  // Displays the done notice and then, after a delay, performs the next step.
  private func markStepDoneAndPerformNext() {
    UIView.animate(withDuration: 0.3, animations: {
      self.doneView.alpha = 1
    }) { (_) in
      UIAccessibility.post(notification: .layoutChanged, argument: self.doneView)
      DispatchQueue.main.asyncAfter(deadline: .now() + self.nextStepDelayInterval) {
        self.performNextStep()
      }
    }
  }

  // Performs the next step in the guide or, if none are left, shows the conclusion.
  private func performNextStep() {
    guard steps.count > 0 else {
      stepsDone()
      return
    }

    let nextStep = steps.remove(at: 0)
    nextStep(self)()
  }

  // MARK: Welcome

  private func stepWelcome() {
    headerTitle.alpha = 1
    initialMessage.alpha = 1
  }

  // MARK: Push notifications

  // Ask for push notification permissions.
  private func stepNotifications() {
    updateContinueButtonConstraint(forLabel: notificationsMessage)
    continueButton.removeTarget(nil, action: nil, for: .allEvents)
    continueButton.addTarget(self,
                             action: #selector(checkForNotificationPermissions),
                             for: .touchUpInside)
    let showNotificationsState = {
      self.doneView.alpha = 0
      self.continueButton.isEnabled = UIAccessibility.isVoiceOverRunning
      self.headerTitle.alpha = 0
      self.initialMessage.alpha = 0
      self.startButton.isEnabled = false
      self.notificationsMessage.alpha = 1
    }

    let promptNotificationPermission = {
      self.updateDoneViewConstraint(forLabel: self.notificationsMessage)
      if !UIAccessibility.isVoiceOverRunning {
        // If VoiceOver is running, a user will manually tap a "Check Permission" button to
        // continue. If VO is not running, ask for permission immediately.
        self.checkForNotificationPermissions()
      }
    }

    guard showWelcomeView else {
      showNotificationsState()
      // Delay the permission prompt to give the user time to read the text and match the feel of
      // the other steps.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        promptNotificationPermission()
      }
      return
    }

    animateToStep(animations: showNotificationsState) {
      UIAccessibility.post(notification: .layoutChanged, argument: self.notificationsMessage)
      promptNotificationPermission()
    }
  }

  @objc private func checkForNotificationPermissions() {
    UIView.animate(withDuration: permissionCheckDuration, animations: {
      self.continueButton.isEnabled = false
    }) { (_) in
      LocalNotificationManager.shared.registerUserNotifications()
    }
  }

  // Listen for step 1 completion before moving to step 2.
  @objc private func notificationRegistrationComplete() {
    self.markStepDoneAndPerformNext()
  }

  // MARK: Microphone

  // Ask for microphone permissions.
  private func stepMicrophone() {
    updateContinueButtonConstraint(forLabel: microphoneMessage)
    continueButton.removeTarget(nil, action: nil, for: .allEvents)
    continueButton.addTarget(self,
                             action: #selector(checkForMicrophonePermissions),
                             for: .touchUpInside)
    animateToStep(animations: {
      self.doneView.alpha = 0
      self.continueButton.isEnabled = UIAccessibility.isVoiceOverRunning
      self.notificationsMessage.alpha = 0
      self.microphoneMessage.alpha = 1
    }) {
      UIAccessibility.post(notification: .layoutChanged, argument: self.microphoneMessage)
      self.updateDoneViewConstraint(forLabel: self.microphoneMessage)
      if !UIAccessibility.isVoiceOverRunning {
        // If VoiceOver is running, a user will manually tap a "Check Permission" button to
        // continue. If VO is not running, ask for permission immediately.
        self.checkForMicrophonePermissions()
      }
    }
  }

  @objc private func checkForMicrophonePermissions() {
    UIView.animate(withDuration: permissionCheckDuration, animations: {
      self.continueButton.isEnabled = false
    }) { (_) in
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
          self.markStepDoneAndPerformNext()
        }
      }
    }
  }

  // MARK: Camera

  // Ask for camera permissions.
  private func stepCamera() {
    updateContinueButtonConstraint(forLabel: cameraMessage)
    continueButton.removeTarget(nil, action: nil, for: .allEvents)
    continueButton.addTarget(self,
                             action: #selector(checkForCameraPermissions),
                             for: .touchUpInside)
    animateToStep(animations: {
      self.doneView.alpha = 0
      self.continueButton.isEnabled = UIAccessibility.isVoiceOverRunning
      self.microphoneMessage.alpha = 0
      self.cameraMessage.alpha = 1
    }) {
      UIAccessibility.post(notification: .layoutChanged, argument: self.cameraMessage)
      self.updateDoneViewConstraint(forLabel: self.cameraMessage)
      if !UIAccessibility.isVoiceOverRunning {
        // If VoiceOver is running, a user will manually tap a "Check Permission" button to
        // continue. If VO is not running, ask for permission immediately.
        self.checkForCameraPermissions()
      }
    }
  }

  @objc private func checkForCameraPermissions() {
    UIView.animate(withDuration: permissionCheckDuration, animations: {
      self.continueButton.isEnabled = false
    }) { (_) in
      let cameraAuthorizationStatus =
          AVCaptureDevice.authorizationStatus(for: .video)
      switch cameraAuthorizationStatus {
      case .authorized, .denied, .restricted:
        self.markStepDoneAndPerformNext()
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.sync {
            self.markStepDoneAndPerformNext()
          }
        }
      }
    }
  }

  // MARK: Photo library

  // Ask for photo library permissions.
  private func stepPhotoLibrary() {
    updateContinueButtonConstraint(forLabel: photoLibraryMessage)
    continueButton.removeTarget(nil, action: nil, for: .allEvents)
    continueButton.addTarget(self,
                             action: #selector(checkForPhotoLibraryPermissions),
                             for: .touchUpInside)
    animateToStep(animations: {
      self.doneView.alpha = 0
      self.continueButton.isEnabled = UIAccessibility.isVoiceOverRunning
      self.cameraMessage.alpha = 0
      self.photoLibraryMessage.alpha = 1
    }) {
      UIAccessibility.post(notification: .layoutChanged, argument: self.photoLibraryMessage)
      self.updateDoneViewConstraint(forLabel: self.photoLibraryMessage)
      if !UIAccessibility.isVoiceOverRunning {
        // If VoiceOver is running, a user will manually tap a "Check Permission" button to
        // continue. If VO is not running, ask for permission immediately.
        self.checkForPhotoLibraryPermissions()
      }
    }
  }

  @objc private func checkForPhotoLibraryPermissions() {
    UIView.animate(withDuration: permissionCheckDuration, animations: {
      self.continueButton.isEnabled = false
    }) { (_) in
      PHPhotoLibrary.requestAuthorization{ status in
        DispatchQueue.main.sync {
          self.markStepDoneAndPerformNext()
        }
      }
    }
  }

  // MARK: All steps complete

  // Thank the user and add a completion button which dismisses the guide.
  private func stepsDone() {
    animateToStep(animations: {
      self.continueButton.isEnabled = false
      self.doneView.alpha = 0
      self.photoLibraryMessage.alpha = 0
      self.finalMessage.alpha = 1
      self.completeButton.isEnabled = true
    }) {
      UIAccessibility.post(notification: .layoutChanged, argument: self.finalMessage)
    }
  }

  // MARK: - Helpers

  private func updateContinueButtonConstraint(forLabel label: UILabel) {
    continueTopConstraint?.isActive = false
    continueTopConstraint = continueButton.topAnchor.constraint(equalTo: label.bottomAnchor,
                                                                constant: Metrics.buttonSpacing)
    continueTopConstraint?.isActive = true
    continueButton.layoutIfNeeded()
  }

  private func updateDoneViewConstraint(forLabel label: UILabel) {
    doneViewTopConstraint?.isActive = false
    doneViewTopConstraint = doneView.topAnchor.constraint(equalTo: label.bottomAnchor,
                                                          constant: Metrics.buttonSpacing)
    doneViewTopConstraint?.isActive = true
    doneView.layoutIfNeeded()
  }

  // MARK: - User actions

  @objc private func startGuideButtonPressed() {
    performNextStep()
  }

  @objc private func completeGuideButtonPressed() {
    delegate?.permissionsGuideDidComplete(self)
  }

}
