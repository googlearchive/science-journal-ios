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

/// A cell displaying the results of a trigger in a trigger note detail view.
class TriggerDetailCell: UICollectionViewCell {

  // MARK: - Properties

  /// The trigger note for this cell.
  var triggerNote: DisplayTriggerNote? {
    didSet {
      triggerStack.removeAllArrangedViews()
      guard let triggerNote = triggerNote else { return }

      let triggerCardView = TriggerCardView(triggerNote: triggerNote,
                                            preferredMaxLayoutWidth: bounds.width)
      triggerCardView.translatesAutoresizingMaskIntoConstraints = false
      triggerStack.addArrangedSubview(triggerCardView)
    }
  }

  private let triggerStack = UIStackView()

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
    triggerNote = nil
  }

  /// Calculates the height required to display this view, given the data provided.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - triggerNote: The snapshot note to measure.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat, triggerNote: DisplayTriggerNote) -> CGFloat {
    return TriggerCardView.heightForTriggerNote(triggerNote,
                                                showingTimestamp: false,
                                                inWidth: width)
  }

  // MARK: - Private

  private func configureView() {
    // The outer, wrapping stack view.
    contentView.addSubview(triggerStack)
    triggerStack.axis = .vertical
    triggerStack.translatesAutoresizingMaskIntoConstraints = false
    triggerStack.layoutMargins = UIEdgeInsets(top: -ExperimentCardView.innerVerticalPadding,
                                              left: -ExperimentCardView.innerHorizontalPadding,
                                              bottom: ExperimentCardView.innerVerticalPadding,
                                              right: ExperimentCardView.innerHorizontalPadding)
    triggerStack.isLayoutMarginsRelativeArrangement = true
    triggerStack.pinToEdgesOfView(contentView)
  }

}
