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

class ExperimentListViewControllerTest: XCTestCase {

  func testRightBarButtonItems() {
    let mockAccountsManager = MockAccountsManager()
    let settableNetworkAvailability = SettableNetworkAvailability()
    let sensorDataManager = SensorDataManager.testStore
    let metadataManager = MetadataManager.testingInstance
    let experimentDataDeleter = ExperimentDataDeleter(accountID: "MockUser",
                                                      metadataManager: metadataManager,
                                                      sensorDataManager: sensorDataManager)
    let documentManager = DocumentManager(experimentDataDeleter: experimentDataDeleter,
                                          metadataManager: metadataManager,
                                          sensorDataManager: sensorDataManager)
    let experimentsListVC =
        ExperimentsListViewController(accountsManager: mockAccountsManager,
                                      analyticsReporter: AnalyticsReporterOpen(),
                                      commonUIComponents: CommonUIComponentsOpen(),
                                      existingDataMigrationManager: nil,
                                      metadataManager: metadataManager,
                                      networkAvailability: settableNetworkAvailability,
                                      preferenceManager: PreferenceManager(),
                                      sensorDataManager: sensorDataManager,
                                      documentManager: documentManager,
                                      exportType: .saveToFiles,
                                      shouldAllowManualSync: true)

    settableNetworkAvailability.setAvailability(nil)
    experimentsListVC.updateRightBarButtonItems()
    XCTAssertEqual(experimentsListVC.navigationItem.rightBarButtonItems!,
                   [experimentsListVC.menuBarButton],
                   "Just the menu button should be shown if network availability is nil.")

    settableNetworkAvailability.setAvailability(true)
    experimentsListVC.updateRightBarButtonItems()
    XCTAssertEqual(experimentsListVC.navigationItem.rightBarButtonItems!,
                   [experimentsListVC.menuBarButton],
                   "Just the menu button should be shown if network availability is true.")

    settableNetworkAvailability.setAvailability(false)
    experimentsListVC.updateRightBarButtonItems()
    XCTAssertEqual(experimentsListVC.navigationItem.rightBarButtonItems!,
                   [experimentsListVC.menuBarButton, experimentsListVC.noConnectionBarButton],
                   "The menu and no connection buttons should be shown if network availability " +
                       "is false.")

    mockAccountsManager.mockSupportsAccounts = false
    settableNetworkAvailability.setAvailability(false)
    experimentsListVC.updateRightBarButtonItems()
    XCTAssertEqual(experimentsListVC.navigationItem.rightBarButtonItems!,
                   [experimentsListVC.menuBarButton],
                   "Just the menu button should be shown if accounts are not supported.")
  }

}
