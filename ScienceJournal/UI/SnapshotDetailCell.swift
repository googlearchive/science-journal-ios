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

/// A cell displaying the results of a sensor snapshot in a snapshot note detail view.
class SnapshotDetailCell: UICollectionViewCell {

  // MARK: - Properties

  /// The snapshot note for this cell.
  var snapshotNote: DisplaySnapshotNote? {
    didSet {
      snapshotsStack.removeAllArrangedViews()
      guard let snapshotNote = snapshotNote else { return }

      // Add snapshot views.
      for snapshot in snapshotNote.snapshots {
        snapshotsStack.addArrangedSubview(SnapshotCardView(snapshot: snapshot,
                                                           preferredMaxLayoutWidth: bounds.width))
      }
    }
  }

  private let snapshotsStack = UIStackView()

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
    snapshotNote = nil
  }

  /// Calculates the height required to display this view, given the data provided in `snapshots`.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - snapshotNote: The snapshot note to measure.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat, snapshotNote: DisplaySnapshotNote) -> CGFloat {
    // Measure the height of the snapshots.
    let totalHeight = snapshotNote.snapshots.reduce(0) { (result, snapshot) in
      result + SnapshotCardView.heightForSnapshot(snapshot, inWidth: width)
    }
    return totalHeight
  }

  // MARK: - Private

  private func configureView() {
    // The outer, wrapping stackView.
    contentView.addSubview(snapshotsStack)
    snapshotsStack.axis = .vertical
    snapshotsStack.translatesAutoresizingMaskIntoConstraints = false
    snapshotsStack.layoutMargins = UIEdgeInsets(top: -ExperimentCardView.innerVerticalPadding,
                                                left: -ExperimentCardView.innerHorizontalPadding,
                                                bottom: ExperimentCardView.innerVerticalPadding,
                                                right: ExperimentCardView.innerHorizontalPadding)
    snapshotsStack.isLayoutMarginsRelativeArrangement = true
    snapshotsStack.pinToEdgesOfView(contentView)
  }

}
