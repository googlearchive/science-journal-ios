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

/// A cell displaying the results of a picture snapshot in an Experiment. The cell contains the
/// picture, a header and an optional caption.
class PictureCardCell: FrameLayoutMaterialCardCell {

  // MARK: - Properties

  weak var delegate: ExperimentCardCellDelegate?
  private var pictureNote: DisplayPictureNote?
  private var pictureStyle: PictureStyle?
  private var pictureView: PictureCardView?
  private var captionView = ExperimentCardCaptionView()
  private let headerView = ExperimentCardHeaderView()
  private var metadataManager: MetadataManager?
  private let separator = SeparatorView(direction: .horizontal, style: .dark)

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

  override func layoutSubviews() {
    super.layoutSubviews()

    var nextOriginY: CGFloat = 0
    if !headerView.isHidden {
      headerView.frame = CGRect(x: 0,
                                y: nextOriginY,
                                width: cellContentView.bounds.width,
                                height: ExperimentCardHeaderView.height)
      nextOriginY = headerView.frame.maxY
    }

    separator.frame = CGRect(x: 0,
                             y: nextOriginY,
                             width: cellContentView.bounds.width,
                             height: SeparatorView.Metrics.dimension)
    nextOriginY = separator.frame.maxY

    if let pictureView = pictureView {
      pictureView.frame = CGRect(x: 0,
                                 y: nextOriginY,
                                 width: cellContentView.bounds.width,
                                 height: pictureStyle?.height ?? 0)
      nextOriginY = pictureView.frame.maxY
    }

    if let caption = pictureNote?.caption {
      let captionViewHeight =
          ceil(ExperimentCardCaptionView.heightWithCaption(caption,
                                                           inWidth: cellContentView.bounds.width))
      captionView.frame = CGRect(x: 0,
                                 y: nextOriginY,
                                 width: cellContentView.bounds.width,
                                 height: captionViewHeight)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    pictureNote = nil
  }

  /// Calculates the height required to display this view.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - pictureNote: The picture note to measure.
  ///   - pictureStyle: The picture style.
  ///   - showingHeader: Whether or not the cell will be showing the header.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat,
                     pictureNote: DisplayPictureNote,
                     pictureStyle: PictureStyle,
                     showingHeader: Bool = true) -> CGFloat {
    // The fixed picture height.
    var totalHeight = pictureStyle.height
    // Add the separator height.
    totalHeight += SeparatorView.Metrics.dimension
    if showingHeader {
      // Add the header view's height.
      totalHeight += ExperimentCardHeaderView.height
    }
    // The caption, if necessary.
    if let caption = pictureNote.caption {
      totalHeight += ExperimentCardCaptionView.heightWithCaption(caption, inWidth: width)
    }
    return totalHeight
  }

  /// Displays the image in a picture card cell. Called when a cell is about to be displayed.
  func displayImage() {
    guard let pictureNote = pictureNote, let imagePath = pictureNote.imagePath else {
      return
    }

    DispatchQueue.main.async {
      self.pictureView?.image = self.metadataManager?.image(forFullImagePath: imagePath)
    }
  }

  /// Removes the image in a picture card cell. Called when a cell leaves the screen.
  func removeImage() {
    pictureView?.image = nil
  }

  /// Sets the picture note for the cell, along with the style, and whether or not to show the
  /// header or inline timestamp.
  ///
  /// - Parameters:
  ///   - pictureNote: The picture note to display.
  ///   - pictureStyle: The picture style.
  ///   - metadataManager: The metadata manager to fetch the image with.
  ///   - shouldShowHeader: Whether or not to show the header.
  ///   - shouldShowInlineTimestamp: Whether or not to show the inline timestamp.
  ///   - shouldShowCaptionButton: Whether or not to show the caption button.
  func setPictureNote(_ pictureNote: DisplayPictureNote,
                      withPictureStyle pictureStyle: PictureStyle,
                      metadataManager: MetadataManager,
                      showHeader shouldShowHeader: Bool,
                      showInlineTimestamp shouldShowInlineTimestamp: Bool,
                      showCaptionButton shouldShowCaptionButton: Bool,
                      experimentDisplay: ExperimentDisplay = .normal) {
    self.pictureStyle = pictureStyle
    self.pictureNote = pictureNote
    self.metadataManager = metadataManager

    // Update image.
    if pictureView == nil || pictureView!.style != experimentDisplay.trialPictureStyle {
      pictureView?.removeFromSuperview()

      let pictureCardView = PictureCardView(style: pictureStyle)
      cellContentView.addSubview(pictureCardView)
      pictureCardView.clipsToBounds = true
      pictureView = pictureCardView
    }
    pictureView?.experimentDisplay = experimentDisplay
    pictureView?.pictureNote = pictureNote
    pictureView?.showTimestamp = shouldShowInlineTimestamp

    // Header.
    headerView.isHidden = !shouldShowHeader

    // Timestamp.
    headerView.headerTimestampLabel.text = pictureNote.timestamp.string
    headerView.accessibilityLabel = pictureNote.timestamp.string
    headerView.isTimestampRelative = pictureNote.timestamp.isRelative

    // Caption and add caption button.
    if let caption = pictureNote.caption {
      captionView.isHidden = false
      captionView.captionLabel.text = caption
      headerView.showCaptionButton = false
    } else {
      captionView.isHidden = true
      headerView.showCaptionButton = shouldShowCaptionButton
    }

    headerView.showMenuButton = experimentDisplay.showMenuButton

    setNeedsLayout()
  }

  // MARK: - Private

  private func configureView() {
    // Header view.
    cellContentView.addSubview(headerView)
    headerView.timestampButton.addTarget(self,
                                         action: #selector(timestampButtonPressed),
                                         for: .touchUpInside)
    headerView.commentButton.addTarget(self,
                                       action: #selector(commentButtonPressed),
                                       for: .touchUpInside)
    headerView.menuButton.addTarget(self,
                                    action: #selector(menuButtonPressed(sender:)),
                                    for: .touchUpInside)

    // Separator view.
    cellContentView.addSubview(separator)

    // Caption view.
    cellContentView.addSubview(captionView)

    // Accessibility wrapping view, which sits behind all other elements to allow a user to "grab"
    // a cell by tapping anywhere in the empty space of a cell.
    let accessibilityWrappingView = UIView()
    cellContentView.configureAccessibilityWrappingView(
        accessibilityWrappingView,
        withLabel: String.noteContentDescriptionPicture,
        hint: String.doubleTapToViewDetails)

    // Set the order of elements to be the wrapping view first, then the header.
    accessibilityElements = [accessibilityWrappingView, headerView]
  }

  private func addNotificationObservers() {
    // Listen to notifications of newly downloaded assets and sensor data.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(downloadedImages),
                                           name: .driveSyncManagerDownloadedImages,
                                           object: nil)
  }

  // MARK: - User actions

  @objc private func commentButtonPressed() {
    delegate?.experimentCardCellCommentButtonPressed(self)
  }

  @objc private func menuButtonPressed(sender: MenuButton) {
    delegate?.experimentCardCellMenuButtonPressed(self, button: sender)
  }

  @objc private func timestampButtonPressed() {
    delegate?.experimentCardCellTimestampButtonPressed(self)
  }

  // MARK: - Notifications

  @objc private func downloadedImages(notification: Notification) {
    guard let imagePaths =
        notification.userInfo?[DriveSyncUserInfoConstants.downloadedImagePathsKey] as? [String],
        let pictureNoteImagePath = pictureNote?.imagePath,
        imagePaths.contains(pictureNoteImagePath) else {
      return
    }

    displayImage()
  }

}
