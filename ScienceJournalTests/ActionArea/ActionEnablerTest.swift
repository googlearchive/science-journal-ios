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

class ActionEnablerTest: XCTestCase {

  class Observable: NSObject {
    @objc dynamic var isEnabled: Bool
    init(isEnabled: Bool) { self.isEnabled = isEnabled }
  }

  func testIsEnabledWhenTrue() {
    let observable = Observable(isEnabled: true)
    let enabler = ActionEnabler(target: observable, keyPath: \.isEnabled)
    XCTAssert(enabler.isEnabled, "Expected isEnabled to be true.")
  }

  func testIsEnabledWhenFalse() {
    let observable = Observable(isEnabled: false)
    let enabler = ActionEnabler(target: observable, keyPath: \.isEnabled)
    XCTAssertFalse(enabler.isEnabled, "Expected isEnabled to be false.")
  }

  func testObservation() {
    let observable = Observable(isEnabled: true)
    let enabler = ActionEnabler(target: observable, keyPath: \.isEnabled)
    var observedValue: Bool = true
    enabler.observe { isEnabled in
      observedValue = isEnabled
    }

    observable.isEnabled = false

    XCTAssertFalse(observedValue, "Expected observedValue to be false.")
  }

  func testUnobservation() {
    let observable = Observable(isEnabled: true)
    let enabler = ActionEnabler(target: observable, keyPath: \.isEnabled)
    var observedValue: Bool = true
    enabler.observe { isEnabled in
      observedValue = isEnabled
    }

    enabler.unobserve()
    observable.isEnabled = false

    XCTAssert(observedValue, "Expected observedValue to be true.")
  }

  func testNoInitialValueWhenObserving() {
    let observable = Observable(isEnabled: true)
    let enabler = ActionEnabler(target: observable, keyPath: \.isEnabled)
    var observedValue: Bool = false

    enabler.observe { isEnabled in
      observedValue = isEnabled
    }

    XCTAssertFalse(observedValue, "Expected observedValue to be false.")
  }

}
