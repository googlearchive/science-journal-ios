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

/// A list of options to learn about the Science Journal app.
class AboutViewController: MaterialHeaderCollectionViewController {

  // MARK: - Data model

  enum AboutRow {
    case website
    case licenses
    case version
    case privacy
    case terms

    var title: String {
      switch self {
      case .website: return String.settingsWebsiteTitle
      case .licenses: return String.settingsOpenSourceTitle
      case .version: return String.settingsVersionTitle
      case .privacy: return String.settingsPrivacyPolicyTitle
      case .terms: return String.settingsTermsTitle
      }
    }

    var description: String? {
      switch self {
      case .website: return "https://g.co/sciencejournal"
      case .licenses: return nil
      case .version: return Bundle.appVersionString
      case .privacy: return "https://www.google.com/policies/privacy/"
      case .terms: return "https://www.google.com/policies/terms/"
      }
    }

    var accessibilityLabel: String {
      switch self {
      case .website: return String.settingsWebsiteTitle
      case .licenses: return String.settingsOpenSourceTitle
      case .version: return "\(String.settingsVersionTitle) \(self.description ?? "")"
      case .privacy: return String.settingsPrivacyPolicyTitle
      case .terms: return String.settingsTermsTitle
      }
    }

    var accessibilityHint: String? {
      switch self {
      case .version: return nil
      default: return "\(String.doubleTapToOpen) \(self.description ?? "")"
      }
    }

    var accessibilityTrait: UIAccessibilityTraits {
      switch self {
      case .version: return .staticText
      default: return .button
      }
    }
  }

  // MARK: - Constants

  let cellIdentifier = "AboutCell"

  // MARK: - Datasource

  let rows: [AboutRow] = [
    .website,
    .licenses,
    .version,
    .privacy,
    .terms
  ]

  // MARK: - Public

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(MDCCollectionViewTextCell.self,
                             forCellWithReuseIdentifier: cellIdentifier)

    styler.cellStyle = .default
    collectionView?.backgroundColor = .white

    title = String.actionAbout

    if isPresented {
      appBar.hideStatusBarOverlay()
      let closeMenuItem = MaterialCloseBarButtonItem(target: self,
                                                     action: #selector(closeButtonPressed))
      navigationItem.leftBarButtonItem = closeMenuItem
    } else {
      let backMenuItem = MaterialBackBarButtonItem(target: self,
                                                   action: #selector(backButtonPressed))
      navigationItem.leftBarButtonItem = backMenuItem
    }
  }

  // MARK: - Private

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func closeButtonPressed() {
    dismiss(animated: true)
  }

  // MARK: - UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return rows.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier,
                                                  for: indexPath)
    if let textCell = cell as? MDCCollectionViewTextCell {
      let rowData = rows[indexPath.row]
      textCell.textLabel?.text = rowData.title
      textCell.detailTextLabel?.text = rowData.description
      textCell.accessibilityLabel = rowData.accessibilityLabel
      textCell.accessibilityHint = rowData.accessibilityHint
      textCell.isAccessibilityElement = true
      textCell.accessibilityTraits = rowData.accessibilityTrait
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    let rowData = rows[indexPath.row]
    if rowData.description != nil {
      return MDCCellDefaultTwoLineHeight
    } else {
      return MDCCellDefaultOneLineHeight
    }
  }

  // MARK: - UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    let rowData = rows[indexPath.row]
    switch rowData {
    case .website, .privacy, .terms:
      if let stringURL = rowData.description, let url = URL(string: stringURL) {
        UIApplication.shared.open(url)
      }
      break
    case .licenses:
      navigationController?.pushViewController(
          LicensesViewController(analyticsReporter: analyticsReporter),
          animated: true)
      break
    default:
      return
    }
  }

}
