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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// The base class for cells shown in experiments list, either an experiment that needs to be
/// claimed, or an experiment that is being synced. It displays the experiment's photo and title.
/// Tapping this cell will load the experiment detail view.
class ExperimentsListCellBase: AutoLayoutMaterialCardCell {

  // MARK: - Properties

  /// The cell's activity spinner.
  let spinner = MaterialFloatingSpinner()

  /// The stack view for the title, plus anything that needs to be displayed next to the title.
  let titleStack = UIStackView()

  // Outer stack to wrap the image, titleStack, and anything else needed vertically.
  let outerStack = UIStackView()

  /// The height of everything in the view below the image. Used to determine the height of the
  /// image view. The base implementation returns the height of the title plus padding needed.
  var titleAndButtonsHeight: CGFloat {
    // Measure the height of two lines of text so we know how big to make the label area.
    let textHeight =
        String.actionOk.labelHeight(withConstrainedWidth: 0, font: Metrics.titleFont) * 2
    return ceil(textHeight) + Metrics.titlePadding * 2
  }

  private let accessibilityWrapper = UIView()
  private let archivedFlag = ArchivedFlagView()
  private let imageView = UIImageView()
  private var imageViewConstraints = [NSLayoutConstraint]()
  private let imageWrapper = UIView()
  private let titleLabel = UILabel()

  private enum Metrics {
    static let archivedAlpha: CGFloat = 0.3
    static let unarchivedAlpha: CGFloat = 1

    static let titleFontSize: CGFloat = 16
    static let titlePadding: CGFloat = 8
    static let titleSpacing: CGFloat = 6

    static let titleFont = MDCTypography.fontLoader().boldFont?(ofSize: Metrics.titleFontSize) ??
        UIFont.boldSystemFont(ofSize: Metrics.titleFontSize)
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NSLayoutConstraint.deactivate(imageViewConstraints)
    imageViewConstraints.removeAll()
    spinner.stopAnimating()
  }

  /// Configures a cell for a given experiment overview and background color.
  ///
  /// - Parameters:
  ///   - experimentOverview: The experiment overview to use for configuring the title.
  ///   - image: The image for this experiment or nil.
  func configureForExperimentOverview(_ experimentOverview: ExperimentOverview, image: UIImage?) {
    let title = experimentOverview.title ?? String.localizedUntitledExperiment
    titleLabel.text = title
    imageWrapper.backgroundColor = experimentOverview.colorPalette.tint500
    accessibilityWrapper.accessibilityLabel = title
    accessibilityWrapper.accessibilityHint = String.doubleTapToOpen

    // Configure for archived state.
    archivedFlag.isHidden = !experimentOverview.isArchived
    titleLabel.alpha =
      experimentOverview.isArchived ? Metrics.archivedAlpha : Metrics.unarchivedAlpha
    imageView.alpha =
      experimentOverview.isArchived ? Metrics.archivedAlpha : Metrics.unarchivedAlpha

    // Set up base constraints for imageView.
    imageViewConstraints += [
      imageView.centerXAnchor.constraint(equalTo: imageWrapper.centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: imageWrapper.centerYAnchor)
    ]

    if let image = image {
      imageView.image = image
      imageWrapper.backgroundColor = .white

      // Photos need width and height constraints so they draw in the scaled space correctly.
      imageViewConstraints += [
        imageView.widthAnchor.constraint(equalTo: imageWrapper.widthAnchor),
        imageView.heightAnchor.constraint(equalTo: imageWrapper.heightAnchor)
      ]
    } else {
      // Set the placeholder image.
      imageView.image = UIImage(named: "experiment_placeholder_book")
    }

    NSLayoutConstraint.activate(imageViewConstraints)
  }

  // MARK: - Private

  private func configureView() {
    shouldGroupAccessibilityChildren = false
    addSubview(accessibilityWrapper)
    accessibilityWrapper.translatesAutoresizingMaskIntoConstraints = false
    accessibilityWrapper.pinToEdgesOfView(self)
    accessibilityWrapper.isAccessibilityElement = true
    accessibilityWrapper.accessibilityTraits = .button

    // The experiment image wrapper, which clips the image and sets a background color.
    imageWrapper.addSubview(imageView)
    imageWrapper.clipsToBounds = true
    imageWrapper.translatesAutoresizingMaskIntoConstraints = false
    imageWrapper.isAccessibilityElement = false

    // The experiment image.
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.isAccessibilityElement = false
    if #available(iOS 11.0, *) {
      imageView.accessibilityIgnoresInvertColors = true
    }

    // The experiment title.
    titleLabel.font = Metrics.titleFont
    titleLabel.numberOfLines = 2
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.lineBreakMode = .byTruncatingMiddle
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    titleLabel.isAccessibilityElement = false

    // The title stack, horizontal.
    titleStack.addArrangedSubview(titleLabel)
    titleStack.alignment = .center
    titleStack.spacing = Metrics.titleSpacing
    titleStack.translatesAutoresizingMaskIntoConstraints = false
    titleStack.layoutMargins = UIEdgeInsets(top: Metrics.titlePadding,
                                            left: Metrics.titlePadding,
                                            bottom: Metrics.titlePadding,
                                            right: Metrics.titlePadding)
    titleStack.isLayoutMarginsRelativeArrangement = true

    // Outer stack.
    outerStack.addArrangedSubview(imageWrapper)
    outerStack.addArrangedSubview(titleStack)
    cellContentView.addSubview(outerStack)
    outerStack.axis = .vertical
    outerStack.translatesAutoresizingMaskIntoConstraints = false
    outerStack.pinToEdgesOfView(cellContentView)

    // Set the imageView height, now that it's in the hierarchy, to the height of the cell minus
    // the necessary text area with padding.
    imageWrapper.heightAnchor.constraint(equalTo: heightAnchor,
                                         constant: -titleAndButtonsHeight).isActive = true

    // Spinner
    cellContentView.addSubview(spinner)
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.centerXAnchor.constraint(equalTo: imageWrapper.centerXAnchor).isActive = true
    spinner.centerYAnchor.constraint(equalTo: imageWrapper.centerYAnchor).isActive = true
    spinner.isAccessibilityElement = false

    // Archived flag, hidden by default.
    cellContentView.addSubview(archivedFlag)
    archivedFlag.isHidden = true
    archivedFlag.translatesAutoresizingMaskIntoConstraints = false
    archivedFlag.topAnchor.constraint(equalTo: cellContentView.topAnchor,
                                      constant: 8.0).isActive = true
    archivedFlag.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor,
                                           constant: -8.0).isActive = true

    // Send the a11y wrapper to the back to allow for menu and archived taps.
    sendSubviewToBack(accessibilityWrapper)
  }

}
