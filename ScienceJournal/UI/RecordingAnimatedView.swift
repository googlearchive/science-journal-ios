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

/// A view containing an animated set of bars to denote a recording in progress, which is used in
/// a TrialCardCell.
class RecordingAnimatedView: UIView {

  // MARK: - Constants

  /// The height of this view.
  static let height: CGFloat = 80.0

  let barMaxHeight: CGFloat = RecordingAnimatedView.height - 20.0
  let barMinHeight: CGFloat = 10.0
  let barSpacing: CGFloat = 6.0
  let barWidth: CGFloat = 6.0
  let numberOfBars = 5

  let barsWrapper = UIView()
  var barViews = [UIView]()

  // MARK: - Public

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: RecordingAnimatedView.height)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    registerForNotifications()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
    registerForNotifications()
  }

  /// Starts the recording animation.
  func startAnimating() {
    // Dispatching to main works around a problem where the animations will not start if they are
    // performed in a collection view batch update.
    DispatchQueue.main.async {
      for bar in self.barViews {
        let randDelay: Double = Double(arc4random_uniform(100)) / 100.0
        UIView.animate(withDuration: 0.4,
                       delay: TimeInterval(randDelay),
                       options: [.autoreverse, .curveEaseInOut, .repeat],
                       animations: {
                         bar.frame = CGRect(x: bar.frame.origin.x,
                                            y: self.barsWrapper.bounds.midY -
                                                (self.barMaxHeight / 2),
                                            width: bar.frame.size.width,
                                            height: self.barMaxHeight)
        })
      }
    }
  }

  // MARK: - Private

  private func configureView() {
    backgroundColor = MDCPalette.grey.tint200

    isAccessibilityElement = true
    accessibilityTraits = .button
    accessibilityLabel = String.throbberContentDescription
    accessibilityHint = String.throbberContentDetails

    addSubview(barsWrapper)
    let totalWidth = (barWidth * CGFloat(numberOfBars)) + (barSpacing * (CGFloat(numberOfBars) - 1))
    barsWrapper.frame = CGRect(x: bounds.midX - (totalWidth / 2),
                           y: bounds.midY - (barMaxHeight / 2),
                           width: totalWidth,
                           height: barMaxHeight).integral

    // Keep bars centered in view.
    barsWrapper.autoresizingMask = [.flexibleTopMargin,
                                    .flexibleRightMargin,
                                    .flexibleBottomMargin,
                                    .flexibleLeftMargin]

    for _ in 0..<numberOfBars {
      let bar = UIView()
      barsWrapper.addSubview(bar)
      bar.isUserInteractionEnabled = false
      bar.backgroundColor = UIColor(red: 0.773, green: 0.404, blue: 0.439, alpha: 1)
      bar.layer.cornerRadius = ceil(barWidth / 2)
      barViews.append(bar)
    }
    setBarFrames()
  }

  private func registerForNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillEnterForeground),
                                           name: UIApplication.willEnterForegroundNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillResignActive),
                                           name: UIApplication.willResignActiveNotification,
                                           object: nil)
  }

  private func setBarFrames() {
    for (i, barView) in barViews.enumerated() {
      barView.frame = CGRect(x: CGFloat(i) * (barWidth + barSpacing),
                             y: barsWrapper.bounds.midY - (barMinHeight / 2),
                             width: barWidth,
                             height: barMinHeight)
    }
  }

  // MARK: - Notifications

  @objc private func applicationWillEnterForeground() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.applicationWillEnterForeground()
      }
      return
    }

    startAnimating()
  }

  @objc private func applicationWillResignActive() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.applicationWillResignActive()
      }
      return
    }

    layer.removeAllAnimations()

    // Reset bars back to their initial frames or the animation will not restart when the
    // application enters the foreground.
    setBarFrames()
  }

}
