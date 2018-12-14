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

import UIKit

import third_party_objective_c_material_components_ios_components_Dialogs_Dialogs

protocol ClaimExperimentsViewControllerDelegate: class {

  /// Informs the delegate the experiment with the given ID should be shown.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsShowExperiment(withID experimentID: String)

  /// Informs the delegate the user has added the experiment to Drive.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsAddExperimentToDrive(withID experimentID: String)

  /// Informs the delegate the user shared the experiment.
  ///
  /// - Parameters:
  ///   - experimentID: An experiment ID.
  ///   - attachmentButton: The button to attach the share sheet to.
  func claimExperimentsShareExperiment(withID experimentID: String, attachmentButton: UIButton)

  /// Informs the delegate the user has deleted the experiment.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsDeleteExperiment(withID experimentID: String)

  /// Informs the delegate the user has claimed all experiments.
  func claimExperimentsClaimAllExperiments()

  /// Informs the delegate the user has deleted all experiments.
  func claimExperimentsDeleteAllExperiments()

}

/// A list of experiments the user can claim, share or delete.
class ClaimExperimentsViewController: MaterialHeaderViewController, ClaimExperimentListCellDelegate,
    ExperimentsListItemsDelegate {

  private let experimentsListItemsViewController: ExperimentsListItemsViewController

  override var trackedScrollView: UIScrollView? {
    return experimentsListItemsViewController.collectionView
  }

  /// The claim experiments view controller delegate.
  weak var delegate: ClaimExperimentsViewControllerDelegate?

  private let menuBarButton = MaterialMenuBarButtonItem()
  private var shouldShowArchivedExperiments = true
  private let authAccount: AuthAccount

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - authAccount: The auth account.
  ///   - analyticsReporter: The analytics reporter.
  ///   - metadataManager: The metadata manager.
  ///   - preferenceManager: The preference manager.
  ///   - shouldAllowSharing: Whether to allow sharing.
  init(authAccount: AuthAccount,
       analyticsReporter: AnalyticsReporter,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager,
       shouldAllowSharing: Bool) {
    self.authAccount = authAccount
    experimentsListItemsViewController =
        ExperimentsListItemsViewController(cellClass: ClaimExperimentListCell.self,
                                           metadataManager: metadataManager,
                                           preferenceManager: preferenceManager)

    super.init(analyticsReporter: analyticsReporter)

    // Collection view header.
    let headerSizeBlock = { (width) in
      return AddExperimentsToDriveHeaderView.viewSize(inWidth: width)
    }
    experimentsListItemsViewController.setCollectionViewHeader(
        headerSizeBlock: headerSizeBlock,
        class: AddExperimentsToDriveHeaderView.self)

    // Cell configuration.
    experimentsListItemsViewController.cellConfigurationBlock = {
        [weak self] (cell, overview, image) in
      if let strongSelf = self,
          let cell = cell as? ClaimExperimentListCell, let overview = overview {
        cell.configureForExperimentOverview(overview,
                                            delegate: strongSelf,
                                            image: image,
                                            showShareOption: shouldAllowSharing)
      }
    }
    experimentsListItemsViewController.cellSizeBlock = { (width) in
      return ClaimExperimentListCell.itemSize(inWidth: width)
    }

    experimentsListItemsViewController.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = String.claimExperimentsViewTitle

    // Experiments list items view controller.
    experimentsListItemsViewController.shouldIncludeArchivedExperiments =
        shouldShowArchivedExperiments
    experimentsListItemsViewController.scrollDelegate = self
    experimentsListItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
    addChild(experimentsListItemsViewController)
    view.addSubview(experimentsListItemsViewController.view)
    experimentsListItemsViewController.view.pinToEdgesOfView(view)

    // Close button
    navigationItem.leftBarButtonItem =
        MaterialCloseBarButtonItem(target: self, action: #selector(closeButtonPressed))

    // Menu button
    menuBarButton.button.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuBarButton.button.setImage(UIImage(named: "ic_more_horiz"), for: .normal)
    navigationItem.rightBarButtonItem = menuBarButton
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshExperiments()
  }

  /// Handles the event that an experiment fails to load.
  func handleExperimentLoadingFailure() {
    experimentsListItemsViewController.handleExperimentLoadingFailure()
  }

  /// Should be called when an experiment is removed.
  ///
  /// Parameter experimentID: The ID of the experiment that was removed.
  func experimentRemoved(withID experimentID: String) {
    experimentsListItemsViewController.experimentWasRemoved(withID: experimentID,
                                                            updateCollectionView: isViewVisible)
  }

  /// Refreshes the experiments.
  func refreshExperiments() {
    experimentsListItemsViewController.updateExperiments()
  }

  // MARK: - User actions

  @objc func closeButtonPressed() {
    dismiss(animated: true)
  }

  @objc func menuButtonPressed() {
    let popUpMenu = PopUpMenuViewController()

    // Show archived experiments?
    let iconName =
        self.shouldShowArchivedExperiments ? "ic_check_box" : "ic_check_box_outline_blank"
    let icon = UIImage(named: iconName)
    popUpMenu.addAction(PopUpMenuAction(title: String.actionIncludeArchivedExperiments,
                                        icon: icon) { _ -> Void in
      self.shouldShowArchivedExperiments.toggle()
      self.experimentsListItemsViewController.shouldIncludeArchivedExperiments =
          self.shouldShowArchivedExperiments
    })

    // Claim all
    let claimAllA11yTitle = String.claimAllExperimentsContentDescription
    popUpMenu.addAction(PopUpMenuAction(title: String.claimAllExperiments,
                                        accessibilityLabel: claimAllA11yTitle) { _ -> Void in
      // Prompt the user to confirm claiming all.
      let message = String.claimExperimentsClaimAllConfirmationMessage(withItemCount:
          self.experimentsListItemsViewController.itemCount, email: self.authAccount.email)
      let alertController = MDCAlertController(title: nil, message: message)
      let claimAction =
          MDCAlertAction(title: String.claimAllExperimentsConfirmationActionConfirm) { (action) in
        self.delegate?.claimExperimentsClaimAllExperiments()
      }
      let cancelAction = MDCAlertAction(title: String.actionCancel)
      alertController.addAction(claimAction)
      alertController.addAction(cancelAction)
      alertController.accessibilityViewIsModal = true
      self.present(alertController, animated: true)
    })

    // Delete all
    let deleteA11yTitle = String.claimExperimentsDeleteAllContentDescription
    popUpMenu.addAction(PopUpMenuAction(title: String.claimExperimentsDeleteAll,
                                        accessibilityLabel: deleteA11yTitle) { _ -> Void in
      // Prompt the user to confirm deleting all.
      let message = String.claimExperimentsDeleteAllConfirmationMessage(withItemCount:
          self.experimentsListItemsViewController.itemCount)
      let alertController = MDCAlertController(title: nil, message: message)
      let deleteAction =
          MDCAlertAction(title: String.claimExperimentsDeleteAllConfirmationAction) { (action) in
        self.delegate?.claimExperimentsDeleteAllExperiments()
      }
      let cancelAction = MDCAlertAction(title: String.actionCancel)
      alertController.addAction(deleteAction)
      alertController.addAction(cancelAction)
      alertController.accessibilityViewIsModal = true
      self.present(alertController, animated: true)
    })

    popUpMenu.present(from: self, position: .sourceView(menuBarButton.button))
  }

  // MARK: - ExperimentsListItemsDelegate

  func experimentsListItemsViewControllerDidSelectExperiment(withID experimentID: String) {
    delegate?.claimExperimentsShowExperiment(withID: experimentID)
  }

  // MARK: - ClaimExperimentListCellDelegate

  func claimExperimentListCellPresssedAddToDriveButton(_ cell: ClaimExperimentListCell) {
    guard let overview = experimentsListItemsViewController.overview(forCell: cell) else { return }

    // Prompt the user to confirm adding to Drive.
    let message = String.claimExperimentConfirmationMessage(withEmail: self.authAccount.email)
    let alertController = MDCAlertController(title: String.claimExperimentConfirmationTitle,
                                             message: message)
    let cancelAction = MDCAlertAction(title: String.actionCancel)
    let claimAction =
        MDCAlertAction(title: String.claimExperimentConfirmationActionTitle) { (action) in
      self.delegate?.claimExperimentsAddExperimentToDrive(withID: overview.experimentID)
    }
    alertController.addAction(claimAction)
    alertController.addAction(cancelAction)
    alertController.accessibilityViewIsModal = true
    present(alertController, animated: true)
  }

  func claimExperimentListCell(_ cell: ClaimExperimentListCell,
                               presssedShareButton shareButton: UIButton) {
    guard let overview = experimentsListItemsViewController.overview(forCell: cell) else { return }
    delegate?.claimExperimentsShareExperiment(withID: overview.experimentID,
                                              attachmentButton: shareButton)
  }

  func claimExperimentListCellPresssedDeleteButton(_ cell: ClaimExperimentListCell) {
    guard let overview = experimentsListItemsViewController.overview(forCell: cell) else { return }

    // Prompt the user to confirm deletion.
    let alertController = MDCAlertController(title: String.deleteExperimentDialogTitle,
                                             message: String.deleteExperimentDialogMessage)
    let cancelAction = MDCAlertAction(title: String.btnDeleteObjectCancel)
    let deleteAction = MDCAlertAction(title: String.btnDeleteObjectConfirm) { (action) in
      self.delegate?.claimExperimentsDeleteExperiment(withID: overview.experimentID)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(deleteAction)
    alertController.accessibilityViewIsModal = true
    present(alertController, animated: true)
  }

}
