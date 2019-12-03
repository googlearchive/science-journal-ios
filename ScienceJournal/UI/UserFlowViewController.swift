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

// swiftlint:disable file_length

import UIKit

import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs
import third_party_objective_c_material_components_ios_components_Dialogs_ColorThemer

protocol UserFlowViewControllerDelegate: class {
  /// Tells the delegate to present the account selector so a user can change or remove accounts.
  func presentAccountSelector()
}

// swiftlint:disable type_body_length
// TODO: Consider breaking this class into multiple classes for each delegate.
/// Manages the navigation of the user flow which begins after a user has signed in and includes
/// all management of data such as viewing, creating, and adding to experiments.
class UserFlowViewController: UIViewController, ExperimentsListViewControllerDelegate,
    ExperimentCoordinatorViewControllerDelegate, PermissionsGuideDelegate, SidebarDelegate,
    UINavigationControllerDelegate, ExperimentItemDelegate {

  /// The user flow view controller delegate.
  weak var delegate: UserFlowViewControllerDelegate?

  /// The experiment coordinator view controller. Exposed for testing.
  weak var experimentCoordinatorVC: ExperimentCoordinatorViewController?

  /// The experiments list view controller.
  weak var experimentsListVC: ExperimentsListViewController?

  /// The settings view controller.
  weak var settingsVC: SettingsViewController?

  private let accountsManager: AccountsManager
  private lazy var _actionAreaController = ActionArea.Controller()
  override var actionAreaController: ActionArea.Controller? { return _actionAreaController }
  private let analyticsReporter: AnalyticsReporter
  private let commonUIComponents: CommonUIComponents
  private let documentManager: DocumentManager
  private let drawerConfig: DrawerConfig
  private var existingDataMigrationManager: ExistingDataMigrationManager?
  private let experimentDataDeleter: ExperimentDataDeleter
  private let feedbackReporter: FeedbackReporter
  private let metadataManager: MetadataManager
  private lazy var _navController = UINavigationController()
  private var navController: UINavigationController {
    return FeatureFlags.isActionAreaEnabled ? _actionAreaController.navController : _navController
  }
  private let networkAvailability: NetworkAvailability
  private let devicePreferenceManager: DevicePreferenceManager
  private let preferenceManager: PreferenceManager
  private let queue = GSJOperationQueue()
  private let sensorController: SensorController
  private let sensorDataManager: SensorDataManager
  private let sidebar: SidebarViewController
  private let userManager: UserManager
  private weak var trialDetailVC: TrialDetailViewController?
  private weak var noteDetailController: NoteDetailController?
  private var importSpinnerVC: SpinnerViewController?
  private var importBeganOperation: GSJBlockOperation?
  private let userAssetManager: UserAssetManager
  private let operationQueue = GSJOperationQueue()
  private var shouldShowPreferenceMigrationMessage: Bool
  private let exportCoordinator: ExportCoordinator

  // Whether to show the experiment list pull to refresh animation. It should show once for a fresh
  // launch per user.
  private var shouldShowExperimentListPullToRefreshAnimation = true

  // The experiment update manager for the displayed experiment. This is populated when an
  // experiment is shown. Callbacks received from detail view controllers will route updates to
  // this manager.
  private var openExperimentUpdateManager: ExperimentUpdateManager?

  // Handles state updates to any experiment.
  private lazy var experimentStateManager: ExperimentStateManager = {
    let stateManager = ExperimentStateManager(experimentDataDeleter: experimentDataDeleter,
                                              metadataManager: metadataManager,
                                              sensorDataManager: sensorDataManager)
    stateManager.addListener(self)
    return stateManager
  }()

  // Drawer view controller is created lazily to avoid loading drawer contents until needed.
  private lazy var drawerVC: DrawerViewController? = {
    if FeatureFlags.isActionAreaEnabled {
      return nil
    } else {
      return DrawerViewController(analyticsReporter: analyticsReporter,
                                  drawerConfig: drawerConfig,
                                  preferenceManager: preferenceManager,
                                  sensorController: sensorController,
                                  sensorDataManager: sensorDataManager)
    }
  }()

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - accountsManager: The accounts manager.
  ///   - analyticsReporter: The analytics reporter.
  ///   - commonUIComponents: Common UI components.
  ///   - devicePreferenceManager: The device preference manager.
  ///   - drawerConfig: The drawer config.
  ///   - existingDataMigrationManager: The existing data migration manager.
  ///   - feedbackReporter: The feedback reporter.
  ///   - networkAvailability: Network availability.
  ///   - sensorController: The sensor controller.
  ///   - shouldShowPreferenceMigrationMessage: Whether to show the preference migration message.
  ///   - userManager: The user manager.
  init(accountsManager: AccountsManager,
       analyticsReporter: AnalyticsReporter,
       commonUIComponents: CommonUIComponents,
       devicePreferenceManager: DevicePreferenceManager,
       drawerConfig: DrawerConfig,
       existingDataMigrationManager: ExistingDataMigrationManager?,
       feedbackReporter: FeedbackReporter,
       networkAvailability: NetworkAvailability,
       sensorController: SensorController,
       shouldShowPreferenceMigrationMessage: Bool,
       userManager: UserManager) {
    self.accountsManager = accountsManager
    self.analyticsReporter = analyticsReporter
    self.commonUIComponents = commonUIComponents
    self.devicePreferenceManager = devicePreferenceManager
    self.drawerConfig = drawerConfig
    self.existingDataMigrationManager = existingDataMigrationManager
    self.feedbackReporter = feedbackReporter
    self.networkAvailability = networkAvailability
    self.sensorController = sensorController
    self.shouldShowPreferenceMigrationMessage = shouldShowPreferenceMigrationMessage
    self.userManager = userManager
    self.documentManager = userManager.documentManager
    self.metadataManager = userManager.metadataManager
    self.preferenceManager = userManager.preferenceManager
    self.sensorDataManager = userManager.sensorDataManager
    self.userAssetManager = userManager.assetManager
    self.experimentDataDeleter = userManager.experimentDataDeleter
    sidebar = SidebarViewController(accountsManager: accountsManager,
                                    analyticsReporter: analyticsReporter)
    exportCoordinator = ExportCoordinator(exportType: userManager.exportType)

    super.init(nibName: nil, bundle: nil)

    // Set user tracking opt-out.
    analyticsReporter.setOptOut(preferenceManager.hasUserOptedOutOfUsageTracking)

    // Register user-specific sensors.
    metadataManager.registerBluetoothSensors()

    // Get updates for changes based on Drive sync.
    userManager.driveSyncManager?.delegate = self

    exportCoordinator.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    if FeatureFlags.isActionAreaEnabled {
      addChild(_actionAreaController)
      view.addSubview(_actionAreaController.view)
      _actionAreaController.didMove(toParent: self)
    } else {
      addChild(navController)
      view.addSubview(navController.view)
      navController.didMove(toParent: self)
      navController.isNavigationBarHidden = true
      navController.delegate = self
    }

    sidebar.delegate = self

    if !devicePreferenceManager.hasAUserCompletedPermissionsGuide {
      let permissionsVC =
          PermissionsGuideViewController(delegate: self,
                                         analyticsReporter: analyticsReporter,
                                         devicePreferenceManager: devicePreferenceManager,
                                         showWelcomeView: !accountsManager.supportsAccounts)
      navController.setViewControllers([permissionsVC], animated: false)
    } else {
      // Don't need the permissions guide, just show the experiments list.
      showExperimentsList(animated: false)
    }

    // Listen to application notifications.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillTerminate),
                                           name: UIApplication.willTerminateNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillResignActive),
                                           name: UIApplication.willResignActiveNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationDidEnterBackground),
                                           name: UIApplication.didEnterBackgroundNotification,
                                           object: nil)

    // Listen to notifications of newly imported experiments.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(experimentImportBegan),
                                           name: .documentManagerDidBeginImportExperiment,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(experimentImported),
                                           name: .documentManagerDidImportExperiment,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(experimentImportFailed),
                                           name: .documentManagerImportExperimentFailed,
                                           object: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Generate the default experiment if necessary.
    createDefaultExperimentIfNecessary()
  }

  override var prefersStatusBarHidden: Bool {
    return false
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return navController.topViewController?.preferredStatusBarStyle ?? .lightContent
  }

  /// Handles a file import URL if possible.
  ///
  /// - Parameter url: A file URL.
  /// - Returns: True if the URL can be handled, otherwise false.
  func handleImportURL(_ url: URL) -> Bool {
    return documentManager.handleImportURL(url)
  }

  // MARK: - Notifications

  @objc private func applicationWillTerminate() {
    sensorDataManager.saveAllContexts()
  }

  @objc private func applicationWillResignActive() {
    sensorDataManager.saveAllContexts()
  }

  @objc private func applicationDidEnterBackground() {
    sensorDataManager.saveAllContexts()
  }

  @objc private func experimentImportBegan() {
    // Wrap the UI work of beginning an import in an operation so we can ensure it finishes before
    // handling success or failure.
    let operation = GSJBlockOperation(mainQueueBlock: { (continuation) in
      let showSpinnerBlock = {
        if let experimentsListVC = self.experimentsListVC {
          // Dismiss the feature highlight if necessary first.
          experimentsListVC.dismissFeatureHighlightIfNecessary()

          self.navController.popToViewController(experimentsListVC, animated: false)
        }

        guard let topViewController = self.navController.topViewController else {
          self.importBeganOperation = nil
          continuation()
          return
        }
        self.importSpinnerVC = SpinnerViewController()
        self.importSpinnerVC?.present(fromViewController: topViewController)
        self.importBeganOperation = nil
        continuation()
      }

      // Dismiss any VCs presented on the top view controller.
      if self.navController.topViewController?.presentedViewController != nil {
        self.navController.topViewController?.dismiss(animated: true, completion: showSpinnerBlock)
      } else {
        showSpinnerBlock()
      }
    })
    importBeganOperation = operation
    queue.addOperation(operation)
  }

  @objc private func experimentImported(_ notification: Notification) {
    let finishedOperation = GSJBlockOperation(mainQueueBlock: { (continuation) in
      self.dismissExperimentImportSpinner {
        if let experimentID =
            notification.userInfo?[DocumentManager.importedExperimentIDKey] as? String {
          self.experimentsListShowExperiment(withID: experimentID)
        }
        continuation()
      }
    })

    // Add began operation as a dependency so we don't show the experiment while the UI is still
    // preparing to begin.
    if let importBeganOperation = importBeganOperation {
      finishedOperation.addDependency(importBeganOperation)
    }
    queue.addOperation(finishedOperation)
  }

  @objc private func experimentImportFailed(_ notification: Notification) {
    let errorOperation = GSJBlockOperation(mainQueueBlock: { (continuation) in
      // Check for an importing while recording error, otherwise the default generic error will
      // be used.
      var errorMessage = String.importFailedFile
      if let errors = notification.userInfo?[DocumentManager.importFailedErrorsKey] as? [Error] {
        forLoop: for error in errors {
          switch error {
          case DocumentManagerError.importingDocumentWhileRecording:
            errorMessage = String.importFailedRecording
            break forLoop
          default: break
          }
        }
      }

      self.dismissExperimentImportSpinner {
        MDCAlertColorThemer.apply(ViewConstants.alertColorScheme)
        let alert = MDCAlertController(title: nil, message: errorMessage)
        let cancelAction = MDCAlertAction(title: String.actionOk)
        alert.addAction(cancelAction)
        guard var topViewController = self.navController.topViewController else { return }
        if let presentedViewController = topViewController.presentedViewController {
          // On iPad, the welcome flow is in a presented view controller, so the alert must be
          // presented on that.
          topViewController = presentedViewController
        }
        topViewController.present(alert, animated: true)
        continuation()
      }
    })

    // Add began operation as a dependency so we don't show the error while the UI is still
    // preparing to begin.
    if let importBeganOperation = importBeganOperation {
      errorOperation.addDependency(importBeganOperation)
    }
    queue.addOperation(errorOperation)
  }

  // MARK: - PermissionsGuideDelegate

  func permissionsGuideDidComplete(_ viewController: PermissionsGuideViewController) {
    showExperimentsList(animated: true)
  }

  // MARK: - SidebarDelegate

  func sidebarShouldShow(_ item: SidebarRow) {
    switch item {
    case .about:
      let aboutVC = AboutViewController(analyticsReporter: analyticsReporter)
      guard UIDevice.current.userInterfaceIdiom == .pad else {
        navController.pushViewController(aboutVC, animated: true)
        return
      }
      // iPad should present modally in a navigation controller of its own since About has
      // sub-navigation items.
      let aboutNavController = UINavigationController()
      aboutNavController.viewControllers = [ aboutVC ]
      aboutNavController.isNavigationBarHidden = true
      aboutNavController.modalPresentationStyle = .formSheet
      present(aboutNavController, animated: true)
    case .website:
      let websiteURL = "new url here"
      guard let url = URL(string: websiteURL) else { return }
      UIApplication.shared.open(url)
    case .settings:
      let settingsVC = SettingsViewController(analyticsReporter: analyticsReporter,
                                              driveSyncManager: userManager.driveSyncManager,
                                              preferenceManager: preferenceManager)
      if UIDevice.current.userInterfaceIdiom == .pad {
        // iPad should present modally.
        settingsVC.modalPresentationStyle = .formSheet
        present(settingsVC, animated: true)
      } else {
        navController.pushViewController(settingsVC, animated: true)
      }
      self.settingsVC = settingsVC
    case .feedback:
      guard let feedbackViewController = feedbackReporter.feedbackViewController(
          withStyleMatching: navController.topViewController) else { return }
      navController.pushViewController(feedbackViewController, animated: true)
    default:
      break
    }
  }

  func sidebarShouldShowSignIn() {
    delegate?.presentAccountSelector()
  }

  func sidebarDidOpen() {
    analyticsReporter.track(.sidebarOpened)
  }

  func sidebarDidClose() {
    analyticsReporter.track(.sidebarClosed)
  }

  // MARK: - ExperimentsListViewControllerDelegate

  func experimentsListShowSidebar() {
    showSidebar()
  }

  func experimentsListManualSync() {
    userManager.driveSyncManager?.syncExperimentLibrary(andReconcile: true, userInitiated: true)
  }

  func experimentsListShowExperiment(withID experimentID: String) {
    guard let experiment = metadataManager.experiment(withID: experimentID) else {
      experimentsListVC?.handleExperimentLoadingFailure()
      return
    }

    showExperiment(experiment)
  }

  func experimentsListShowNewExperiment() {
    let (experiment, overview) = metadataManager.createExperiment()
    experimentsListVC?.insertOverview(overview, atBeginning: true)
    showExperiment(experiment)
  }

  func experimentsListToggleArchiveStateForExperiment(withID experimentID: String) {
    experimentStateManager.toggleArchiveStateForExperiment(withID: experimentID)
  }

  func experimentsListDeleteExperiment(withID experimentID: String) {
    experimentStateManager.deleteExperiment(withID: experimentID)
  }

  func experimentsListDeleteExperimentCompleted(_ deletedExperiment: DeletedExperiment) {
    experimentStateManager.confirmDeletion(for: deletedExperiment)
    userManager.driveSyncManager?.deleteExperiment(withID: deletedExperiment.experimentID)
  }

  func experimentsListDidAppear() {
    userManager.driveSyncManager?.syncExperimentLibrary(andReconcile: true, userInitiated: false)
    showPreferenceMigrationMessageIfNeeded()
  }

  func experimentsListDidSetTitle(_ title: String?, forExperimentID experimentID: String) {
    if openExperimentUpdateManager?.experiment.ID == experimentID {
      openExperimentUpdateManager?.setTitle(title)
    } else {
      metadataManager.setExperimentTitle(title, forID: experimentID)
      userManager.driveSyncManager?.syncExperiment(withID: experimentID, condition: .onlyIfDirty)
    }
  }

  func experimentsListDidSetCoverImageData(_ imageData: Data?,
                                           metadata: NSDictionary?,
                                           forExperimentID experimentID: String) {
    if openExperimentUpdateManager?.experiment.ID == experimentID {
      openExperimentUpdateManager?.setCoverImageData(imageData, metadata: metadata)
    } else {
      let experimentUpdateManager =
          ExperimentUpdateManager(experimentID: experimentID,
                                  experimentDataDeleter: experimentDataDeleter,
                                  metadataManager: metadataManager,
                                  sensorDataManager: sensorDataManager)
      experimentUpdateManager?.setCoverImageData(imageData, metadata: metadata)
    }
  }

  func experimentsListExportExperimentPDF(
    _ experiment: Experiment,
    completionHandler: @escaping PDFExportController.CompletionHandler
  ) {
    presentPDFExportFlow(experiment, completionHandler: completionHandler)
  }

  func experimentsListExportFlowAction(for experiment: Experiment,
                                       from presentingViewController: UIViewController,
                                       sourceView: UIView) -> PopUpMenuAction {
    return PopUpMenuAction.exportFlow(for: experiment,
                                      from: self,
                                      documentManager: documentManager,
                                      sourceView: sourceView,
                                      exportCoordinator: exportCoordinator)
  }

  // MARK: - ExperimentCoordinatorViewControllerDelegate

  func experimentViewControllerToggleArchiveStateForExperiment(withID experimentID: String) {
    experimentStateManager.toggleArchiveStateForExperiment(withID: experimentID)
  }

  func experimentViewControllerDidRequestDeleteExperiment(_ experiment: Experiment) {
    experimentStateManager.deleteExperiment(withID: experiment.ID)
    if let experimentsListVC = experimentsListVC {
      navController.popToViewController(experimentsListVC, animated: true)
    }
  }

  func experimentViewControllerToggleArchiveStateForTrial(withID trialID: String) {
    openExperimentUpdateManager?.toggleArchivedState(forTrialID: trialID)
  }

  func experimentViewControllerDeleteExperimentNote(withID noteID: String) {
    openExperimentUpdateManager?.deleteExperimentNote(withID: noteID)
  }

  func experimentViewControllerShowTrial(withID trialID: String, jumpToCaption: Bool) {
    guard let experiment = openExperimentUpdateManager?.experiment,
        let trialIndex = experiment.trials.firstIndex(where: { $0.ID == trialID }) else {
      return
    }
    let trial = experiment.trials[trialIndex]
    let experimentInteractionOptions = interactionOptions(forExperiment: experiment)
    let experimentDataParser = ExperimentDataParser(experimentID: experiment.ID,
                                                    metadataManager: metadataManager,
                                                    sensorController: sensorController)
    let trialDetailVC =
        TrialDetailViewController(trial: trial,
                                  experiment: experiment,
                                  experimentInteractionOptions: experimentInteractionOptions,
                                  exportType: userManager.exportType,
                                  delegate: self,
                                  itemDelegate: self,
                                  analyticsReporter: analyticsReporter,
                                  experimentDataParser: experimentDataParser,
                                  metadataManager: metadataManager,
                                  preferenceManager: preferenceManager,
                                  sensorDataManager: sensorDataManager)
    self.trialDetailVC = trialDetailVC
    openExperimentUpdateManager?.addListener(trialDetailVC)

    if FeatureFlags.isActionAreaEnabled {
      if let experimentCoordinator = experimentCoordinatorVC {
        let content = configure(trialDetailViewController: trialDetailVC,
                                experimentCoordinator: experimentCoordinator)
        actionAreaController?.show(content, sender: self)
      } else {
        fatalError("Experiment coordinator not available.")
      }
    } else {
      navController.pushViewController(trialDetailVC, animated: true)
    }
  }

  func experimentViewControllerShowNote(_ displayNote: DisplayNote, jumpToCaption: Bool) {
    showNote(displayNote, jumpToCaption: jumpToCaption)
  }

  func experimentViewControllerAddTrial(_ trial: Trial, recording isRecording: Bool) {
    openExperimentUpdateManager?.addTrial(trial, recording: isRecording)
  }

  func experimentViewControllerDeleteTrialCompleted(_ trial: Trial,
                                                    fromExperiment experiment: Experiment) {
    // Delete trial data locally.
    openExperimentUpdateManager?.confirmTrialDeletion(for: trial)
    userAssetManager.deleteSensorData(forTrialID: trial.ID, experimentID: experiment.ID)

    // Delete trial data from Drive.
    let recordingURL =
        metadataManager.recordingURL(forTrialID: trial.ID, experimentID: experiment.ID)
    userManager.driveSyncManager?.deleteSensorDataAsset(atURL: recordingURL,
                                                        experimentID: experiment.ID)

    // Delete trial image assets from Drive.
    let imageURLs = trial.allImagePaths.map { return URL(fileURLWithPath: $0) }
    userManager.driveSyncManager?.deleteImageAssets(atURLs: imageURLs, experimentID: experiment.ID)
  }

  func experimentViewControllerShouldPermanentlyDeleteTrial(_ trial: Trial,
                                                            fromExperiment experiment: Experiment) {
    guard experiment.ID == openExperimentUpdateManager?.experiment.ID else {
      return
    }
    openExperimentUpdateManager?.permanentlyDeleteTrial(withID: trial.ID)
  }

  func experimentsListShowClaimExperiments() {
    guard let existingDataMigrationManager = existingDataMigrationManager,
        let authAccount = accountsManager.currentAccount else { return }
    let claimExperimentsVC =
        ClaimExperimentsFlowController(authAccount: authAccount,
                                       analyticsReporter: analyticsReporter,
                                       existingDataMigrationManager: existingDataMigrationManager,
                                       sensorController: sensorController)
    present(claimExperimentsVC, animated: true)
  }

  func experimentViewControllerDidFinishRecordingTrial(_ trial: Trial,
                                                       forExperiment experiment: Experiment) {
    userAssetManager.storeSensorData(forTrial: trial, experiment: experiment)
  }

  // No-op in non-claim flow.
  func experimentViewControllerRemoveCoverImageForExperiment(_ experiment: Experiment) -> Bool {
    return false
  }

  func experimentViewControllerDidSetTitle(_ title: String?, forExperiment experiment: Experiment) {
    guard openExperimentUpdateManager?.experiment.ID == experiment.ID else {
      return
    }
    openExperimentUpdateManager?.setTitle(title)
  }

  func experimentViewControllerDidSetCoverImageData(_ imageData: Data?,
                                                    metadata: NSDictionary?,
                                                    forExperiment experiment: Experiment) {
    guard openExperimentUpdateManager?.experiment.ID == experiment.ID else {
      return
    }
    openExperimentUpdateManager?.setCoverImageData(imageData, metadata: metadata)
  }

  func experimentViewControllerDidChangeRecordingTrial(_ recordingTrial: Trial,
                                                       experiment: Experiment) {
    guard openExperimentUpdateManager?.experiment.ID == experiment.ID else {
      return
    }
    openExperimentUpdateManager?.recordingTrialChangedExternally(recordingTrial)
  }

  func experimentViewControllerExportExperimentPDF(
    _ experiment: Experiment,
    completionHandler: @escaping PDFExportController.CompletionHandler) {
    presentPDFExportFlow(experiment, completionHandler: completionHandler)
  }

  func experimentViewControllerExportFlowAction(for experiment: Experiment,
                                                from presentingViewController: UIViewController,
                                                sourceView: UIView) -> PopUpMenuAction? {
    return PopUpMenuAction.exportFlow(for: experiment,
                                      from: self,
                                      documentManager: documentManager,
                                      sourceView: sourceView,
                                      exportCoordinator: exportCoordinator)
  }

  // MARK: - ExperimentItemDelegate

  func detailViewControllerDidAddNote(_ note: Note, forTrialID trialID: String?) {
    if let trialID = trialID {
      openExperimentUpdateManager?.addTrialNote(note, trialID: trialID)
    } else {
      openExperimentUpdateManager?.addExperimentNote(note)
    }

    guard FeatureFlags.isActionAreaEnabled, actionAreaController?.isMasterVisible == false else {
      return
    }

    showSnackbar(
      withMessage: String.actionAreaRecordingNoteSavedMessage,
      category: nil,
      actionTitle: String.actionAreaRecordingNoteSavedViewButton,
      actionHandler: {
        self.actionAreaController?.revealMaster()
    })
  }

  func detailViewControllerDidDeleteNote(_ deletedDisplayNote: DisplayNote) {
    if let trialID = deletedDisplayNote.trialID {
      // Trial note.
      openExperimentUpdateManager?.deleteTrialNote(withID: deletedDisplayNote.ID, trialID: trialID)
    } else {
      // Experiment note.
      openExperimentUpdateManager?.deleteExperimentNote(withID: deletedDisplayNote.ID)
    }
  }

  func detailViewControllerDidUpdateCaptionForNote(_ updatedDisplayNote: CaptionableNote) {
    openExperimentUpdateManager?.updateNoteCaption(updatedDisplayNote.caption,
                                                   forNoteWithID: updatedDisplayNote.ID,
                                                   trialID: updatedDisplayNote.trialID)
  }

  func detailViewControllerDidUpdateTextForNote(_ updatedDisplayTextNote: DisplayTextNote) {
    openExperimentUpdateManager?.updateText(updatedDisplayTextNote.text,
                                            forNoteWithID: updatedDisplayTextNote.ID,
                                            trialID: updatedDisplayTextNote.trialID)
  }

  func trialDetailViewControllerDidUpdateTrial(cropRange: ChartAxis<Int64>?,
                                               name trialName: String?,
                                               caption: String?,
                                               withID trialID: String) {
    openExperimentUpdateManager?.updateTrial(cropRange: cropRange,
                                             name: trialName,
                                             captionString: caption,
                                             forTrialID: trialID)
  }

  func trialDetailViewControllerDidRequestDeleteTrial(withID trialID: String) {
    openExperimentUpdateManager?.deleteTrial(withID: trialID)
  }

  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateChanged trial: Trial) {
    openExperimentUpdateManager?.toggleArchivedState(forTrialID: trial.ID)
  }

  func trialDetailViewController(_ trialDetailViewController: TrialDetailViewController,
                                 trialArchiveStateToggledForTrialID trialID: String) {
    openExperimentUpdateManager?.toggleArchivedState(forTrialID: trialID)
  }

  func experimentViewControllerDeletePictureNoteCompleted(_ pictureNote: PictureNote,
                                                          forExperiment experiment: Experiment) {
    guard let pictureNoteFilePath = pictureNote.filePath else {
      return
    }

    userManager.driveSyncManager?.deleteImageAssets(
        atURLs: [URL(fileURLWithPath: pictureNoteFilePath)], experimentID: experiment.ID)
  }

  // MARK: - Private

  /// Shows the sidebar.
  private func showSidebar() {
    present(sidebar, animated: false) {
      self.sidebar.show()
    }
  }

  /// Shows the experiments list view controller.
  ///
  /// - Parameter animated: Whether to animate the showing of the view controller.
  func showExperimentsList(animated: Bool) {
    // Force the drawer to be created here, to avoid it being created when the first experiment is
    // shown as it is a performance issue.
    // TODO: Avoid lazy loading drawer by making drawer contents load on demand. http://b/72745126
    _ = drawerVC
    let experimentsListVC =
        ExperimentsListViewController(accountsManager: accountsManager,
                                      analyticsReporter: analyticsReporter,
                                      commonUIComponents: commonUIComponents,
                                      existingDataMigrationManager: existingDataMigrationManager,
                                      metadataManager: metadataManager,
                                      networkAvailability: networkAvailability,
                                      preferenceManager: preferenceManager,
                                      sensorDataManager: sensorDataManager,
                                      documentManager: documentManager,
                                      exportType: userManager.exportType,
                                      shouldAllowManualSync: userManager.isDriveSyncEnabled)
    experimentsListVC.delegate = self

    // Add as listeners for experiment state changes.
    experimentStateManager.addListener(experimentsListVC)

    self.experimentsListVC = experimentsListVC
    navController.setViewControllers([experimentsListVC], animated: animated)
  }

  /// Presents the PDF export flow.
  ///
  /// - Parameter experiment: An experiment.
  func presentPDFExportFlow(_ experiment: Experiment,
                            completionHandler: @escaping PDFExportController.CompletionHandler) {
    let experimentCoordinatorVC = ExperimentCoordinatorViewController(
      experiment: experiment,
      experimentInteractionOptions: .readOnly,
      exportType: userManager.exportType,
      drawerViewController: nil,
      analyticsReporter: analyticsReporter,
      metadataManager: metadataManager,
      preferenceManager: preferenceManager,
      sensorController: sensorController,
      sensorDataManager: sensorDataManager,
      documentManager: documentManager)

    experimentCoordinatorVC.experimentDisplay = .pdfExport
    let container = PDFExportController(contentViewController: experimentCoordinatorVC,
                                        analyticsReporter: analyticsReporter)
    container.completionHandler = completionHandler

    let readyForPDFExport = {
      let headerInfo = PDFExportController.HeaderInfo(
        title: experiment.titleOrDefault,
        subtitle: experiment.notesAndTrialsString,
        image: self.metadataManager.imageForExperiment(experiment)
      )

      let documentFilename = experiment.titleOrDefault.validFilename(withExtension: "pdf")
      let pdfURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent(documentFilename)
      container.exportPDF(with: headerInfo, to: pdfURL)
    }

    experimentCoordinatorVC.readyForPDFExport = readyForPDFExport

    let navController = UINavigationController(rootViewController: container)
    present(navController, animated: true)
  }

  /// Shows an experiment. Exposed for testing.
  ///
  /// - Parameter experiment: An experiment.
  func showExperiment(_ experiment: Experiment) {
    openExperimentUpdateManager =
        ExperimentUpdateManager(experiment: experiment,
                                experimentDataDeleter: experimentDataDeleter,
                                metadataManager: metadataManager,
                                sensorDataManager: sensorDataManager)
    openExperimentUpdateManager?.delegate = self
    let experimentInteractionOptions = interactionOptions(forExperiment: experiment)
    let experimentCoordinatorVC = ExperimentCoordinatorViewController(
        experiment: experiment,
        experimentInteractionOptions: experimentInteractionOptions,
        exportType: userManager.exportType,
        drawerViewController: drawerVC,
        analyticsReporter: analyticsReporter,
        metadataManager: metadataManager,
        preferenceManager: preferenceManager,
        sensorController: sensorController,
        sensorDataManager: sensorDataManager,
        documentManager: documentManager)
    experimentCoordinatorVC.delegate = self
    experimentCoordinatorVC.itemDelegate = self
    self.experimentCoordinatorVC = experimentCoordinatorVC

    // Add as listeners for all experiment changes.
    openExperimentUpdateManager?.addListener(experimentCoordinatorVC)
    experimentStateManager.addListener(experimentCoordinatorVC)

    if FeatureFlags.isActionAreaEnabled {
      let content = configure(experimentCoordinator: experimentCoordinatorVC)
      actionAreaController?.show(content, sender: self)
    } else {
      navController.pushViewController(experimentCoordinatorVC, animated: true)
    }

    if isExperimentTooNewToEdit(experiment) {
      let alertController = MDCAlertController(title: nil,
                                               message: String.experimentVersionTooNewToEdit)
      alertController.addAction(MDCAlertAction(title: String.actionOk))
      alertController.accessibilityViewIsModal = true
      experimentCoordinatorVC.present(alertController, animated: true)
    }

    // Mark opened in experiment library.
    metadataManager.markExperimentOpened(withID: experiment.ID)

    // Tell drive manager to sync the experiment.
    userManager.driveSyncManager?.syncExperiment(withID: experiment.ID, condition: .always)

    // This is a good time to generate any missing recording protos.
    userAssetManager.writeMissingSensorDataProtos(forExperiment: experiment)
  }

  private func configure(trialDetailViewController: TrialDetailViewController,
                         experimentCoordinator: ExperimentCoordinatorViewController) ->
    ActionArea.MasterContent {
    let recordingDetailEmptyState = RecordingDetailEmptyStateViewController()
    trialDetailViewController.subscribeToTimestampUpdate { (timestamp) in
      recordingDetailEmptyState.timestampString = timestamp
    }

    let textItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonText,
      accessibilityHint: String.actionAreaButtonTextContentDescription,
      image: UIImage(named: "ic_action_area_text")
    ) {
      let notesVC = trialDetailViewController.notesViewController
      trialDetailViewController.prepareToAddNote()
      self.actionAreaController?.showDetailViewController(notesVC, sender: self)
    }

    let galleryItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonGallery,
      accessibilityHint: String.actionAreaButtonGalleryContentDescription,
      image: UIImage(named: "ic_action_area_gallery")
    ) {
      let photoLibraryVC = trialDetailViewController.photoLibraryViewController
      self.actionAreaController?.showDetailViewController(photoLibraryVC, sender: self)
    }

    let cameraItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonCamera,
      accessibilityHint: String.actionAreaButtonCameraContentDescription,
      image: UIImage(named: "ic_action_area_camera")
    ) {
      trialDetailViewController.cameraButtonPressed()
    }

    let content = ActionArea.MasterContentContainerViewController(
      content: trialDetailViewController,
      emptyState: recordingDetailEmptyState,
      actionEnablingKeyPath: \.isEditable,
      outsideOfSafeAreaKeyPath: \.scrollViewContentObserver.isContentOutsideOfSafeArea,
      mode: .stateless(actionItem: ActionArea.ActionItem(
        items: [textItem, cameraItem, galleryItem]
      ))
    )

    return content
  }

  private func configure(
    experimentCoordinator: ExperimentCoordinatorViewController
  ) -> ActionArea.MasterContent {
    let textItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonText,
      accessibilityHint: String.actionAreaButtonTextContentDescription,
      image: UIImage(named: "ic_action_area_text")
    ) {
      let textTitle = experimentCoordinator.observeViewController.isRecording ?
        String.actionAreaRecordingTitleAddTextNote : String.actionAreaTitleAddTextNote
      experimentCoordinator.notesViewController.title = textTitle
      self.actionAreaController?.showDetailViewController(
        experimentCoordinator.notesViewController,
        sender: self)
    }

    let cameraItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonCamera,
      accessibilityHint: String.actionAreaButtonCameraContentDescription,
      image: UIImage(named: "ic_action_area_camera")
    ) {
      experimentCoordinator.cameraButtonPressed()
    }

    let galleryItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonGallery,
      accessibilityHint: String.actionAreaButtonGalleryContentDescription,
      image: UIImage(named: "ic_action_area_gallery")
    ) {
      self.actionAreaController?.showDetailViewController(
        experimentCoordinator.photoLibraryViewController,
        sender: self)
    }

    let detail = ActionArea.DetailContentContainerViewController(
      content: experimentCoordinator.observeViewController,
      outsideOfSafeAreaKeyPath: \.scrollViewContentObserver.isContentOutsideOfSafeArea
    ) {
      let addSensorItem = ActionArea.BarButtonItem(
        title: String.actionAreaButtonAddSensor,
        accessibilityHint: String.actionAreaButtonAddSensorContentDescription,
        image: UIImage(named: "ic_action_area_add_sensor")
      ) {
        experimentCoordinator.observeViewController.observeFooterAddButtonPressed()
      }

      let snapshotItem = ActionArea.BarButtonItem(
        title: String.actionAreaButtonSnapshot,
        accessibilityHint: String.actionAreaButtonSnapshotContentDescription,
        image: UIImage(named: "ic_action_area_snapshot")
      ) {
        experimentCoordinator.observeViewController.snapshotButtonPressed()
      }

      let recordItem = ActionArea.BarButtonItem(
        title: String.actionAreaFabRecord,
        accessibilityHint: String.actionAreaFabRecordContentDescription,
        image: UIImage(named: "record_button")
      ) {
        experimentCoordinator.observeViewController.recordButtonPressed()
      }

      let stopItem = ActionArea.BarButtonItem(
        title: String.actionAreaFabStop,
        accessibilityHint: String.actionAreaFabStopContentDescription,
        image: UIImage(named: "stop_button")
      ) {
        experimentCoordinator.observeViewController.recordButtonPressed()
      }

      return .stateful(
        nonModal: ActionArea.ActionItem(primary: recordItem, items: [addSensorItem, snapshotItem]),
        modal: ActionArea.ActionItem(
          primary: stopItem,
          items: [textItem, snapshotItem, cameraItem, galleryItem]
        )
      )
    }

    let sensorsItem = ActionArea.BarButtonItem(
      title: String.actionAreaButtonSensors,
      accessibilityHint: String.actionAreaButtonSensorsContentDescription,
      image: UIImage(named: "ic_action_area_sensors")
    ) {
      self.actionAreaController?.showDetailViewController(detail, sender: self)
    }

    let emptyState = ExperimentDetailEmptyStateViewController()

    let content = ActionArea.MasterContentContainerViewController(
      content: experimentCoordinator,
      emptyState: emptyState,
      actionEnablingKeyPath: \.shouldAllowAdditions,
      outsideOfSafeAreaKeyPath: \.scrollViewContentObserver.isContentOutsideOfSafeArea,
      mode: .stateless(actionItem: ActionArea.ActionItem(
        items: [textItem, sensorsItem, cameraItem, galleryItem]
      ))
    )

    return content
  }

  /// Shows a note.
  ///
  /// - Parameters:
  ///   - displayNote: A display note.
  ///   - jumpToCaption: Whether to jump to the caption input when showing the note.
  private func showNote(_ displayNote: DisplayNote, jumpToCaption: Bool) {
    guard let experiment = openExperimentUpdateManager?.experiment else {
        return
    }

    let experimentInteractionOptions = interactionOptions(forExperiment: experiment)

    var viewController: UIViewController?
    switch displayNote {
    case let displayTextNote as DisplayTextNote:
      viewController =
          TextNoteDetailViewController(displayTextNote: displayTextNote,
                                       delegate: self,
                                       experimentInteractionOptions: experimentInteractionOptions,
                                       analyticsReporter: analyticsReporter)
    case let displayPicture as DisplayPictureNote:
      viewController =
          PictureDetailViewController(displayPicture: displayPicture,
                                      experimentInteractionOptions: experimentInteractionOptions,
                                      exportType: userManager.exportType,
                                      delegate: self,
                                      jumpToCaption: jumpToCaption,
                                      analyticsReporter: analyticsReporter,
                                      metadataManager: metadataManager,
                                      preferenceManager: preferenceManager)
    case let displaySnapshot as DisplaySnapshotNote:
      viewController =
          SnapshotDetailViewController(displaySnapshot: displaySnapshot,
                                       experimentInteractionOptions: experimentInteractionOptions,
                                       delegate: self,
                                       jumpToCaption: jumpToCaption,
                                       analyticsReporter: analyticsReporter)
    case let displayTrigger as DisplayTriggerNote:
      viewController =
          TriggerDetailViewController(displayTrigger: displayTrigger,
                                      experimentInteractionOptions: experimentInteractionOptions,
                                      delegate: self,
                                      jumpToCaption: jumpToCaption,
                                      analyticsReporter: analyticsReporter)
    default:
      return
    }

    noteDetailController = viewController as? NoteDetailController
    if let viewController = viewController {
      navController.pushViewController(viewController, animated: true)
    }
  }

  private func dismissExperimentImportSpinner(completion: (() -> Void)? = nil) {
    if importSpinnerVC != nil {
      importSpinnerVC?.dismissSpinner(completion: completion)
      importSpinnerVC = nil
    } else {
      completion?()
    }
  }

  /// Whether an experiment is too new to allow editing.
  ///
  /// - Parameter experiment: An experiment.
  /// - Returns: True if the experiment is too new to allow editing, otherwise false.
  private func isExperimentTooNewToEdit(_ experiment: Experiment) -> Bool {
    let isMajorVersionNewer = experiment.fileVersion.version > Experiment.Version.major
    let isMinorVersionNewer = experiment.fileVersion.version == Experiment.Version.major &&
        experiment.fileVersion.minorVersion > Experiment.Version.minor
    return isMajorVersionNewer || isMinorVersionNewer
  }

  /// The experiment interaction options to use for an experiment.
  ///
  /// - Parameter experiment: An experiment.
  /// - Returns: The experiment interaction options to use.
  private func interactionOptions(forExperiment experiment: Experiment) ->
      ExperimentInteractionOptions {
    let experimentInteractionOptions: ExperimentInteractionOptions
    if isExperimentTooNewToEdit(experiment) {
      experimentInteractionOptions = .readOnly
    } else {
      let isExperimentArchived = metadataManager.isExperimentArchived(withID: experiment.ID)
      experimentInteractionOptions = isExperimentArchived ? .archived : .normal
    }
    return experimentInteractionOptions
  }

  private func createDefaultExperimentIfNecessary() {
    guard !self.preferenceManager.defaultExperimentWasCreated else {
      return
    }

    guard let driveSyncManager = userManager.driveSyncManager else {
      // If there is no Drive sync manager, create the default experiment if it has not been
      // created yet.
      metadataManager.createDefaultExperimentIfNecessary()
      experimentsListVC?.reloadExperiments()
      return
    }

    let createDefaultOp = GSJBlockOperation(mainQueueBlock: { finished in
      guard !self.preferenceManager.defaultExperimentWasCreated else {
        finished()
        return
      }

      // A spinner will be shown if the experiments list is visible.
      var spinnerVC: SpinnerViewController?

      let createDefaultExperiment = {
        driveSyncManager.experimentLibraryExists { (libraryExists) in
          // If existence is unknown, perhaps due to a fetch error or lack of network, don't create
          // the default experiment.
          if libraryExists == false {
            self.metadataManager.createDefaultExperimentIfNecessary()
            self.userManager.driveSyncManager?.syncExperimentLibrary(andReconcile: false,
                                                                     userInitiated: false)

            DispatchQueue.main.async {
              if let spinnerVC = spinnerVC {
                spinnerVC.dismissSpinner {
                  self.experimentsListVC?.reloadExperiments()
                  finished()
                }
              } else {
                finished()
              }
            }
          } else {
            // If library exists or the state is unknown, mark the default experiment as created
            // to avoid attempting to create it again in the future.
            self.preferenceManager.defaultExperimentWasCreated = true
            DispatchQueue.main.async {
              if let spinnerVC = spinnerVC {
               spinnerVC.dismissSpinner {
                 finished()
                }
              } else {
                finished()
              }
            }

            if libraryExists == true {
              self.analyticsReporter.track(.signInSyncExistingAccount)
            }
          }
        }
      }

      if let experimentsListVC = self.experimentsListVC,
          experimentsListVC.presentedViewController == nil {
        spinnerVC = SpinnerViewController()
        spinnerVC?.present(fromViewController: experimentsListVC) {
          createDefaultExperiment()
        }
      } else {
        createDefaultExperiment()
      }
    })

    createDefaultOp.addCondition(MutuallyExclusive(primaryCategory: "CreateDefaultExperiment"))
    createDefaultOp.addCondition(MutuallyExclusive.modalUI)
    operationQueue.addOperation(createDefaultOp)
  }

  private func showPreferenceMigrationMessageIfNeeded() {
    guard shouldShowPreferenceMigrationMessage else { return }

    let showPreferenceMigrationMessageOp = GSJBlockOperation(mainQueueBlock: { finished in
      // If signing in and immediately showing experiments list, the sign in view controller needs a
      // brief delay to finish dismissing before showing a snackbar.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        showSnackbar(withMessage: String.preferenceMigrationMessage)
        self.shouldShowPreferenceMigrationMessage = false
        finished()
      }
    })

    showPreferenceMigrationMessageOp.addCondition(MutuallyExclusive.modalUI)
    operationQueue.addOperation(showPreferenceMigrationMessageOp)
  }

  // MARK: - UINavigationControllerDelegate

  func navigationController(_ navigationController: UINavigationController,
                            didShow viewController: UIViewController,
                            animated: Bool) {
    setNeedsStatusBarAppearanceUpdate()

    if viewController is ExperimentsListViewController {
      // Reset open experiment update manager and observe state in the drawer when the list appears.
      openExperimentUpdateManager = nil
      experimentCoordinatorVC?.observeViewController.prepareForReuse()
    }
  }

}

// MARK: - TrialDetailViewControllerDelegate

extension UserFlowViewController: TrialDetailViewControllerDelegate {

  func trialDetailViewControllerShowNote(_ displayNote: DisplayNote, jumpToCaption: Bool) {
    showNote(displayNote, jumpToCaption: jumpToCaption)
  }

  func trialDetailViewControllerDeletePictureNoteCompleted(_ pictureNote: PictureNote,
                                                           forExperiment experiment: Experiment) {
    guard let pictureNoteFilePath = pictureNote.filePath else {
      return
    }

    userManager.driveSyncManager?.deleteImageAssets(
        atURLs: [URL(fileURLWithPath: pictureNoteFilePath)], experimentID: experiment.ID)
  }

}

// MARK: - DriveSyncManagerDelegate

extension UserFlowViewController: DriveSyncManagerDelegate {

  func driveSyncWillUpdateExperimentLibrary() {
    if shouldShowExperimentListPullToRefreshAnimation {
      experimentsListVC?.startPullToRefreshAnimation()
      shouldShowExperimentListPullToRefreshAnimation = false
    }
  }

  func driveSyncDidUpdateExperimentLibrary() {
    experimentsListVC?.reloadExperiments()
    experimentsListVC?.endPullToRefreshAnimation()
  }

  func driveSyncDidDeleteTrial(withID trialID: String, experimentID: String) {
    openExperimentUpdateManager?.experimentTrialDeletedExternally(trialID: trialID,
                                                                  experimentID: experimentID)
  }

  func driveSyncDidUpdateExperiment(_ experiment: Experiment) {
    // Reload experiments list in case cover image, title, or sort changed.
    experimentsListVC?.reloadExperiments()

    // If the experiment ID matches the open experiment, refresh views as needed.
    if let experimentCoordinatorVC = experimentCoordinatorVC,
        experimentCoordinatorVC.experiment.ID == experiment.ID {
      // Replace instance handled by the update manager as well as experiment view.
      openExperimentUpdateManager?.experiment = experiment
      experimentCoordinatorVC.reloadWithNewExperiment(experiment)

      // Check if trial detail exists and reload or pop as needed.
      if let trialDetailVC = trialDetailVC {
        let trialID = trialDetailVC.trialDetailDataSource.trial.ID
        if let trial = experiment.trial(withID: trialID) {
          trialDetailVC.reloadTrial(trial)
        } else {
          trialDetailVC.dismissPresentedVCIfNeeded(animated: true) {
            self.navController.popToViewController(experimentCoordinatorVC, animated: true)
          }
          // If we pop back to the experiment view there is no need to continue.
          return
        }
      }

      // Check if a detail view exists and reload or pop as needed.
      if let detailNoteID = noteDetailController?.displayNote.ID {
        // Make a parser for this experiment.
        let parser = ExperimentDataParser(experimentID: experiment.ID,
                                          metadataManager: metadataManager,
                                          sensorController: sensorController)

        // Find the note in the experiment.
        let (note, trial) = experiment.findNote(withID: detailNoteID)
        if let note = note, let displayNote = parser.parseNote(note) {
          // The note being displayed still exists, reload the view with a new display model in
          // case there are changes.
          noteDetailController?.displayNote = displayNote
        } else if trial != nil, let trialDetailVC = trialDetailVC {
          // It's a trial note, has been deleted and the trial view exists, pop back to that.
          navController.popToViewController(trialDetailVC, animated: true)
        } else {
          // The note has been deleted and there is no trial view, pop back to the experiment view.
          navController.popToViewController(experimentCoordinatorVC, animated: true)
        }
      }
    }
  }

  func driveSyncDidDeleteExperiment(withID experimentID: String) {
    experimentsListVC?.reloadExperiments()
    // If an experiment was deleted and is currently being displayed, cancel its recording if needed
    // and pop back to the experiments list.
    guard let experimentsListVC = experimentsListVC,
        experimentCoordinatorVC?.experiment.ID == experimentID else {
      return
    }
    experimentCoordinatorVC?.cancelRecordingIfNeeded()

    navController.popToViewController(experimentsListVC, animated: true)
  }

}

// MARK: - ExperimentUpdateManagerDelegate

extension UserFlowViewController: ExperimentUpdateManagerDelegate {

  func experimentUpdateManagerDidSaveExperiment(withID experimentID: String) {
    userManager.driveSyncManager?.syncExperiment(withID: experimentID, condition: .onlyIfDirty)
  }

  func experimentUpdateManagerDidDeleteCoverImageAsset(withPath assetPath: String,
                                                       experimentID: String) {
    userManager.driveSyncManager?.deleteImageAssets(atURLs: [URL(fileURLWithPath: assetPath)],
                                                    experimentID: experimentID)
  }

}

// MARK: - ExperimentStateListener

extension UserFlowViewController: ExperimentStateListener {
  func experimentStateArchiveStateChanged(forExperiment experiment: Experiment,
                                          overview: ExperimentOverview,
                                          undoBlock: @escaping () -> Void) {
    userManager.driveSyncManager?.syncExperimentLibrary(andReconcile: true, userInitiated: false)
  }

  func experimentStateDeleted(_ deletedExperiment: DeletedExperiment, undoBlock: (() -> Void)?) {
    userManager.driveSyncManager?.syncExperimentLibrary(andReconcile: true, userInitiated: false)
  }

  func experimentStateRestored(_ experiment: Experiment, overview: ExperimentOverview) {
    userManager.driveSyncManager?.syncExperimentLibrary(andReconcile: true, userInitiated: false)
  }
}

extension UserFlowViewController: ExportCoordinatorDelegate {

  func showPDFExportFlow(for experiment: Experiment,
                         completionHandler: @escaping PDFExportController.CompletionHandler) {
    presentPDFExportFlow(experiment, completionHandler: completionHandler)
  }

}

// swiftlint:enable file_length, type_body_length
