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

/// A cell displaying the results of a Trial in an Experiment. The Trial cell contains a header with
/// the date and time of the trial (and a menu button), one or many sensor recordings, and zero or
/// more notes.
class TrialCardCell: AutoLayoutMaterialCardCell {

  // MARK: - Properties

  /// The experiment card cell delegate.
  weak var delegate: ExperimentCardCellDelegate?

  private let wrapperView = UIView()
  private let recordedTrialCardView = RecordedTrialCardView()
  private let recordingTrialCardView = RecordingTrialCardView()
  private var metadataManager: MetadataManager?

  private var pictureCardViews: [PictureCardView] {
    return recordedTrialCardView.trialCardNotesView.pictureCardViews
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    addNotificationObservers()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
    addNotificationObservers()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    recordedTrialCardView.trialCardNotesView.removeAllNotes()
  }

  /// Calculates the height required to display this cell, given the Trial's data and status,
  /// constrained to a maximum width.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this cell, used to constrain measurements.
  ///   - trial: The trial to measure.
  /// - Returns: The total height of this view.
  static func height(inWidth width: CGFloat,
                     trial: DisplayTrial,
                     experimentDisplay: ExperimentDisplay = .normal) -> CGFloat {
    if trial.status == .recording {
      return RecordingTrialCardView.height
    } else {
      return RecordedTrialCardView.heightOfTrial(trial,
                                                 constrainedToWidth: width,
                                                 experimentDisplay: experimentDisplay)
    }
  }

  /// Configures the cell for an in-progress trial recording.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - metadataManager: The metadata manager.
  func configureRecordingCellWithTrial(_ trial: DisplayTrial, metadataManager: MetadataManager) {
    self.metadataManager = metadataManager
    recordedTrialCardView.removeFromSuperview()
    recordingTrialCardView.frame = wrapperView.bounds
    recordingTrialCardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    wrapperView.addSubview(recordingTrialCardView)
    recordingTrialCardView.configure(withTrial: trial)
  }

  /// Configures the cell for a recorded trial.
  ///
  /// - Parameters:
  ///   - trial: The trial.
  ///   - metadataManager: The metadata manager.
  func configureCellWithTrial(
    _ trial: DisplayTrial, metadataManager: MetadataManager,
    experimentDisplay: ExperimentDisplay = .normal) {
    self.metadataManager = metadataManager
    recordingTrialCardView.removeFromSuperview()
    recordedTrialCardView.frame = wrapperView.bounds
    recordedTrialCardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    wrapperView.addSubview(recordedTrialCardView)
    recordedTrialCardView.configure(withTrial: trial, experimentDisplay: experimentDisplay)
    recordedTrialCardView.experimentCardHeaderView.menuButton.addTarget(
        self,
        action: #selector(menuButtonPressed(sender:)),
        for: .touchUpInside)
    pictureCardViews.forEach { $0.experimentDisplay = experimentDisplay }
  }

  /// Displays the images for picture notes in a trial card cell. Called when a cell is about to be
  /// displayed.
  func displayImages() {
    pictureCardViews.forEach { (pictureView) in
      displayImage(forPictureCardView: pictureView)
    }
  }

  /// Removes the images in a trial card cell. Called when a cell leaves the screen.
  func removeImages() {
    pictureCardViews.forEach { $0.image = nil }
  }

  /// Sets the trial card note view pool.
  func setTrialCardNoteViewPool(_ trialCardNoteViewPool: TrialCardNoteViewPool) {
    recordedTrialCardView.trialCardNotesView.trialCardNoteViewPool = trialCardNoteViewPool
  }

  // MARK: - Private

  private func configureView() {
    cellContentView.addSubview(wrapperView)
    wrapperView.frame = cellContentView.bounds
    wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    // Accessibility wrapping view, which sits behind all other elements to allow a user to "grab"
    // a cell by tapping anywhere in the empty space of a cell.
    let accessibilityWrappingView = UIView()
    cellContentView.configureAccessibilityWrappingView(accessibilityWrappingView,
                                                       withLabel: String.runDefaultTitle,
                                                       hint: String.doubleTapToViewDetails)

    // Set the order of elements to be the wrapping view first, then the rest.
    accessibilityElements = [accessibilityWrappingView, wrapperView]
  }

  private func addNotificationObservers() {
    // Listen to notifications of newly downloaded assets and sensor data.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(downloadedImages),
                                           name: .driveSyncManagerDownloadedImages,
                                           object: nil)
  }

  private func displayImage(forPictureCardView pictureCardView: PictureCardView) {
    guard let imagePath = pictureCardView.pictureNoteImagePath else {
      return
    }

    DispatchQueue.main.async {
      let image = self.metadataManager?.image(forFullImagePath: imagePath)
      pictureCardView.image = image
    }
  }

  // MARK: - User actions

  @objc private func menuButtonPressed(sender: MenuButton) {
    delegate?.experimentCardCellMenuButtonPressed(self, button: sender)
  }

  // MARK: - Notifications

  @objc private func downloadedImages(notification: Notification) {
    guard let imagePaths =
        notification.userInfo?[DriveSyncUserInfoConstants.downloadedImagePathsKey]
            as? [String] else {
      return
    }

    for pictureCardView in pictureCardViews {
      if let pictureNoteImagePath = pictureCardView.pictureNote?.imagePath,
          imagePaths.contains(pictureNoteImagePath) {
        displayImage(forPictureCardView: pictureCardView)
      }
    }
  }

}
