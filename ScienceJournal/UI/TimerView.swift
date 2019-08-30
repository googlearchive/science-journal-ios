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
import third_party_objective_c_material_components_ios_components_Typography_Typography
import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// The timer view is a capsule containing the current recording timer.
/// It is meant to be used in a bar button item.
final class TimerView: UIView {

  enum Metrics {
    static let padding: CGFloat = 5
    static let spacing: CGFloat = 8
    static let backgroundCornerRadius: CGFloat = 14
    static let overallLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    static let contentEdgeInsets = UIEdgeInsets(top: padding,
                                                left: padding,
                                                bottom: padding,
                                                right: backgroundCornerRadius)
    static let contentBackgroundColor: UIColor = .white
    static let dotDimension: CGFloat = 14
    static let dotCornerRadius: CGFloat = dotDimension / 2
    static let dotColor: UIColor = .trialHeaderRecordingBackgroundColor
    static let labelFont: UIFont = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    static let labelTextColor: UIColor = MDCPalette.grey.tint900
  }

  /// The timer label.
  private let timerLabel: UILabel = {
    let timerLabel = UILabel()
    timerLabel.font = Metrics.labelFont
    timerLabel.textColor = Metrics.labelTextColor
    timerLabel.isAccessibilityElement = true
    timerLabel.accessibilityTraits = .updatesFrequently
    return timerLabel
  }()

  /// The elapsed time formatter.
  private let timeFormatter : ElapsedTimeFormatter = {
    let timeFormatter = ElapsedTimeFormatter()
    timeFormatter.alwaysDisplayHours = true
    timeFormatter.shouldDisplayTenths = false
    return timeFormatter
  }()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return systemLayoutSizeFitting(size)
  }

  /// Updates `timerLabel.text` with a formatted version of `duration`.
  ///
  /// - Parameter duration: The duration to format and display.
  func updateTimerLabel(with duration: Int64) {
    timerLabel.text = timeFormatter.string(fromTimestamp: duration)
  }

  // MARK: - Private

  private func configureView() {
    snp.setLabel("TimerView")
    layoutMargins = Metrics.overallLayoutMargins

    let contentView : UIView = {
      let contentView = UIView()
      contentView.layer.cornerRadius = Metrics.backgroundCornerRadius
      contentView.backgroundColor = Metrics.contentBackgroundColor
      contentView.layoutMargins = Metrics.contentEdgeInsets
      return contentView
    }()

    let dotView : UIView = {
      let dotView = UIView()
      dotView.backgroundColor = Metrics.dotColor
      dotView.layer.cornerRadius = Metrics.dotCornerRadius
      return dotView
    }()

    addSubview(contentView)
    contentView.snp.setLabel("wrapperView")
    contentView.snp.makeConstraints { (make) in
      make.leading.equalTo(snp.leadingMargin)
      make.trailing.equalTo(snp.trailingMargin)
      make.centerY.equalToSuperview()
    }

    contentView.addSubview(dotView)
    dotView.snp.setLabel("dotView")
    dotView.snp.makeConstraints { (make) in
      make.leading.equalTo(contentView.snp.leadingMargin)
      make.centerY.equalToSuperview()
      make.size.equalTo(Metrics.dotDimension)
    }

    contentView.addSubview(timerLabel)
    timerLabel.snp.setLabel("timerLabel")
    timerLabel.snp.makeConstraints { (make) in
      make.top.equalTo(contentView.snp.topMargin)
      make.trailing.equalTo(contentView.snp.trailingMargin)
      make.bottom.equalTo(contentView.snp.bottomMargin)
      make.leading.equalTo(dotView.snp.trailing).offset(Metrics.spacing)
    }
    timerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    timerLabel.setContentHuggingPriority(.required, for: .horizontal)
    timerLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    timerLabel.setContentHuggingPriority(.required, for: .vertical)

    updateTimerLabel(with: 0)
  }

}
