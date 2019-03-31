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

/// A list of all the metadata for a picture note.
class PictureInfoViewController: MaterialHeaderCollectionViewController {

  // MARK: - Nested types

  struct PictureMetadata {
    var icon: UIImage?
    var title: String
    var description: String
  }

  // MARK: - Constants

  let cellIdentifier = "NoteMetadataDetailCell"
  let headerIdentifier = "NoteMetadataDetailHeaderView"
  let innerHorizontalPadding: CGFloat = 16.0
  let innerVerticalPadding: CGFloat = 16.0

  // MARK: - Properties

  private var cellHorizontalInset: CGFloat {
    var inset: CGFloat {
      switch displayType {
      case .compact, .compactWide:
        return innerHorizontalPadding * 2
      case .regular:
        return ViewConstants.cellHorizontalInsetRegularDisplayType
      case .regularWide:
        return ViewConstants.cellHorizontalInsetRegularWideDisplayType
      }
    }
    return inset + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  private var metadataEdgeInsets: UIEdgeInsets {
    return UIEdgeInsets(top: SnapshotDetailViewController.innerVerticalPadding,
                        left: cellHorizontalInset / 2,
                        bottom: SnapshotDetailViewController.innerVerticalPadding,
                        right: cellHorizontalInset / 2)
  }

  // MARK: - Data source

  private var dataSource = [PictureMetadata]()
  private let displayPictureNote: DisplayPictureNote

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - displayPicture: A display picture.
  ///   - analyticsReporter: The analytics reporter.
  ///   - metadataManager: The metadata manager.
  init(displayPicture: DisplayPictureNote,
       analyticsReporter: AnalyticsReporter,
       metadataManager: MetadataManager) {
    self.displayPictureNote = displayPicture
    super.init(analyticsReporter: analyticsReporter)

    // Create the date metadata item for the picture.
    let date = Date(milliseconds: displayPictureNote.timestamp.milliseconds)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM d, yyyy"
    let datestamp = dateFormatter.string(from: date)
    dateFormatter.dateFormat = "EEEE h:mm a"
    let timestamp = dateFormatter.string(from: date)
    dataSource.append(PictureMetadata(icon: UIImage(named: "ic_today"),
                                      title: datestamp,
                                      description: timestamp))

    // Fetch and display the exif data if possible.
    guard let imagePath = displayPicture.imagePath,
        let exif = metadataManager.exifDataForImagePath(imagePath) else {
      return
    }
    if let device = exif.device {
      dataSource.append(PictureMetadata(icon: UIImage(named: "ic_camera"),
                                        title: String.pictureDetailExifDevice,
                                        description: device))
    }
    if let shutterSpeed = exif.shutterSpeed {
      dataSource.append(PictureMetadata(icon: UIImage(named: "ic_timer"),
                                        title: String.pictureDetailExifShutterSpeed,
                                        description: shutterSpeed))
    }
    // Dimensions come straight from the image itself. EXIF dimensions can be arbitrarily edited by
    // any photo process and should not be trusted considering we can just ask the actual image
    // for its dimensions.
    if let imagePath = displayPictureNote.imagePath,
        let image = metadataManager.image(forFullImagePath: imagePath) {
      let dimensions = String(format: "%.0fx%.0f", image.size.width, image.size.height)
      dataSource.append(PictureMetadata(
          icon: UIImage(named: "ic_photo_size_select_large"),
          title: String.pictureDetailExifDimensions,
          description: "\(dimensions) \(String.pixels.lowercased())"))
    }
    if let notes = exif.notes {
      dataSource.append(PictureMetadata(icon: UIImage(named: "ic_note"),
                                        title: String.pictureDetailExifNotes,
                                        description: notes))
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(NoteMetadataDetailCell.self,
                             forCellWithReuseIdentifier: cellIdentifier)
    collectionView?.register(NoteMetadataDetailHeaderView.self,
                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                             withReuseIdentifier: headerIdentifier)

    styler.cellStyle = .default
    collectionView?.backgroundColor = .white

    appBar.headerViewController.headerView.backgroundColor = .white
    appBar.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
    appBar.navigationBar.tintColor = .black

    title = String.pictureDetailInfo

    let backMenuItem = MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    backMenuItem.tintColor = .black
    navigationItem.leftBarButtonItem = backMenuItem
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    // The iPad always has a black bar under the status area. On iPhone the header is white in
    // this view.
    return UIDevice.current.userInterfaceIdiom == .pad ? .lightContent : .default
  }

  // MARK: - UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return dataSource.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.width - cellHorizontalInset
    var calculatedHeight: CGFloat = 0
    let metadata = dataSource[indexPath.item]
      calculatedHeight = NoteMetadataDetailCell.heightWithText(metadata.title,
                                                               description: metadata.description,
                                                               inWidth: width)
    return CGSize(width: width, height: ceil(calculatedHeight))
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: headerIdentifier,
      for: indexPath)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier,
                                                  for: indexPath)
    if let cell = cell as? NoteMetadataDetailCell {
      let metadata = dataSource[indexPath.item]
      cell.textLabel.text = metadata.title
      cell.descriptionLabel.text = metadata.description
      cell.iconView.image = metadata.icon
    }
    return cell
  }

  // MARK: - UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
    return metadataEdgeInsets
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.bounds.size.width - cellHorizontalInset,
                  height: NoteMetadataDetailHeaderView.height)
  }

  // MARK: - Private

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

}
