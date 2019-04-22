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

protocol RecordingManagerDelegate: class {

  /// Called when the recording manager fired a visual trigger.
  ///
  /// - Parameters:
  ///   - recordingManager: The recording manager.
  ///   - trigger: The trigger.
  ///   - sensor: The sensor that the trigger was fired for.
  func recordingManager(_ recordingManager: RecordingManager,
                        didFireVisualTrigger trigger: SensorTrigger,
                        forSensor sensor: Sensor)

  /// Called when the recording manager fired a trigger that should start recording.
  ///
  /// - Parameters:
  ///   - recordingManager: The recording manager.
  ///   - trigger: The trigger.
  func recordingManager(_ recordingManager: RecordingManager,
                        didFireStartRecordingTrigger trigger: SensorTrigger)

  /// Called when the recording manager fired a trigger that should stop recording.
  ///
  /// - Parameters:
  ///   - recordingManager: The recording manager.
  ///   - trigger: The trigger.
  func recordingManager(_ recordingManager: RecordingManager,
                        didFireStopRecordingTrigger trigger: SensorTrigger)

  /// Called when recording manager creates a note trigger.
  ///
  /// - Parameters:
  ///   - recordingManager: The recording manager.
  ///   - trigger: The trigger.
  ///   - sensor: The sensor associated with the note trigger.
  ///   - timestamp: The timestamp when the trigger fired.
  func recordingManager(_ recordingManager: RecordingManager,
                        didFireNoteTrigger trigger: SensorTrigger,
                        forSensor sensor: Sensor,
                        atTimestamp timestamp: Int64)

  /// Called by the recording manager during recording, to update with recording session timing
  /// info.
  ///
  /// - Parameters:
  ///   - recordingManager: The recording manager.
  ///   - hasRecordedForDuration: The duration of the recording session.
  func recordingManager(_ recordingManager: RecordingManager,
                        hasRecordedForDuration duration: Int64)

  /// Called by the recording manager when a sensor exceeded the maximum allowed trigger fire limit.
  ///
  /// - Parameters:
  ///   - recordingManager: The recording manager.
  ///   - sensor: The sensor that the trigger fired for.
  func recordingManager(_ recordingManager: RecordingManager,
                        didExceedTriggerFireLimitForSensor sensor: Sensor)

}

/// Expose a static property so any any class can see if recording is active.
public struct RecordingState {
  /// Whether or not the recording manager is recording.
  public static fileprivate(set) var isRecording = false
}

/// Manages sensor recorders, which record to the database and updates its listeners.
class RecordingManager: RecorderDelegate {

  /// The recording manager delegate.
  weak var delegate: RecordingManagerDelegate?

  /// Whether or not the recording manager is recording. Setting this value will update all
  /// recorders to either store to the database or not.
  var isRecording = false {
    didSet {
      RecordingState.isRecording = isRecording
      for recorder in recorders {
        recorder.shouldStoreDataToDatabase = isRecording
      }
    }
  }

  /// True if any of the recorders has yet to record a data point since recording began, otherwise
  /// false. Always returns false if a recording is not in progress.
  var isRecordingMissingData: Bool {
    guard isRecording else { return false }
    for recorder in recorders where !recorder.hasRecordedOneDataPoint {
      return true
    }
    return false
  }

  /// The recording start date.
  var recordingStartDate: DataPoint.Millis?

  /// The recording manager is ready when all sensors set to record are ready.
  var isReady: Bool {
    for recorder in recorders where recorder.sensor.state != .ready {
      return false
    }
    return true
  }

  /// The recorders monitoring sensor data.
  private var recorders = [Recorder]()

  /// The sensors being recorded.
  var recordingSensors: [Sensor] {
    return recorders.map { $0.sensor }
  }

  /// The ID of the trial to record for.
  private var trialID: String?

  /// An array of snapshots for the currently observing sensors.
  var sensorSnapshots: [SensorSnapshot] {
    var snapshots = [SensorSnapshot]()
    for recorder in self.recorders {
      // Skip recorder if the sensor does not have proper user permission.
      guard recorder.sensor.state == .ready else {
        continue
      }

      // Skip recorder if no data point has been recorded.
      guard let lastDataPoint = recorder.lastDataPoint else {
        continue
      }

      let snapshot = SensorSnapshot()
      snapshot.sensorSpec = SensorSpec(sensor: recorder.sensor)
      snapshot.timestamp = lastDataPoint.x
      snapshot.value = lastDataPoint.y
      snapshots.append(snapshot)
    }
    return snapshots
  }

  private let sensorDataManager: SensorDataManager

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameter sensorDataManager: The sensor data manager.
  init(sensorDataManager: SensorDataManager) {
    self.sensorDataManager = sensorDataManager
  }

  deinit {
    UIApplication.shared.isIdleTimerDisabled = false
  }

  /// Saves recorded data. Should be called periodically during recording.
  func save() {
    sensorDataManager.savePrivateContext()
  }

  /// Returns a recorder for a sensor ID.
  ///
  /// - Parameter sensorID: A sensor ID.
  /// - Returns: A recorder.
  func recorder(forSensorID sensorID: String) -> Recorder? {
    guard let index = recorders.index(where: { $0.sensor.sensorId == sensorID }) else {
      return nil
    }
    return recorders[index]
  }

  /// Removes a recorder from the recording manager.
  ///
  /// - Parameter recorder: The recorder to remove.
  private func remove(recorder: Recorder) {
    recorder.removeSensorListener()
    if let index = recorders.index(where: { $0 == recorder }) {
      recorders.remove(at: index)
    }
  }

  // MARK: Listeners

  /// Creates a recorder for `sensor` and begins updating the `listener` with data. If a listener is
  /// added for a sensor that already has a recorder, the existing object will be removed and a new
  /// one will be created.
  ///
  /// - Parameters:
  ///   - sensor: The sensor to listen to data for.
  ///   - triggers: The triggers to fire for the sensor.
  ///   - block: The block to call to update the listener.
  func addListener(forSensor sensor: Sensor,
                   triggers: [SensorTrigger],
                   using block: @escaping RecorderListener) {
    if let sensorRecorder = recorder(forSensorID: sensor.sensorId) {
      remove(recorder: sensorRecorder)
    }
    let aRecorder = Recorder(sensor: sensor,
                             delegate: self,
                             triggers: triggers,
                             listener: block,
                             sensorDataManager: sensorDataManager)
    recorders.append(aRecorder)
  }

  /// Removes the recorder associated with a sensor.
  ///
  /// - Parameter sensor: The sensor to remove the listener for.
  func removeListener(for sensor: Sensor) throws {
    guard let aRecorder = recorder(forSensorID: sensor.sensorId) else { return }
    remove(recorder: aRecorder)
  }

  // MARK: Start/end recording

  /// Starts recording, which will begin recording to the database. If called more than once, this
  /// method does nothing. To commit the data call `endRecording()`.
  func startRecording(trialID: String) {
    guard !isRecording else { return }

    self.trialID = trialID
    recorders.forEach { $0.prepareForRecordingToDatabase() }
    isRecording = true
    recordingStartDate = Date().millisecondsSince1970

    UIApplication.shared.isIdleTimerDisabled = true
  }

  /// Ends a recording, which will stop writing data to the database.
  ///
  /// - Parameters:
  ///   - isCancelled: True if the recording was cancelled, otherwise false. Default is false.
  ///   - removeCancelledData: True if data from a cancelled recording should be removed, otherwise
  ///                          false (data is left in the database). Only has impact if
  ///                          `isCancelled` is true. Default is true.
  func endRecording(isCancelled: Bool = false, removeCancelledData: Bool = true) {
    isRecording = false
    if !isCancelled {
      sensorDataManager.savePrivateContext()
    } else if removeCancelledData, let trialID = trialID {
      // If cancelled, remove data.
      sensorDataManager.removeData(forTrialID: trialID)
    }
    trialID = nil
    recordingStartDate = nil
    UIApplication.shared.isIdleTimerDisabled = false
    recorders.forEach { $0.hasRecordedOneDataPoint = false }
  }

  // MARK: - Triggers

  /// Adds a trigger for a sensor that is already being listened to.
  ///
  /// - Parameters:
  ///   - trigger: The trigger to add.
  ///   - sensor: The sensor to add the trigger for.
  func add(trigger: SensorTrigger, forSensor sensor: Sensor) {
    guard let recorder = recorder(forSensorID: sensor.sensorId) else { return }
    recorder.add(trigger: trigger)
  }

  /// Removes all triggers for all sensors.
  func removeAllTriggers() {
    for recorder in recorders {
      recorder.removeAllTriggers()
    }
  }

  /// Removes a trigger from a sensor.
  ///
  /// - Parameters:
  ///   - trigger: The trigger to remove.
  ///   - sensor: The sensor to remove the trigger from.
  private func remove(trigger: SensorTrigger, forSensor sensor: Sensor) {
    guard let recorder = recorder(forSensorID: sensor.sensorId) else { return }
    recorder.remove(trigger: trigger)
  }

  // MARK: - RecorderDelegate

  func recorder(_ recorder: Recorder, didFireStartRecordingTrigger trigger: SensorTrigger) {
    delegate?.recordingManager(self, didFireStartRecordingTrigger: trigger)
  }

  func recorder(_ recorder: Recorder, didFireStopRecordingTrigger trigger: SensorTrigger) {
    delegate?.recordingManager(self, didFireStopRecordingTrigger: trigger)
  }

  func recorder(_ recorder: Recorder, didFireVisualTrigger trigger: SensorTrigger) {
    delegate?.recordingManager(self, didFireVisualTrigger: trigger, forSensor: recorder.sensor)
  }

  func recorder(_ recorder: Recorder,
                didFireNoteTrigger trigger: SensorTrigger,
                at timestamp: Int64) {
    delegate?.recordingManager(self,
                               didFireNoteTrigger: trigger,
                               forSensor: recorder.sensor,
                               atTimestamp: timestamp)
  }

  func recorderDidReceiveData(_ recorder: Recorder) {
    guard isRecording, let recordingStartDate = recordingStartDate else { return }

    let duration = Date().millisecondsSince1970 - recordingStartDate
    delegate?.recordingManager(self, hasRecordedForDuration: duration)
  }

  func recorderTrialID(_ recorder: Recorder) -> String? {
    return trialID
  }

  func recorder(_ recorder: Recorder, didExceedTriggerFireLimitForSensor sensor: Sensor) {
    delegate?.recordingManager(self, didExceedTriggerFireLimitForSensor: sensor)
  }

}
