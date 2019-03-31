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
import MaterialComponents

protocol ExistingDataOptionsDelegate: class {
  /// Delegate method for selecting to save all experiments.
  func existingDataOptionsViewControllerDidSelectSaveAllExperiments()

  /// Delegate method for selecting to delete all experiments.
  func existingDataOptionsViewControllerDidSelectDeleteAllExperiments()

  /// Delegate method for selecting to select which experiments to save.
  func existingDataOptionsViewControllerDidSelectSelectExperimentsToSave()
}

/// The view controller for the existing data options screen, explaining that the user can now sync
/// experiments and presents choices for what to do with the existing data on the device.
class ExistingDataOptionsViewController: ScienceJournalCollectionViewController {

  // MARK: - Nested Types

  private struct DataOption {
    let icon: UIImage?
    let title: String
    let description: String
    let identifier: String
  }

  // MARK: - Properties

  /// The existing data options delegate.
  weak var delegate: ExistingDataOptionsDelegate?

  private enum Metrics {
    static let cellIdentifier = "ExistingDataOptionsCell"
    static let headerIdentifier = "ExistingDataOptionsHeaderView"

    static let cellForSaveAll = "SaveAllCell"
    static let cellForDeleteAll = "DeleteAllCell"
    static let cellForSelect = "SelectCell"

    static let collectionInsets = UIEdgeInsets(top: 0,
                                               left: 64,
                                               bottom: 0,
                                               right: 16)
  }

  private let options: [DataOption] = {
    return [DataOption(icon: UIImage(named: "ic_claim_drive"),
                       title: String.existingDataOptionSaveAllExperimentsTitle,
                       description: String.existingDataOptionSaveAllExperimentsDescription,
                       identifier: Metrics.cellForSaveAll),
            DataOption(icon: UIImage(named: "ic_claim_delete"),
                       title: String.existingDataOptionDeleteAllExperimentsTitle,
                       description: String.existingDataOptionDeleteAllExperimentsDescription,
                       identifier: Metrics.cellForDeleteAll),
            DataOption(icon: UIImage(named: "ic_claim_select"),
                       title: String.existingDataOptionSelectExperimentsTitle,
                       description: String.existingDataOptionSelectExperimentsDescription,
                       identifier: Metrics.cellForSelect)]
  }()

  private let numberOfExistingExperiments: Int

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: The analytics reporter.
  ///   - numberOfExistingExperiments: The number of existing experiments.
  init(analyticsReporter: AnalyticsReporter, numberOfExistingExperiments: Int) {
    self.numberOfExistingExperiments = numberOfExistingExperiments
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout(),
               analyticsReporter: analyticsReporter)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.backgroundColor = .white

    collectionView?.register(ExistingDataOptionsHeaderView.self,
                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                             withReuseIdentifier: Metrics.headerIdentifier)
    collectionView?.register(ExistingDataOptionsCell.self,
                             forCellWithReuseIdentifier: Metrics.cellIdentifier)
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    collectionView?.collectionViewLayout.invalidateLayout()
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
    return Metrics.collectionInsets
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    let width =
        collectionView.bounds.width - Metrics.collectionInsets.left - Metrics.collectionInsets.right
    let height =
        ExistingDataOptionsHeaderView.height(inWidth: width,
                                             numberOfExperiments: numberOfExistingExperiments)
    return CGSize(width: collectionView.bounds.width, height: height)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind, withReuseIdentifier: Metrics.headerIdentifier, for: indexPath)
    if let header = header as? ExistingDataOptionsHeaderView {
      header.setNumberOfExperiments(numberOfExistingExperiments)
    }
    return header
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    let option = options[indexPath.item]
    let width = collectionView.bounds.width - Metrics.collectionInsets.left -
        Metrics.collectionInsets.right
    let height = ExistingDataOptionsCell.height(withTitle: option.title,
                                                description: option.description,
                                                inWidth: width)
    return CGSize(width: width, height: height)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return options.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Metrics.cellIdentifier,
                                                  for: indexPath)
    if let cell = cell as? ExistingDataOptionsCell {
      // The last cell should show the bottom separator.
      cell.shouldShowBottomSeparator = indexPath.item == options.count - 1

      let option = options[indexPath.item]
      cell.imageView.image = option.icon
      cell.titleText = option.title
      cell.descriptionText = option.description
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    let option = options[indexPath.item]
    if option.identifier == Metrics.cellForSaveAll {
      // Prompt the user to confirm claiming all.
      let message = String.claimAllExperimentsImmediatelyConfirmationMessage
      let alertController =
          MDCAlertController(title: String.claimAllExperimentsMigrationConfirmationTitle,
                             message: message)
      let claimAction =
          MDCAlertAction(title: String.claimAllExperimentsConfirmationAction) { (action) in
        self.delegate?.existingDataOptionsViewControllerDidSelectSaveAllExperiments()
      }
      let cancelAction = MDCAlertAction(title: String.actionCancel)
      alertController.addAction(claimAction)
      alertController.addAction(cancelAction)
      alertController.accessibilityViewIsModal = true
      self.present(alertController, animated: true)
    } else if option.identifier == Metrics.cellForDeleteAll {
      // Prompt the user to confirm deleting all.
      let message = String.claimExperimentsDeleteAllMigrationConfirmationMessage
      let alertController =
          MDCAlertController(title: String.claimExperimentsDeleteAllMigrationConfirmationTitle,
                             message: message)
      let deleteAction =
          MDCAlertAction(title: String.claimExperimentsDeleteAllConfirmationAction) { (action) in
        self.delegate?.existingDataOptionsViewControllerDidSelectDeleteAllExperiments()
      }
      let cancelAction = MDCAlertAction(title: String.actionCancel)
      alertController.addAction(deleteAction)
      alertController.addAction(cancelAction)
      alertController.accessibilityViewIsModal = true
      self.present(alertController, animated: true)
    } else if option.identifier == Metrics.cellForSelect {
      delegate?.existingDataOptionsViewControllerDidSelectSelectExperimentsToSave()
    }
  }

}
