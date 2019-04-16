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

import third_party_objective_c_material_components_ios_components_CollectionCells_CollectionCells

/// Data model for open source licenses.
struct LicenseData {
  let title: String
  let filename: String
}

/// A list of all open source licenses used in Science Journal.
class LicensesViewController: MaterialHeaderCollectionViewController {

  // MARK: - Constants

  let cellIdentifier = "LicenseCell"

  // MARK: - Data source

  private var licenses: [LicenseData] = []

  // MARK: - Public

  override func viewDidLoad() {
    super.viewDidLoad()

    // Prepare the license files.
    guard let file = Bundle.currentBundle.path(forResource: "oss_licenses_index", ofType: "txt"),
        let contents = try? NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue)
        else {
      return
    }

    let allLines = contents.components(separatedBy: NSCharacterSet.newlines)

    for line in allLines {
      guard line.count > 0, let range = line.range(of: "/") else { continue }
      let filename = String(line[..<range.lowerBound])
      let title = String(line[range.upperBound...])
      licenses.append(LicenseData(title: title, filename: filename))
    }

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(MDCCollectionViewTextCell.self,
                             forCellWithReuseIdentifier: cellIdentifier)

    styler.cellStyle = .default
    collectionView?.backgroundColor = .white

    title = String.settingsOpenSourceTitle

    if isPresented {
      appBar.hideStatusBarOverlay()
    }

    let backMenuItem = MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    navigationItem.leftBarButtonItem = backMenuItem
  }

  // MARK: - Private

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  // MARK: - UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return licenses.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier,
                                                  for: indexPath)
    if let textCell = cell as? MDCCollectionViewTextCell {
      let rowData = licenses[indexPath.row]
      textCell.textLabel?.text = rowData.title
      textCell.isAccessibilityElement = true
      textCell.accessibilityLabel = rowData.title
      textCell.accessibilityHint = String.doubleTapToOpen
      textCell.accessibilityTraits = .button
    }
    return cell
  }

  // MARK: - UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    let licenseViewer = LicenseViewController(license: licenses[indexPath.row],
                                              analyticsReporter: analyticsReporter)
    navigationController?.pushViewController(licenseViewer, animated: true)
  }

}
