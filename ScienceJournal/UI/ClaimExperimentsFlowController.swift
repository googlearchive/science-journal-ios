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

import UIKit

/// Manages the navigation of the claim experiments flow which begins when a user presses claim
/// experiments from the experiments list, and includes all management of data such as viewing,
/// claiming, and deleting experiments.
class ClaimExperimentsFlowController: UIViewController, ClaimExperimentsViewControllerDelegate,
    ExperimentCoordinatorViewControllerDelegate, TrialDetailViewControllerDelegate,
    UINavigationControllerDelegate {

  // MARK: - Properties

  /// The experiment coordinator view controller. Exposed for testing.
  var experimentCoordinatorVC: ExperimentCoordinatorViewController?

  /// The experiment update manager for the displayed experiment. This is populated when an
  /// experiment is shown. Callbacks received from detail view controllers will route updates to
  /// this manager. Exposed for testing.
  var openExperimentUpdateManager: ExperimentUpdateManager?

  /// The claim experiments view controller. Exposed for testing.
  let claimExperimentsViewController: ClaimExperimentsViewController

  /// The trial detail view controller. Exposed for testing.
  var trialDetailVC: TrialDetailViewController?

  private let authAccount: AuthAccount
  private let analyticsReporter: AnalyticsReporter
  private let existingDataMigrationManager: ExistingDataMigrationManager
  private let experimentDataDeleter: ExperimentDataDeleter
  private let sensorController: SensorController
  private let navController = UINavigationController()
  private let preferenceManager: PreferenceManager
  private let metadataManager: MetadataManager
  private let sensorDataManager: SensorDataManager
  private let documentManager: DocumentManager
  private let saveToFilesHandler = SaveToFilesHandler()

  private var exportType: UserExportType {
    return existingDataMigrationManager.rootUserManager.exportType
  }

  // Handles state updates to any experiment.
  private lazy var experimentStateManager: ExperimentStateManager = {
    return ExperimentStateManager(experimentDataDeleter: experimentDataDeleter,
                                  metadataManager: metadataManager,
                                  sensorDataManager: sensorDataManager)
  }()

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - authAccount: The auth account.
  ///   - analyticsReporter: The analytics reporter.
  ///   - existingDataMigrationManager: The existing data migration manager.
  ///   - sensorController: The sensor controller.
  init(authAccount: AuthAccount,
       analyticsReporter: AnalyticsReporter,
       existingDataMigrationManager: ExistingDataMigrationManager,
       sensorController: SensorController) {
    self.authAccount = authAccount
    self.analyticsReporter = analyticsReporter
    self.documentManager = existingDataMigrationManager.rootUserManager.documentManager
    self.existingDataMigrationManager = existingDataMigrationManager
    self.sensorController = sensorController
    self.preferenceManager = existingDataMigrationManager.rootUserManager.preferenceManager
    self.metadataManager = existingDataMigrationManager.rootUserManager.metadataManager
    self.sensorDataManager = existingDataMigrationManager.rootUserManager.sensorDataManager
    self.experimentDataDeleter = existingDataMigrationManager.rootUserManager.experimentDataDeleter

    claimExperimentsViewController = ClaimExperimentsViewController(
        authAccount: authAccount,
        analyticsReporter: analyticsReporter,
        metadataManager: existingDataMigrationManager.rootUserManager.metadataManager,
        preferenceManager: preferenceManager)

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChild(navController)
    view.addSubview(navController.view)
    navController.isNavigationBarHidden = true
    navController.delegate = self

    claimExperimentsViewController.delegate = self
    navController.setViewControllers([claimExperimentsViewController], animated: false)
  }

  override var prefersStatusBarHidden: Bool {
    return false
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return navController.topViewController?.preferredStatusBarStyle ?? .lightContent
  }

  /// Shows an experiment. Exposed for testing.
  ///
  /// - Parameter experiment: An experiment.
  func showExperiment(_ experiment: Experiment) {
    openExperimentUpdateManager = ExperimentUpdateManager(
        experiment: experiment,
        experimentDataDeleter: experimentDataDeleter,
        metadataManager: metadataManager,
        sensorDataManager: sensorDataManager)
    let experimentCoordinatorVC = ExperimentCoordinatorViewController(
        experiment: experiment,
        experimentInteractionOptions: .readOnlyWithItemDelete,
        exportType: exportType,
        drawerViewController: nil,
        analyticsReporter: analyticsReporter,
        metadataManager: metadataManager,
        preferenceManager: preferenceManager,
        sensorController: sensorController,
        sensorDataManager: sensorDataManager,
        documentManager: documentManager)
    experimentCoordinatorVC.delegate = self
    experimentCoordinatorVC.itemDelegate = self
    experimentCoordinatorVC.requireExperimentTitle = false

    // Add as listeners for all experiment changes.
    openExperimentUpdateManager?.addListener(experimentCoordinatorVC)
    experimentStateManager.addListener(experimentCoordinatorVC)

    self.experimentCoordinatorVC = experimentCoordinatorVC
    navController.pushViewController(experimentCoordinatorVC, animated: true)
  }

  /// Shows a trial. Exposed for testing.
  ///
  /// - Parameter trialID: A trial ID.
  func showTrial(withID trialID: String) {
    guard let experiment = openExperimentUpdateManager?.experiment,
        let trial = experiment.trials.first(where: { $0.ID == trialID }) else {
      return
    }
    let experimentDataParser = ExperimentDataParser(
        experimentID: experiment.ID,
        metadataManager: metadataManager,
        sensorController: sensorController)
    let trialDetailVC = TrialDetailViewController(
        trial: trial,
        experiment: experiment,
        experimentInteractionOptions: .readOnlyWithItemDelete,
        exportType: exportType,
        delegate: self,
        itemDelegate: self,
        analyticsReporter: analyticsReporter,
        experimentDataParser: experimentDataParser,
        metadataManager: metadataManager,
        preferenceManager: preferenceManager,
        sensorDataManager: sensorDataManager)
    self.trialDetailVC = trialDetailVC
    openExperimentUpdateManager?.addListener(trialDetailVC)
    navController.pushViewController(trialDetailVC, animated: true)
  }

  // MARK: - Private

  private func showNote(_ displayNote: DisplayNote) {
    var viewController: UIViewController?
    switch displayNote {
    case let displayTextNote as DisplayTextNote:
      viewController =
          TextNoteDetailViewController(displayTextNote: displayTextNote,
                                       delegate: self,
                                       experimentInteractionOptions: .readOnlyWithItemDelete,
                                       analyticsReporter: analyticsReporter)
    case let displayPicture as DisplayPictureNote:
      viewController = PictureDetailViewController(
          displayPicture: displayPicture,
          experimentInteractionOptions: .readOnlyWithItemDelete,
          exportType: exportType,
          delegate: self,
          jumpToCaption: false,
          analyticsReporter: analyticsReporter,
          metadataManager: metadataManager,
          preferenceManager: preferenceManager)
    case let displaySnapshot as DisplaySnapshotNote:
      viewController =
          SnapshotDetailViewController(displaySnapshot: displaySnapshot,
                                       experimentInteractionOptions: .readOnlyWithItemDelete,
                                       delegate: self,
                                       jumpToCaption: false,
                                       analyticsReporter: analyticsReporter)
    case let displayTrigger as DisplayTriggerNote:
      viewController =
          TriggerDetailViewController(displayTrigger: displayTrigger,
                                      experimentInteractionOptions: .readOnlyWithItemDelete,
                                      delegate: self,
                                      jumpToCaption: false,
                                      analyticsReporter: analyticsReporter)
    default:
      return
    }

    if let viewController = viewController {
      navController.pushViewController(viewController, animated: true)
    }
  }

  // Dismiss the claim view if all experiments have been claimed or deleted. Returns a bool result
  // for testing purposes.
  @discardableResult func dismissClaimFlowIfComplete() -> Bool {
    guard !existingDataMigrationManager.hasExistingExperiments else { return false }
    claimExperimentsViewController.dismiss(animated: true)
    return true
  }

  // MARK: - ClaimExperimentsViewControllerDelegate

  func claimExperimentsShowExperiment(withID experimentID: String) {
    guard let experiment = metadataManager.experiment(withID: experimentID) else {
      claimExperimentsViewController.handleExperimentLoadingFailure()
      return
    }

    showExperiment(experiment)
    analyticsReporter.track(.claimingViewExperiment)
  }

  func claimExperimentsAddExperimentToDrive(withID experimentID: String) {
    let spinnerViewController = SpinnerViewController()
    spinnerViewController.present(fromViewController: claimExperimentsViewController) {
      self.existingDataMigrationManager.migrateExperiment(withID: experimentID,
                                                          completion: { (errors) in
        spinnerViewController.dismissSpinner(completion: {
          if errors.isEmpty {
            self.claimExperimentsViewController.experimentRemoved(withID: experimentID)
            showSnackbar(withMessage: String(format: String.claimExperimentSnackbarMessage,
                                             self.authAccount.email))
            self.dismissClaimFlowIfComplete()
          } else if errors.containsDiskSpaceError {
            showSnackbar(withMessage: String.claimExperimentDiskSpaceErrorMessage)
          } else {
            showSnackbar(withMessage: String.claimExperimentErrorMessage)
          }
        })
      })
    }
    analyticsReporter.track(.claimingClaimSingle)
  }

  func claimExperimentsSaveExperimentToFiles(withID experimentID: String) {
    guard let experiment = metadataManager.experiment(withID: experimentID) else { return }

    saveToFilesHandler.presentSaveToFiles(forExperiment: experiment,
                                          documentManager: documentManager,
                                          presentingViewController: claimExperimentsViewController)
    analyticsReporter.track(.claimingSaveToFiles)
  }

  func claimExperimentsDeleteExperiment(withID experimentID: String) {
    existingDataMigrationManager.removeExperimentFromRootUser(withID: experimentID)
    claimExperimentsViewController.experimentRemoved(withID: experimentID)
    dismissClaimFlowIfComplete()
    analyticsReporter.track(.claimingDeleteSingle)
  }

  func claimExperimentsClaimAllExperiments() {
    let spinnerViewController = SpinnerViewController()
    spinnerViewController.present(fromViewController: claimExperimentsViewController) {
      self.existingDataMigrationManager.migrateAllExperiments(completion: { (errors) in
        spinnerViewController.dismissSpinner(completion: {
          if errors.isEmpty {
            self.claimExperimentsViewController.dismiss(animated: true)
          } else {
            if errors.containsDiskSpaceError {
              showSnackbar(withMessage: String.claimExperimentsDiskSpaceErrorMessage)
            } else {
              showSnackbar(withMessage: String.claimExperimentsErrorMessage)
            }
            self.claimExperimentsViewController.refreshExperiments()
          }
        })
      })
    }
    analyticsReporter.track(.claimAll)
  }

  func claimExperimentsDeleteAllExperiments() {
    existingDataMigrationManager.removeAllExperimentsFromRootUser()
    claimExperimentsViewController.dismiss(animated: true)
    analyticsReporter.track(.claimingDeleteAll)
  }

  // MARK: - ExperimentCoordinatorViewControllerDelegate

  func experimentViewControllerDidRequestDeleteExperiment(_ experiment: Experiment) {
    existingDataMigrationManager.removeExperimentFromRootUser(withID: experiment.ID)
    navController.popViewController(animated: true)

    // User could have deleted the last experiment in the flow, there might be nothing left to do.
    dismissClaimFlowIfComplete()
    analyticsReporter.track(.claimingDeleteSingle)
  }

  func experimentViewControllerShowTrial(withID trialID: String, jumpToCaption: Bool) {
    showTrial(withID: trialID)
    analyticsReporter.track(.claimingViewTrial)
  }

  func experimentViewControllerShowNote(_ displayNote: DisplayNote, jumpToCaption: Bool) {
    showNote(displayNote)
    analyticsReporter.track(.claimingViewNote(displayNote))
  }

  func experimentViewControllerToggleArchiveStateForExperiment(withID experimentID: String) {}
  func experimentViewControllerToggleArchiveStateForTrial(withID trialID: String) {}
  func experimentViewControllerAddTrial(_ trial: Trial, recording isRecording: Bool) {}
  func experimentViewControllerDeleteTrialCompleted(_ trial: Trial,
                                                    fromExperiment experiment: Experiment) {}

  // swiftlint:disable vertical_parameter_alignment
  func experimentViewControllerShouldPermanentlyDeleteTrial(_ trial: Trial,
      fromExperiment experiment: Experiment) {}
  // swiftlint:enable vertical_parameter_alignment

  func experimentViewControllerDidFinishRecordingTrial(_ trial: Trial,
                                                       forExperiment experiment: Experiment) {}

  func experimentViewControllerRemoveCoverImageForExperiment(_ experiment: Experiment) -> Bool {
    guard let coverImagePath = experiment.imagePath else {
      return false
    }
    analyticsReporter.track(.claimingRemoveCoverImage)
    experimentDataDeleter.permanentlyDeleteAsset(atPath: coverImagePath,
                                                 experimentID: experiment.ID)
    return metadataManager.removeCoverImageForExperiment(experiment)
  }

  func experimentViewControllerDidSetTitle(_ title: String?, forExperiment experiment: Experiment) {
    // Claim flow does not support setting a new title.
  }

  func experimentViewControllerDidSetCoverImageData(_ imageData: Data?,
                                                    metadata: NSDictionary?,
                                                    forExperiment experiment: Experiment) {
    // Claim flow does not support setting a new cover image.
  }

  func experimentViewControllerDidChangeRecordingTrial(_ recordingTrial: Trial,
                                                       experiment: Experiment) {
    // Claim flow does not support editing an experiment.
  }

  func experimentViewControllerDeletePictureNoteCompleted(_ pictureNote: PictureNote,
                                                          forExperiment experiment: Experiment) {}

  // Claim flow does not support export flow for PDF.
  func experimentViewControllerExportExperimentPDF(
    _ experiment: Experiment,
    completionHandler: PDFExportController.CompletionHandler) {}

  // Claim flow does not support export flow for PDF.
  func experimentViewControllerExportFlowAction(for experiment: Experiment,
                                                from presentingViewController: UIViewController,
                                                sourceView: UIView) -> PopUpMenuAction? {
    return nil
  }

  // MARK: - TrialDetailViewControllerDelegate

  func trialDetailViewControllerShowNote(_ displayNote: DisplayNote, jumpToCaption: Bool) {
    showNote(displayNote)
    analyticsReporter.track(.claimingViewTrialNote(displayNote))
  }

  func trialDetailViewControllerDeletePictureNoteCompleted(_ pictureNote: PictureNote,
                                                           forExperiment experiment: Experiment) {}

  // MARK: - UINavigationControllerDelegate

  func navigationController(_ navigationController: UINavigationController,
                            didShow viewController: UIViewController,
                            animated: Bool) {
    setNeedsStatusBarAppearanceUpdate()

    if viewController is ClaimExperimentsViewController,
        let experimentCoordinatorVC = experimentCoordinatorVC {
      // If going back to claim list from experiment, reset open experiment update manager.
      self.experimentCoordinatorVC = nil
      openExperimentUpdateManager = nil
      experimentStateManager.removeListener(experimentCoordinatorVC)
    } else if viewController is ExperimentCoordinatorViewController,
        let trialDetailVC = trialDetailVC {
      // If going back to experiment from a trial, remove trial as listener for experiment updates.
      openExperimentUpdateManager?.removeListener(trialDetailVC)
      self.trialDetailVC = nil
    }
  }

}

// MARK: - ExperimentItemDelegate

extension ClaimExperimentsFlowController: ExperimentItemDelegate {

  func detailViewControllerDidDeleteNote(_ deletedDisplayNote: DisplayNote) {
    if let trialID = deletedDisplayNote.trialID {
      // Trial note.
      openExperimentUpdateManager?.deleteTrialNote(withID: deletedDisplayNote.ID, trialID: trialID)
      analyticsReporter.track(.claimingDeleteTrialNote(deletedDisplayNote))
    } else {
      // Experiment note.
      openExperimentUpdateManager?.deleteExperimentNote(withID: deletedDisplayNote.ID)
      analyticsReporter.track(.claimingDeleteNote(deletedDisplayNote))
    }
  }

  func trialDetailViewControllerDidRequestDeleteTrial(withID trialID: String) {
    openExperimentUpdateManager?.deleteTrial(withID: trialID)
    analyticsReporter.track(.claimingDeleteTrial)
  }

  func detailViewControllerDidAddNote(_ note: Note, forTrialID trialID: String?) {}
  func detailViewControllerDidUpdateCaptionForNote(_ updatedDisplayNote: CaptionableNote) {}
  func detailViewControllerDidUpdateTextForNote(_ updatedDisplayTextNote: DisplayTextNote) {}
  func trialDetailViewControllerDidUpdateTrial(cropRange: ChartAxis<Int64>?,
                                               name trialName: String?,
                                               caption: String?,
                                               withID trialID: String) {}
  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateChanged trial: Trial) {}
  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateToggledForTrialID trialID: String) {}

}
