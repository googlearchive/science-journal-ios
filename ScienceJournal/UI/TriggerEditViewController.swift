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

import ScienceJournalProtos

protocol TriggerEditViewControllerDelegate: class {
  /// Called when a trigger was edited.
  func triggerEditViewController(_ triggerEditViewController: TriggerEditViewController,
                                 didEditTrigger trigger: SensorTrigger)
}

/// View controller that allows editing of a new or existing trigger.
class TriggerEditViewController: MaterialHeaderViewController, TriggerEditDelegate,
    OptionSelectorDelegate, TriggerTypeSelectorDelegate, TriggerWhenSelectorDelegate {

  // MARK: - Properties

  override var trackedScrollView: UIScrollView? {
    return scrollView
  }

  private let trigger: SensorTrigger
  private let sensor: Sensor
  private weak var delegate: TriggerEditViewControllerDelegate?
  private let isEditMode: Bool
  static private let numberFormatter = LocalizedNumberFormatter()

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  private lazy var triggerTypeSelectorView: TriggerTypeSelectorView = {
    let triggerTypeSelectorView = TriggerTypeSelectorView()
    triggerTypeSelectorView.delegate = self
    triggerTypeSelectorView.optionSelectorDelegate = self
    triggerTypeSelectorView.triggerTypeSelectorDelegate = self
    triggerTypeSelectorView.translatesAutoresizingMaskIntoConstraints = false
    return triggerTypeSelectorView
  }()

  /// Wraps the trigger type selector with an inset.
  private lazy var triggerTypeSelectorViewWrapped: UIStackView = {
    let wrapperStack = UIStackView(arrangedSubviews: [self.triggerTypeSelectorView])
    wrapperStack.layoutMargins = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
    wrapperStack.isLayoutMarginsRelativeArrangement = true
    return wrapperStack
  }()

  private lazy var triggerWhenSelectorView: TriggerWhenSelectorView = {
    let triggerWhenSelectorView = TriggerWhenSelectorView()
    triggerWhenSelectorView.delegate = self
    triggerWhenSelectorView.optionSelectorDelegate = self
    triggerWhenSelectorView.triggerWhenSelectorDelegate = self
    triggerWhenSelectorView.translatesAutoresizingMaskIntoConstraints = false
    return triggerWhenSelectorView
  }()

  /// Wraps the trigger when selector with an inset.
  private lazy var triggerWhenSelectorViewWrapped: UIStackView = {
    let wrapperStack = UIStackView(arrangedSubviews: [self.triggerWhenSelectorView])
    wrapperStack.layoutMargins = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
    wrapperStack.isLayoutMarginsRelativeArrangement = true
    return wrapperStack
  }()

  private lazy var triggerValueEntryView: TriggerValueEntryView = {
    let triggerValueEntryView = TriggerValueEntryView()
    triggerValueEntryView.unitDescription = self.sensor.unitDescription
    triggerValueEntryView.translatesAutoresizingMaskIntoConstraints = false
    return triggerValueEntryView
  }()

  private lazy var triggerOnlyWhenRecordingSwitchView: TriggerOnlyWhenRecordingSwitchView = {
    let triggerOnlyWhenRecordingSwitchView = TriggerOnlyWhenRecordingSwitchView()
    triggerOnlyWhenRecordingSwitchView.delegate = self
    triggerOnlyWhenRecordingSwitchView.translatesAutoresizingMaskIntoConstraints = false
    return triggerOnlyWhenRecordingSwitchView
  }()

  private lazy var lastSectionHeaderView: TriggerEditSectionHeaderView = {
    let lastSectionHeaderView = TriggerEditSectionHeaderView()
    lastSectionHeaderView.translatesAutoresizingMaskIntoConstraints = false
    return lastSectionHeaderView
  }()

  private lazy var triggerNoteTextEntryView: TriggerNoteTextEntryView = {
    let triggerNoteTextEntryView = TriggerNoteTextEntryView()
    triggerNoteTextEntryView.translatesAutoresizingMaskIntoConstraints = false
    return triggerNoteTextEntryView
  }()

  private lazy var triggerAlertSoundSwitchView: TriggerOptionSwitchView = {
    let triggerAlertSoundSwitchView = TriggerOptionSwitchView()
    triggerAlertSoundSwitchView.delegate = self
    triggerAlertSoundSwitchView.titleText = String.triggerAudioAlert
    triggerAlertSoundSwitchView.translatesAutoresizingMaskIntoConstraints = false
    return triggerAlertSoundSwitchView
  }()

  private lazy var triggerAlertVibrationSwitchView: TriggerOptionSwitchView = {
    let triggerAlertVibrationSwitchView = TriggerOptionSwitchView()
    triggerAlertVibrationSwitchView.delegate = self
    triggerAlertVibrationSwitchView.translatesAutoresizingMaskIntoConstraints = false
    triggerAlertVibrationSwitchView.titleText = String.triggerHapticAlert
    return triggerAlertVibrationSwitchView
  }()

  private lazy var triggerAlertVisualNotificationSwitchView: TriggerOptionSwitchView = {
    let triggerAlertVisualNotificationSwitchView = TriggerOptionSwitchView()
    triggerAlertVisualNotificationSwitchView.delegate = self
    triggerAlertVisualNotificationSwitchView.translatesAutoresizingMaskIntoConstraints = false
    triggerAlertVisualNotificationSwitchView.titleText = String.triggerVisualAlert
    return triggerAlertVisualNotificationSwitchView
  }()

  // Tracks the last trigger type that was updated in `updateStackViewForTriggerType`.
  private var triggerTypeForLastUpdate: GSJTriggerInformation_TriggerActionType?

  private var stackViewHorizontalInset: CGFloat {
    switch displayType {
    case .compact, .compactWide:
      return 0
    case .regular:
      return ViewConstants.cellHorizontalInsetRegularDisplayType
    case .regularWide:
      return ViewConstants.cellHorizontalInsetRegularWideDisplayType
    }
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorTrigger: The sensor trigger to edit.
  ///   - sensor: The sensor the trigger is being edited for.
  ///   - delegate: The trigger edit view controller delegate.
  ///   - isEditMode: Whether or not this trigger is being edited. Otherwise, it is being created
  ///                 for the first time.
  ///   - analyticsReporter: An AnalyticsReporter.
  init(sensorTrigger: SensorTrigger,
       sensor: Sensor,
       delegate: TriggerEditViewControllerDelegate,
       isEditMode: Bool,
       analyticsReporter: AnalyticsReporter) {
    trigger = sensorTrigger
    self.sensor = sensor
    self.delegate = delegate
    self.isEditMode = isEditMode
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    accessibilityViewIsModal = true

    // Background colors.
    appBar.headerViewController.headerView.backgroundColor = .appBarReviewBackgroundColor
    view.backgroundColor = .white

    // Title.
    let titleFormat = isEditMode ? String.triggerEditTitleFormat : String.triggerEditTitleNewFormat
    title = String(format: titleFormat, sensor.name)

    if isPresented && UIDevice.current.userInterfaceIdiom == .pad {
      appBar.hideStatusBarOverlay()
    }

    // Back and save buttons.
    navigationItem.leftBarButtonItem =
        MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    let saveBarButtonItem = MaterialBarButtonItem()
    saveBarButtonItem.button.addTarget(self,
                                       action: #selector(saveButtonPressed),
                                       for: .touchUpInside)
    saveBarButtonItem.button.setImage(UIImage(named: "ic_check"), for: .normal)
    saveBarButtonItem.button.accessibilityLabel = String.actionSave
    saveBarButtonItem.button.accessibilityHint = String.saveBtnContentDetails
    navigationItem.rightBarButtonItem = saveBarButtonItem

    // Scroll view.
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    scrollView.pinToEdgesOfView(view)

    // Stack view.
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)
    stackView.pinToEdgesOfView(scrollView)
    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true

    // Add the default arranged views to the stack view, and update the stack view for the trigger
    // type.
    defaultArrangedViews.forEach { stackView.addArrangedSubview($0) }
    updateStackViewForTriggerType()

    // Pass in the trigger's existing values.
    if isEditMode {
      triggerTypeSelectorView.triggerType = trigger.triggerInformation.triggerActionType
      triggerTypeSelectorView.shouldOnlyAllowTriggerActionAlert =
          trigger.triggerInformation.triggerWhen.shouldOnlyAllowTriggerActionAlert
      triggerWhenSelectorView.triggerWhen = trigger.triggerInformation.triggerWhen
      triggerValueEntryView.triggerValueString = TriggerEditViewController.numberFormatter.string(
          fromDouble: trigger.triggerInformation.valueToTrigger)
      triggerOnlyWhenRecordingSwitchView.aSwitch.isOn =
          trigger.triggerInformation.triggerOnlyWhenRecording
      triggerNoteTextEntryView.noteText = trigger.triggerInformation.noteText
      triggerAlertSoundSwitchView.aSwitch.isOn =
          trigger.triggerInformation.triggerAlertTypes.contains(.triggerAlertAudio)
      triggerAlertVibrationSwitchView.aSwitch.isOn =
          trigger.triggerInformation.triggerAlertTypes.contains(.triggerAlertPhysical)
      triggerAlertVisualNotificationSwitchView.aSwitch.isOn =
          trigger.triggerInformation.triggerAlertTypes.contains(.triggerAlertVisual)
    }

    // Register for keyboard notifications.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: UIResponder.keyboardWillShowNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: UIResponder.keyboardWillHideNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleKeyboardNotification(_:)),
                                           name: UIResponder.keyboardWillChangeFrameNotification,
                                           object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateStackViewInsetsForDisplayType()
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { (_) in
      self.updateStackViewInsetsForDisplayType()
    })
  }

  override func accessibilityPerformEscape() -> Bool {
    // Just close the view without saving if a user escapes.
    close()
    return true
  }

  // MARK: - Private

  // Views that should always stay in the stack view.
  private var defaultArrangedViews: [UIView] {
    return [triggerTypeSelectorViewWrapped, triggerWhenSelectorViewWrapped, triggerValueEntryView]
  }

  private func updateStackViewForTriggerType() {
    // Track the trigger type being updated.
    triggerTypeForLastUpdate = triggerTypeSelectorView.triggerType

    // Only alert and note action types show the only when recording option and last section header.
    let shouldShowTriggerOnlyWhenRecordingAndLastSectionHeader =
        triggerTypeSelectorView.triggerType == .triggerActionAlert ||
        triggerTypeSelectorView.triggerType == .triggerActionNote

    // Remove all arranged views except for those still needed.
    var viewsToKeep = defaultArrangedViews
    if shouldShowTriggerOnlyWhenRecordingAndLastSectionHeader {
      viewsToKeep.append(triggerOnlyWhenRecordingSwitchView)
      viewsToKeep.append(lastSectionHeaderView)
    }
    stackView.removeAllArrangedViews(exceptViews: viewsToKeep, leaveInSuperview: false)

    // Add the only when recording option and last section header views if needed.
    if shouldShowTriggerOnlyWhenRecordingAndLastSectionHeader {
      if !stackView.arrangedSubviews.contains(triggerOnlyWhenRecordingSwitchView) {
        stackView.addArrangedSubview(triggerOnlyWhenRecordingSwitchView)
      }
      if !stackView.arrangedSubviews.contains(lastSectionHeaderView) {
        stackView.addArrangedSubview(lastSectionHeaderView)
      }
    }

    // Add the additional views needed for alert and note action types.
    if triggerTypeSelectorView.triggerType == .triggerActionAlert {
      lastSectionHeaderView.textLabel.text = String.triggerAlertPrompt
      stackView.addArrangedSubview(triggerAlertSoundSwitchView)
      // Vibration switches should only be shown on iPhones, and only when the sensor is not audio.
      if UIDevice.isPhone && !(sensor is AudioSensor) {
        stackView.addArrangedSubview(triggerAlertVibrationSwitchView)
      }
      stackView.addArrangedSubview(triggerAlertVisualNotificationSwitchView)
    } else if triggerTypeSelectorView.triggerType == .triggerActionNote {
      lastSectionHeaderView.textLabel.text = String.triggerNoteTextLabel
      stackView.addArrangedSubview(triggerNoteTextEntryView)
    }
  }

  private func updateStackViewInsetsForDisplayType() {
    stackView.layoutMargins = UIEdgeInsets(top: 0,
                                           left: stackViewHorizontalInset,
                                           bottom: 0,
                                           right: stackViewHorizontalInset)
  }

  // Validates and updates `trigger` from the data in the view. If it can't be validated, this will
  // show a validation error message and return nil.
  private func validateAndUpdateTrigger() -> SensorTrigger? {
    // There must be a value to trigger. If there is not, show the error message.
    guard let triggerValueString = triggerValueEntryView.triggerValueString,
        let valueToTrigger =
            TriggerEditViewController.numberFormatter.double(fromString: triggerValueString) else {
      triggerValueEntryView.showValidationError()
      triggerValueEntryView.textField.becomeFirstResponder()
      // Trigger value entry view's validation error message is out of bounds of its view. Bring it
      // to foreground so it doesn't present behind the view under it.
      stackView.bringSubviewToFront(triggerValueEntryView)
      return nil
    }

    // Make sure the validation error message is hidden if there is a value to trigger.
    triggerValueEntryView.hideValidationError()

    // Update the trigger from the data in the views.
    trigger.triggerInformation.triggerActionType = triggerTypeSelectorView.triggerType
    trigger.triggerInformation.triggerWhen = triggerWhenSelectorView.triggerWhen
    trigger.triggerInformation.valueToTrigger = valueToTrigger

    // Clear data that is only set for alerts and notes.
    trigger.triggerInformation.triggerOnlyWhenRecording = false
    trigger.triggerInformation.triggerAlertTypes.removeAll()
    trigger.triggerInformation.noteText = ""

    if trigger.triggerInformation.triggerActionType == .triggerActionAlert ||
        trigger.triggerInformation.triggerActionType == .triggerActionNote {
      trigger.triggerInformation.triggerOnlyWhenRecording =
          triggerOnlyWhenRecordingSwitchView.aSwitch.isOn

      if trigger.triggerInformation.triggerActionType == .triggerActionAlert {
        if triggerAlertSoundSwitchView.aSwitch.isOn {
          trigger.triggerInformation.triggerAlertTypes.append(.triggerAlertAudio)
        }
        if triggerAlertVibrationSwitchView.aSwitch.isOn {
          trigger.triggerInformation.triggerAlertTypes.append(.triggerAlertPhysical)
        }
        if triggerAlertVisualNotificationSwitchView.aSwitch.isOn {
          trigger.triggerInformation.triggerAlertTypes.append(.triggerAlertVisual)
        }
      } else if trigger.triggerInformation.triggerActionType == .triggerActionNote {
        if let noteText = triggerNoteTextEntryView.noteText {
          trigger.triggerInformation.noteText = noteText
        }
      }
    }

    return trigger
  }

  private func close() {
    navigationController?.popViewController(animated: true)
  }

  // MARK: - User actions

  @objc private func backButtonPressed() {
    close()
  }

  @objc private func saveButtonPressed() {
    // Call back with the validated trigger and dismiss, or return if it is not validated.
    guard let trigger = validateAndUpdateTrigger() else { return }
    delegate?.triggerEditViewController(self, didEditTrigger: trigger)
    close()
  }

  // MARK: - TriggerEditDelegate

  func triggerEditDelegateDidBeginEditing() {
    view.endEditing(true)
  }

  // MARK: - OptionSelectorDelegate

  func optionSelectorView(_ optionSelectorView: OptionSelectorView,
                          didPressShowOptions actions: [PopUpMenuAction],
                          coveringView: UIView) {
    // Show the actions in a pop up menu.
    let popUpMenu = PopUpMenuViewController()
    popUpMenu.addActions(actions)
    popUpMenu.present(from: self, position: .coveringView(coveringView))
  }

  // MARK: - TriggerTypeSelectorDelegate

  func triggerTypeSelectorView(_ triggerTypeSelectorView: TriggerTypeSelectorView,
                               didSelectType triggerType: GSJTriggerInformation_TriggerActionType) {
    // If there is a trigger type for the last update, only update if it is different than the type
    // from the previous update.
    if let triggerTypeForLastUpdate = triggerTypeForLastUpdate {
      guard triggerTypeForLastUpdate != triggerTypeSelectorView.triggerType else { return }
    }
    updateStackViewForTriggerType()
  }

  // MARK: - TriggerWhenSelectorDelegate

  func triggerWhenSelectorView(_ triggerWhenSelectorView: TriggerWhenSelectorView,
      didSelectWhenToTrigger triggerWhen: GSJTriggerInformation_TriggerWhen) {
    triggerTypeSelectorView.shouldOnlyAllowTriggerActionAlert =
        triggerWhen.shouldOnlyAllowTriggerActionAlert
  }

  // MARK: - Notifications

  @objc private func handleKeyboardNotification(_ notification: Notification) {
    guard let keyboardFrameEndValue =
        notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    let converedKeyboardFrameEnd = view.convert(keyboardFrameEndValue.cgRectValue, from: nil)
    scrollView.contentInset =
        UIEdgeInsets(top: ViewConstants.headerHeight,
                     left: 0,
                     bottom: view.frame.size.height - converedKeyboardFrameEnd.origin.y,
                     right: 0)
    scrollView.scrollIndicatorInsets = scrollView.contentInset
  }

}
