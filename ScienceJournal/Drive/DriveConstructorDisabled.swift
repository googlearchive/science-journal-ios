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

/// A disabled version of drive constructor. Currently used by the open-source build since it does
/// not support Drive sync.
open class DriveConstructorDisabled: DriveConstructor {

  public init() {}

  public func driveSyncManager(withAuthorization authorization: GTMFetcherAuthorizationProtocol,
                               metadataManager: MetadataManager,
                               networkAvailability: NetworkAvailability,
                               preferenceManager: PreferenceManager,
                               sensorDataManager: SensorDataManager) -> DriveSyncManager? {
    return nil
  }

}
