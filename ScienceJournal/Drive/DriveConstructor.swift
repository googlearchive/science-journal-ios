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

import googlemac_iPhone_Shared_SSOAuth_SSOAuth

/// A protocol for an object that builds drive objects.
public protocol DriveConstructor {

  /// Returns an instance conforming to DriveSyncManager with the given authorization.
  ///
  /// - Parameters:
  ///   - authorization: An authorization object.
  ///   - experimentDataDeleter: An experiment data deleter.
  ///   - metadataManager: A metadata manager.
  ///   - networkAvailability: Network availability.
  ///   - preferenceManager: A preference manager.
  ///   - sensorDataManager: A sensor data manager.
  ///   - analyticsReporter: An analytics reporter.
  /// - Returns: A drive sync manager.
  func driveSyncManager(withAuthorization authorization: GTMFetcherAuthorizationProtocol,
                        experimentDataDeleter: ExperimentDataDeleter,
                        metadataManager: MetadataManager,
                        networkAvailability: NetworkAvailability,
                        preferenceManager: PreferenceManager,
                        sensorDataManager: SensorDataManager,
                        analyticsReporter: AnalyticsReporter) -> DriveSyncManager?

}
