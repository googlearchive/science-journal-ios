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

/// A button subclass for the record button to change accessibility labels when selected or not.
class RecordButton: MDCFlatButton {

  override var isSelected: Bool {
    didSet {
      accessibilityLabel = isSelected ? String.btnStopDescription : String.btnRecordDescription
    }
  }

}

/// The record button view is a bar containing a record button. It has a snapshot button on the left
/// and has a timer label on the right.
class RecordButtonView: UIView {

  // MARK: - Properties

  /// The record button.
  let recordButton = RecordButton(type: .custom)

  /// The snapshot button.
  let snapshotButton = MDCFlatButton(type: .custom)

  /// The timer label.
  let timerLabel = UILabel()

  /// The elapsed time formatter.
  let timeFormatter = ElapsedTimeFormatter()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: ViewConstants.toolbarHeight)
  }

  /// Updates `timerLabel.text` with a formatted version of `duration`.
  ///
  /// - Parameter duration: The duration to format and display.
  func updateTimerLabel(with duration: Int64) {
    let oneHour: Int64 = 1000 * 60 * 60
    timeFormatter.shouldDisplayTenths = duration < oneHour
    timerLabel.text = timeFormatter.string(fromTimestamp: duration)
  }

  // MARK: - Private

  private func configureView() {
    // The snapshot button.
    let snapshotWrapper = UIView()
    snapshotWrapper.translatesAutoresizingMaskIntoConstraints = false
    snapshotWrapper.addSubview(snapshotButton)
    snapshotButton.setImage(UIImage(named: "ic_snapshot_action"), for: .normal)
    snapshotButton.tintColor = .white
    snapshotButton.translatesAutoresizingMaskIntoConstraints = false
    snapshotButton.inkStyle = .unbounded
    snapshotButton.inkMaxRippleRadius = 40.0
    snapshotButton.hitAreaInsets = UIEdgeInsets(top: -10, left: -20, bottom: -10, right: -20)
    snapshotButton.pinToEdgesOfView(snapshotWrapper,
                                    withInsets: UIEdgeInsets(top: 0,
                                                             left: 20,
                                                             bottom: 0,
                                                             right: -20))
    snapshotButton.accessibilityLabel = String.snapshotButtonText
    snapshotButton.accessibilityHint = String.snapshotButtonContentDetails

    // The record button.
    recordButton.setImage(UIImage(named: "record_button"), for: .normal)
    recordButton.setImage(UIImage(named: "stop_button"), for: .selected)
    recordButton.inkColor = .clear
    recordButton.autoresizesSubviews = false
    recordButton.contentEdgeInsets = .zero
    recordButton.imageEdgeInsets = .zero
    recordButton.translatesAutoresizingMaskIntoConstraints = false
    recordButton.hitAreaInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    recordButton.setContentHuggingPriority(.required, for: .horizontal)
    recordButton.setContentHuggingPriority(.required, for: .vertical)
    recordButton.isSelected = false  // Calls the didSet on isSelected to update a11y label.

    // The timer label.
    let timerWrapper = UIView()
    timerWrapper.translatesAutoresizingMaskIntoConstraints = false
    timerWrapper.addSubview(timerLabel)
    timerLabel.font = MDCTypography.headlineFont()
    timerLabel.textAlignment = .left
    timerLabel.textColor = .white
    timerLabel.translatesAutoresizingMaskIntoConstraints = false
    timerLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    timerLabel.leadingAnchor.constraint(equalTo: timerWrapper.leadingAnchor,
                                        constant: 16.0).isActive = true
    timerLabel.centerYAnchor.constraint(equalTo: timerWrapper.centerYAnchor).isActive = true
    timerLabel.isAccessibilityElement = true
    timerLabel.accessibilityTraits = .updatesFrequently

    let stackView = UIStackView(arrangedSubviews: [snapshotWrapper, recordButton, timerWrapper])
    addSubview(stackView)
    stackView.distribution = .fillEqually
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.pinToEdgesOfView(self)
  }

}
