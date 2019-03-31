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

import Foundation

protocol RecorderDelegate: class {

  /// Called when the recorder fires a start recording trigger.
  ///
  /// - Parameters:
  ///   - recorder: The recorder that fired the trigger.
  ///   - trigger: The trigger that fired.
  func recorder(_ recorder: Recorder, didFireStartRecordingTrigger trigger: SensorTrigger)

  /// Called when the recorder fires a stop recording trigger.
  ///
  /// - Parameters:
  ///   - recorder: The recorder that fired the trigger.
  ///   - trigger: The trigger that fired.
  func recorder(_ recorder: Recorder, didFireStopRecordingTrigger trigger: SensorTrigger)

  /// Called when the recorder fires a visual trigger.
  ///
  /// - Parameters:
  ///   - recorder: The recorder that fired the trigger.
  ///   - trigger: The trigger that fired.
  func recorder(_ recorder: Recorder, didFireVisualTrigger trigger: SensorTrigger)

  /// Called when the recorder fires a note trigger.
  ///
  /// - Parameters:
  ///   - recorder: The recorder that fired the trigger.
  ///   - trigger: The trigger that fired.
  ///   - timestamp: The timestamp at which the trigger fired.
  func recorder(_ recorder: Recorder,
                didFireNoteTrigger trigger: SensorTrigger,
                at timestamp: Int64)

  /// Called by the recorder during recording, when data is received.
  ///
  /// - Parameter recorder: The recorder that received data.
  func recorderDidReceiveData(_ recorder: Recorder)

  /// Called by the recorder during recording, when it needs the trial ID it is recording for.
  ///
  /// - Parameter recorder: The recorder.
  func recorderTrialID(_ recorder: Recorder) -> String?

  /// Called by the recorder when a sensor exceeded the maximum allowed trigger fire limit.
  ///
  /// - Parameters:
  ///   - recorder: The recorder.
  ///   - sensor: The sensor that the trigger fired for.
  func recorder(_ recorder: Recorder, didExceedTriggerFireLimitForSensor sensor: Sensor)

}

/// The listener block with a data point, called by recorders.
typealias RecorderListener = ((DataPoint) -> Void)

/// Records a single sensor to the database and updates its listener.
class Recorder: Equatable, SensorTriggerFrequencyObserverDelegate {

  public static func ==(lhs: Recorder, rhs: Recorder) -> Bool {
    return lhs.sensor.sensorId == rhs.sensor.sensorId
  }

  /// For each data point in a zoom tier above 1, the number of points in the tier below
  /// it represents.
  static let zoomLevelBetweenTiers = 20

  /// The default buffer size for zoom tier recording.
  static let zoomBufferSize = zoomLevelBetweenTiers * 2

  // MARK: - Properties

  /// The sensor to record.
  let sensor: Sensor

  /// Whether or not the data should be stored to the database.
  var shouldStoreDataToDatabase = false

  /// The sensor trigger evaluators for this recorder to monitor.
  var sensorTriggerEvaluators: [SensorTriggerEvaluator]

  /// The recorder delegate.
  weak private var delegate: RecorderDelegate?

  /// The listener to update.
  private let listener: RecorderListener

  /// Records multiple tiers of data resolution.
  private var zoomRecorder: ZoomRecorder?

  /// The total number of tiers currently recorded.
  var zoomTierCount: Int {
    return zoomRecorder?.tierCount ?? 0
  }

  /// True if the recorder has recorded at least one data point since the latest recording began,
  /// otherwise false. This value is reset externally when a recording trial ends.
  var hasRecordedOneDataPoint = false

  /// The helper for trigger alerts.
  private lazy var triggerAlertHelper: TriggerAlertHelper = {
    return TriggerAlertHelper()
  }()

  // The last data point observed, cached for snapshots.
  private(set) var lastDataPoint: DataPoint?

  private let sensorDataManager: SensorDataManager

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensor: The sensor to record.
  ///   - delegate: The recorder delegate.
  ///   - triggers: The sensor triggers for this recorder to monitor.
  ///   - listener: The object to udpdate with sensor data.
  ///   - sensorDataManager: The sensor data manager.
  init(sensor: Sensor,
       delegate: RecorderDelegate,
       triggers: [SensorTrigger],
       listener: @escaping RecorderListener,
       sensorDataManager: SensorDataManager) {
    self.sensor = sensor
    self.delegate = delegate
    sensorTriggerEvaluators = SensorTriggerEvaluator.sensorTriggerEvaluators(for: triggers)
    self.listener = listener
    self.sensorDataManager = sensorDataManager
    let sensorTriggerFrequencyObserver = SensorTriggerFrequencyObserver(delegate: self)
    self.sensor.addListener(self, using: { [weak self] (dataPoint) in
      guard let weakSelf = self else { return }
      // Capture latest data point.
      weakSelf.lastDataPoint = dataPoint

      delegate.recorderDidReceiveData(weakSelf)

      for sensorTriggerEvaluator in weakSelf.sensorTriggerEvaluators {
        if !weakSelf.shouldStoreDataToDatabase &&
            sensorTriggerEvaluator.sensorTrigger.triggerInformation.triggerOnlyWhenRecording {
          continue
        }
        if sensorTriggerEvaluator.shouldTrigger(withValue: dataPoint.y) {
          weakSelf.fire(sensorTrigger: sensorTriggerEvaluator.sensorTrigger,
                    at: dataPoint.x)
          sensorTriggerFrequencyObserver.triggerFired(sensorTriggerEvaluator.sensorTrigger,
                                                      at: dataPoint.x)
        }
      }

      weakSelf.listener(dataPoint)

      if weakSelf.shouldStoreDataToDatabase, let trialID = delegate.recorderTrialID(weakSelf) {
        weakSelf.hasRecordedOneDataPoint = true
        sensorDataManager.addSensorDataPoint(dataPoint,
                                             sensorID: weakSelf.sensor.sensorId,
                                             trialID: trialID)
        weakSelf.zoomRecorder?.addDataPoint(dataPoint: dataPoint)
      }
    })
  }

  deinit {
    removeSensorListener()
  }

  /// Removes the sensor's listener.
  func removeSensorListener() {
    sensor.removeListener(self)
  }

  /// Adds a trigger.
  ///
  /// - Parameters:
  ///   - trigger: The trigger to add.
  func add(trigger: SensorTrigger) {
    sensorTriggerEvaluators.append(SensorTriggerEvaluator(sensorTrigger: trigger))
  }

  /// Removes a trigger.
  ///
  /// - Parameter trigger: The trigger to remove.
  func remove(trigger: SensorTrigger) {
    if let index = sensorTriggerEvaluators.firstIndex(where: { $0.sensorTrigger === trigger }) {
      sensorTriggerEvaluators.remove(at: index)
    }
  }

  /// Removes all triggers.
  func removeAllTriggers() {
    sensorTriggerEvaluators.removeAll()
  }

  /// Performs any preparation necessary before recording data to the database.
  func prepareForRecordingToDatabase() {
    guard let trialID = delegate?.recorderTrialID(self) else { return }
    zoomRecorder = ZoomRecorder(
        sensorID: sensor.sensorId,
        trialID: trialID,
        bufferSize: Recorder.zoomBufferSize,
        addingDataPointBlock: { [weak self] (dataPoint, sensorID, trialID, tier) in
          self?.sensorDataManager.addSensorDataPoint(dataPoint,
                                                     sensorID: sensorID,
                                                     trialID: trialID,
                                                     resolutionTier: tier)
    })
  }

  // MARK: - Private

  /// Handles a trigger that has fired.
  ///
  /// - Parameters:
  ///   - sensorTrigger: The trigger.
  ///   - timestamp: The timestamp when the trigger fired.
  private func fire(sensorTrigger: SensorTrigger, at timestamp: Int64) {
    switch sensorTrigger.triggerInformation.triggerActionType {
    case .triggerActionStartRecording:
      if !shouldStoreDataToDatabase {
        delegate?.recorder(self, didFireStartRecordingTrigger: sensorTrigger)
      }
    case .triggerActionStopRecording:
      if shouldStoreDataToDatabase {
        delegate?.recorder(self, didFireStopRecordingTrigger: sensorTrigger)
      }
    case .triggerActionNote:
      delegate?.recorder(self, didFireNoteTrigger: sensorTrigger, at: timestamp)
    case .triggerActionAlert:
      sensorTrigger.triggerInformation.triggerAlertTypes.forEach{ (alertType) in
        switch alertType {
        case .triggerAlertAudio:
          self.triggerAlertHelper.playTriggerAlertSound()
        case .triggerAlertPhysical:
          self.triggerAlertHelper.playTriggerAlertVibration()
        case .triggerAlertVisual:
          self.delegate?.recorder(self, didFireVisualTrigger: sensorTrigger)
        default: fatalError("Impossible case")
        }
      }
    default: fatalError("Impossible case")
    }
  }

  // MARK: - SensorTriggerFrequencyObserverDelegate

  func sensorTriggerFrequencyObserverDidExceedFireLimit(_
      sensorTriggerFrequencyObserver: SensorTriggerFrequencyObserver) {
    delegate?.recorder(self, didExceedTriggerFireLimitForSensor: sensor)
  }

}
