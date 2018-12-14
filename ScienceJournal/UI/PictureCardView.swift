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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// PictureCardView supports two different heights, depending on usage. In a Trial card, as a Trial
/// Note, it uses `.small`. In a standalone picture cell, it uses `.large`.
enum PictureStyle {
  case small
  case large

  var height: CGFloat {
    switch self {
    case .small: return 100.0
    case .large: return 300.0
    }
  }
}

/// A view composed of a picture. This view can be used inside a trial card or inside a snapshot
/// card, both in Experiment detail views. Timestamp can be shown by setting `showRelativeTimestamp`
/// to true.
class PictureCardView: ExperimentCardView {

  // MARK: - Properties

  /// The image view.
  let imageView = UIImageView()

  /// The optional image path for the picture note's image.
  private(set) var pictureNoteImagePath: String?

  /// The picture note to display.
  var pictureNote: DisplayPictureNote? {
    didSet {
      updateForPictureNote()
    }
  }

  /// Whether or not to show the timestamp.
  var showTimestamp: Bool {
    didSet {
      updateTimestampHidden()
    }
  }

  /// The picture style.
  let style: PictureStyle

  // MARK: - Public

  init(pictureNote: DisplayPictureNote? = nil, style: PictureStyle, showTimestamp: Bool = false) {
    self.pictureNote = pictureNote
    self.style = style
    self.showTimestamp = showTimestamp
    super.init(frame: .zero)
    updateForPictureNote()
    configureView()
  }

  override required init(frame: CGRect) {
    fatalError("init(frame:) is not supported")
  }

  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return CGSize(width: size.width, height: style.height)
  }

  override func reset() {
    pictureNote = nil
    pictureNoteImagePath = nil
    timestampLabel.text = nil
  }

  // MARK: - Private

  private func configureView() {
    // Image view, which fills the full width and height of this view, and clips to bounds.
    addSubview(imageView)
    imageView.backgroundColor = MDCPalette.grey.tint200
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill
    imageView.translatesAutoresizingMaskIntoConstraints = false
    if #available(iOS 11.0, *) {
      imageView.accessibilityIgnoresInvertColors = true
    }
    imageView.pinToEdgesOfView(self)

    // Timestamp label. Make it white with a shadow since it's above visual content in this case.
    timestampLabel.textColor = .white
    timestampLabel.isShadowEnabled = true
    addSubview(timestampLabel)
    timestampLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    timestampLabel.topAnchor.constraint(
        equalTo: topAnchor,
        constant: ExperimentCardView.innerVerticalPadding).isActive = true
    timestampLabel.trailingAnchor.constraint(
        equalTo: trailingAnchor,
        constant: -ExperimentCardView.innerHorizontalPadding).isActive = true
    updateTimestampHidden()
  }

  private func updateForPictureNote() {
    pictureNoteImagePath = pictureNote?.imagePath
    timestampLabel.text = pictureNote?.timestamp.string
  }

  private func updateTimestampHidden() {
    timestampLabel.isHidden = !showTimestamp
  }

}
