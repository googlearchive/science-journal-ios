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

/// An operation that imports multiple sensor data protos.
public class ImportMultipleSensorDataOperation: GroupOperation {

  private let dataResults: OperationResult<[OperationResult<Data>]>
  private let sensorDataManager: SensorDataManager
  private let trialIDsOperationResult: OperationResult<[String]>

  private var downloadedSensorDataTrialIDs = Set<String>() {
    didSet {
      trialIDsOperationResult.value = Array(downloadedSensorDataTrialIDs)
    }
  }

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - dataResults: A result of data results.
  ///   - sensorDataManager: The sensor data manager.
  ///   - trialIDsOperationResult: An operation result for the IDs of the trials for which the
  ///                              sensor data downloaded.
  public init(dataResults: OperationResult<[OperationResult<Data>]>,
              sensorDataManager: SensorDataManager,
              trialIDsOperationResult: OperationResult<[String]>) {
    self.dataResults = dataResults
    self.sensorDataManager = sensorDataManager
    self.trialIDsOperationResult = trialIDsOperationResult
    super.init(operations: [])
  }

  public override func configureOperationsBeforeExecution() {
    guard let dataResults = dataResults.value else {
      return
    }

    for dataResult in dataResults {
      guard let data = dataResult.value,
          let proto = try? GSJScalarSensorData.parse(from: data) else {
        continue
      }

      let importedTrialIDsOperationResult = OperationResult<[String]>()
      let importSensorDataOp = ImportSensorDataFromProtoOperation(
          sensorDataManager: sensorDataManager,
          sensorDataProto: proto,
          trialIDsOperationResult: importedTrialIDsOperationResult)
      addOperation(importSensorDataOp)
      importSensorDataOp.addObserver(BlockObserver { [unowned self] (operation, errors) in
        if let trialIDs = importedTrialIDsOperationResult.value {
          self.downloadedSensorDataTrialIDs.formUnion(trialIDs)
        }
      })
    }
  }

}
