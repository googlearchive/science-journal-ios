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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class SensorTest: XCTestCase {

  func testLoadingStateEquality() {
    XCTAssertTrue(Sensor.LoadingState.paused == Sensor.LoadingState.paused)
    XCTAssertTrue(Sensor.LoadingState.loading == Sensor.LoadingState.loading)
    XCTAssertTrue(Sensor.LoadingState.ready == Sensor.LoadingState.ready)

    let failedState1 = Sensor.LoadingState.failed(.notSupported)
    let failedState2 = Sensor.LoadingState.failed(.unavailableHardware)
    XCTAssertTrue(failedState1 == failedState2)

    let noPermissionState1 = Sensor.LoadingState.noPermission(.userPermissionError(.microphone))
    let noPermissionState2 = Sensor.LoadingState.noPermission(.userPermissionError(.camera))
    XCTAssertTrue(noPermissionState1 == noPermissionState2)

    XCTAssertTrue(Sensor.LoadingState.interrupted == Sensor.LoadingState.interrupted)
  }

}
