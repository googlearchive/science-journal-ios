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

// swiftlint:disable file_length

import UIKit

import third_party_objective_c_material_components_ios_components_Collections_Collections
import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs
import third_party_objective_c_material_components_ios_components_Dialogs_ColorThemer
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Snackbar_Snackbar
import third_party_sciencejournal_ios_ScienceJournalProtos

protocol ObserveViewControllerDelegate: class {
  /// Tells the delegate recording started.
  func observeViewControllerDidStartRecording(_ observeViewController: ObserveViewController)

  /// Tells the delegate recording stopped.
  func observeViewControllerDidEndRecording(_ observeViewController: ObserveViewController)

  /// Tells the delegate sensor snapshots were created.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didCreateSensorSnapshots sensorSnapshots: [SensorSnapshot])

  /// Tells the delegate a trigger note was received.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didReceiveNoteTrigger trigger: SensorTrigger,
                             forSensor sensor: Sensor,
                             atTimestamp timestamp: Int64)

  /// Tells the delegate a trial began recording.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didBeginTrial trial: Trial)

  /// Tells the delegate a trial was updated.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didUpdateTrial trial: Trial,
                             isFinishedRecording: Bool)

  /// Tells the delegate a trial recording was cancelled.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didCancelTrial trial: Trial)

  /// Tells the delegate set triggers was pressed for a sensor.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didPressSetTriggersForSensor sensor: Sensor)

  /// Asks the delegate if a sensor trigger is active.
  func observeViewController(_ observeViewController: ObserveViewController,
                             isSensorTriggerActive sensorTrigger: SensorTrigger) -> Bool

  /// Tells the delegate sensor layouts were updated.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didUpdateSensorLayouts sensorLayouts: [SensorLayout])

  /// Tells the delegate sensor settings was pressed for a sensor.
  func observeViewControllerDidPressSensorSettings(_ observeViewController: ObserveViewController)

  /// Tells the delegate a sensor exceeded the maximum allowed trigger fire limit.
  func observeViewController(_ observeViewController: ObserveViewController,
                             didExceedTriggerFireLimitForSensor sensor: Sensor)

}

// swiftlint:disable type_body_length
// TODO: Consider breaking into multiple files for each delegate.
/// Manages the view that displays sensor data, both for observing and recording.
open class ObserveViewController: ScienceJournalCollectionViewController, ChartControllerDelegate,
                                  DrawerItemViewController, DrawerPositionListener,
                                  ObserveDataSourceDelegate, ObserveFooterCellDelegate,
                                  SensorCardCellDelegate, TimeAxisControllerDelegate,
                                  RecordingManagerDelegate {

  // MARK: - Constants

  let cellGap: CGFloat = 10.0
  let jumpToNowTrailingConstantHidden: CGFloat = 65
  let jumpToNowTrailingConstantVisible: CGFloat = -14
  let jumpToNowAnimationDuration: TimeInterval = 0.8
  let SensorCellIdentifier = "SensorCell"
  let FooterCellIdentifier = "FooterCell"
  var chartTimeAxisInsets: UIEdgeInsets {
    let sideInset = cellHorizontalInset / 2
    let chartYAxisInset = ChartView.yLabelWidth
    return UIEdgeInsets(top: 0, left: sideInset + chartYAxisInset, bottom: 0, right: sideInset)
  }
  /// Record button view.
  let recordButtonView = RecordButtonView(frame: .zero)
  let recordingTimerView = TimerView()

  // MARK: - Properties

  let observeDataSource: ObserveDataSource
  let timeAxisController = TimeAxisController(style: .observe)
  let recordingManager: RecordingManager
  var recordingTrial: Trial?
  let sensorController: SensorController
  @objc dynamic private(set) var isContentOutsideOfSafeArea: Bool = false

  // TODO: Refactor this out by more logically enabling/disabling the brightness listener.
  // http://b/64401602
  /// Is there a brightness listener in use?
  private var brightnessListenerExists: Bool = false

  /// The delegate.
  weak var delegate: ObserveViewControllerDelegate?

  /// Sensor triggers for the experiment.
  var sensorTriggers = [SensorTrigger]() {
    didSet {
      recordingManager.removeAllTriggers()
      for trigger in activeSensorTriggers {
        if let sensor = sensorController.sensor(for: trigger.sensorID) {
          recordingManager.add(trigger: trigger, forSensor: sensor)
        }
      }

      // Update sensor cards for whether or not they need a visual trigger view, and if a change is
      // made to visible cells, invalidate the collection view layout and layout the view.
      if updateSensorCardsForVisualTriggers(whileRecording: recordingManager.isRecording) {
        invalidateCollectionView(andLayoutIfNeeded: true)
      }
    }
  }

  /// The sensor triggers that are currently active for the experiment.
  var activeSensorTriggers: [SensorTrigger] {
    guard let delegate = self.delegate else { return [] }
    return sensorTriggers.filter { delegate.observeViewController(self, isSensorTriggerActive: $0) }
  }

  /// Are we recording?
  var isRecording: Bool {
    return recordingManager.isRecording
  }

  private var drawerPanner: DrawerPanner?
  private var backgroundRecordingTaskID: UIBackgroundTaskIdentifier?
  private var backgroundRecordingTimer: Timer?
  private var recordingSaveTimer: Timer?
  private var shouldNotifyUserIfBackgroundRecordingWillEnd = false
  private let jumpToNowButton = JumpToNowButton()
  private var jumpToNowTrailingConstraint: NSLayoutConstraint?
  private let recordButtonViewWrapper = UIView()
  private var recordButtonViewWrapperHeightConstraint: NSLayoutConstraint?
  private let preferenceManager: PreferenceManager

  /// The interval in which recorded data is saved while recoridng, in seconds.
  private let saveInterval: TimeInterval = 5

  // The audio and brightness sensor background message alert, stored so that it can be dismissed if
  // it is still on screen when a recording stopped alert shows in `applicationWillResignActive()`.
  private var audioAndBrightnessSensorBackgroundMessageAlert: MDCAlertController?

  /// Sensor layouts used for the setup of the sensor cards.
  private var sensorLayouts: [SensorLayout] {
    return observeDataSource.items.compactMap { $0.sensorLayout }
  }

  /// The available sensors for the current experiment.
  private var availableSensorIDs: [String] {
    return self.observeDataSource.availableSensorIDs
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: An AnalyticsReporter.
  ///   - preferenceManager: The preference manager.
  ///   - sensorController: The sensor controller.
  ///   - sensorDataManager: The sensor data manager.
  public init(analyticsReporter: AnalyticsReporter,
              preferenceManager: PreferenceManager,
              sensorController: SensorController,
              sensorDataManager: SensorDataManager) {
    self.preferenceManager = preferenceManager
    self.sensorController = sensorController
    self.recordingManager = RecordingManager(sensorDataManager: sensorDataManager)
    observeDataSource = ObserveDataSource(sensorController: sensorController)
    observeDataSource.shouldShowFooterAddButton = FeatureFlags.isActionAreaEnabled == false

    let flowLayout = MDCCollectionViewFlowLayout()
    flowLayout.minimumLineSpacing = SensorCardCell.cardInsets.bottom
    super.init(collectionViewLayout: flowLayout, analyticsReporter: analyticsReporter)

    observeDataSource.delegate = self

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillResignActive),
                                           name: UIApplication.willResignActiveNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationDidBecomeActive),
                                           name: UIApplication.didBecomeActiveNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillTerminate),
                                           name: UIApplication.willTerminateNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(localNotificationManagerDidReceiveStopRecordingAction),
        name: LocalNotificationManager.DidReceiveStopRecordingAction,
        object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(accessibilityVoiceOverStatusChanged),
        name: UIAccessibility.voiceOverStatusDidChangeNotification,
        object: nil)

    // If a user will be signed out, this notification will be fired.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(forceEndRecordingForSignOut),
                                           name: .userWillBeSignedOut,
                                           object: nil)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  /// Adds the note to all recording charts.
  ///
  /// - Parameter note: A display note.
  func addNoteToCharts(_ note: DisplayNote) {
    guard recordingTrial != nil else { return }
    observeDataSource.enumerateChartControllers { $0.addNote(note) }
    timeAxisController.addNoteDotAtTimestamp(note.timestamp.milliseconds)
  }

  /// This should be called when observe will no longer be used by an experiment for input. To
  /// enable observing again either call `addListenersForAllSensorCards()` or set new sensor
  /// layouts with listeners.
  func prepareForReuse() {
    removeAllSensorListeners()
  }

  // MARK: - View lifecycle

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(SensorCardCell.self, forCellWithReuseIdentifier: SensorCellIdentifier)
    collectionView?.register(ObserveFooterCell.self,
                             forCellWithReuseIdentifier: FooterCellIdentifier)

    recordingManager.delegate = self

    styler.cellStyle = .default
    MDCAlertColorThemer.apply(ViewConstants.alertColorScheme)

    collectionView?.backgroundColor = .white
    if FeatureFlags.isActionAreaEnabled {
      collectionView?.contentInsetAdjustmentBehavior = .automatic
    } else {
      collectionView?.contentInsetAdjustmentBehavior = .never
    }
    collectionView?.panGestureRecognizer.addTarget(
        self,
        action: #selector(handleCollectionViewPanGesture(_:)))

    timeAxisController.delegate = self
    timeAxisController.listener = { [weak self] visibleXAxis, dataXAxis, sourceChartController in
      guard let strongSelf = self else { return }
      strongSelf.observeDataSource.enumerateChartControllers {
        // Only update chart controller if `chartController` not equal the current controller.
        // This prevents interaction loops when the change is initiated by one of the enumerated
        // chart controllers.
        if sourceChartController != $0 {
          $0.setXAxis(visibleXAxis: visibleXAxis, dataXAxis: dataXAxis)
        }
        // Let chart know whether it is pinned or not.
        $0.chartOptions.isPinnedToNow = strongSelf.timeAxisController.isPinnedToNow
      }
    }

    // Record button view.
    recordButtonView.snapshotButton.addTarget(self,
                                              action: #selector(snapshotButtonPressed),
                                              for: .touchUpInside)
    recordButtonView.recordButton.addTarget(self,
                                            action: #selector(recordButtonPressed),
                                            for: .touchUpInside)
    recordButtonView.translatesAutoresizingMaskIntoConstraints = false
    recordButtonViewWrapper.addSubview(recordButtonView)
    recordButtonView.topAnchor.constraint(
        equalTo: recordButtonViewWrapper.topAnchor).isActive = true
    recordButtonView.leadingAnchor.constraint(
        equalTo: recordButtonViewWrapper.leadingAnchor).isActive = true
    recordButtonView.trailingAnchor.constraint(
        equalTo: recordButtonViewWrapper.trailingAnchor).isActive = true

    recordButtonViewWrapper.backgroundColor = DrawerView.actionBarBackgroundColor
    recordButtonViewWrapper.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(recordButtonViewWrapper)
    recordButtonViewWrapper.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    recordButtonViewWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    recordButtonViewWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    recordButtonViewWrapperHeightConstraint =
        recordButtonViewWrapper.heightAnchor.constraint(equalTo: recordButtonView.heightAnchor)
    recordButtonViewWrapperHeightConstraint?.isActive = true
    // TODO: Just hiding this so it will still work w/o the AA flag, but should probably be removed
    // at the time of The Big Delete of the old UI.
    recordButtonViewWrapper.isHidden = FeatureFlags.isActionAreaEnabled

    // Time axis view.
    addChild(timeAxisController)
    let axisView = timeAxisController.timeAxisView
    axisView.alpha = 0  // Initially, the axis view is hidden.
    axisView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(axisView)
    axisView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    axisView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    if FeatureFlags.isActionAreaEnabled {
      axisView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    } else {
      axisView.bottomAnchor.constraint(equalTo: recordButtonViewWrapper.topAnchor).isActive = true
    }

    // Jump to now button
    jumpToNowButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(jumpToNowButton)
    let trailingConstraint =
        jumpToNowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: jumpToNowTrailingConstantHidden)
    trailingConstraint.isActive = true
    jumpToNowTrailingConstraint = trailingConstraint
    jumpToNowButton.bottomAnchor.constraint(equalTo: axisView.topAnchor,
                                            constant: -14).isActive = true
    jumpToNowButton.addTarget(self, action: #selector(jumpToNowButtonPressed), for: .touchUpInside)

    updateNavigationItems()

    // Adjust the content insets of the view based on action bar and time axis.
    adjustContentInsets()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Update sensors for any cells showing the sensor picker as available sensors may have changed.
    updateSensorPickersIfNeeded()

    // This is the earliest point the chart axis report the correct value.
    timeAxisController.chartTimeAxisInsets = chartTimeAxisInsets

    // Reset data and time axis for all charts if not recording.
    if !recordingManager.isRecording {
      observeDataSource.enumerateChartControllers { $0.resetData() }
      timeAxisController.resetAxisToDefault()
      timeAxisController.isPinnedToNow = true
    }

    updateCollectionViewScrollEnabled()
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updateBrightnessSensorListenerIfNecessary(viewVisible: true)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    updateBrightnessSensorListenerIfNecessary(viewVisible: false)
  }

  override open func viewWillTransition(to size: CGSize,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil, completion: { (_) in
      self.timeAxisController.chartTimeAxisInsets = self.chartTimeAxisInsets
    })
  }

  override open var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override open func viewSafeAreaInsetsDidChange() {
    recordButtonViewWrapperHeightConstraint?.constant = view.safeAreaInsetsOrZero.bottom
    adjustContentInsets()
  }

  // Updates the listener for a brightness sensor if one exists and we're not in record mode. This
  // allows the brightness sensor to be paused when not recording, which means the camera can be
  // used to take images.
  private func updateBrightnessSensorListenerIfNecessary(viewVisible: Bool) {
    guard !isRecording else { return }
    observeDataSource.items.forEach { card in
      guard card.sensor is BrightnessSensor else { return }
      if viewVisible && !brightnessListenerExists {
        addListener(forSensorCard: card)
      } else if !viewVisible {
        removeListener(forSensorCard: card)
      }
    }
  }

  // MARK: - Alerts

  /// Presents an alert controller with a message.
  ///
  /// - Parameters:
  ///   - title: The title of the alert. Optional.
  ///   - message: The message to show.
  ///   - dismissTitle: Optional alternative title for the dismiss button, "OK" if not set.
  @discardableResult private func showAlert(withTitle title: String?,
                                            message: String,
                                            dismissTitle: String? = nil) -> MDCAlertController {
    let alert = MDCAlertController(title: title, message: message)
    let cancelAction = MDCAlertAction(title: dismissTitle ?? String.actionCancel)
    alert.addAction(cancelAction)
    present(alert, animated: true)
    return alert
  }

  // MARK: - User actions

  @objc func snapshotButtonPressed() {
    func createSnapshots() {
      let sensorSnapshots = recordingManager.sensorSnapshots
      guard sensorSnapshots.count == self.observeDataSource.items.count else {
        // Not all sensors provided a snapshot, show a toast alert.
        let message = MDCSnackbarMessage()
        message.text = String.snapshotFailedDisconnected
        MDCSnackbarManager.setButtonTitleColor(MDCPalette.yellow.tint200, for: .normal)
        MDCSnackbarManager.show(message)
        return
      }
      self.delegate?.observeViewController(self, didCreateSensorSnapshots: sensorSnapshots)
    }

    // If the drawer will be animating, create the snapshots after the animation completes.
    if let drawerViewController = drawerViewController {
      drawerViewController.minimizeFromFull(completion: {
        createSnapshots()
      })
    } else {
      createSnapshots()
    }
  }

  @objc func recordButtonPressed() {
    if !recordingManager.isRecording {
      guard recordingManager.isReady else {
        let alertController =
            MDCAlertController(title: String.recordingStartFailed,
                               message: String.recordingStartFailedSensorDisconnected)
        alertController.addAction(MDCAlertAction(title: String.actionOk))
        present(alertController, animated: true)
        return
      }

      startRecording()
      timeAxisController.isPinnedToNow = true
      drawerViewController?.setPositionToFull()
    } else {
      // If data is missing from at least one sensor, prompt the user to cancel or
      // continue recording.
      guard !recordingManager.isRecordingMissingData else {
        let alertController = MDCAlertController(title: String.recordingStopFailedNoDataTitle,
                                                 message: String.recordingStopFailedNoData)
        let cancelAction = MDCAlertAction(title: String.recordingStopFailedCancel) { (_) in
          self.endRecording(isCancelled: true)
        }
        let continueAction = MDCAlertAction(title: String.recordingStopFailedContinue,
                                            handler: nil)
        alertController.addAction(continueAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)

        return
      }

      endRecording()
      drawerViewController?.minimizeFromFull()

      // Increment the successful recording count.
      RatingsPromptManager.shared.incrementSuccessfulRecordingCount()
    }
  }

  /// Creates a trial and begins recording sensor data.
  func startRecording() {
    // Cannot start recording a trial if one is already in progress.
    guard recordingTrial == nil else {
      return
    }

    for card in observeDataSource.items where card.sensor is BrightnessSensor {
      CaptureSessionInterruptionObserver.shared.isBrightnessSensorInUse = true
      break
    }

    beginBackgroundRecordingTask()

    // Show the time axis view.
    showTimeAxisView(true)

    // Create a trial.
    let trial = Trial()
    recordingTrial = trial

    // Remove the add sensor card button if it is being shown (if all sensors have cards, it
    // wouldn't be shown).
    if let footerIndexPath = observeDataSource.footerIndexPath {
      observeDataSource.shouldShowFooterAddButton = false
      collectionView?.deleteSections(IndexSet(integer: footerIndexPath.section))
    }

    resetCalculators()
    recordingManager.startRecording(trialID: trial.ID)

    recordingSaveTimer = Timer.scheduledTimer(timeInterval: saveInterval,
                                     target: self,
                                     selector: #selector(recordingSaveTimerFired),
                                     userInfo: nil,
                                     repeats: true)

    delegate?.observeViewControllerDidStartRecording(self)
    trial.recordingRange.min = recordingManager.recordingStartDate!

    // Do an initial update so that if the app terminates before the recording save timer fires, the
    // trial has semi-valid data.
    updateRecordingTrial(isFinishedRecording: false)

    delegate?.observeViewController(self, didBeginTrial: trial)

    for sensorCard in observeDataSource.items {
      sensorCard.chartController.recordingStartTime = recordingManager.recordingStartDate
      if let sensorLayout = sensorCard.sensorLayout, sensorLayout.shouldShowStatsOverlay {
        sensorCard.chartController.shouldShowStats = true
      }

      if (sensorCard.sensor is AudioSensor || sensorCard.sensor is BrightnessSensor) &&
          !preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage {
        audioAndBrightnessSensorBackgroundMessageAlert =
            showAlert(withTitle: String.sensorTypeBackgroundIssueDialogTitle,
                      message: String.sensorTypeAudioAndBrightnessBackgroundMessage,
                      dismissTitle: String.actionConfirmCasual)
        preferenceManager.hasUserSeenAudioAndBrightnessSensorBackgroundMessage = true
      }
    }

    timeAxisController.recordingStartTime = recordingManager.recordingStartDate
    recordButtonView.recordButton.isSelected = true

    updateCellsToRecord(true)
    updateNavigationItems()
  }

  /// Ends a recording, which will stop writing data to the database and create a completed trial
  /// with layouts and stats if appropriate.
  ///
  /// - Parameters:
  ///   - isCancelled: True if the recording was cancelled, otherwise false. Default is false.
  ///   - removeCancelledData: True if data from a cancelled recording should be removed, otherwise
  ///                          false (data is left in the database). Only has impact if
  ///                          `isCancelled` is true. Default is true.
  func endRecording(isCancelled: Bool = false, removeCancelledData: Bool = true) {
    guard recordingTrial != nil else {
      print("[ObserveViewController] Recording ended with no valid recording trial.")
      return
    }

    CaptureSessionInterruptionObserver.shared.isBrightnessSensorInUse = false

    updateCellsToRecord(false)

    // Hide the time axis view.
    showTimeAxisView(false)

    // Stop the recorder.
    recordingManager.endRecording(isCancelled: isCancelled,
                                  removeCancelledData: removeCancelledData)
    recordingSaveTimer?.invalidate()
    recordingSaveTimer = nil
    delegate?.observeViewControllerDidEndRecording(self)

    // Show the add sensor card button if it should be (if all sensors have cards, it shouldn't be
    // shown).
    observeDataSource.shouldShowFooterAddButton = FeatureFlags.isActionAreaEnabled == false
    if let footerIndexPath = observeDataSource.footerIndexPath {
      collectionView?.insertSections(IndexSet(integer: footerIndexPath.section))
    }

    // If the recording was not cancelled, configure the new trial. If it was cancelled and we
    // need to remove data, do that now instead.
    if !isCancelled {
      updateRecordingTrial(isFinishedRecording: true)
    } else if removeCancelledData {
      cancelAndRemoveRecordingTrial()
    }

    observeDataSource.enumerateChartControllers { (chartController) in
      chartController.recordingStartTime = nil
      chartController.shouldShowStats = false
      chartController.removeAllNotes()
    }

    timeAxisController.recordingStartTime = nil
    timeAxisController.removeAllNoteDots()
    recordButtonView.recordButton.isSelected = false
    recordButtonView.timerLabel.text = nil

    updateNavigationItems()

    endBackgroundRecordingTask()
  }

  @objc private func jumpToNowButtonPressed() {
    timeAxisController.isPinnedToNow = true
  }

  // MARK: - Changing sensors in cells

  // Loops through visible cells and updates their sensor pickers, if they're showing. This is
  // useful when first loading this VC or for when a user comes back from a modal that might change
  // available sensors.
  private func updateSensorPickersIfNeeded() {
    if let visibleCells = collectionView?.visibleCells {
      visibleCells.forEach { (cell) in
        guard let indexPath = collectionView?.indexPath(for: cell),
          let cell = cell as? SensorCardCell,
          observeDataSource.item(
              at: indexPath.item).cellState.options.contains(.sensorPickerVisible) else { return }
        cell.updateSensorPicker()
      }
    }
  }

  func removeListener(forSensorCard sensorCard: SensorCard) {
    let sensor = sensorCard.sensor
    do {
      try recordingManager.removeListener(for: sensor)
      if sensor is BrightnessSensor {
        brightnessListenerExists = false
      }
    } catch {
      print("Error removing listener \(error.localizedDescription)")
    }
  }

  func addListener(forSensorCard sensorCard: SensorCard) {
    let sensor = sensorCard.sensor

    if sensor is BrightnessSensor && !isViewVisible {
      // The brightness sensor should only have a listener added if the view is visible. This is
      // necessary for the camera to take pictures. The brightness sensor will have a listener
      // added in viewDidAppear.
      return
    }

    sensorCard.chartController.resetData()

    recordingManager.addListener(
        forSensor: sensor,
        triggers: activeSensorTriggers.filter { $0.sensorID == sensor.sensorId },
        using: { [weak self] (dataPoint) in

      var sensorCardCell: SensorCardCell?
      if let indexPath = self?.observeDataSource.indexPathForItem(sensorCard) {
        sensorCardCell = self?.collectionView?.cellForItem(at: indexPath) as? SensorCardCell
      }

      sensorCard.chartController.addDataPointToEnd(dataPoint)
      let visibleYAxis = sensorCard.chartController.visibleYAxis
      if let cell = sensorCardCell {
        cell.currentValueView.textLabel.text = sensor.string(for: dataPoint.y, withUnits: true)
        cell.currentValueView.setAnimatingIconValue(dataPoint.y,
                                                    minValue: visibleYAxis.min,
                                                    maxValue: visibleYAxis.max)
      }

      sensorCard.toneGenerator.setToneFrequency(for: dataPoint.y,
                                                valueMin: visibleYAxis.min,
                                                valueMax: visibleYAxis.max,
                                                atTimestamp: dataPoint.x)
      // Only add a value to the calculator if a trial is recording.
      if let recordingManager = self?.recordingManager, recordingManager.isRecording {
        sensorCard.statCalculator.addDataPoint(dataPoint)

        if let min = sensorCard.statCalculator.minimum,
            let max = sensorCard.statCalculator.maximum,
            let average = sensorCard.statCalculator.average {
          sensorCard.chartController.setStats(min: min,
                                              max: max,
                                              average: average)

          if let cell = sensorCardCell {
            cell.statsView.setMin(sensor.string(for: min),
                                  average: sensor.string(for: average),
                                  max: sensor.string(for: max))
          }
        }
      }
    })

    if sensor is BrightnessSensor {
      brightnessListenerExists = true
    }
  }

  /// Removes all sensor listeners.
  func removeAllSensorListeners() {
    for sensorCard in observeDataSource.items {
      sensorCard.toneGenerator.stop()
      removeListener(forSensorCard: sensorCard)
      observeDataSource.endUsingSensor(sensorCard.sensor)
    }
  }

  /// Adds listeners for all sensor cards.
  func addListenersForAllSensorCards() {
    // Track the previous footer path, if it existed.
    let previousFooterIndexPath = observeDataSource.footerIndexPath

    for sensorCard in observeDataSource.items {
      observeDataSource.beginUsingSensor(sensorCard.sensor)
      addListener(forSensorCard: sensorCard)
      if let sensorLayout = sensorCard.sensorLayout, sensorLayout.isAudioEnabled {
        sensorCard.toneGenerator.start()
      }
    }

    // If the footer was showing, is still showing, and should no longer show, remove it.
    if collectionView?.numberOfSections == 2 && observeDataSource.footerIndexPath == nil,
        let previousFooterIndexPath = previousFooterIndexPath {
      collectionView?.deleteSections(IndexSet(integer: previousFooterIndexPath.section))
    }
  }

  // MARK: - Helpers

  private func removeSensorCardFromDataSource(_ sensorCard: SensorCard) {
    observeDataSource.removeItem(sensorCard)
    removeSensorLayoutForSensorCard(sensorCard)
    removeListener(forSensorCard: sensorCard)
    observeDataSource.endUsingSensor(sensorCard.sensor)
    sensorCard.toneGenerator.stop()
  }

  private func removeSensorCardCell(_ cell: SensorCardCell) {
    guard let indexPath = collectionView?.indexPath(for: cell) else {
      return
    }

    let previousFooterPath = observeDataSource.footerIndexPath

    // Update the dataSource.
    let sensorCard = observeDataSource.item(at: indexPath.item)
    removeSensorCardFromDataSource(sensorCard)

    collectionView?.performBatchUpdates({
      // Delete the cell.
      self.collectionView?.deleteItems(at: [indexPath])

      if previousFooterPath == nil {
        if let newFooterPath = self.observeDataSource.footerIndexPath {
          // Footer was not visible before but is now, insert it.
          self.collectionView?.insertSections(IndexSet(integer: newFooterPath.section))
        }
      }
    }, completion: { (_) in
      self.updateSensorPickersIfNeeded()
      // TODO: Show/Enable the "Add Sensor" button if needed
    })
  }

  func addNewSensorCardCell() {
    // Track the previous footer path, if it existed.
    let previousFooterIndexPath = observeDataSource.footerIndexPath

    guard let newSensorCard = observeDataSource.sensorCardWithNextSensor() else {
      return
    }

    configureSensorCard(newSensorCard, andAddListener: true)
    addSensorLayoutForSensorCard(newSensorCard)

    let newItemIndexPath = observeDataSource.lastCardIndexPath
    let indexPathsOfSensorPickersToHide =
        [Int](0..<newItemIndexPath.item).map { IndexPath(item: $0, section: 0) }

    collectionView?.performBatchUpdates({
      self.hideSensorPickers(at: indexPathsOfSensorPickersToHide)
      self.collectionView?.insertItems(at: [newItemIndexPath])

      // If the footer should no longer show, remove it.
      if self.observeDataSource.footerIndexPath == nil,
          let previousFooterIndexPath = previousFooterIndexPath {
        self.collectionView?.deleteSections(IndexSet(integer: previousFooterIndexPath.section))
      }
    }, completion: { (_) in
      // TODO: Hide/Disable the "Add Sensor" button.
    })
    collectionView?.scrollToItem(at: IndexPath(item: newItemIndexPath.item, section: 0),
                                 at: .top,
                                 animated: true)
  }

  /// Hides the sensor picker for sensor cards at index paths.
  ///
  /// - Parameter indexPaths: The index paths of cells at which to hide the sensor picker.
  func hideSensorPickers(at indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      let cellData = observeDataSource.item(at: indexPath.item)
      cellData.cellState.options.remove(.sensorPickerVisible)
      if let sensorCell = collectionView?.cellForItem(at: indexPath) as? SensorCardCell {
        sensorCell.setStateOptions(cellData.cellState.options, animated: true)
      }
    }
  }

  // Called when starting and stopping recording, tells all items in the data source to change to
  // or from record mode and updates cells on screen animated.
  private func updateCellsToRecord(_ recording: Bool) {
    for (index, sensorCard) in observeDataSource.items.enumerated() {
      if recording {
        sensorCard.cellState.options.remove(.sensorPickerVisible)
        sensorCard.cellState.options.insert(.statsViewVisible)
      } else {
        sensorCard.cellState.options.remove(.statsViewVisible)
        if index == observeDataSource.items.endIndex - 1 {
          sensorCard.cellState.options.insert(.sensorPickerVisible)
        }
      }
      let indexPath = IndexPath(item: index, section: 0)
      if let sensorCell = collectionView?.cellForItem(at: indexPath) as? SensorCardCell {
        sensorCell.setStateOptions(sensorCard.cellState.options, animated: true)
      }
    }
    updateSensorCardsForVisualTriggers(whileRecording: recording)
    invalidateCollectionView()
  }

  func configureSensorCard(_ sensorCard: SensorCard,
                           withSensorLayout sensorLayout: SensorLayout? = nil,
                           andAddListener shouldAddListener: Bool) {
    if shouldAddListener {
      observeDataSource.beginUsingSensor(sensorCard.sensor)
      addListener(forSensorCard: sensorCard)
    }

    sensorCard.chartController.setXAxis(visibleXAxis: timeAxisController.visibleXAxis,
                                        dataXAxis: timeAxisController.dataXAxis)
    sensorCard.chartController.delegate = self

    // If the sensor card has a layout, configure the sensor card to match it. Otherwise, create a
    // layout for the card.
    if let sensorLayout = sensorLayout {
      if shouldAddListener && sensorLayout.isAudioEnabled {
        sensorCard.toneGenerator.start()
      }
      sensorCard.chartController.shouldShowStats = sensorLayout.shouldShowStatsOverlay
      sensorCard.sensorLayout = SensorLayout(proto: sensorLayout.proto)
    } else {
      addSensorLayoutForSensorCard(sensorCard)
    }
  }

  // Adjust collection view insets for the record button view and time axis view.
  func adjustContentInsets() {
    if FeatureFlags.isActionAreaEnabled {
      let topInset = timeAxisController.timeAxisView.alpha > 0 ?
        timeAxisController.timeAxisView.systemLayoutSizeFitting(
          UIView.layoutFittingCompressedSize).height : 0
      collectionView?.contentInset.top = topInset
      collectionView?.scrollIndicatorInsets.top = topInset
    } else {
      var bottomInset =
        recordButtonViewWrapper.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      if timeAxisController.timeAxisView.alpha > 0 {
        bottomInset += timeAxisController.timeAxisView.systemLayoutSizeFitting(
          UIView.layoutFittingCompressedSize).height
      }
      collectionView?.contentInset.bottom = bottomInset
      collectionView?.scrollIndicatorInsets.bottom = bottomInset
    }
  }

  // Animates the display of the time axis view.
  func showTimeAxisView(_ isVisible: Bool) {
    UIView.animate(withDuration: 0.5, animations: {
      self.timeAxisController.timeAxisView.alpha = isVisible ? 1 : 0
    }) { (_) in
      self.adjustContentInsets()
    }
  }

  // Resets all sensor card calculators.
  func resetCalculators() {
    for sensorCard in observeDataSource.items {
      sensorCard.statCalculator.reset()
    }
  }

  @objc private func setCollectionViewContentOffsetToZero() {
    collectionView?.setContentOffset(.zero, animated: true)
  }

  private func updateSensorsForAvailableSensorIDs(andAddListener shouldAddListener: Bool) {
    let observeItems = observeDataSource.items
    for sensorCard in observeItems {
      if !availableSensorIDs.contains(sensorCard.sensor.sensorId) {
        removeSensorCardFromDataSource(sensorCard)
      }
    }

    addInitialSensorCardIfNeeded(andAddListener: shouldAddListener)

    collectionView?.reloadData()
  }

  // If there are no observe data source items, add an initial sensor card. Exposed for testing.
  func addInitialSensorCardIfNeeded(andAddListener shouldAddListener: Bool) {
    if observeDataSource.items.isEmpty,
        let firstSensorCard = observeDataSource.sensorCardWithNextSensor() {
      configureSensorCard(firstSensorCard, andAddListener: shouldAddListener)
    }
  }

  @objc private func recordingSaveTimerFired() {
    recordingManager.save()
    updateRecordingTrial(isFinishedRecording: false)
  }

  private func updateRecordingTrial(isFinishedRecording: Bool) {
    guard let recordingTrial = recordingTrial else { return }

    // Set the recording end timestamp.
    recordingTrial.recordingRange.max = Date().millisecondsSince1970

    // Remove previous stats and sensor appearances.
    recordingTrial.trialStats.removeAll()
    recordingTrial.removeAllSensorAppearances()

    for sensor in recordingManager.recordingSensors {
      // Assemble trial stats.
      let sensorTrialStats = TrialStats(sensorID: sensor.sensorId)

      // Add trial stats from the sensorCard.statCalculator
      if let sensorCard = observeDataSource.sensorCard(for: sensor) {
        sensorTrialStats.addStatsFromStatCalculator(sensorCard.statCalculator)
      }

      // Add trial stats from the zoom recorder.
      if let recorder = recordingManager.recorder(forSensorID: sensor.sensorId) {
        sensorTrialStats.zoomPresenterTierCount = recorder.zoomTierCount
        sensorTrialStats.zoomLevelBetweenTiers = Recorder.zoomLevelBetweenTiers
      }

      recordingTrial.trialStats.append(sensorTrialStats)
      recordingTrial.addSensorAppearance(BasicSensorAppearance(sensor: sensor),
                                         for: sensor.sensorId)
    }
    recordingTrial.sensorLayouts = sensorLayouts

    // Clear recording trial before notifying delegate since the existence of the recording trial
    // can indicate a recording is in progress.
    if isFinishedRecording {
      self.recordingTrial = nil
    }

    delegate?.observeViewController(self,
                                    didUpdateTrial: recordingTrial,
                                    isFinishedRecording: isFinishedRecording)
  }

  private func cancelAndRemoveRecordingTrial() {
    guard let recordingTrial = recordingTrial else {
      return
    }
    self.recordingTrial = nil
    delegate?.observeViewController(self, didCancelTrial: recordingTrial)
  }

  private func updateCollectionViewScrollEnabled() {
    // The collection view scrolling should be disabled when in a drawer, unless voiceover mode is
    // running or the drawer is open full.
    var shouldEnableScroll: Bool {
      guard let drawerViewController = drawerViewController else { return true }
      return drawerViewController.isOpenFull || UIAccessibility.isVoiceOverRunning
    }

    collectionView?.isScrollEnabled = shouldEnableScroll
  }

  /// Sets the densor layouts used for the setup of the sensor cards.
  func setSensorLayouts(_ sensorLayouts: [SensorLayout], andAddListeners: Bool) {
    observeDataSource.removeAllItems()

    for sensorLayout in sensorLayouts {
      var cellStateOptions: SensorCardCell.State.Options =
          sensorLayout.sensorID == sensorLayouts.last?.sensorID ? .showingSensorPicker : .normal
      guard let sensor = sensorController.sensor(for: sensorLayout.sensorID),
          sensor.isSupported else { continue }
      if sensorHasVisualTriggers(sensor, forRecording: recordingManager.isRecording) {
        cellStateOptions.insert(.visualTriggersVisible)
      }
      let sensorCard =
          observeDataSource.sensorCardWithSensor(sensor,
                                                 cardColorPalette: sensorLayout.colorPalette,
                                                 cellStateOptions: cellStateOptions)

      configureSensorCard(sensorCard,
                          withSensorLayout: sensorLayout,
                          andAddListener: andAddListeners)
    }

    addInitialSensorCardIfNeeded(andAddListener: andAddListeners)

    collectionView?.reloadData()
  }

  /// Sets the available sensors for the current experiment.
  func setAvailableSensorIDs(_ availableSensorIDs: [String], andAddListeners: Bool) {
    if availableSensorIDs != self.availableSensorIDs {
      self.observeDataSource.availableSensorIDs = availableSensorIDs
      updateSensorsForAvailableSensorIDs(andAddListener: andAddListeners)
    }
  }

  /// The visual triggers to show for a sensor.
  ///
  /// - Parameters:
  ///   - sensor: The sensor.
  ///   - recording: Whether or not the sensor is being recorded. Used to filter triggers that
  ///                should fire only when recording.
  /// - Returns: The visual triggers to show.
  func visualTriggers(_ sensor: Sensor, forRecording isRecording: Bool) -> [SensorTrigger] {
    return activeSensorTriggers.filter {
      $0.sensorID == sensor.sensorId && $0.isVisualTrigger &&
          (isRecording || !isRecording && !$0.triggerInformation.triggerOnlyWhenRecording)
    }
  }

  /// Whether or not a sensor has visual triggers to show.
  ///
  /// - Parameters:
  ///   - sensor: The sensor.
  ///   - recording: Whether or not the sensor is being recorded. Used to filter triggers that
  ///                should fire only when recording.
  /// - Returns: Whether or not the sensor has visual triggers to show.
  func sensorHasVisualTriggers(_ sensor: Sensor, forRecording isRecording: Bool) -> Bool {
    return !visualTriggers(sensor, forRecording: isRecording).isEmpty
  }

  // Invalidates the collection view layout and optionally lays it out if needed.
  private func invalidateCollectionView(andLayoutIfNeeded layoutIfNeeded: Bool = false) {
    collectionView?.collectionViewLayout.invalidateLayout()
    if layoutIfNeeded {
      UIView.animate(withDuration: SensorCardCell.stateOptionsChangeAnimationDuration,
                     delay: 0,
                     options: SensorCardCell.stateOptionsChangeAnimationOptions,
                     animations: {
                       self.collectionView?.layoutIfNeeded()
      })
    }
  }

  /// Updates sensor cards and visible cells for whether or not they should show a visual trigger
  /// view.
  ///
  /// - Parameter isRecording: Whether or not sensors are being recorded. Filters out triggers that
  ///             should fire only while recording if needed.
  /// - Returns: Whether or not the collection view needs a layout update.
  @discardableResult func updateSensorCardsForVisualTriggers(
      whileRecording isRecording: Bool) -> Bool {
    var shouldLayoutCollectionView = false

    // Sets the cell's state options if it is visible, and marks `shouldLayoutCollectionView` as
    // true.
    func setStateOptionsAndLayoutIfNeeded(for sensorCard: SensorCard) {
      if let indexPath = observeDataSource.indexPathForItem(sensorCard),
          let cell = collectionView?.cellForItem(at: indexPath) as? SensorCardCell {
        cell.setStateOptions(sensorCard.cellState.options, animated: true)
        shouldLayoutCollectionView = true
      }
    }

    for sensorCard in observeDataSource.items {
      if sensorHasVisualTriggers(sensorCard.sensor, forRecording: isRecording) {
        if !sensorCard.cellState.options.contains(.visualTriggersVisible) {
          // If there should be a visual trigger view, but then sensor card doesn't have one, add
          // it. The collection view should be layed out.
          sensorCard.cellState.options.insert(.visualTriggersVisible)
          setStateOptionsAndLayoutIfNeeded(for: sensorCard)
        }

        // If the cell is on screen, give it the updated triggers.
        if let indexPath = observeDataSource.indexPathForItem(sensorCard),
            let cell = collectionView?.cellForItem(at: indexPath) as? SensorCardCell {
          let visualTriggersForSensor =
              visualTriggers(sensorCard.sensor, forRecording: recordingManager.isRecording)
          cell.visualTriggerView.setTriggers(visualTriggersForSensor, forSensor: sensorCard.sensor)
        }
      } else if !sensorHasVisualTriggers(sensorCard.sensor, forRecording: isRecording) &&
          sensorCard.cellState.options.contains(.visualTriggersVisible) {
        // If there should not be a visual trigger view and there is one, remove it. The collection
        // view should be layed out.
        sensorCard.cellState.options.remove(.visualTriggersVisible)
        setStateOptionsAndLayoutIfNeeded(for: sensorCard)
      }
    }
    return shouldLayoutCollectionView
  }

  private func showJumpToNowButton() {
    jumpToNowTrailingConstraint?.constant = jumpToNowTrailingConstantVisible
    let distance = jumpToNowTrailingConstantVisible - jumpToNowTrailingConstantHidden
    jumpToNowButton.animateRollRotationTransform(forDistance: distance,
                                                 duration: jumpToNowAnimationDuration)
  }

  private func hideJumpToNowButton() {
    jumpToNowTrailingConstraint?.constant = jumpToNowTrailingConstantHidden
    let distance = jumpToNowTrailingConstantHidden - jumpToNowTrailingConstantVisible
    jumpToNowButton.animateRollRotationTransform(forDistance: distance,
                                                 duration: jumpToNowAnimationDuration)
  }

  private func updateNavigationItems() {
    guard FeatureFlags.isActionAreaEnabled else { return }

    if isRecording {
      // Reset to 0 since we reuse the view and otherwise previous value lingers in UI momentarily.
      recordingTimerView.updateTimerLabel(with: 0)
      navigationItem.rightBarButtonItem = UIBarButtonItem(customView: recordingTimerView)
      title = String.actionAreaTitleRecording
    } else {
      // Settings button.
      let settingsButton = UIBarButtonItem(image: UIImage(named: "ic_settings"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(settingsButtonPressed))
      settingsButton.accessibilityLabel = String.titleActivitySensorSettings
      navigationItem.rightBarButtonItem = settingsButton
      title = String.actionAreaTitleAddSensorNote
    }
  }

  @objc private func settingsButtonPressed() {
    showSettings()
  }

  private func updateTimerLabel(with duration: Int64) {
    if FeatureFlags.isActionAreaEnabled {
      recordingTimerView.updateTimerLabel(with: duration)
    } else {
      recordButtonView.updateTimerLabel(with: duration)
    }
  }

  private func showSettings() {
    delegate?.observeViewControllerDidPressSensorSettings(self)
  }

  // MARK: - Sensor layouts

  private func addSensorLayoutForSensorCard(_ sensorCard: SensorCard) {
    let sensorLayout = SensorLayout(sensorID: sensorCard.sensor.sensorId,
                                    colorPalette: sensorCard.colorPalette)
    sensorLayout.isAudioEnabled = sensorCard.toneGenerator.isPlayingTone
    sensorCard.sensorLayout = sensorLayout
    delegate?.observeViewController(self, didUpdateSensorLayouts: sensorLayouts)
  }

  func updateSensorLayouts() {
    for sensorCard in observeDataSource.items {
      guard let sensorLayout = sensorCard.sensorLayout else { continue }
      sensorLayout.isAudioEnabled = sensorCard.toneGenerator.isPlayingTone
      sensorLayout.sensorID = sensorCard.sensor.sensorId
      sensorLayout.shouldShowStatsOverlay = sensorCard.chartController.shouldShowStats
    }
    delegate?.observeViewController(self, didUpdateSensorLayouts: sensorLayouts)
  }

  private func removeSensorLayoutForSensorCard(_ sensorCard: SensorCard) {
    sensorCard.sensorLayout = nil
    delegate?.observeViewController(self, didUpdateSensorLayouts: sensorLayouts)
  }

  // MARK: - Background recording

  private func beginBackgroundRecordingTask() {
    backgroundRecordingTaskID = UIApplication.shared.beginBackgroundTask {
      // If background recording ends because it ran out of time, cancel the recording-will-end
      // notification and present a recording ended notification. Then end recording.
      LocalNotificationManager.shared.cancelRecordingWillEndNotification()
      LocalNotificationManager.shared.presentRecordingEndedNotification()
      // `endRecording()` calls `endBackgroundRecordingTask()`, which ends the background task.
      self.endRecording()
    }
    startBackgroundRecordingTimer()
  }

  private func endBackgroundRecordingTask() {
    if let backgroundRecordingTaskID = self.backgroundRecordingTaskID,
        backgroundRecordingTaskID != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundRecordingTaskID)
    }
    self.backgroundRecordingTaskID = .invalid
    stopBackgroundRecordingTimer()
  }

  private func startBackgroundRecordingTimer() {
    guard backgroundRecordingTimer == nil else { return }
    backgroundRecordingTimer =
        Timer.scheduledTimer(timeInterval: 1,
                             target: self,
                             selector: #selector(backgroundRecordingTimerFired),
                             userInfo: nil,
                             repeats: true)
    // Allows the timer to fire while scroll views are tracking.
    RunLoop.main.add(backgroundRecordingTimer!, forMode: .common)
  }

  private func stopBackgroundRecordingTimer() {
    backgroundRecordingTimer?.invalidate()
    backgroundRecordingTimer = nil
  }

  @objc private func backgroundRecordingTimerFired() {
    if UIApplication.shared.backgroundTimeRemaining < 60 {
      notifyUserBackgroundRecordingWillEnd()
    } else {
      shouldNotifyUserIfBackgroundRecordingWillEnd = true
    }
  }

  private func notifyUserBackgroundRecordingWillEnd() {
    guard shouldNotifyUserIfBackgroundRecordingWillEnd else { return }
    shouldNotifyUserIfBackgroundRecordingWillEnd = false
    LocalNotificationManager.shared.presentRecordingWillEndNotification()
  }

  // MARK: - UICollectionViewDataSource

  override open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return observeDataSource.numberOfSections
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    numberOfItemsInSection section: Int) -> Int {
    return observeDataSource.numberOfItemsInSection(section)
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.section == observeDataSource.footerIndexPath?.section &&
        observeDataSource.footerIndexPath != nil && observeDataSource.footerIndexPath == indexPath {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FooterCellIdentifier,
                                                    for: indexPath)
      if let cell = cell as? ObserveFooterCell {
        cell.delegate = self
      }
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SensorCellIdentifier,
                                                    for: indexPath)
      if let cell = cell as? SensorCardCell {
        let sensorCard = observeDataSource.item(at: indexPath.item)
        let visualTriggersForSensor =
            visualTriggers(sensorCard.sensor, forRecording: recordingManager.isRecording)
        cell.configureWithSensor(sensorCard.sensor,
                                 delegate: self,
                                 stateOptions: sensorCard.cellState.options,
                                 colorPalette: sensorCard.colorPalette,
                                 chartView: sensorCard.chartController.chartView,
                                 visualTriggers: visualTriggersForSensor)
        sensorCard.toneGenerator.setPlayingStateUpdateBlock { (isPlayingTone) in
          cell.headerView.setShowAudioIcon(isPlayingTone)
        }
      }
      return cell
    }
  }

  // MARK: - UICollectionViewDelegate

  override open func collectionView(_ collectionView: UICollectionView,
                                    willDisplay cell: UICollectionViewCell,
                                    forItemAt indexPath: IndexPath) {
    guard let sensorCell = cell as? SensorCardCell,
        let sensor = sensorCell.sensor,
        let sensorCard = observeDataSource.item(withSensorID: sensor.sensorId) else {
      return
    }

    // Mark chart as visible so it will know to draw its data.
    sensorCard.chartController.isObserveVisible = true
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    didEndDisplaying cell: UICollectionViewCell,
                                    forItemAt indexPath: IndexPath) {
    guard let sensorCell = cell as? SensorCardCell,
        let sensor = sensorCell.sensor,
        let sensorCard = observeDataSource.item(withSensorID: sensor.sensorId) else {
      return
    }

    // Mark chart as not visible so it won't keep drawing data.
    sensorCard.chartController.isObserveVisible = false
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  private var cellHorizontalInset: CGFloat {
    var inset = SensorCardCell.cardInsets.left + SensorCardCell.cardInsets.right
    if let drawerViewController = drawerViewController,
        !drawerViewController.drawerView.isDisplayedAsSidebar,
        traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular {
      inset = 300
    }
    return inset + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.size.width - cellHorizontalInset
    if indexPath.section == observeDataSource.footerIndexPath?.section &&
        observeDataSource.footerIndexPath != nil && observeDataSource.footerIndexPath == indexPath {
      return CGSize(width: width, height: ObserveFooterCell.cellHeight)
    }
    return CGSize(width: width, height: observeDataSource.item(at: indexPath.item).cellState.height)
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: SensorCardCell.cardInsets.top,
                        left: cellHorizontalInset / 2,
                        bottom: SensorCardCell.cardInsets.bottom,
                        right: cellHorizontalInset / 2)
  }

  // MARK: - ObserveFooterCellDelegate

  func observeFooterAddButtonPressed() {
    addNewSensorCardCell()
  }

  // MARK: - TimeAxisControllerDelegate

  func timeAxisController(_ timeAxisController: TimeAxisController,
                          didChangePinnedToNow isPinnedToNow: Bool) {
    if isPinnedToNow {
      hideJumpToNowButton()
    } else {
      showJumpToNowButton()
    }
  }

  // MARK: - SensorCardCellDelegate

  func sensorCardCellExpandButtonPressed(_ sensorCardCell: SensorCardCell) {
    guard let indexPath = collectionView?.indexPath(for: sensorCardCell) else {
      return
    }

    // Update the datasource.
    let sensorCard = observeDataSource.item(at: indexPath.item)
    if sensorCard.cellState.options.contains(.sensorPickerVisible) {
      sensorCard.cellState.options.remove(.sensorPickerVisible)
    } else {
      let indexPathsOfSensorPickersToHide =
          observeDataSource.indexPathsForCardsShowingSensorPicker()
      hideSensorPickers(at: indexPathsOfSensorPickersToHide)
      sensorCard.cellState.options.insert(.sensorPickerVisible)
    }

    sensorCardCell.setStateOptions(sensorCard.cellState.options, animated: true)
    invalidateCollectionView(andLayoutIfNeeded: true)
  }

  func sensorCardCell(_ sensorCardCell: SensorCardCell, didSelectSensor sensor: Sensor) {
    guard let indexPath = collectionView?.indexPath(for: sensorCardCell) else {
      return
    }

    let sensorCard = observeDataSource.item(at: indexPath.item)

    // If this is the same sensor already being displayed, return.
    guard sensorCard.sensor != sensor else { return }

    // Stop listening to previous sensor
    removeListener(forSensorCard: sensorCard)
    observeDataSource.endUsingSensor(sensorCard.sensor)
    removeSensorLayoutForSensorCard(sensorCard)

    // Start listening to new sensor
    sensorCard.sensor = sensor

    // Clear the current value so it does not persist between sensors when the new sensor takes
    // a moment to return a value.
    sensorCardCell.currentValueView.textLabel.text = sensorCard.sensor.unitDescription

    observeDataSource.beginUsingSensor(sensorCard.sensor)
    addListener(forSensorCard: sensorCard)
    addSensorLayoutForSensorCard(sensorCard)

    sensorCardCell.updateSensor(sensor, chartView: sensorCard.chartController.chartView)
  }

  func sensorCardAvailableSensors(_ sensorCardCell: SensorCardCell,
                                  withSelectedSensor selectedSensor: Sensor?) -> [Sensor] {
    return observeDataSource.availableSensors(withSelectedSensor: selectedSensor)
  }

  func sensorCardCell(_ sensorCardCell: SensorCardCell, menuButtonPressed menuButton: MenuButton) {
    guard let indexPath = collectionView?.indexPath(for: sensorCardCell) else { return }

    let sensorCard = observeDataSource.item(at: indexPath.item)

    let popUpMenu = PopUpMenuViewController()

    // Enable/disable audio. (based on whether or not audio is playing).
    if sensorCard.toneGenerator.isPlayingTone {
      popUpMenu.addAction(PopUpMenuAction(title: String.graphOptionsAudioFeedbackDisable,
                                          icon: UIImage(named: "ic_volume_mute")) { (_) in
        sensorCard.toneGenerator.stop()
        sensorCard.sensorLayout?.isAudioEnabled = false
      })
    } else {
      popUpMenu.addAction(PopUpMenuAction(title: String.graphOptionsAudioFeedbackEnable,
                                          icon: UIImage(named: "ic_volume_up")) { (_) in
        sensorCard.toneGenerator.start()
        sensorCard.sensorLayout?.isAudioEnabled = true
      })
    }

    // Audio settings.
    popUpMenu.addAction(PopUpMenuAction(title: String.menuItemAudioSettings,
                                        icon: UIImage(named: "ic_audio_settings")) { (_) in
      // TODO: Create a full modal VC for audio settings. http://b/63319780
      let audioSettingsActionSheetController =
          UIAlertController(title: String.menuItemAudioSettings,
                            message: nil,
                            preferredStyle: .actionSheet)
      let cancelAction = UIAlertAction(title: String.actionCancel, style: .cancel)
      audioSettingsActionSheetController.addAction(cancelAction)

      for soundType in SoundTypeManager.sharedInstance.allSoundTypes {
        let action =
          UIAlertAction(title: soundType.name, style: .default) { (_) in
            sensorCard.toneGenerator.soundType = soundType
        }
        audioSettingsActionSheetController.addAction(action)
      }
      if UIDevice.current.userInterfaceIdiom == .pad {
        audioSettingsActionSheetController.modalPresentationStyle = .popover
        audioSettingsActionSheetController.popoverPresentationController?.sourceView = menuButton
        audioSettingsActionSheetController.popoverPresentationController?.sourceRect =
            menuButton.bounds
      }
      self.present(audioSettingsActionSheetController, animated: true)
    })

    if !isRecording {
      // Triggers create/edit.
      let triggerActionTitle =
          sensorTriggers.filter { $0.sensorID == sensorCard.sensor.sensorId }.isEmpty ?
          String.menuItemSetTriggers : String.menuItemEditTriggers
      popUpMenu.addAction(PopUpMenuAction(title: triggerActionTitle,
                                          icon: UIImage(named: "ic_trigger")) { (_) in
        self.delegate?.observeViewController(self, didPressSetTriggersForSensor: sensorCard.sensor)
      })

      // If there is more than one card, add a close card option.
      if observeDataSource.shouldAllowCardDeletion {
        popUpMenu.addAction(PopUpMenuAction(title: String.btnSensorCardClose,
                                            icon: UIImage(named: "ic_close")) { (_) in
          self.removeSensorCardCell(sensorCardCell)
        })
      }
    }

    popUpMenu.present(from: self, position: .sourceView(menuButton))
  }

  func sensorCardCellInfoButtonPressed(_ sensorCardCell: SensorCardCell) {
    guard let indexPath = collectionView?.indexPath(for: sensorCardCell) else { return }
    let sensorCard = observeDataSource.item(at: indexPath.item)
    let vc = LearnMoreViewController(sensor: sensorCard.sensor,
                                     analyticsReporter: analyticsReporter)
    if UIDevice.current.userInterfaceIdiom == .pad {
      vc.modalPresentationStyle = .formSheet
    }
    present(vc, animated: true)
  }

  func sensorCardCellSensorSettingsButtonPressed(_ cell: SensorCardCell) {
    showSettings()
  }

  func sensorCardCellDidTapStats(_ sensorCardCell: SensorCardCell) {
    guard let indexPath = collectionView?.indexPath(for: sensorCardCell) else { return }

    // Toggle display of stats and save state to sensor layout.
    let sensorCard = observeDataSource.item(at: indexPath.item)
    let shouldShowStats = !sensorCard.chartController.shouldShowStats
    sensorCard.chartController.shouldShowStats = shouldShowStats
    sensorCard.sensorLayout?.shouldShowStatsOverlay = shouldShowStats
  }

  // MARK: - ChartControllerDelegate

  func chartController(_ chartController: ChartController,
                       didUpdateVisibleXAxis visibleAxis: ChartAxis<Int64>) {
    timeAxisController.visibleAxisChanged(visibleAxis, by: chartController)
  }

  func chartController(_ chartController: ChartController,
                       scrollStateChanged isUserScrolling: Bool) {
    timeAxisController.isUserScrolling = isUserScrolling
  }

  func chartControllerDidFinishLoadingData(_ chartController: ChartController) {}

  func chartController(_ chartController: ChartController, shouldPinToNow: Bool) {
    timeAxisController.isPinnedToNow = shouldPinToNow
  }

  // MARK: - DrawerItemViewController

  public func setUpDrawerPanner(with drawerViewController: DrawerViewController) {
    if let collectionView = collectionView {
      drawerPanner = DrawerPanner(drawerViewController: drawerViewController,
                                  scrollView: collectionView)
    }
  }

  public func reset() {
    collectionView?.scrollToTop()
  }

  // MARK: - DrawerPositionListener

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   willChangeDrawerPosition position: DrawerPosition) {
    // If the content offset of the scroll view is within the first cell, scroll to the top when the
    // drawer position changes to anything but open full.
    if let collectionView = collectionView,
        let firstSensorCard = observeDataSource.firstItem {
      let firstCellHeight = firstSensorCard.cellState.height
      let isContentOffsetWithinFirstCell = collectionView.contentOffset.y < firstCellHeight
      if isContentOffsetWithinFirstCell && !drawerViewController.isPositionOpenFull(position) {
        perform(#selector(setCollectionViewContentOffsetToZero), with: nil, afterDelay: 0.01)
      }
    }
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   didChangeDrawerPosition position: DrawerPosition) {
    updateCollectionViewScrollEnabled()
  }

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   isPanningDrawerView drawerView: DrawerView) {}

  public func drawerViewController(_ drawerViewController: DrawerViewController,
                                   didPanBeyondBounds panDistance: CGFloat) {
    collectionView?.contentOffset = CGPoint(x: 0, y: panDistance)
  }

  // MARK: - RecordingManagerDelegate

  func recordingManager(_ recordingManager: RecordingManager,
                        didFireVisualTrigger trigger: SensorTrigger,
                        forSensor sensor: Sensor) {
    guard let indexPath = observeDataSource.indexPath(ofSensor: sensor) else { return }
    let cell = collectionView?.cellForItem(at: indexPath) as? SensorCardCell
    cell?.visualTriggerView.triggerFired()
  }

  func recordingManager(_ recordingManager: RecordingManager,
                        didFireStartRecordingTrigger trigger: SensorTrigger) {
    startRecording()
  }

  func recordingManager(_ recordingManager: RecordingManager,
                        didFireStopRecordingTrigger trigger: SensorTrigger) {
    endRecording()
  }

  func recordingManager(_ recordingManager: RecordingManager,
                        didFireNoteTrigger trigger: SensorTrigger,
                        forSensor sensor: Sensor,
                        atTimestamp timestamp: Int64) {
    if observeDataSource.sensorCard(for: sensor) != nil {
      // TODO: Add note to chart (requires new chart controller method).
      delegate?.observeViewController(self,
                                      didReceiveNoteTrigger: trigger,
                                      forSensor: sensor,
                                      atTimestamp: timestamp)
    }
  }

  func recordingManager(_ recordingManager: RecordingManager,
                        hasRecordedForDuration duration: Int64) {
    updateTimerLabel(with: duration)
  }

  func recordingManager(_ recordingManager: RecordingManager,
                        didExceedTriggerFireLimitForSensor sensor: Sensor) {
    delegate?.observeViewController(self, didExceedTriggerFireLimitForSensor: sensor)
  }

  // MARK: - ObserveDataSourceDelegate

  func observeDataSource(_ observeDataSource: ObserveDataSource,
                         sensorStateDidChangeForCard sensorCard: SensorCard) {
    // This delegate method can be called on a non-main thread.
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.observeDataSource(observeDataSource, sensorStateDidChangeForCard: sensorCard)
      }
      return
    }

    guard let visibleCells = collectionView?.visibleCells else {
      return
    }

    for case let cell as SensorCardCell in visibleCells {
      guard let sensor = cell.sensor else { continue }
      if sensor.sensorId == sensorCard.sensor.sensorId {
        cell.updateSensorLoadingState()
        break
      }
    }
  }

  // MARK: - UIScrollViewDelegate

  open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if isContentOutsideOfSafeArea != scrollView.isContentOutsideOfSafeArea {
      isContentOutsideOfSafeArea = scrollView.isContentOutsideOfSafeArea
    }
  }

  override open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    drawerPanner?.scrollViewWillBeginDragging(scrollView)
  }

  override open func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                              willDecelerate decelerate: Bool) {
    drawerPanner?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
  }

  // MARK: - Gesture recognizer

  @objc func handleCollectionViewPanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    drawerPanner?.handlePanGesture(panGestureRecognizer)
  }

  // MARK: - Notifications

  @objc func applicationWillResignActive() {
    updateSensorLayouts()

    // If there are no sensors recording besides audio and brightness, end recording and prepare an
    // alert.
    if recordingManager.isRecording {
      let otherSensors = observeDataSource.items.filter({
          !($0.sensor is AudioSensor || $0.sensor is BrightnessSensor) })
      if otherSensors.isEmpty {
        audioAndBrightnessSensorBackgroundMessageAlert?.dismiss(animated: false)
        endRecording()
        showAlert(withTitle: String.recordingStopped,
                  message: String.sensorTypeAudioAndBrightnessRecordingStoppedMessage)
      }
    }
    updateBrightnessSensorListenerIfNecessary(viewVisible: false)

    for sensorCard in observeDataSource.items {
      sensorCard.sensor.prepareForBackground()
    }
  }

  @objc func applicationDidBecomeActive() {
    let isViewOnScreen = view.superview != nil
    if isViewOnScreen {
      updateBrightnessSensorListenerIfNecessary(viewVisible: true)
    }
    for sensorCard in observeDataSource.items {
      sensorCard.sensor.prepareForForeground()
    }
  }

  @objc private func applicationWillTerminate() {
    // If the app is about to terminate, end recording so it will save.
    if recordingManager.isRecording {
      endRecording()
    }
  }

  @objc private func localNotificationManagerDidReceiveStopRecordingAction() {
    endRecording()
  }

  @objc private func accessibilityVoiceOverStatusChanged() {
    updateCollectionViewScrollEnabled()
  }

  @objc private func forceEndRecordingForSignOut() {
    if recordingManager.isRecording {
      // When a user is forced to sign out, their DB is completely removed along with all of their
      // data. We need to make sure the recording manager does not also attempt to remove data
      // asynchronously.
      endRecording(isCancelled: true, removeCancelledData: false)
    }
  }

}

// swiftlint:enable file_length, type_body_length
