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

/// A view displaying data for a recording trial, in a trial cell.
class RecordingTrialCardView: UIView {

  // MARK: - Properties

  /// The height of a recording trial card view.
  static let height: CGFloat = {
    return TrialCardHeaderView.height + RecordingAnimatedView.height
  }()

  private let trialCardHeaderView = TrialCardHeaderView()
  private var recordingAnimatedView: RecordingAnimatedView?

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    trialCardHeaderView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: bounds.width,
                                       height: ceil(TrialCardHeaderView.height))

    recordingAnimatedView?.frame = CGRect(x: 0,
                                          y: trialCardHeaderView.frame.maxY,
                                          width: bounds.width,
                                          height: RecordingAnimatedView.height)
  }

  /// Configures the recording view for the trial.
  ///
  /// - Parameter trial: The trial.
  func configure(withTrial trial: DisplayTrial) {
    // Recording animated view. Reusing this view leads to an issue where the bars don't animate.
    // Instead, create a new one each time a recording trial is configured.
    recordingAnimatedView?.removeFromSuperview()
    let recordingBars = RecordingAnimatedView()
    addSubview(recordingBars)
    recordingBars.startAnimating()
    recordingAnimatedView = recordingBars

    setNeedsLayout()
  }

  // MARK: - Private

  private func configureView() {
    // Trial card header view.
    addSubview(trialCardHeaderView)
    trialCardHeaderView.backgroundColor = .trialHeaderRecordingBackgroundColor
    trialCardHeaderView.titleLabel.text = String.experimentRecordingTitle
    trialCardHeaderView.accessibilityLabel = trialCardHeaderView.titleLabel.text
  }

}
