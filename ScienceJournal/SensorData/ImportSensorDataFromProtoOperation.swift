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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// An operation that imports sensor data from a proto. The operation requires either an
/// `ImportExperimentOperation` as a dependency or a proto passed in during initialization.
public class ImportSensorDataFromProtoOperation: GSJOperation {

  private let sensorDataManager: SensorDataManager
  private let sensorDataResult: OperationResult<Data>?
  private let trialIDsOperationResult: OperationResult<[String]>?

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorDataManager: A sensor data manager.
  ///   - sensorDataResult: A sensor data result.
  ///   - trialIDsOperationResult: An operation result for the IDs of the trials the sensor data is
  ///                              imported for.
  public init(sensorDataManager: SensorDataManager,
              sensorDataResult: OperationResult<Data>? = nil,
              trialIDsOperationResult: OperationResult<[String]>? = nil) {
    self.sensorDataManager = sensorDataManager
    self.sensorDataResult = sensorDataResult
    self.trialIDsOperationResult = trialIDsOperationResult
  }

  public override func execute() {
    var findSensorDataProto: GSJScalarSensorData?
    var trialIDMap: [String: String]?
    if let importExperimentOp: ImportExperimentOperation = successfulDependency(),
        let sensorData = importExperimentOp.sensorData {
      findSensorDataProto = sensorData
      trialIDMap = importExperimentOp.trialIDMap
    } else if let sensorData = sensorDataResult?.value {
      findSensorDataProto = try? GSJScalarSensorData.parse(from: sensorData)
      // Pass nil for the trial map because we are not re-IDing the trials.
    }

    guard let sensorData = findSensorDataProto else {
      // The experiment didn't contain any sensor data.
      finish()
      return
    }

    sensorDataManager.importSensorData(sensorData, withTrialIDMap: trialIDMap) { (trialIDs) in
      self.trialIDsOperationResult?.value = trialIDs
      self.finish()
    }
  }

}
