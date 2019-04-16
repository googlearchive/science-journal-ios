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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_ProgressView_ProgressView
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view controller for managing trial share settings.
class TrialShareSettingsViewController: ScienceJournalViewController {

  /// The mode in which to export.
  ///
  /// - share: Share to any available app or service.
  /// - saveToFiles: Save to Files only.
  enum Mode {
    case share
    case saveToFiles
  }

  private enum Metrics {
    static let maxWidth: CGFloat = 414
    static let stackSpacing: CGFloat = 14
    static let viewInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    static let progressViewHeight: CGFloat = 10
  }

  /// The state of the share settings view.
  ///
  /// - options: Shows the switch for toggling relative time.
  /// - progress: Shows a progress view for the export.
  private enum State {
    case options
    case progress
  }

  private let titleLabel = UILabel()
  private let relativeLabel = UILabel()
  private let progressView = MDCProgressView()
  private let verticalStack = UIStackView()
  private let switchStack = UIStackView()
  private let mode: Mode

  /// The relative time switch.
  let relativeSwitch = UISwitch()

  /// The cancel button.
  let cancelButton = MDCFlatButton()

  /// The share button.
  let shareButton = MDCFlatButton()

  private var state: State = .options {
    didSet {
      guard state != oldValue else { return }

      switch state {
      case .options:
        verticalStack.removeArrangedSubview(progressView)
        progressView.removeFromSuperview()
        verticalStack.insertArrangedSubview(switchStack, at: 1)
        shareButton.isEnabled = true
      case .progress:
        verticalStack.removeArrangedSubview(switchStack)
        switchStack.removeFromSuperview()
        verticalStack.insertArrangedSubview(progressView, at: 1)
        shareButton.isEnabled = false
      }
    }
  }

  /// The height required to display the view's content.
  private var contentHeight: CGFloat {
    let titleHeight =
        titleLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let shareButtonHeight =
        shareButton.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let switchHeight =
        relativeSwitch.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

    return Metrics.viewInsets.top + Metrics.viewInsets.bottom + titleHeight + shareButtonHeight +
        switchHeight + Metrics.stackSpacing * 2
  }

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: The analytics reporter.
  ///   - mode: The mode in which to export.
  init(analyticsReporter: AnalyticsReporter, mode: Mode) {
    self.mode = mode
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    // Progress view.
    progressView.translatesAutoresizingMaskIntoConstraints = false
    // MDCProgressView has no intrinsic content size.
    progressView.heightAnchor.constraint(equalToConstant:
        Metrics.progressViewHeight).isActive = true

    titleLabel.text = String.exportOptionsTitle
    titleLabel.font = MDCTypography.titleFont()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    relativeSwitch.translatesAutoresizingMaskIntoConstraints = false
    relativeLabel.translatesAutoresizingMaskIntoConstraints = false
    relativeLabel.text = String.exportOptionsRelativeTime
    relativeLabel.font = MDCTypography.body1Font()
    switchStack.addArrangedSubview(relativeSwitch)
    switchStack.addArrangedSubview(relativeLabel)
    switchStack.spacing = Metrics.stackSpacing
    switchStack.translatesAutoresizingMaskIntoConstraints = false

    let buttonWrapper = UIView()
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false
    buttonWrapper.addSubview(cancelButton)
    buttonWrapper.addSubview(shareButton)

    cancelButton.setTitle(String.actionCancel, for: .normal)
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    let shareButtonTitle: String
    switch mode {
    case .share: shareButtonTitle = String.exportAction
    case .saveToFiles: shareButtonTitle = String.saveToFilesTitle
    }
    shareButton.setTitle(shareButtonTitle, for: .normal)
    shareButton.translatesAutoresizingMaskIntoConstraints = false
    shareButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor).isActive = true
    shareButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor).isActive = true
    shareButton.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor).isActive = true
    cancelButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor).isActive = true
    cancelButton.centerYAnchor.constraint(equalTo: shareButton.centerYAnchor).isActive = true

    cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)

    verticalStack.addArrangedSubview(titleLabel)
    verticalStack.addArrangedSubview(switchStack)
    verticalStack.addArrangedSubview(buttonWrapper)
    verticalStack.translatesAutoresizingMaskIntoConstraints = false
    verticalStack.distribution = .equalSpacing
    verticalStack.spacing = Metrics.stackSpacing
    verticalStack.axis = .vertical
    view.addSubview(verticalStack)
    verticalStack.pinToEdgesOfView(view, withInsets: Metrics.viewInsets)

    preferredContentSize = CGSize(width: min(Metrics.maxWidth, view.frame.size.width),
                                  height: contentHeight)
  }

  /// Sets the share settings view to show a progress bar with the given progress.
  ///
  /// - Parameter progress: The progress value to display.
  func setProgress(_ progress: Double) {
    state = .progress
    progressView.progress = Float(progress)
  }

  @objc private func cancelButtonPressed() {
    analyticsReporter.track(.trialExportCancelled)
    dismiss(animated: true)
  }

}
