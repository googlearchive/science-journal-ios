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

import CoreBluetooth
import UIKit

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

/// A BLE sensor interface for testing.
class TestSensorInterface: BLESensorInterface {
  let _identifier: String

  init(identifier: String) {
    _identifier = identifier
  }

  var identifier: String {
    return _identifier
  }
  var peripheral: CBPeripheral?
  var serviceId = CBUUID(string: "0000")
  var providerId: String {
    return "TEST PROVIDER ID"
  }
  var name: String {
    return "TEST NAME"
  }
  var iconName: String {
    return "TEST ICON NAME"
  }
  var animatingIconName: String {
    return "TEST"
  }
  var config: Data? {
    return nil
  }
  var unitDescription: String? {
    return "TEST UNIT DESCRIPTION"
  }
  var textDescription: String {
    return "TEST TEXT DESCRIPTION"
  }
  var hasOptions: Bool {
    return true
  }
  var learnMoreInformation: Sensor.LearnMore {
    return Sensor.LearnMore(firstParagraph: "", secondParagraph: "", imageName: "")
  }
  func presentOptions(from viewController: UIViewController, completion: @escaping () -> Void) {}
  func connect(_ completion: @escaping (Bool) -> Void) {}
  func startObserving(_ listener: @escaping (DataPoint) -> Void) {}
  func stopObserving() {}
}
