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

protocol TriggerListDelegate: class {
  /// Called when the trigger list view controller updates triggers.
  func triggerListViewController(_ triggerListViewController: TriggerListViewController,
                                 didUpdateTriggers sensorTriggers: [SensorTrigger],
                                 withActiveTriggerIDs activeTriggerIDs: [String],
                                 forSensor sensor: Sensor)
}

/// View controller that displays a list of triggers for a sensor. Each can be modified.
class TriggerListViewController: MaterialHeaderCollectionViewController, TriggerListCellDelegate,
    TriggerEditViewControllerDelegate {

  // MARK: - No triggers view

  class NoTriggersView: UIView {

    override init(frame: CGRect) {
      super.init(frame: frame)
      configureView()
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      configureView()
    }

    private func configureView() {
      backgroundColor = .white

      let noTriggersLabel = UILabel()
      noTriggersLabel.alpha = MDCTypography.titleFontOpacity()
      noTriggersLabel.font = MDCTypography.titleFont()
      noTriggersLabel.text = String.emptyTriggerList
      noTriggersLabel.translatesAutoresizingMaskIntoConstraints = false
      addSubview(noTriggersLabel)
      noTriggersLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
      noTriggersLabel.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true

      let triggerImageView = UIImageView(image: UIImage(named: "ic_trigger_large"))
      triggerImageView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(triggerImageView)
      triggerImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
      triggerImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
      triggerImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
      triggerImageView.topAnchor.constraint(equalTo: noTriggersLabel.bottomAnchor).isActive = true
    }

  }

  // MARK: - TriggerListViewController

  // MARK: - Properties

  private var activeTriggerIDs: [String]
  private let addButton = MDCFloatingButton()
  private let addButtonPadding: CGFloat = 16
  private weak var delegate: TriggerListDelegate?
  private let emptyView = NoTriggersView()
  private let sensor: Sensor
  private let triggerListCellIdentifier = "TriggerListCell"
  private let triggerListDataSource: TriggerListDataSource

  private var isEmptyViewHidden = true {
    didSet {
      guard isEmptyViewHidden != oldValue else { return }
      if isEmptyViewHidden {
        removeEmptyView()
      } else {
        addEmptyView()
      }
    }
  }

  private var horizontalPadding: CGFloat {
    var padding: CGFloat {
      switch displayType {
      case .compact, .compactWide:
        return 0
      case .regular:
        return ViewConstants.cellHorizontalInsetRegularDisplayType
      case .regularWide:
        return ViewConstants.cellHorizontalInsetRegularWideDisplayType
      }
    }
    return padding + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - sensorTriggers: The sensor triggers for a sensor.
  ///   - activeTriggerIDs: The IDs of the triggers that are active.
  ///   - sensor: The sensor to show sensor triggers for.
  ///   - delegate: The sensor trigger list delgate.
  ///   - analyticsReporter: An AnalyticsReporter.
  init(sensorTriggers: [SensorTrigger],
       activeTriggerIDs: [String],
       sensor: Sensor,
       delegate: TriggerListDelegate,
       analyticsReporter: AnalyticsReporter) {
    self.activeTriggerIDs = activeTriggerIDs
    self.sensor = sensor
    self.delegate = delegate
    triggerListDataSource = TriggerListDataSource(sensorTriggers: sensorTriggers)

    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(TriggerListCell.self,
                             forCellWithReuseIdentifier: triggerListCellIdentifier)

    accessibilityViewIsModal = true

    styler.cellStyle = .default

    appBar.headerViewController.headerView.backgroundColor = .appBarReviewBackgroundColor
    collectionView?.backgroundColor = .white

    if isPresented && UIDevice.current.userInterfaceIdiom == .pad {
      appBar.hideStatusBarOverlay()
    }

    // Title.
    title = String.triggerListTitle + " " + sensor.name

    // Close button
    navigationItem.leftBarButtonItem =
        MaterialCloseBarButtonItem(target: self, action: #selector(closeButtonPressed))

    // Add button.
    view.addSubview(addButton)
    addButton.setImage(UIImage(named: "ic_add"), for: .normal)
    addButton.tintColor = .white
    addButton.setBackgroundColor(MDCPalette.blue.tint600, for: .normal)
    addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
    addButton.translatesAutoresizingMaskIntoConstraints = false
    addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                      constant: -addButtonPadding).isActive = true
    addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                        constant: -addButtonPadding).isActive = true
    addButton.accessibilityLabel = String.btnAddNewTrigger

    // Show the empty view if the data source doesn't have items.
    self.isEmptyViewHidden = self.triggerListDataSource.hasItems
  }

  override func accessibilityPerformEscape() -> Bool {
    callDelegateWithUpdatedTriggers()
    dismiss(animated: true)
    return true
  }

  // MARK: - Private

  private func addEmptyView() {
    emptyView.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(emptyView, belowSubview: addButton)
    emptyView.topAnchor.constraint(equalTo: appBar.navigationBar.bottomAnchor).isActive = true
    emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  private func removeEmptyView() {
    emptyView.removeFromSuperview()
  }

  /// Whether or not a trigger is active. Exposed for testing.
  func isTriggerActive(_ trigger: SensorTrigger) -> Bool {
    return activeTriggerIDs.contains(trigger.triggerID)
  }

  private func callDelegateWithUpdatedTriggers() {
    delegate?.triggerListViewController(self,
                                        didUpdateTriggers: triggerListDataSource.triggers,
                                        withActiveTriggerIDs: activeTriggerIDs,
                                        forSensor: sensor)
  }

  private func showTriggerEditViewController(with trigger: SensorTrigger, isEditMode: Bool) {
    let triggerEditViewController = TriggerEditViewController(sensorTrigger: trigger,
                                                              sensor: sensor,
                                                              delegate: self,
                                                              isEditMode: isEditMode,
                                                              analyticsReporter: analyticsReporter)
    self.navigationController?.pushViewController(triggerEditViewController, animated: true)
  }

  // MARK: - User actions

  @objc private func addButtonPressed() {
    // Show the edit view controller for a new trigger.
    showTriggerEditViewController(with: SensorTrigger(sensorID: sensor.sensorId), isEditMode: false)
  }

  @objc private func closeButtonPressed() {
    callDelegateWithUpdatedTriggers()
    dismiss(animated: true)
  }

  // MARK: - UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return triggerListDataSource.numberOfItems
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: triggerListCellIdentifier,
                                                  for: indexPath)
    if let triggerListCell = cell as? TriggerListCell {
      let trigger = triggerListDataSource.item(at: indexPath)
      triggerListCell.delegate = self
      triggerListCell.textLabel.text = trigger.textDescription(for: sensor)
      triggerListCell.aSwitch.isOn = isTriggerActive(trigger)
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.size.width - horizontalPadding,
                  height: TriggerListCell.height)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    // Don't show selection highlight ink.
    return false
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldSelectItemAt indexPath: IndexPath) -> Bool {
    // Trigger cells aren't selectable.
    return false
  }

  // MARK: - TriggerListCellDelegate

  func triggerListCellSwitchValueChanged(_ triggerListCell: TriggerListCell) {
    guard let indexPath = collectionView?.indexPath(for: triggerListCell) else { return }
    let trigger = triggerListDataSource.item(at: indexPath)
    if triggerListCell.aSwitch.isOn {
      activeTriggerIDs.append(trigger.triggerID)
    } else {
      guard let index = activeTriggerIDs.index(where: { $0 == trigger.triggerID }) else { return }
      activeTriggerIDs.remove(at: index)
    }
    callDelegateWithUpdatedTriggers()
  }

  func triggerListCellMenuButtonPressed(_ triggerListCell: TriggerListCell) {
    let popUpMenu = PopUpMenuViewController()
    popUpMenu.addAction(PopUpMenuAction(title: String.actionEdit,
                                        icon: UIImage(named: "ic_edit")) { (_) in
      guard let indexPath = self.collectionView?.indexPath(for: triggerListCell) else { return }
      let trigger = self.triggerListDataSource.item(at: indexPath)
      self.showTriggerEditViewController(with: trigger, isEditMode: true)
    })

    popUpMenu.addAction(PopUpMenuAction(title: String.actionDelete,
                                        icon: UIImage(named: "ic_delete")) { (_) in
      guard let indexPath = self.collectionView?.indexPath(for: triggerListCell),
          let removedTrigger = self.triggerListDataSource.removeItem(at: indexPath) else {
        return
      }

      self.collectionView?.deleteItems(at: [indexPath])
      self.isEmptyViewHidden = self.triggerListDataSource.hasItems

      // Allow the user to undo the delete action.
      showUndoSnackbar(withMessage: String.sensorTriggerDeleted, undoBlock: {
        self.triggerListDataSource.insertItem(removedTrigger, atIndex: indexPath.item)
        self.collectionView?.insertItems(at: [indexPath])
        self.isEmptyViewHidden = self.triggerListDataSource.hasItems
      })
    })

    popUpMenu.present(from: self, position: .sourceView(triggerListCell.menuButton))
  }

  // MARK: - TriggerEditViewControllerDelegate

  func triggerEditViewController(_ triggerEditViewController: TriggerEditViewController,
                                 didEditTrigger trigger: SensorTrigger) {
    // If the item has an index path, reload it. Otherwise, add the item and insert it.
    if let indexPathOfItem = triggerListDataSource.indexPathOfItem(trigger) {
      collectionView?.reloadItems(at: [indexPathOfItem])
    } else {
      triggerListDataSource.addItem(trigger)
      activeTriggerIDs.append(trigger.triggerID)
      collectionView?.insertItems(at: [triggerListDataSource.indexPathOfLastItem])
      isEmptyViewHidden = triggerListDataSource.hasItems
    }
  }

}
