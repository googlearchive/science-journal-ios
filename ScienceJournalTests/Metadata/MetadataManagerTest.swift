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

@testable import third_party_objective_c_material_components_ios_components_Palettes_Palettes
@testable import third_party_sciencejournal_ios_ScienceJournalOpen
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class MetadataManagerTest: XCTestCase {

  var metadataManager: MetadataManager!
  let sensorDataManager = SensorDataManager.testStore
  let testingRootURL = URL.documentsDirectoryURL.appendingPathComponent("TESTING")

  override func setUp() {
    super.setUp()

    // Clean up any old data.
    sensorDataManager.performChanges(andWait: true, save: true) {
      self.sensorDataManager.removeData(forTrialID: "TEST_TRIAL_1_MIGRATION")
      self.sensorDataManager.removeData(forTrialID: "TEST_TRIAL_2_MIGRATION")
    }

    metadataManager = MetadataManager(rootURL: testingRootURL,
                                      deletedRootURL: testingRootURL,
                                      preferenceManager: PreferenceManager(),
                                      sensorController: MockSensorController(),
                                      sensorDataManager: sensorDataManager)
  }

  override func tearDown() {
    if FileManager.default.fileExists(atPath: testingRootURL.path) {
      do {
        try FileManager.default.removeItem(at: testingRootURL)
      } catch {
        print("[MetadataManagerTest] Error deleting testing directory: \(error)")
      }
    }
    super.tearDown()
  }

  func testSaveExperiment() {
    let experiment = Experiment(ID: UUID().uuidString)
    experiment.setTitle("123 Test Title")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 1
    let experimentID = experiment.ID

    let experimentsURL =
        metadataManager.experimentsDirectoryURL.appendingPathComponent(experimentID)
    XCTAssertFalse(FileManager.default.fileExists(atPath: experimentsURL.path),
                   "Directory should not exist yet")
    metadataManager.saveExperiment(experiment)
    XCTAssertTrue(FileManager.default.fileExists(atPath: experimentsURL.path))

    let protoURL = experimentsURL.appendingPathComponent("experiment.proto")
    XCTAssertTrue(FileManager.default.fileExists(atPath: protoURL.path))

    let data = try! Data(contentsOf: protoURL)
    let experimentProto = try! GSJExperiment(data: data)
    XCTAssertNotNil(experimentProto)
    XCTAssertEqual("123 Test Title", experimentProto.title)

    XCTAssertNoThrow(try FileManager.default.removeItem(at: experimentsURL),
                     "Verify cleanup succeeded.")
  }

  func testSaveExperimentWithoutUpdatingLastUsedDate() {
    let settableClock = SettableClock(now: 12345)
    metadataManager.clock = settableClock

    let (experiment, overview) = metadataManager.createExperiment(withTitle: "456 Test Title")
    XCTAssertEqual("456 Test Title", experiment.title)
    XCTAssertEqual(12345, overview.lastUsedDate.millisecondsSince1970)

    let syncExperiment = SyncExperiment(experimentID: experiment.ID, clock: metadataManager.clock)
    metadataManager.experimentLibrary.addExperiment(syncExperiment)

    // Save with standard save method which updates last used time and confirm.

    // Change the clock time.
    settableClock.setNow(6789)

    metadataManager.saveExperiment(experiment)
    XCTAssertEqual(6789, overview.lastUsedDate.millisecondsSince1970)
    XCTAssertEqual(6789,
                   metadataManager.experimentLibrary.syncExperiment(
                      forID: experiment.ID)?.lastModifiedDate.millisecondsSince1970)

    // Now save without updating last used date and confirm.

    // Change the clock time.
    settableClock.setNow(99999)

    metadataManager.saveExperimentWithoutDateChange(experiment)
    XCTAssertEqual(6789, overview.lastUsedDate.millisecondsSince1970)
    XCTAssertEqual(6789,
                   metadataManager.experimentLibrary.syncExperiment(
                      forID: experiment.ID)?.lastModifiedDate.millisecondsSince1970)
  }

  func testOverviewOnNewExperiment() {
    let (experiment, overview) = metadataManager.createExperiment(withTitle: "123 Title")

    XCTAssertEqual("123 Title", experiment.title)
    XCTAssertEqual("123 Title", overview.title)
    XCTAssertEqual(experiment.ID, overview.experimentID)

    let index = metadataManager.experimentOverviews.index(
        where: { $0.experimentID == overview.experimentID })
    XCTAssertNotNil(index, "Overviews contains the new overview")
  }

  func testTitleIsNilWhenNotSet() {
    let (experiment, overview) = metadataManager.createExperiment()
    XCTAssertNil(experiment.title)
    XCTAssertNil(overview.title)
  }

  func testImageDeleteAndRestore() {
    // Get an image.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    XCTAssertNotNil(image, "The test requires an image that exists.")

    // Get a path.
    let path = metadataManager.relativePicturePath(for: "ExperimentTestID")

    // Save the image.
    metadataManager.saveImage(image, atPicturePath: path, experimentID: "ExperimentTestID")
    XCTAssertNotNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                    "Image at path should not be nil.")

    // Delete the image.
    metadataManager.deleteAssetAtPath(path, experimentID: "ExperimentTestID")
    XCTAssertNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                 "Deleted image path should be nil.")

    // Restore the image.
    metadataManager.restoreDeletedAssetAtPath(path, experimentID: "ExperimentTestID")
    XCTAssertNotNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                    "Restored image should not be nil")
  }

  func testRemoveAllDeletedAssets() {
    // Get an image.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    XCTAssertNotNil(image, "The test requires an image that exists.")

    // Get a path.
    let path = metadataManager.relativePicturePath(for: "ExperimentTestID")

    // Save the image.
    metadataManager.saveImage(image, atPicturePath: path, experimentID: "ExperimentTestID")
    XCTAssertNotNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                    "Image at path should not be nil.")

    // Delete the image.
    metadataManager.deleteAssetAtPath(path, experimentID: "ExperimentTestID")
    XCTAssertNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                 "Deleted image path should be nil.")

    // Remove all deleted assets.
    metadataManager.removeAllDeletedData()

    // Restore the image.
    metadataManager.restoreDeletedAssetAtPath(path, experimentID: "ExperimentTestID")
    XCTAssertNil(metadataManager.image(forPicturePath: path, experimentID: "ExperimentTestID"),
                 "Restored image should be nil")
  }

  func testUpgradeWhenExperimentVersionNotSet() {
    let experiment = Experiment(ID: "TEST_ID")

    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 2,
                                                           toPlatformVersion: 200)
    )

    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(2, experiment.fileVersion.minorVersion)
    XCTAssertEqual(200, experiment.fileVersion.platformVersion)
    XCTAssertEqual(.ios, experiment.fileVersion.platform)
  }

  func testExperimentVersionTooNewThrowsError() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = Experiment.Version.major + 1
    experiment.fileVersion.minorVersion = Experiment.Version.minor

    XCTAssertThrowsError(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
          toMajorVersion: Experiment.Version.major,
          toMinorVersion: Experiment.Version.minor,
          toPlatformVersion: Experiment.Version.platform)
      )
  }

  func testOnlyUpgradesExperimentMinorVersion() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 0
    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 1)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(1, experiment.fileVersion.minorVersion)
  }

  func testUpgradesToMinor2() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 2
    experiment.fileVersion.platform = .ios
    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 2,
                                                           toPlatformVersion: 500)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(2, experiment.fileVersion.minorVersion)
    XCTAssertEqual(500, experiment.fileVersion.platformVersion)
    XCTAssertEqual(.ios, experiment.fileVersion.platform)
  }

  func testDontDowngradePlatform() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 2
    experiment.fileVersion.platformVersion = 1000
    experiment.fileVersion.platform = .ios
    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 2,
                                                           toPlatformVersion: 500)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(2, experiment.fileVersion.minorVersion)
    XCTAssertEqual(1000, experiment.fileVersion.platformVersion)
    XCTAssertEqual(.ios, experiment.fileVersion.platform)
  }

  func testChangePlatformToiOS() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 1000
    experiment.fileVersion.platform = .android
    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 2,
                                                           toPlatformVersion: 500)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(2, experiment.fileVersion.minorVersion)
    XCTAssertEqual(500, experiment.fileVersion.platformVersion)
    XCTAssertEqual(.ios, experiment.fileVersion.platform);
  }

  func testOnlyUpgradesExperimentPlatformVersion() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 0
    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 1)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(1, experiment.fileVersion.minorVersion)
    XCTAssertEqual(1, experiment.fileVersion.platformVersion)
  }

  func testCantWriteExperimentWithNewerVersion() {
    let experiment = Experiment(ID: "TEST_ID")

    // Same major version, newer minor version.
    experiment.fileVersion.version = Experiment.Version.major
    experiment.fileVersion.minorVersion = Experiment.Version.minor + 1
    var didSave = metadataManager.saveExperiment(experiment)
    XCTAssertFalse(didSave)

    // Newer major version.
    experiment.fileVersion.version = Experiment.Version.major + 1
    experiment.fileVersion.version = Experiment.Version.minor
    didSave = metadataManager.saveExperiment(experiment)
    XCTAssertFalse(didSave)
  }

  func testCantUpgradeNewerVersionToLowerVersion() {
    let experiment = Experiment(ID: "TEST_ID")

    // Same major version, newer minor version.
    experiment.fileVersion.version = 2
    experiment.fileVersion.minorVersion = 2

    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 2,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 1)
    )
    XCTAssertEqual(experiment.fileVersion.version, 2)
    XCTAssertEqual(experiment.fileVersion.minorVersion, 2)

    XCTAssertThrowsError(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 1)
    )
  }

  func testPicturePathMigrationFromPlatformVersion2() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 2

    let experimentNote = PictureNote()
    experimentNote.filePath = "experiments/AAABBBCCCDDD/assets/EEEFFFGGG.jpg"
    experiment.notes = [experimentNote]

    let trial = Trial()
    let trialNote = PictureNote()
    trialNote.filePath = "experiments/HHHIIIJJJ/assets/LLLMMMNNN.jpg"
    trial.notes = [trialNote]
    experiment.trials = [trial]

    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 3)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(1, experiment.fileVersion.minorVersion)
    XCTAssertEqual(3, experiment.fileVersion.platformVersion)
    XCTAssertEqual("assets/EEEFFFGGG.jpg", (experiment.notes[0] as! PictureNote).filePath)
    XCTAssertEqual("assets/LLLMMMNNN.jpg", (experiment.trials[0].notes[0] as! PictureNote).filePath)
  }

  func testIconPathMigrationFromPlatformVersion2() {
    let experiment = Experiment(ID: "TEST_ID")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 2

    // setup
    // - a trial with sensor appearances
    let trial = Trial()
    let sensorAppearanceProto = GSJBasicSensorAppearance()
    sensorAppearanceProto.iconPath = GSJIconPath()
    sensorAppearanceProto.iconPath.pathString = "ic_sensor_acc_linear"
    trial.addSensorAppearance(BasicSensorAppearance(proto: sensorAppearanceProto),
                              for: "TrialSensorID")
    experiment.trials = [trial]

    // - a trial snapshot note
    let snapshot = SensorSnapshot()
    snapshot.sensorSpec.rememberedAppearance.iconPath = IconPath()
    snapshot.sensorSpec.rememberedAppearance.iconPath?.pathString = "ic_sensor_acc_x"
    let snapshotNote = SnapshotNote(snapshots: [snapshot])

    // - a trial trigger note
    let sensorSpec = GSJSensorSpec()
    sensorSpec.rememberedAppearance.iconPath = GSJIconPath()
    sensorSpec.rememberedAppearance.iconPath.pathString = "ic_sensor_audio"
    let triggerSensorSpec = SensorSpec(proto: sensorSpec)
    let triggerInfo = TriggerInformation()
    let triggerNote = TriggerNote(sensorSpec: triggerSensorSpec,
                                  triggerInformation: triggerInfo,
                                  timestamp: Date().millisecondsSince1970)

    trial.notes = [snapshotNote, triggerNote]

    // - an experiment snapshot note
    let expSnapshot = SensorSnapshot()
    expSnapshot.sensorSpec.rememberedAppearance.iconPath = IconPath()
    expSnapshot.sensorSpec.rememberedAppearance.iconPath?.pathString = "ic_sensor_barometer"
    let expSnapshotNote = SnapshotNote(snapshots: [expSnapshot])

    // - an experiment trigger note
    let expSensorSpec = GSJSensorSpec()
    expSensorSpec.rememberedAppearance.iconPath = GSJIconPath()
    expSensorSpec.rememberedAppearance.iconPath.pathString = "ic_sensor_audio"
    let expTriggerSensorSpec = SensorSpec(proto: expSensorSpec)
    let expTriggerInfo = TriggerInformation()
    let exptriggerNote = TriggerNote(sensorSpec: expTriggerSensorSpec,
                                     triggerInformation: expTriggerInfo,
                                     timestamp: Date().millisecondsSince1970)

    experiment.notes = [expSnapshotNote, exptriggerNote]

    XCTAssertNil(snapshot.sensorSpec.rememberedAppearance.largeIconPath)
    XCTAssertFalse(sensorSpec.rememberedAppearance.largeIconPath.hasPathString)
    XCTAssertNil(expSnapshot.sensorSpec.rememberedAppearance.largeIconPath)
    XCTAssertFalse(expSensorSpec.rememberedAppearance.largeIconPath.hasPathString)

    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 3)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(1, experiment.fileVersion.minorVersion)
    XCTAssertEqual(3, experiment.fileVersion.platformVersion)

    // Fetching the notes from the experiment in case we inadvertendly introduced a copy at some
    // point in the future.
    let expSnapAppearance =
        (experiment.notes[0] as! SnapshotNote).snapshots[0].sensorSpec.rememberedAppearance
    XCTAssertEqual("BarometerSensor", expSnapAppearance.iconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, expSnapAppearance.iconPath?.type)
    XCTAssertEqual("BarometerSensor", expSnapAppearance.largeIconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, expSnapAppearance.largeIconPath?.type)

    let expTriggerAppearance =
        (experiment.notes[1] as! TriggerNote).sensorSpec?.rememberedAppearance
    XCTAssertEqual("DecibelSource", expTriggerAppearance?.iconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, expTriggerAppearance?.iconPath?.type)
    XCTAssertEqual("DecibelSource", expTriggerAppearance?.largeIconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, expTriggerAppearance?.largeIconPath?.type)

    let trialSnapPathAppearance =
        (experiment.trials[0].notes[0] as! SnapshotNote)
            .snapshots[0].sensorSpec.rememberedAppearance
    XCTAssertEqual("AccX", trialSnapPathAppearance.iconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, trialSnapPathAppearance.iconPath?.type)
    XCTAssertEqual("AccX", trialSnapPathAppearance.largeIconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, trialSnapPathAppearance.largeIconPath?.type)

    let trialTrigAppearance =
        (experiment.trials[0].notes[1] as! TriggerNote).sensorSpec?.rememberedAppearance
    XCTAssertEqual("DecibelSource", trialTrigAppearance?.iconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, trialTrigAppearance?.iconPath?.type)
    XCTAssertEqual("DecibelSource", trialTrigAppearance?.largeIconPath?.pathString)
    XCTAssertEqual(GSJIconPath_PathType.builtin, trialTrigAppearance?.largeIconPath?.type)
  }

  func testTrialCaptionsToNotesMigrationFromPlatformVersion2() {
    // Create an experiment with platform version 2 that has two trials with captions, two without.
    // One of the two with captions has a text note already. One has a note, but no caption.
    let caption2 = Caption(text: "test caption 2")
    let caption4 = Caption(text: "test caption 4")

    let note3 = TextNote(text: "test text note 3")
    let note4 = TextNote(text: "test text note 4")

    let trial1 = Trial()
    let trial2 = Trial()
    trial2.caption = caption2
    trial2.recordingRange = ChartAxis(min: 123, max: 456)
    let trial3 = Trial()
    trial3.notes = [note3]
    let trial4 = Trial()
    trial4.caption = caption4
    trial4.notes = [note4]
    trial4.recordingRange = ChartAxis(min: 78, max: 90)

    let experiment = Experiment(ID: "")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 1
    experiment.fileVersion.platformVersion = 2
    experiment.trials = [trial1, trial2, trial3, trial4]

    // Trials 2 and 4 have captions.
    XCTAssertNil(experiment.trials[0].caption)
    XCTAssertNotNil(experiment.trials[1].caption)
    XCTAssertNil(experiment.trials[2].caption)
    XCTAssertNotNil(experiment.trials[3].caption)

    // Trials 3 and 4 have notes.
    XCTAssertEqual((experiment.trials[2].notes[0] as! TextNote).text, note3.text)
    XCTAssertEqual((experiment.trials[3].notes[0] as! TextNote).text, note4.text)

    // Trial note counts.
    XCTAssertEqual(experiment.trials[0].notes.count, 0)
    XCTAssertEqual(experiment.trials[1].notes.count, 0)
    XCTAssertEqual(experiment.trials[2].notes.count, 1)
    XCTAssertEqual(experiment.trials[3].notes.count, 1)

    // Caption text equals trial caption text.
    XCTAssertEqual(experiment.trials[1].caption?.text, caption2.text)
    XCTAssertEqual(experiment.trials[3].caption?.text, caption4.text)

    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(1, experiment.fileVersion.minorVersion)
    XCTAssertEqual(2, experiment.fileVersion.platformVersion)
    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 1,
                                                           toPlatformVersion: 3)
    )
    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(1, experiment.fileVersion.minorVersion)
    XCTAssertEqual(3, experiment.fileVersion.platformVersion)

    // There should be text notes with the caption text, and their timestamp should be the same as
    // the start of the trial.
    XCTAssertEqual((experiment.trials[1].notes[0] as! TextNote).text, caption2.text)
    XCTAssertEqual(experiment.trials[1].notes[0].timestamp, trial2.recordingRange.min)
    XCTAssertEqual((experiment.trials[3].notes[1] as! TextNote).text, caption4.text)
    XCTAssertEqual(experiment.trials[3].notes[1].timestamp, trial4.recordingRange.min)

    // Pre-existing notes are untouched.
    XCTAssertEqual((experiment.trials[2].notes[0] as! TextNote).text, note3.text)
    XCTAssertEqual((experiment.trials[3].notes[0] as! TextNote).text, note4.text)

    // Trial note counts.
    XCTAssertEqual(experiment.trials[0].notes.count, 0)
    XCTAssertEqual(experiment.trials[1].notes.count, 1)
    XCTAssertEqual(experiment.trials[2].notes.count, 1)
    XCTAssertEqual(experiment.trials[3].notes.count, 2)

    // Captions should be nil in all trials.
    XCTAssertNil(experiment.trials[0].caption)
    XCTAssertNil(experiment.trials[1].caption)
    XCTAssertNil(experiment.trials[2].caption)
    XCTAssertNil(experiment.trials[3].caption)
  }

  func testUserMetadataImagePathMigrationFromPlatformVersion1() {
    let userMetadata = UserMetadata()
    userMetadata.fileVersion = FileVersion(major: 1, minor: 1, platform: 1)

    let overview1 = ExperimentOverview(experimentID: "1")
    overview1.imagePath = "experiments/ABC123/assets/some_file.jpg"
    let overview2 = ExperimentOverview(experimentID: "2")
    overview2.imagePath = "experiments/ABC123/assets/ExperimentCoverImage.jpg"
    userMetadata.addExperimentOverview(overview1)
    userMetadata.addExperimentOverview(overview2)

    // This upgrade can have any platform version > 1.
    XCTAssertNoThrow(
      try metadataManager.upgradeUserMetadataVersionIfNeeded(userMetadata,
                                                             toMajorVersion: 1,
                                                             toMinorVersion: 1,
                                                             toPlatformVersion: 2)
    )

    XCTAssertEqual("assets/some_file.jpg", userMetadata.experimentOverviews[0].imagePath)
    XCTAssertEqual("assets/ExperimentCoverImage.jpg", userMetadata.experimentOverviews[1].imagePath)
  }

  func testAddingStatsForPlatformVersion705() {
    let trial1 = Trial()
    let trial2 = Trial()
    trial1.ID = "TEST_TRIAL_1_MIGRATION"
    trial2.ID = "TEST_TRIAL_2_MIGRATION"

    // Create some dummy data that is unique for each sensor.
    let context = sensorDataManager.privateContext
    context.performAndWait {
      for index in 1...5 {
        let sensorID = "SENSOR_ID_" + String(index)
        let trial = index < 3 ? trial1 : trial2
        trial.trialStats.append(TrialStats(sensorID: sensorID))

        let endIndex = index * 2
        for value in index...endIndex {
          SensorData.insert(dataPoint: DataPoint(x: Int64(value), y: Double(value)),
                            forSensorID: sensorID,
                            trialID: trial.ID,
                            resolutionTier: 0,
                            context: context)
        }

        // Add some extra data for other resolution tiers.
        for tier: Int16 in 1...3 {
          SensorData.insert(dataPoint: DataPoint(x: 0, y: 10),
                            forSensorID: sensorID,
                            trialID: trial.ID,
                            resolutionTier: tier,
                            context: context)
        }
      }
    }
    sensorDataManager.savePrivateContext()

    let experiment = Experiment(ID: "")
    experiment.fileVersion.version = 1
    experiment.fileVersion.minorVersion = 2
    experiment.fileVersion.platformVersion = 705
    experiment.trials = [trial1, trial2]

    XCTAssertNil(trial1.trialStats[0].numberOfValues)
    XCTAssertNil(trial1.trialStats[0].totalDuration)
    XCTAssertNil(trial1.trialStats[0].zoomPresenterTierCount)
    XCTAssertNil(trial1.trialStats[0].zoomLevelBetweenTiers)
    XCTAssertNil(trial1.trialStats[1].numberOfValues)
    XCTAssertNil(trial1.trialStats[1].totalDuration)
    XCTAssertNil(trial1.trialStats[1].zoomPresenterTierCount)
    XCTAssertNil(trial1.trialStats[1].zoomLevelBetweenTiers)
    XCTAssertNil(trial2.trialStats[0].numberOfValues)
    XCTAssertNil(trial2.trialStats[0].totalDuration)
    XCTAssertNil(trial2.trialStats[0].zoomPresenterTierCount)
    XCTAssertNil(trial2.trialStats[0].zoomLevelBetweenTiers)
    XCTAssertNil(trial2.trialStats[1].numberOfValues)
    XCTAssertNil(trial2.trialStats[1].totalDuration)
    XCTAssertNil(trial2.trialStats[1].zoomPresenterTierCount)
    XCTAssertNil(trial2.trialStats[1].zoomLevelBetweenTiers)
    XCTAssertNil(trial2.trialStats[2].numberOfValues)
    XCTAssertNil(trial2.trialStats[2].totalDuration)
    XCTAssertNil(trial2.trialStats[2].zoomPresenterTierCount)
    XCTAssertNil(trial2.trialStats[2].zoomLevelBetweenTiers)

    XCTAssertNoThrow(
      try metadataManager.upgradeExperimentVersionIfNeeded(experiment,
                                                           toMajorVersion: 1,
                                                           toMinorVersion: 2,
                                                           toPlatformVersion: 800)
    )

    XCTAssertEqual(1, experiment.fileVersion.version)
    XCTAssertEqual(2, experiment.fileVersion.minorVersion)
    XCTAssertEqual(800, experiment.fileVersion.platformVersion)

    XCTAssertEqual(2, trial1.trialStats[0].numberOfValues)
    XCTAssertEqual(1, trial1.trialStats[0].totalDuration)
    XCTAssertEqual(4, trial1.trialStats[0].zoomPresenterTierCount)
    XCTAssertEqual(20, trial1.trialStats[0].zoomLevelBetweenTiers)
    XCTAssertEqual(3, trial1.trialStats[1].numberOfValues)
    XCTAssertEqual(2, trial1.trialStats[1].totalDuration)
    XCTAssertEqual(4, trial1.trialStats[1].zoomPresenterTierCount)
    XCTAssertEqual(20, trial1.trialStats[1].zoomLevelBetweenTiers)
    XCTAssertEqual(4, trial2.trialStats[0].numberOfValues)
    XCTAssertEqual(3, trial2.trialStats[0].totalDuration)
    XCTAssertEqual(4, trial2.trialStats[0].zoomPresenterTierCount)
    XCTAssertEqual(20, trial2.trialStats[0].zoomLevelBetweenTiers)
    XCTAssertEqual(5, trial2.trialStats[1].numberOfValues)
    XCTAssertEqual(4, trial2.trialStats[1].totalDuration)
    XCTAssertEqual(4, trial2.trialStats[1].zoomPresenterTierCount)
    XCTAssertEqual(20, trial2.trialStats[1].zoomLevelBetweenTiers)
    XCTAssertEqual(6, trial2.trialStats[2].numberOfValues)
    XCTAssertEqual(5, trial2.trialStats[2].totalDuration)
    XCTAssertEqual(4, trial2.trialStats[2].zoomPresenterTierCount)
    XCTAssertEqual(20, trial2.trialStats[2].zoomLevelBetweenTiers)
  }

  func testOverviewImagePathsForPlatformVersion705() {
    let userMetadata = UserMetadata()
    userMetadata.fileVersion.version = 1
    userMetadata.fileVersion.minorVersion = 1
    userMetadata.fileVersion.platformVersion = 1
    userMetadata.fileVersion.platform = .ios

    // Overview with a nil image path, trial has a picture note.
    let experiment1 = Experiment(ID: "EXP_1")
    let overview1 = ExperimentOverview(experimentID: experiment1.ID)
    let pictureNote1 = PictureNote()
    pictureNote1.filePath = "picture_path_1.jpg"
    let trial1 = Trial()
    trial1.notes = [pictureNote1]
    experiment1.trials = [trial1]
    metadataManager.saveExperiment(experiment1)
    XCTAssertNil(overview1.imagePath)

    // Overview has non-nil image path, experiment has picture note.
    let experiment2 = Experiment(ID: "EXP_2")
    let overview2 = ExperimentOverview(experimentID: experiment2.ID)
    overview2.imagePath = "existing_path.jpg"
    experiment2.notes = [pictureNote1]
    metadataManager.saveExperiment(experiment2)

    // Overview has nil image path, experiment does NOT have any picture notes.
    let experiment3 = Experiment(ID: "EXP_3")
    let overview3 = ExperimentOverview(experimentID: experiment3.ID)
    XCTAssertEqual(0, experiment3.notes.count)
    XCTAssertEqual(0, experiment3.trials.count)
    XCTAssertNil(overview3.imagePath)
    metadataManager.saveExperiment(experiment3)

    // Overview with a nil image path, experiment and trial have picture notes.
    let experiment4 = Experiment(ID: "EXP_4")
    let overview4 = ExperimentOverview(experimentID: experiment4.ID)
    let pictureNote2 = PictureNote()
    pictureNote2.filePath = "picture_path_2.jpg"
    let trial = Trial()
    trial.notes = [pictureNote2]
    experiment4.notes = [pictureNote1]
    experiment4.trials = [trial]
    metadataManager.saveExperiment(experiment4)
    XCTAssertNil(overview4.imagePath)

    userMetadata.addExperimentOverview(overview1)
    userMetadata.addExperimentOverview(overview2)
    userMetadata.addExperimentOverview(overview3)
    userMetadata.addExperimentOverview(overview4)

    XCTAssertNoThrow(
      try metadataManager.upgradeUserMetadataVersionIfNeeded(userMetadata,
                                                             toMajorVersion: 1,
                                                             toMinorVersion: 1,
                                                             toPlatformVersion: 800)
    )

    XCTAssertEqual("picture_path_1.jpg", userMetadata.experimentOverview(with: "EXP_1")?.imagePath)
    XCTAssertEqual("existing_path.jpg", userMetadata.experimentOverview(with: "EXP_2")?.imagePath)
    XCTAssertNil(userMetadata.experimentOverview(with: "EXP_3")?.imagePath)
    XCTAssertEqual("picture_path_1.jpg", userMetadata.experimentOverview(with: "EXP_4")?.imagePath)
  }

  func testCanOpenExperimentVersion() {
    let experimentProto = GSJExperiment()

    experimentProto.fileVersion = GSJFileVersion()
    experimentProto.fileVersion.version = 1
    experimentProto.fileVersion.minorVersion = 1
    let experimentID = "1234567890"

    writeExperimentProto(experimentProto, withID: experimentID)
    XCTAssertNotNil(metadataManager.experiment(withID: experimentID))

    experimentProto.fileVersion.minorVersion = 2
    writeExperimentProto(experimentProto, withID: experimentID)
    XCTAssertNotNil(metadataManager.experiment(withID: experimentID))

    experimentProto.fileVersion.minorVersion = 3
    writeExperimentProto(experimentProto, withID: experimentID)
    XCTAssertNotNil(metadataManager.experiment(withID: experimentID))

    experimentProto.fileVersion.version = 2
    experimentProto.fileVersion.minorVersion = 1
    writeExperimentProto(experimentProto, withID: experimentID)
    XCTAssertNil(metadataManager.experiment(withID: experimentID))

    experimentProto.fileVersion.version = 0
    experimentProto.fileVersion.minorVersion = 0
    writeExperimentProto(experimentProto, withID: experimentID)
    XCTAssertNotNil(metadataManager.experiment(withID: experimentID))
  }

  func testUpdateCoverImageForAddedImageWithNilPath() {
    // overview with nil path
    let (experiment, overview) = metadataManager.createExperiment()
    XCTAssertNil(overview.imagePath)
    XCTAssertNil(experiment.imagePath)
    metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: "new/image/path",
                                                          experiment: experiment)
    XCTAssertEqual("new/image/path", overview.imagePath)
    XCTAssertEqual("new/image/path", experiment.imagePath)
  }

  func testUpdateCoverImageForAddedImageWithExistingPath() {
    // overview with nil path
    let (experiment, overview) = metadataManager.createExperiment()
    overview.imagePath = "old/path/to/image"
    experiment.imagePath = "old/path/to/image"
    metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: "new/image/path",
                                                          experiment: experiment)
    XCTAssertEqual("old/path/to/image", overview.imagePath)
    XCTAssertEqual("old/path/to/image", experiment.imagePath)
  }

  func testUpdateCoverImageForRemovedImageWithOtherNotes() {
    let (experiment, overview) = metadataManager.createExperiment()
    overview.imagePath = "assets/experiment_image.jpg"
    experiment.imagePath = "assets/experiment_image.jpg"

    let trial = Trial()
    let pictureNote = PictureNote()
    pictureNote.filePath = "assets/trial_image.jpg"
    trial.notes = [pictureNote]
    experiment.trials = [trial]
    metadataManager.saveExperiment(experiment)

    // Save actual images.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    metadataManager.saveImage(image,
                              atPicturePath: "assets/experiment_image.jpg",
                              experimentID: overview.experimentID)
    metadataManager.saveImage(image,
                              atPicturePath: "assets/trial_image.jpg",
                              experimentID: overview.experimentID)

    var undoBlock = metadataManager.updateCoverImageForRemovedImageIfNeeded(
        imagePath: "assets/experiment_image.jpg",
        experiment: experiment)

    XCTAssertEqual("assets/trial_image.jpg",
                   overview.imagePath,
                   "Overview image changed to other image note in experiment.")
    XCTAssertEqual("assets/trial_image.jpg",
                   experiment.imagePath,
                   "Experiment image changed to other image note in experiment.")

    undoBlock()

    XCTAssertEqual("assets/experiment_image.jpg",
                   overview.imagePath,
                   "Previous overview image restored after undo block executed.")
    XCTAssertEqual("assets/experiment_image.jpg",
                   experiment.imagePath,
                   "Previous experiment image restored after undo block executed.")

    // Remove the picture notes.
    trial.notes = []
    metadataManager.saveExperiment(experiment)

    undoBlock = metadataManager.updateCoverImageForRemovedImageIfNeeded(
        imagePath: "assets/experiment_image.jpg",
        experiment: experiment)

    XCTAssertNil(overview.imagePath,
                 "Overview image is nil when previous image removed and no picture notes exist.")
    XCTAssertNil(experiment.imagePath,
                 "Experiment image is nil when previous image removed and no picture notes exist.")

    undoBlock()

    XCTAssertEqual("assets/experiment_image.jpg",
                   overview.imagePath,
                   "Previous overview image restored after undo block executed.")
    XCTAssertEqual("assets/experiment_image.jpg",
                   experiment.imagePath,
                   "Previous experiment image restored after undo block executed.")
  }

  func testUpdateCoverImageForRemovedImageNoMatch() {
    let (experiment, overview) = metadataManager.createExperiment()
    overview.imagePath = "assets/cover_image.jpg"
    experiment.imagePath = "assets/cover_image.jpg"

    _ = metadataManager.updateCoverImageForRemovedImageIfNeeded(
        imagePath: "assets/other_image.jpg",
        experiment: experiment)

    XCTAssertEqual("assets/cover_image.jpg",
                   overview.imagePath,
                   "Overview image did not change because removed path didn't match.")
    XCTAssertEqual("assets/cover_image.jpg",
                   experiment.imagePath,
                   "Experiment image did not change because removed path didn't match.")
  }

  func testSavingCoverImageData() {
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    let imageData = image.jpegData(compressionQuality: 0.8)

    let (experiment, overview) = metadataManager.createExperiment()

    XCTAssertNil(experiment.imagePath)
    XCTAssertNil(overview.imagePath)

    metadataManager.saveCoverImageData(imageData, metadata: nil, forExperiment: experiment)

    XCTAssertNotNil(experiment.imagePath)
    XCTAssertNotNil(overview.imagePath)

    let coverImageURL = metadataManager.pictureFileURL(for: experiment.imagePath!,
                                                       experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: coverImageURL.path))
  }

  func testRemovingUsedCoverImage() {
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!

    let (experiment, overview) = metadataManager.createExperiment()

    XCTAssertNil(experiment.imagePath)
    XCTAssertNil(overview.imagePath)

    let imagePath = "assets/note_image.jpg"
    metadataManager.saveImage(image,
                              atPicturePath: imagePath,
                              experimentID: experiment.ID)
    let pictureNote = PictureNote()
    pictureNote.filePath = imagePath
    experiment.addNote(pictureNote)

    let noteImageURL = metadataManager.pictureFileURL(for: imagePath,
                                                      experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: noteImageURL.path), "Note image exists")

    metadataManager.updateCoverImageForAddedImageIfNeeded(imagePath: imagePath,
                                                          experiment: experiment)

    XCTAssertEqual(imagePath, experiment.imagePath)
    XCTAssertEqual(imagePath, overview.imagePath)

    let image2 = UIImage(named: "select_item_button",
                         in: Bundle.currentBundle,
                         compatibleWith: nil)!
    let imageData = image2.jpegData(compressionQuality: 0.8)
    metadataManager.saveCoverImageData(imageData, metadata: nil, forExperiment: experiment)

    XCTAssertTrue(FileManager.default.fileExists(atPath: noteImageURL.path),
                  "Note image still exists")
  }

  func testRemovingUnusedCoverImage() {
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    let imageData = image.jpegData(compressionQuality: 0.8)

    let (experiment, overview) = metadataManager.createExperiment()

    XCTAssertNil(experiment.imagePath)
    XCTAssertNil(overview.imagePath)

    metadataManager.saveCoverImageData(imageData, metadata: nil, forExperiment: experiment)

    XCTAssertNotNil(experiment.imagePath)
    XCTAssertNotNil(overview.imagePath)

    let coverImageURL1 = metadataManager.pictureFileURL(for: experiment.imagePath!,
                                                        experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: coverImageURL1.path))

    metadataManager.saveCoverImageData(imageData, metadata: nil, forExperiment: experiment)

    XCTAssertNotNil(experiment.imagePath)
    XCTAssertNotNil(overview.imagePath)

    let coverImageURL2 = metadataManager.pictureFileURL(for: experiment.imagePath!,
                                                        experimentID: experiment.ID)
    XCTAssertTrue(FileManager.default.fileExists(atPath: coverImageURL2.path),
                  "New cover image exists.")
    XCTAssertFalse(FileManager.default.fileExists(atPath: coverImageURL1.path),
                   "Original cover image doesn't exist.")
  }

  func testAddingAndGettingExperimentsAndOverviews() {
    // Create an experiment and overview and add them to the metadata manager.
    let experimentID = "testID"
    let experimentTitle = "test title"
    let lastUsedDate = Date(timeIntervalSince1970: 1000)
    let colorPalette = MDCPalette.green
    let textNote = TextNote(text: "test text")
    let overview = ExperimentOverview(experimentID: experimentID)
    overview.title = experimentTitle
    overview.lastUsedDate = lastUsedDate
    overview.colorPalette = colorPalette
    let experiment = Experiment(ID: experimentID)
    experiment.setTitle(experimentTitle)
    experiment.notes.append(textNote)
    metadataManager.addExperiment(experiment, overview: overview)

    // Assert they are returned, and the expected properties are equal.
    let experimentAndOverview = metadataManager.experimentAndOverview(forExperimentID: experimentID)
    XCTAssertEqual(experimentAndOverview?.experiment.ID, experimentID)
    XCTAssertEqual(experimentAndOverview?.experiment.title, experimentTitle)
    XCTAssertEqual(experimentAndOverview?.experiment.notes[0].ID, textNote.ID)
    XCTAssertEqual(experimentAndOverview?.overview.experimentID, experimentID)
    XCTAssertEqual(experimentAndOverview?.overview.title, experimentTitle)
    XCTAssertEqual(experimentAndOverview?.overview.lastUsedDate, lastUsedDate)
    XCTAssertEqual(experimentAndOverview?.overview.colorPalette, colorPalette)
  }

  func testExperimentLibraryAdded() {
    let (experiment, _) = metadataManager.createExperiment()
    XCTAssertFalse(metadataManager.experimentLibrary.isExperimentArchived(withID: experiment.ID)!)
    XCTAssertFalse(metadataManager.experimentLibrary.isExperimentDeleted(withID: experiment.ID)!)
  }

  func testExperimentLibraryArchived() {
    let (experiment, _) = metadataManager.createExperiment()
    XCTAssertFalse(metadataManager.experimentLibrary.isExperimentArchived(withID: experiment.ID)!)

    metadataManager.toggleArchiveStateForExperiment(withID: experiment.ID)

    XCTAssertTrue(metadataManager.experimentLibrary.isExperimentArchived(withID: experiment.ID)!)
  }

  func testExperimentLibraryOpened() {
    let settableClock = SettableClock(now: 100)
    metadataManager.clock = settableClock
    let (experiment, _) = metadataManager.createExperiment()
    XCTAssertEqual(100,
                   metadataManager.experimentLibrary.experimentLastModified(withID: experiment.ID))
    XCTAssertEqual(100,
                   metadataManager.experimentLibrary.experimentLastOpened(withID: experiment.ID))

    settableClock.setNow(500)
    metadataManager.markExperimentOpened(withID: experiment.ID)

    XCTAssertEqual(100,
                   metadataManager.experimentLibrary.experimentLastModified(withID: experiment.ID))
    XCTAssertEqual(500,
                   metadataManager.experimentLibrary.experimentLastOpened(withID: experiment.ID))
  }

  func testExperientLibraryModified() {
    let settableClock = SettableClock(now: 100)
    metadataManager.clock = settableClock
    let (experiment, _) = metadataManager.createExperiment()
    XCTAssertEqual(100,
                   metadataManager.experimentLibrary.experimentLastModified(withID: experiment.ID))
    XCTAssertEqual(100,
                   metadataManager.experimentLibrary.experimentLastOpened(withID: experiment.ID))

    settableClock.setNow(500)
    metadataManager.saveExperiment(experiment)

    XCTAssertEqual(500,
                   metadataManager.experimentLibrary.experimentLastModified(withID: experiment.ID))
    XCTAssertEqual(100,
                   metadataManager.experimentLibrary.experimentLastOpened(withID: experiment.ID))
  }

  func testImageFilesExistForExperiment() {
    // Create some picture notes in a trial, some in an experiment, and a cover image.
    let experiment = Experiment(ID: "testExperiment")
    experiment.imagePath = MetadataManager.assetsDirectoryName + "/" + UUID().uuidString + ".jpg"
    let trial = Trial()
    experiment.trials = [trial]

    let pictureNote1 = PictureNote()
    pictureNote1.filePath = metadataManager.relativePicturePath(for: pictureNote1.ID)
    let pictureNote2 = PictureNote()
    pictureNote2.filePath = metadataManager.relativePicturePath(for: pictureNote2.ID)
    experiment.notes = [pictureNote1, pictureNote2]

    let pictureNote3 = PictureNote()
    pictureNote3.filePath = metadataManager.relativePicturePath(for: pictureNote3.ID)
    let pictureNote4 = PictureNote()
    pictureNote4.filePath = metadataManager.relativePicturePath(for: pictureNote4.ID)
    trial.notes = [pictureNote3, pictureNote4]

    // None of the images exist on disk.
    XCTAssertFalse(metadataManager.imageFilesExist(forExperiment: experiment),
                   "The images should not exist on disk.")

    // Save one of the experiment's and one of the trial's picture note's images to disk.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    metadataManager.saveImage(image,
                              atPicturePath: pictureNote1.filePath!,
                              experimentID: experiment.ID)
    metadataManager.saveImage(image,
                              atPicturePath: pictureNote3.filePath!,
                              experimentID: experiment.ID)
    XCTAssertFalse(metadataManager.imageFilesExist(forExperiment: experiment),
                   "Not all of the images should exist on disk.")

    // Save all of the experiment's picture note's images to disk.
    metadataManager.saveImage(image,
                              atPicturePath: pictureNote2.filePath!,
                              experimentID: experiment.ID)
    XCTAssertFalse(metadataManager.imageFilesExist(forExperiment: experiment),
                   "Not all of the images should exist on disk.")

    // Save the trial's picture note's images to disk so that all of the picture note's images are
    // saved to disk, but not the cover image yet.
    metadataManager.saveImage(image,
                              atPicturePath: pictureNote4.filePath!,
                              experimentID: experiment.ID)
    XCTAssertFalse(metadataManager.imageFilesExist(forExperiment: experiment),
                  "Not all of the images should exist on disk.")

    // Save the cover image to disk.
    metadataManager.saveImage(image,
                              atPicturePath: experiment.imagePath!,
                              experimentID: experiment.ID)
    XCTAssertTrue(metadataManager.imageFilesExist(forExperiment: experiment),
                   "All of the images should exist on disk.")
  }

  func testSaveNewerVersionViaURL() {
    let experiment = Experiment(ID: "TEST_ID_111")
    experiment.setTitle("ABC Title")
    experiment.imagePath = "foo/path/789"
    experiment.fileVersion = FileVersion(major: Experiment.Version.major,
                                         minor: Experiment.Version.minor + 1,
                                         platform: 0)

    let saveURL = metadataManager.experimentsDirectoryURL.appendingPathComponent(experiment.ID)
        .appendingPathComponent("experiment.proto")
    metadataManager.saveExperiment(experiment, toURL: saveURL)
    XCTAssertNotNil(metadataManager.experiment(withID: "TEST_ID_111"))
  }

  func testOverviewAfterAddingImportedExperimentCurrentVersion() {
    let experiment = Experiment(ID: "TEST_ID_222")
    experiment.setTitle("ABC Title")
    experiment.imagePath = "foo/path/789"
    experiment.fileVersion = FileVersion(major: Experiment.Version.major,
                                         minor: Experiment.Version.minor,
                                         platform: 0)

    let saveURL = metadataManager.experimentsDirectoryURL.appendingPathComponent(experiment.ID)
        .appendingPathComponent("experiment.proto")
    metadataManager.saveExperiment(experiment, toURL: saveURL)
    metadataManager.addImportedExperiment(withID: "TEST_ID_222")

    let overview = metadataManager.experimentOverviews[0]
    XCTAssertEqual("ABC Title", overview.title)
    XCTAssertNil(overview.imagePath, "imagePath should be ignored for imported experiments.")
  }

  func testOverviewAfterAddingImportedExperimentNewerMinorVersion() {
    let experiment = Experiment(ID: "TEST_ID_333")
    experiment.setTitle("ABC Title")
    experiment.imagePath = "foo/path/789"
    experiment.fileVersion = FileVersion(major: Experiment.Version.major,
                                         minor: Experiment.Version.minor + 1,
                                         platform: 0)

    let saveURL = metadataManager.experimentsDirectoryURL.appendingPathComponent(experiment.ID)
        .appendingPathComponent("experiment.proto")
    metadataManager.saveExperiment(experiment, toURL: saveURL)
    metadataManager.addImportedExperiment(withID: "TEST_ID_333")

    let overview = metadataManager.experimentOverviews[0]
    XCTAssertEqual("ABC Title", overview.title)
    XCTAssertNil(overview.imagePath, "imagePath should be ignored for imported experiments.")
  }

  func testSaveNewerVersionWithoutValidating() {
    let experiment = Experiment(ID: "TEST_ID_444")
    experiment.setTitle("ABC Title")
    experiment.imagePath = "foo/path/789"
    experiment.fileVersion = FileVersion(major: Experiment.Version.major,
                                         minor: Experiment.Version.minor + 1,
                                         platform: 0)

    metadataManager.saveExperiment(experiment, validateVersion: false)
    XCTAssertNotNil(metadataManager.experiment(withID: "TEST_ID_444"))
  }

  func testDoesNotSaveNewerVersionWithValidating() {
    let experiment = Experiment(ID: "TEST_ID_555")
    experiment.setTitle("ABC Title")
    experiment.imagePath = "foo/path/789"
    experiment.fileVersion = FileVersion(major: Experiment.Version.major,
                                         minor: Experiment.Version.minor + 1,
                                         platform: 0)

    metadataManager.saveExperiment(experiment)
    XCTAssertNil(metadataManager.experiment(withID: "TEST_ID_555"))
  }

  func testUpdateOverviewForExperiment() {
    // Add an experiment and its overview to metadata.
    let overview = ExperimentOverview(experimentID: "test_experiment")
    metadataManager.clock = SettableClock(now: 1234)
    let originalLastUsedDate = metadataManager.clock.now
    overview.lastUsedDate = originalLastUsedDate
    overview.imagePath = "image/path"
    let originalImagePath = overview.imagePath
    let experiment = Experiment(ID: overview.experimentID)
    metadataManager.addExperiment(experiment, overview: overview)

    // Modify some experiment properties and confirm the overview reflects the desired experiment's
    // data.
    experiment.setTitle("test title")
    metadataManager.clock = SettableClock(now: 5678)
    experiment.trials = [Trial(), Trial()]
    metadataManager.saveExperimentWithoutDateChange(experiment)

    // Title and trial count should update, last used date and image path should not.
    XCTAssertEqual(experiment.title, overview.title)
    XCTAssertEqual(overview.lastUsedDate.millisecondsSince1970,
                   originalLastUsedDate.millisecondsSince1970)
    XCTAssertEqual(overview.trialCount, 2)
    XCTAssertEqual(overview.imagePath, originalImagePath)
  }

  func testUpdateOverviewForExperimentLastUsedDate() {
    // Add an experiment and its overview to metadata.
    let overview = ExperimentOverview(experimentID: "test_experiment")
    metadataManager.clock = SettableClock(now: 1234)
    overview.lastUsedDate = metadataManager.clock.now
    let experiment = Experiment(ID: overview.experimentID)
    metadataManager.addExperiment(experiment, overview: overview)

    // Update the overview and confirm the overview reflects the new last used date.
    metadataManager.clock = SettableClock(now: 5678)
    metadataManager.saveExperiment(experiment)
    XCTAssertEqual(overview.lastUsedDate.millisecondsSince1970,
                   metadataManager.clock.now.millisecondsSince1970)
  }

  func testUpdateOverviewForExperimentImagePath() {
    // Add an experiment and its overview to metadata.
    let overview = ExperimentOverview(experimentID: "test_experiment")
    overview.imagePath = "image/path"
    let experiment = Experiment(ID: overview.experimentID)
    metadataManager.addExperiment(experiment, overview: overview)

    // Modify the experiment's image path and confirm the overview reflects it.
    experiment.imagePath = "new/image/path"
    metadataManager.saveExperiment(experiment)
    XCTAssertEqual(overview.imagePath, experiment.imagePath)
  }

  func testCoverImageForImportedExperiment() {
    let experiment = Experiment(ID: "TEST_ID_222")
    experiment.setTitle("ABC Title")
    experiment.imagePath = "foo/path/789"
    experiment.fileVersion = FileVersion(major: Experiment.Version.major,
                                         minor: Experiment.Version.minor,
                                         platform: 0)

    // Simulate a cover image that was copied to ExperimentCoverImage.jpg during export.
    let image = UIImage(named: "record_button", in: Bundle.currentBundle, compatibleWith: nil)!
    metadataManager.saveImage(image, atPicturePath: "assets/123456.jpg",
                              experimentID: experiment.ID)
    metadataManager.saveImage(image, atPicturePath: metadataManager.importExportCoverImagePath,
                              experimentID: experiment.ID)
    experiment.imagePath = "assets/123456.jpg"

    let saveURL = metadataManager.experimentsDirectoryURL.appendingPathComponent(experiment.ID)
        .appendingPathComponent("experiment.proto")
    metadataManager.saveExperiment(experiment, toURL: saveURL)
    metadataManager.addImportedExperiment(withID: "TEST_ID_222")

    let (latestExperiment, overview) =
        metadataManager.experimentAndOverview(forExperimentID: "TEST_ID_222")!

    XCTAssertEqual(metadataManager.importExportCoverImagePath,
                   latestExperiment.imagePath,
                   "After import the image path is now the standardized cover image path filename.")
    XCTAssertEqual(metadataManager.importExportCoverImagePath, overview.imagePath)
  }

  func testCreateOverviewFromExperimentLibraryForExperiment() {
    let experiment = Experiment(ID: "TEST_ID_234")
    let syncExperiment = SyncExperiment(experimentID: "TEST_ID_234", clock: Clock())
    syncExperiment.isArchived = true
    syncExperiment.lastModifiedTimestamp = 1000000
    experiment.setTitle("test title")
    experiment.imagePath = "path/to/image"
    metadataManager.experimentLibrary.addExperiment(syncExperiment)

    metadataManager.createOverviewFromExperimentLibrary(forExperiment: experiment)

    let overview = metadataManager.experimentOverviews[0]
    XCTAssertEqual(overview.experimentID, "TEST_ID_234")
    XCTAssertEqual(overview.isArchived, true)
    XCTAssertEqual(overview.lastUsedDate.millisecondsSince1970, 1000000)
    XCTAssertEqual(overview.title, "test title")
    XCTAssertEqual(overview.imagePath, "path/to/image")
  }

  func testRecreateOverviewsIfUserMetadataDeleted() {
    _ = metadataManager.createExperiment(withTitle: "Missing Experiment 1")
    _ = metadataManager.createExperiment(withTitle: "Missing Experiment 2")
    _ = metadataManager.createExperiment(withTitle: "Missing Experiment 3")

    XCTAssertEqual(3, metadataManager.experimentOverviews.count)

    let userMetadataURL = testingRootURL.appendingPathComponent("user_metadata")
    XCTAssertTrue(FileManager.default.fileExists(atPath: userMetadataURL.path))

    XCTAssertNoThrow(try FileManager.default.removeItem(at: userMetadataURL))

    XCTAssertFalse(FileManager.default.fileExists(atPath: userMetadataURL.path))

    // Create new metadataManager instance at the same root URL to simulate what happens when a user
    // session begins.
    let anotherMetadataManager = MetadataManager(rootURL: testingRootURL,
                                                 deletedRootURL: testingRootURL,
                                                 preferenceManager: PreferenceManager(),
                                                 sensorController: MockSensorController(),
                                                 sensorDataManager: sensorDataManager)

    // Verify userMetadata file exists
    XCTAssertTrue(FileManager.default.fileExists(atPath: userMetadataURL.path))

    // Verify overviews exist
    XCTAssertEqual(3, anotherMetadataManager.experimentOverviews.count)
  }

  func testAddMissingOverviews() {
    _ = metadataManager.createExperiment(withTitle: "Missing Experiment 1")
    _ = metadataManager.createExperiment(withTitle: "Missing Experiment 2")

    XCTAssertEqual(2, metadataManager.experimentOverviews.count)

    let newExperiment = Experiment(ID: "Orphaned Experiment ID")
    newExperiment.setTitle("Orphan")
    if let protoData = newExperiment.proto.data() {
      let newExperimentURL =
          metadataManager.experimentsDirectoryURL.appendingPathComponent("Orphaned Experiment ID")

      XCTAssertNoThrow(try FileManager.default.createDirectory(atPath: newExperimentURL.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil))

      let newExperimentProtoURL = newExperimentURL.appendingPathComponent("experiment.proto")
      XCTAssertNoThrow(try protoData.write(to: newExperimentProtoURL))
    }

    // Create new metadataManager instance at the same root URL to simulate what happens when a user
    // session begins.
    let anotherMetadataManager = MetadataManager(rootURL: testingRootURL,
                                                 deletedRootURL: testingRootURL,
                                                 preferenceManager: PreferenceManager(),
                                                 sensorController: MockSensorController(),
                                                 sensorDataManager: sensorDataManager)

    XCTAssertEqual(3, anotherMetadataManager.experimentOverviews.count)
    XCTAssertEqual("Orphaned Experiment ID",
                   anotherMetadataManager.experimentOverviews[2].experimentID)
    XCTAssertEqual("Orphan", anotherMetadataManager.experimentOverviews[2].title)
  }

  func testImportedExperimentTitle() {
    let noTitleExperiment = Experiment(ID: "testImportedExperimentTitle_noTitle")
    let noTitleExperimentSaveURL =
        metadataManager.experimentsDirectoryURL.appendingPathComponent(noTitleExperiment.ID)
            .appendingPathComponent("experiment.proto")
    metadataManager.saveExperiment(noTitleExperiment, toURL: noTitleExperimentSaveURL)
    metadataManager.addImportedExperiment(withID: noTitleExperiment.ID)
    let noTitleExperimentAndOverview =
        metadataManager.experimentAndOverview(forExperimentID: noTitleExperiment.ID)
    XCTAssertEqual("Untitled Experiment",
                   noTitleExperimentAndOverview?.experiment.title,
                   "Experiment title should be set to the default title")
    XCTAssertEqual("Untitled Experiment",
                   noTitleExperimentAndOverview?.overview.title,
                   "Overview title should be set to the default title")

    let titledExperiment = Experiment(ID: "testImportedExperimentTitle_hasTitle")
    titledExperiment.setTitle("has a title")
    let titledExperimentSaveURL =
        metadataManager.experimentsDirectoryURL.appendingPathComponent(titledExperiment.ID)
            .appendingPathComponent("experiment.proto")
    metadataManager.saveExperiment(titledExperiment, toURL: titledExperimentSaveURL)
    metadataManager.addImportedExperiment(withID: titledExperiment.ID)
    let titledExperimentAndOverview =
        metadataManager.experimentAndOverview(forExperimentID: titledExperiment.ID)
    XCTAssertEqual("has a title",
                   titledExperimentAndOverview?.experiment.title,
                   "Experiment title should not have changed")
    XCTAssertEqual("has a title",
                   titledExperimentAndOverview?.overview.title,
                   "Overview title should not have changed")
  }

  // MARK: - Helpers

  /// Creates an experiment that has one trial with sensor data, and asserts it and its data are on
  /// disk.
  ///
  /// - Returns: The experiment.
  func createExperimentAndAssert() -> Experiment {
    // Create the experiment.
    let (experiment, _) = metadataManager.createExperiment()

    // Create a trial with sensor data and add it to the experiment.
    let trial = Trial()
    trial.ID = "test trial"
    experiment.trials.append(trial)
    metadataManager.saveExperiment(experiment)

    // Assert the experiment is on disk, along with its overview and trial sensor data.
    XCTAssertNotNil(metadataManager.experiment(withID: experiment.ID),
                    "The experiment should be on disk.")
    XCTAssertTrue(metadataManager.experimentOverviews.contains {
      $0.experimentID == experiment.ID }, "The experiment should have a corresponding overview.")
    return experiment
  }

  /// Asserts the experiment with an ID and its overview are not on disk, as well as a trial's
  /// sensor data.
  ///
  /// - Parameters:
  ///   - experimentID: The experiment ID.
  ///   - trialID: The trial ID.
  func assertExperimentIsDeleted(withID experimentID: String,
                                 andSensorDataForTrialID trialID: String) {
    XCTAssertNil(metadataManager.experiment(withID: experimentID),
                 "The experiment should not be on disk.")
    XCTAssertFalse(metadataManager.experimentOverviews.contains {
                       $0.experimentID == experimentID },
                   "The experiment should not have a corresponding overview.")
  }

  // Writes an experiment proto directly to the experiments directory. This way invalid data can
  // be tested that would not be allowed by MetadataManager's save methods.
  func writeExperimentProto(_ experimentProto: GSJExperiment, withID experimentID: String) {
    let data = experimentProto.data()!
    let experimentURL = testingRootURL.appendingPathComponent("experiments")
        .appendingPathComponent(experimentID)
    try! FileManager.default.createDirectory(at: experimentURL,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
    try! data.write(to: experimentURL.appendingPathComponent("experiment.proto"))
  }

}
