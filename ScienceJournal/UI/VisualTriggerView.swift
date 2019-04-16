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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// The view for the sensor card cell that displays visual triggers.
class VisualTriggerView: UIView {

  // MARK: - Properties

  /// The height of the visual trigger view.
  static var height: CGFloat {
    return Metrics.height
  }

  private var indexOfTriggerToDisplay = 0
  private var isShowingTriggerActivatedView = false
  private var sensor: Sensor?
  private var triggerFiredViewWidthConstraint: NSLayoutConstraint?
  private var triggers: [SensorTrigger]?

  // Timers
  private var multipleTriggersTimer: Timer?
  private var triggerFiredTimer: Timer?

  // Views
  private let checkmarkIconImageView = UIImageView(image: UIImage(named: "ic_check"))
  private let snapshotWrapper = UIView()
  private let triggerIconImageView = UIImageView(image: UIImage(named: "ic_trigger"))
  private let titleLabel = UILabel()
  private let triggerCountLabel = UILabel()
  private let triggerFiredView = TriggerFiredView()

  private enum Metrics {
    // View constants
    static let height: CGFloat = 50
    static let imageSize = CGSize(width: 24, height: 24)
    static let innerHorizontalSpacing: CGFloat = 15
    static let outerHorizontalMargin: CGFloat = 20
    static let triggerCountHorizontalOffset: CGFloat = -2

    // Rotation angles
    static let rotationAngleLeft = CGFloat(-Double.pi / 2)
    static let rotationAngleRight = CGFloat(Double.pi / 2)
    static let rotationAngleZero: CGFloat = 0

    // Animation durations
    static let imageViewAlphaAnimationDuration: TimeInterval = 0.2
    static let snapshotFadeAnimationDuration: TimeInterval = 0.3
    static let triggerFiredAnimationDuration: TimeInterval = 0.2
    static let rotationAnimationDuration: TimeInterval = 0.2

    // Timer intervals
    static let multipleTriggersTimerInterval: TimeInterval = 4
    static let triggerFiredTimerInterval: TimeInterval = 1
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  deinit {
    multipleTriggersTimer?.invalidate()
    triggerFiredTimer?.invalidate()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: Metrics.height)
  }

  /// Sets the sensor and triggers for the visual trigger view.
  ///
  /// - Parameters:
  ///   - triggers: The visual triggers.
  ///   - sensor: The sensor the triggers are for.
  func setTriggers(_ triggers: [SensorTrigger], forSensor sensor: Sensor) {
    self.triggers = triggers
    self.sensor = sensor

    indexOfTriggerToDisplay = 0
    updateTitleLabel()

    if triggers.count > 1 {
      triggerCountLabel.text = String(triggers.count)
      multipleTriggersTimer =
          Timer.scheduledTimer(timeInterval: Metrics.multipleTriggersTimerInterval,
                               target: self,
                               selector: #selector(multipleTriggersTimerFired),
                               userInfo: nil,
                               repeats: true)
      // Allows the timer to fire while scroll views are tracking.
      RunLoop.main.add(multipleTriggersTimer!, forMode: .common)
    } else {
      triggerCountLabel.text = nil
      multipleTriggersTimer?.invalidate()
    }
  }

  /// Shows the fired state for the trigger.
  @objc func triggerFired() {
    guard !isShowingTriggerActivatedView else { return }

    triggerFiredTimer?.invalidate()
    triggerFiredTimer =
        Timer.scheduledTimer(timeInterval: Metrics.triggerFiredTimerInterval,
                             target: self,
                             selector: #selector(endDisplayingTriggerActivatedViewTimerFired),
                             userInfo: nil,
                             repeats: false)
    // Allows the timer to fire while scroll views are tracking.
    RunLoop.main.add(triggerFiredTimer!, forMode: .common)

    UIView.animate(withDuration: Metrics.triggerFiredAnimationDuration) {
      self.triggerFiredViewWidthConstraint?.constant = self.bounds.size.width
      self.layoutIfNeeded()
    }
    updateImageViews(forFiredState: true)

    UIAccessibility.post(notification: .announcement, argument: triggerFiredView.titleLabel.text)

    isShowingTriggerActivatedView = true
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = MDCPalette.grey.tint900

    // Image view wrapper.
    let imageViewWrapper = UIView()
    addSubview(imageViewWrapper)
    imageViewWrapper.translatesAutoresizingMaskIntoConstraints = false
    imageViewWrapper.leadingAnchor.constraint(
        equalTo: leadingAnchor, constant: Metrics.outerHorizontalMargin).isActive = true
    imageViewWrapper.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    imageViewWrapper.heightAnchor.constraint(
        equalToConstant: Metrics.imageSize.height).isActive = true
    imageViewWrapper.widthAnchor.constraint(
        equalToConstant: Metrics.imageSize.width).isActive = true

    // Checkmark image view.
    checkmarkIconImageView.alpha = 0
    checkmarkIconImageView.tintColor = .white
    // Starts rotated left, so it can rotate to zero each time it shows.
    checkmarkIconImageView.transform = CGAffineTransform(rotationAngle: Metrics.rotationAngleLeft)
    checkmarkIconImageView.translatesAutoresizingMaskIntoConstraints = false
    imageViewWrapper.addSubview(checkmarkIconImageView)
    checkmarkIconImageView.pinToEdgesOfView(imageViewWrapper)

    // Trigger image view.
    triggerIconImageView.tintColor = .white
    triggerIconImageView.translatesAutoresizingMaskIntoConstraints = false
    imageViewWrapper.addSubview(triggerIconImageView)
    triggerIconImageView.pinToEdgesOfView(imageViewWrapper)

    // Trigger count label.
    triggerCountLabel.font = MDCTypography.captionFont()
    triggerCountLabel.textColor = MDCPalette.grey.tint900
    triggerCountLabel.translatesAutoresizingMaskIntoConstraints = false
    imageViewWrapper.addSubview(triggerCountLabel)
    triggerCountLabel.centerXAnchor.constraint(
        equalTo: imageViewWrapper.centerXAnchor,
        constant: Metrics.triggerCountHorizontalOffset).isActive = true
    triggerCountLabel.centerYAnchor.constraint(
        equalTo: imageViewWrapper.centerYAnchor).isActive = true

    // Title label.
    titleLabel.font = MDCTypography.body2Font()
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    titleLabel.leadingAnchor.constraint(equalTo: imageViewWrapper.trailingAnchor,
                                        constant: Metrics.innerHorizontalSpacing).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                        constant: -Metrics.outerHorizontalMargin).isActive = true
    titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

    // Snapshot wrapper.
    snapshotWrapper.translatesAutoresizingMaskIntoConstraints = false
    addSubview(snapshotWrapper)
    snapshotWrapper.pinToEdgesOfView(self)
    snapshotWrapper.alpha = 0

    // Trigger fired view, width starts at 0.
    triggerFiredView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(triggerFiredView)
    triggerFiredView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    triggerFiredView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    triggerFiredView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    triggerFiredViewWidthConstraint = triggerFiredView.widthAnchor.constraint(equalToConstant: 0)
    triggerFiredViewWidthConstraint?.isActive = true
    triggerFiredView.titleLabel.translatesAutoresizingMaskIntoConstraints = false
    triggerFiredView.titleLabel.leadingAnchor.constraint(
        equalTo: titleLabel.leadingAnchor).isActive = true
    triggerFiredView.titleLabel.trailingAnchor.constraint(
        equalTo: titleLabel.trailingAnchor).isActive = true
    triggerFiredView.titleLabel.centerYAnchor.constraint(
        equalTo: titleLabel.centerYAnchor).isActive = true

    // Bring image view wrapper to the front so it is in front of the trigger fired view.
    bringSubviewToFront(imageViewWrapper)
  }

  private func updateImageViews(forFiredState firedState: Bool) {
    // Rotate the image views and count label.
    if firedState {
      triggerIconImageView.animateRotationTransform(to: Metrics.rotationAngleRight,
                                                    from: Metrics.rotationAngleZero,
                                                    duration: Metrics.rotationAnimationDuration)
      triggerCountLabel.animateRotationTransform(to: Metrics.rotationAngleRight,
                                                 from: Metrics.rotationAngleZero,
                                                 duration: 0.2)
      checkmarkIconImageView.animateRotationTransform(to: Metrics.rotationAngleZero,
                                                      from: Metrics.rotationAngleLeft,
                                                      duration: Metrics.rotationAnimationDuration)
    } else {
      triggerIconImageView.animateRotationTransform(to: Metrics.rotationAngleZero,
                                                    from: Metrics.rotationAngleRight,
                                                    duration: Metrics.rotationAnimationDuration)
      triggerCountLabel.animateRotationTransform(to: Metrics.rotationAngleZero,
                                                 from: Metrics.rotationAngleRight,
                                                 duration: Metrics.rotationAnimationDuration)
      checkmarkIconImageView.animateRotationTransform(to: Metrics.rotationAngleLeft,
                                                      from: Metrics.rotationAngleZero,
                                                      duration: Metrics.rotationAnimationDuration)
    }

    // Set the alphas of the image views.
    UIView.animate(withDuration: Metrics.imageViewAlphaAnimationDuration) {
      self.checkmarkIconImageView.alpha = firedState ? 1 : 0
      self.triggerIconImageView.alpha = firedState ? 0 : 1
      self.triggerCountLabel.alpha = self.triggerIconImageView.alpha
    }
  }

  private func updateTitleLabel() {
    guard let triggers = triggers, triggers.count > 0, let sensor = sensor else {
      titleLabel.text = nil
      return
    }

    titleLabel.text = triggers[indexOfTriggerToDisplay].textDescription(for: sensor)
  }

  // MARK: Timers

  @objc private func multipleTriggersTimerFired() {
    guard let triggers = triggers, triggers.count > 1 else {
      multipleTriggersTimer?.invalidate()
      indexOfTriggerToDisplay = 0
      return
    }

    // Show a snapshot.
    guard let snapshotView = snapshotView(afterScreenUpdates: false) else { return }
    snapshotWrapper.addSubview(snapshotView)
    snapshotWrapper.alpha = 1

    // Update the view
    indexOfTriggerToDisplay += 1
    if indexOfTriggerToDisplay > triggers.endIndex - 1 {
      indexOfTriggerToDisplay = 0
    }

    updateTitleLabel()

    // Fade away the snapshot.
    UIView.animate(withDuration: Metrics.snapshotFadeAnimationDuration,
                   animations: {
      self.snapshotWrapper.alpha = 0
    }) { (_) in
      snapshotView.removeFromSuperview()
    }
  }

  @objc private func endDisplayingTriggerActivatedViewTimerFired() {
    UIView.animate(withDuration: Metrics.triggerFiredAnimationDuration) {
      self.triggerFiredViewWidthConstraint?.constant = 0
      self.layoutIfNeeded()
    }
    updateImageViews(forFiredState: false)
    isShowingTriggerActivatedView = false
  }

}
