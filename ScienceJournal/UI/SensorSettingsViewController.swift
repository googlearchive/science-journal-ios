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

import third_party_objective_c_material_components_ios_components_Collections_Collections
import third_party_objective_c_material_components_ios_components_Palettes_Palettes

protocol SensorSettingsDelegate: class {
  /// Called when the sensor settings view controller close button is pressed. The delegate is
  /// responsible for dismissing this view controller.
  ///
  /// - Parameters:
  ///   - sensorSettingsViewController: The sensor settings view controller.
  ///   - enabledSensorIDs: The IDs of the sensors that are enabled.
  func sensorSettingsViewController(_ sensorSettingsViewController: SensorSettingsViewController,
                                    didRequestCloseWithEnabledSensors enabledSensorIDs: [String])
}

/// Displays the sensors active for the current experiment with options to enable or disable
/// specific sensors. Also shows discovered bluetooth devices with the option to connect to them.
class SensorSettingsViewController: MaterialHeaderCollectionViewController,
    SensorSettingsDataSourceDelegate, SensorSettingsCellDelegate {

  // MARK: - Properties

  /// The delegate.
  weak var delegate: SensorSettingsDelegate?

  private let dataSource: SensorSettingsDataSource
  private let sensorCellIdentifier = "SensorSettingsCell"

  private var cellHorizontalInset: CGFloat {
    var inset: CGFloat {
      switch displayType {
      case .compact, .compactWide:
        return 0
      case .regular:
        return ViewConstants.cellHorizontalInsetRegularDisplayType
      case .regularWide:
        return ViewConstants.cellHorizontalInsetRegularWideDisplayType
      }
    }
    return inset + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  private let metadataManager: MetadataManager
  private let sensorController: SensorController

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - enabledSensorIDs: The IDs of sensors that are enabled.
  ///   - analyticsReporter: An AnalyticsReporter.
  ///   - metadataManager: A metadata manager.
  ///   - sensorController: The sensor controller.
  init(enabledSensorIDs: [String],
       analyticsReporter: AnalyticsReporter,
       metadataManager: MetadataManager,
       sensorController: SensorController) {
    self.metadataManager = metadataManager
    self.sensorController = sensorController
    dataSource = SensorSettingsDataSource(enabledSensorIDs: enabledSensorIDs,
                                          metadataManager: metadataManager,
                                          sensorController: sensorController)
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(SensorSettingsCell.self,
                             forCellWithReuseIdentifier: sensorCellIdentifier)
    collectionView?.register(MDCCollectionViewTextCell.self,
                             forSupplementaryViewOfKind:UICollectionView.elementKindSectionHeader,
                             withReuseIdentifier:UICollectionView.elementKindSectionHeader)

    dataSource.delegate = self

    title = String.titleActivitySensorSettings

    if isPresented && UIDevice.current.userInterfaceIdiom == .pad {
      appBar.hideStatusBarOverlay()
    }

    collectionView?.backgroundColor = .white
    if #available(iOS 11.0, *) {
      collectionView?.contentInsetAdjustmentBehavior = .never
    }

    let closeButton = MaterialCloseBarButtonItem(target: self,
                                                 action: #selector(closeButtonPressed))
    navigationItem.leftBarButtonItem = closeButton

    styler.separatorLineHeight = 0
  }

  override func viewSafeAreaInsetsDidChange() {
    collectionView?.contentInset.bottom = view.safeAreaInsetsOrZero.bottom
  }

  func sensorForIndexPath(_ indexPath: IndexPath) -> Sensor {
    return sensorController.availableSensors[indexPath.item]
  }

  // MARK: - User actions

  @objc func closeButtonPressed() {
    delegate?.sensorSettingsViewController(
        self,
        didRequestCloseWithEnabledSensors: dataSource.enabledSensorIDs)
  }

  // MARK: - UICollectionViewDataSource

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return dataSource.numberOfSections
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return dataSource.numberOfItems(inSection: section)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // swiftlint:disable force_cast
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sensorCellIdentifier,
                                                  for: indexPath) as! SensorSettingsCell
    // swiftlint:enable force_cast
    dataSource.configureCell(cell, atIndexPath: indexPath)
    cell.delegate = self
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    // swiftlint:disable force_cast
    let supplementaryView =
        collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                        withReuseIdentifier: kind,
                                                        for: indexPath)
        as! MDCCollectionViewTextCell
    // swiftlint:enable force_cast

    if kind == UICollectionView.elementKindSectionHeader {
      if let section = SensorSettingsDataSource.Section(rawValue: indexPath.section) {
        supplementaryView.textLabel?.text = section.sectionTitle
      }
      supplementaryView.textLabel?.textColor = MDCPalette.blue.tint500
    }
    return supplementaryView
  }

  // MARK: - UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    dataSource.didSelectItem(atIndexPath: indexPath)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    return dataSource.shouldSelectItemAt(indexPath: indexPath)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return dataSource.shouldSelectItemAt(indexPath: indexPath)
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    guard let sensorSection = SensorSettingsDataSource.Section(rawValue: section),
        sensorSection.sectionTitle != nil else {
      return CGSize.zero
    }
    return CGSize(width: collectionView.bounds.size.width - cellHorizontalInset,
                  height: MDCCellDefaultOneLineHeight)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.size.width - cellHorizontalInset,
                  height: SensorSettingsCell.height)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0,
                        left: cellHorizontalInset / 2,
                        bottom: 0,
                        right: cellHorizontalInset / 2)
  }

  // MARK: - SensorSettingsDataSourceDelegate

  func sensorSettingsDataSourceNeedsRefresh(_ dataSource: SensorSettingsDataSource) {
    collectionView?.reloadData()
  }

  func sensorSettingsDataSource(_ dataSource: SensorSettingsDataSource,
                                sensorShouldShowOptions sensorInterface: BLESensorInterface) {
    sensorInterface.presentOptions(from: self) {
      self.metadataManager.saveAndUpdateBluetoothSensor(sensorInterface)
    }
  }

  // MARK: - SensorSettingsCellDelegate

  func sensorSettingsCell(_ cell: SensorSettingsCell, buttonPressed button: UIButton) {
    guard let indexPath = collectionView?.indexPath(for: cell),
        let deviceSection = dataSource.deviceSection(atIndexPath: indexPath),
        let headerIndex = dataSource.headerIndexOfDeviceSection(atIndexPath: indexPath) else {
      return
    }

    if !deviceSection.isInternalSensors && indexPath.item == headerIndex {
      // Button pressed on first item, which is the device section header.
      let popUpMenuVC = PopUpMenuViewController()
      popUpMenuVC.addAction(PopUpMenuAction(title: String.forgetDevice,
                                            icon: nil,
                                            accessibilityLabel: nil,
                                            isEnabled: true,
                                            handler: { (_) in
        for case let bluetoothSensor as BluetoothSensor in deviceSection.sensors {
          self.metadataManager.removeBluetoothSensor(bluetoothSensor)
          if let peripheral = bluetoothSensor.sensorInterafce.peripheral {
            self.dataSource.serviceScanner.disconnectFromPeripheral(peripheral)
          }
        }
        self.dataSource.removeSection(atIndexPath: indexPath)
      }))
      popUpMenuVC.present(from: self, position: .sourceView(button))
    } else {
      // TODO: Handle configure button press. http://b/66649890
    }
  }

}
