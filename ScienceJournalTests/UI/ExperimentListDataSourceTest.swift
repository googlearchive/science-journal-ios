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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen

class ExperimentListDataSourceTest: XCTestCase {

  var dataSource: ExperimentsListDataSource!
  let metadataManager = MetadataManager.testingInstance

  override func setUp() {
    super.setUp()

    dataSource = ExperimentsListDataSource(
        includeArchived: false,
        metadataManager: metadataManager)
  }

  override func tearDown() {
    metadataManager.deleteRootDirectory()
    super.tearDown()
  }

  func testInsertOverviewAtBeginning() {
    // Insert four overviews at the beginning that will create two separate sections.
    let overview1 = ExperimentOverview(experimentID: "experiment1")
    overview1.lastUsedDate = dateWithFormat("20170920")
    dataSource.insertOverview(overview1, atBeginning: true)
    let overview2 = ExperimentOverview(experimentID: "experiment2")
    overview2.lastUsedDate = dateWithFormat("20170921")
    dataSource.insertOverview(overview2, atBeginning: true)
    let overview3 = ExperimentOverview(experimentID: "experiment3")
    overview3.lastUsedDate = dateWithFormat("20171001")
    dataSource.insertOverview(overview3, atBeginning: true)
    let overview4 = ExperimentOverview(experimentID: "experiment4")
    overview4.lastUsedDate = dateWithFormat("20171002")
    dataSource.insertOverview(overview4, atBeginning: true)

    XCTAssertEqual(dataSource.numberOfSections, 3, "There should be three sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview4.experimentID,
                   "experiment4 should be the first item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the second item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 2))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the first item in the second section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 2))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the second item in the second section.")

    // Insert a final overview that will go into the initial section.
    let overview5 = ExperimentOverview(experimentID: "experiment5")
    overview5.lastUsedDate = dateWithFormat("20170927")
    dataSource.insertOverview(overview5, atBeginning: true)

    XCTAssertEqual(dataSource.numberOfSections, 3, "There should be three sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview4.experimentID,
                   "experiment4 should be the first item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the second item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 2))!.experimentID,
                   overview5.experimentID,
                   "experiment5 should be the first item in the second section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 2))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the second item in the second section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 2, section: 2))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the third item in the second section.")
  }

  func testInsertOverviewIntoNewSections() {
    // Insert three overviews that will create three separate sections.
    let overview1 = ExperimentOverview(experimentID: "experiment1")
    overview1.lastUsedDate = dateWithFormat("20170720")
    dataSource.insertOverview(overview1)
    let overview2 = ExperimentOverview(experimentID: "experiment2")
    overview2.lastUsedDate = dateWithFormat("20170901")
    dataSource.insertOverview(overview2)
    let overview3 = ExperimentOverview(experimentID: "experiment3")
    overview3.lastUsedDate = dateWithFormat("20171001")
    dataSource.insertOverview(overview3)

    XCTAssertEqual(dataSource.numberOfSections, 4, "There should be four sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the first item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 2))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the first item in the second section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 3))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the first item in the third section.")

    // Insert an overview that will go into a section between the existing ones.
    let overview4 = ExperimentOverview(experimentID: "experiment4")
    overview4.lastUsedDate = dateWithFormat("20170802")
    dataSource.insertOverview(overview4)

    XCTAssertEqual(dataSource.numberOfSections, 5, "There should be five sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the first item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 2))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the first item in the second section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 3))!.experimentID,
                   overview4.experimentID,
                   "experiment4 should be the first item in the third section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 4))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the first item in the fourth section.")

    // Insert a final overview that will go into a section after all of the existing ones.
    let overview5 = ExperimentOverview(experimentID: "experiment5")
    overview5.lastUsedDate = dateWithFormat("20170602")
    dataSource.insertOverview(overview5)

    XCTAssertEqual(dataSource.numberOfSections, 6, "There should be six sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the first item in the first section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 2))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the first item in the second section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 3))!.experimentID,
                   overview4.experimentID,
                   "experiment4 should be the first item in the third section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 4))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the first item in the fourth section.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 5))!.experimentID,
                   overview5.experimentID,
                   "experiment5 should be the first item in the fifth section.")
}

  func testInsertOverviewIntoExistingSection() {
    // Insert three overviews that will go into a single section.
    let overview1 = ExperimentOverview(experimentID: "experiment1")
    overview1.lastUsedDate = dateWithFormat("20171005")
    dataSource.insertOverview(overview1)
    let overview2 = ExperimentOverview(experimentID: "experiment2")
    overview2.lastUsedDate = dateWithFormat("20171010")
    dataSource.insertOverview(overview2)
    let overview3 = ExperimentOverview(experimentID: "experiment3")
    overview3.lastUsedDate = dateWithFormat("20171015")
    dataSource.insertOverview(overview3)

    XCTAssertEqual(dataSource.numberOfSections, 2, "There should be two sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the first item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 1))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the second item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 2, section: 1))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the third item.")

    // Insert an overview that will go between the existing ones.
    let overview4 = ExperimentOverview(experimentID: "experiment4")
    overview4.lastUsedDate = dateWithFormat("20171012")
    dataSource.insertOverview(overview4)

    XCTAssertEqual(dataSource.numberOfSections, 2, "There should be two sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the first item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 1))!.experimentID,
                   overview4.experimentID,
                   "experiment4 should be the second item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 2, section: 1))!.experimentID,
                   overview2.experimentID,
                   "experiment2 should be the third item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 3, section: 1))!.experimentID,
                   overview1.experimentID,
                   "experiment1 should be the fourth item.")

    // Insert a final overview that will go after all of the existing ones.
    let overview5 = ExperimentOverview(experimentID: "experiment5")
    overview5.lastUsedDate = dateWithFormat("20171001")
    dataSource.insertOverview(overview5)

    XCTAssertEqual(dataSource.numberOfSections, 2, "There should be two sections.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 0, section: 1))!.experimentID,
                   overview3.experimentID,
                   "experiment3 should be the first item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 1, section: 1))!.experimentID,
                   overview4.experimentID,
                   "experiment4 should be the second item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 2, section: 1))!.experimentID,
                   overview2.experimentID,
                   "experiment3 should be the third item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 3, section: 1))!.experimentID,
                   overview1.experimentID,
                   "experiment2 should be the fourth item.")
    XCTAssertEqual(dataSource.itemAt(IndexPath(item: 4, section: 1))!.experimentID,
                   overview5.experimentID,
                   "experiment5 should be the fifth item.")
  }

  // MARK: - Helpers

  func dateWithFormat(_ format: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    return formatter.date(from: format)!
  }

}
