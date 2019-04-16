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

/// An indeterminate progress bar in the Material style, used as a recording indicator below the
/// drawer.
class RecordingBar: UIView {

  // MARK: - Nested types

  struct AnimationParameters {
    var value: CGFloat
    var keyTime: TimeInterval
    var timingFunctionParameters: [Float]?
  }

  // MARK: - Properties

  private let firstBar = CAShapeLayer()
  private let secondBar = CAShapeLayer()
  private let track = CAShapeLayer()

  private var animating = false
  private var animatingOut = false
  private var animationCycleInProgress = false
  private var animationsAdded = false

  private let strokeWidth: CGFloat = 4.0
  private let defaultWidth: CGFloat = 360
  private let defaultBarWidth: CGFloat = 288

  private let animateInDuration: TimeInterval = 0.5
  private let animateOutDuration: TimeInterval = 0.5
  private let animateTotalDuration: TimeInterval = 2

  private let firstBarInitialScale: CGFloat = 0.08
  private let firstBarInitialTranslate: CGFloat = -522.59998
  private var firstBarScaleKeyframes: [AnimationParameters]?
  private var firstBarTranslateKeyframes: [AnimationParameters]?

  private let secondBarInitialScale: CGFloat = 0.1
  private let secondBarInitialTranslate: CGFloat = -197.600006104
  private var secondBarScaleKeyframes: [AnimationParameters]?
  private var secondBarTranslateKeyframes: [AnimationParameters]?

  private var _animatingForSize: CGSize = .zero
  private var animatingForSize: CGSize {
    set {
      guard !newValue.equalTo(_animatingForSize) else { return }
      _animatingForSize = newValue
      if animationCycleInProgress {
        updateAnimationKeyframes()
      }
    }
    get { return _animatingForSize }
  }

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    configureKeyframes()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
    configureKeyframes()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    animatingForSize = bounds.size

    applyPropertiesWithoutAnimation {
      let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
      [firstBar, secondBar, track].forEach { $0.position = center }
      self.updateStrokePath()
    }
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    // If the recording bar is removed from the window (for instance if a modal occurs in
    // fullscreen, stop animating because otherwise it is using cycles to animate for no reason.
    if newWindow == nil {
      actuallyStopAnimating()
    } else if animating {
      actuallyStartAnimating()
    }
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: strokeWidth)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return CGSize(width: size.width, height: strokeWidth)
  }

  // MARK: - Starting and stopping animation

  /// Start the animation gracefully by animating the bar in.
  func startAnimating() {
    if animatingOut {
      removeAnimations()
    }

    guard !animating else { return }
    animating = true

    if window != nil {
      actuallyStartAnimating()
    }
  }

  /// Stop the animation gracefully by animating the bar out.
  func stopAnimating() {
    guard animating else { return }
    animating = false
    animateOut()
  }

  // MARK: - Private

  private func configureView() {
    track.lineWidth = 0
    track.strokeColor = UIColor(red: 1.0, green: 0.706, blue: 0.757, alpha: 1.0).cgColor
    layer.addSublayer(track)

    [firstBar, secondBar].forEach { (bar) in
      bar.lineWidth = 0
      bar.strokeColor = UIColor(red: 0.855, green: 0.192, blue: 0.176, alpha: 1.0).cgColor
      layer.addSublayer(bar)
    }

    layer.masksToBounds = true
  }

  // Configure the animation parameters for each bar and each type (scale, translate).
  private func configureKeyframes() {
    firstBarScaleKeyframes = [
      AnimationParameters(value: firstBarInitialScale,
                          keyTime: 0,
                          timingFunctionParameters: [0, 0, 1, 1]),
      AnimationParameters(value: 0.08,
                          keyTime: 0.733,
                          timingFunctionParameters: [0.334731432,
                                                     0.124819821,
                                                     0.785843996,
                                                     1]),
      AnimationParameters(value: 0.6614793701,
                          keyTime: 1.383,
                          timingFunctionParameters: [0.06, 0.11, 0.6, 1]),
      AnimationParameters(value: 0.08,
                          keyTime: 2,
                          timingFunctionParameters: nil),
    ]

    firstBarTranslateKeyframes = [
      AnimationParameters(value: firstBarInitialTranslate,
                          keyTime: 0,
                          timingFunctionParameters: [0, 0, 1, 1]),
      AnimationParameters(value: -522.59998,
                          keyTime: 0.4,
                          timingFunctionParameters: [0.5, 0, 0.701732, 0.495818703]),
      AnimationParameters(value: -221.382686832,
                          keyTime: 1.183,
                          timingFunctionParameters: [0.302435,
                                                     0.38135197,
                                                     0.55,
                                                     0.956352125]),
      AnimationParameters(value: 199.600006104,
                          keyTime: 2,
                          timingFunctionParameters: nil),
    ]

    secondBarScaleKeyframes = [
      AnimationParameters(value: secondBarInitialScale,
                          keyTime: 0,
                          timingFunctionParameters: [0.205028172,
                                                     0.057050836,
                                                     0.57660995,
                                                     0.453970841]),
      AnimationParameters(value: 0.571379510698,
                          keyTime: 0.383,
                          timingFunctionParameters: [0.152312994,
                                                     0.196431957,
                                                     0.648373778,
                                                     1.00431535]),
      AnimationParameters(value: 0.909950256348,
                          keyTime: 0.883,
                          timingFunctionParameters: [0.25775882,
                                                     -0.003163357,
                                                     0.211761916,
                                                     1.38178961]),
      AnimationParameters(value: 0.1,
                          keyTime: 2,
                          timingFunctionParameters: nil),
    ]

    secondBarTranslateKeyframes = [
      AnimationParameters(value: secondBarInitialTranslate,
                          keyTime: 0,
                          timingFunctionParameters: [0.15, 0, 0.5150584, 0.409684966]),
      AnimationParameters(value: -62.0531211724,
                          keyTime: 0.5,
                          timingFunctionParameters: [0.3103299,
                                                     0.284057684,
                                                     0.8,
                                                     0.733718979]),
      AnimationParameters(value: 106.190187566,
                          keyTime: 0.967,
                          timingFunctionParameters: [0.4,
                                                     0.627034903,
                                                     0.6,
                                                     0.902025796]),
      AnimationParameters(value: 422.600006104,
                          keyTime: 2,
                          timingFunctionParameters: nil),
    ]
  }

  // Update the stroke path after the bounds change.
  private func updateStrokePath() {
    let width = bounds.size.width

    // The default stoke path is based on a view with a width of `defaultWidth`, so we need to
    // adjust it based on the current width.
    let strokeLayerWidth = defaultBarWidth / defaultWidth * width
    let barPath = UIBezierPath()
    barPath.move(to: CGPoint(x: -strokeLayerWidth / 2, y: 0))
    barPath.addLine(to: CGPoint(x: strokeLayerWidth / 2, y: 0))

    firstBar.path = barPath.cgPath
    secondBar.path = barPath.cgPath

    let trackPath = UIBezierPath()
    trackPath.move(to: CGPoint(x: -width / 2, y: 0))
    trackPath.addLine(to: CGPoint(x: width / 2, y: 0))
    track.path = trackPath.cgPath
  }

  // MARK: - Animation control

  // Animating the showing of the bar.
  private func animateIn() {
    CATransaction.begin()
    CATransaction.setAnimationDuration(animateInDuration)
    [firstBar, secondBar, track].forEach { $0.lineWidth = strokeWidth }
    CATransaction.commit()
  }

  // Start the animation.
  private func actuallyStartAnimating() {
    guard !animationsAdded else { return }
    animationsAdded = true

    applyPropertiesWithoutAnimation {
      let width = bounds.size.width
      let firstBarInitialXTranslation = firstBarInitialTranslate * width / defaultWidth
      let secondBarInitialXTranslation = secondBarInitialTranslate * width / defaultWidth

      firstBar.transform = CATransform3DConcat(
        CATransform3DMakeScale(firstBarInitialScale, 1, 1),
        CATransform3DMakeTranslation(firstBarInitialXTranslation, 0, 0)
      )
      secondBar.transform = CATransform3DConcat(
        CATransform3DMakeScale(secondBarInitialScale, 1, 1),
        CATransform3DMakeTranslation(secondBarInitialXTranslation, 0, 0)
      )
    }

    animateIn()
    addStrokeAnimationCycle()
  }

  // Animate the hiding of the bar, then reset it.
  private func animateOut() {
    animatingOut = true
    CATransaction.begin()
    CATransaction.setCompletionBlock {
      if self.animatingOut { self.removeAnimations() }
      self.strokeAnimationCycleFinished()
    }
    CATransaction.setAnimationDuration(animateOutDuration)
    [firstBar, secondBar, track].forEach { $0.lineWidth = 0 }
    CATransaction.commit()
  }

  // Stop the animation and reset the line widths, but don't hide the bar itself. This is called
  // when the animation needs to stop but will be restarted, such as when the bar goes into the
  // background of a modal.
  private func actuallyStopAnimating() {
    guard animationsAdded else { return }

    removeAnimations()
    applyPropertiesWithoutAnimation {
      firstBar.lineWidth = 0
      secondBar.lineWidth = 0
    }
  }

  // Remove all animations from both layers.
  private func removeAnimations() {
    animationsAdded = false
    animatingOut = false
    animationCycleInProgress = false
    firstBar.removeAllAnimations()
    secondBar.removeAllAnimations()
  }

  // Remove existing animations and complete the cycle.
  private func updateAnimationKeyframes() {
    firstBar.removeAnimation(forKey: "groupAnimation")
    secondBar.removeAnimation(forKey: "groupAnimation")
    strokeAnimationCycleFinished()
  }

  // Mark the animation cycle finished and start another cycle if necessary.
  private func strokeAnimationCycleFinished() {
    animationCycleInProgress = false
    guard animationsAdded else { return }
    addStrokeAnimationCycle()
  }

  // MARK: - Animation creation

  // Generates scale and translate animations for each bar, puts them into an animation group and
  // adds them.
  private func addStrokeAnimationCycle() {
    guard !animationCycleInProgress,
        let firstBarScaleKeyframes = firstBarScaleKeyframes,
        let firstBarTranslateKeyframes = firstBarTranslateKeyframes,
        let secondBarScaleKeyframes = secondBarScaleKeyframes,
        let secondBarTranslateKeyframes = secondBarTranslateKeyframes else { return }

    let firstBarScaleXAnimation = scaleAnimationWithParams(firstBarScaleKeyframes)
    let firstBarTranslateXAnimation = translateAnimationWithParams(firstBarTranslateKeyframes)
    let firstBarAnimations = [firstBarScaleXAnimation, firstBarTranslateXAnimation]

    let firstBarGroup = CAAnimationGroup()
    firstBarGroup.fillMode = .forwards
    firstBarGroup.isRemovedOnCompletion = false
    firstBarGroup.duration = animateTotalDuration
    firstBarGroup.repeatCount = Float.infinity
    firstBarGroup.animations = firstBarAnimations
    firstBar.add(firstBarGroup, forKey: "groupAnimation")

    let secondBarScaleXAnimation = scaleAnimationWithParams(secondBarScaleKeyframes)
    let secondBarTranslateXAnimation = translateAnimationWithParams(secondBarTranslateKeyframes)
    let secondBarAnimations = [secondBarScaleXAnimation, secondBarTranslateXAnimation]

    let secondBarGroup = CAAnimationGroup()
    secondBarGroup.fillMode = .forwards
    secondBarGroup.isRemovedOnCompletion = false
    secondBarGroup.duration = animateTotalDuration
    secondBarGroup.repeatCount = Float.infinity
    secondBarGroup.animations = secondBarAnimations
    secondBar.add(secondBarGroup, forKey: "groupAnimation")

    animationCycleInProgress = true
  }

  // Generates a scale keyframe animation from the given parameters.
  private func scaleAnimationWithParams(_ params: [AnimationParameters]) -> CAKeyframeAnimation {
    let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale.x")
    var values = [NSNumber]()
    var keyTimes = [NSNumber]()
    var timingFunctions = [CAMediaTimingFunction]()
    for (index, param) in params.enumerated() {
      values.append(NSNumber(value: Float(param.value)))
      keyTimes.append(NSNumber(value: param.keyTime / animateTotalDuration))
      if index < params.count - 1, let timingParam = param.timingFunctionParameters {
        let timingFunc = CAMediaTimingFunction(controlPoints: timingParam[0],
                                               timingParam[1],
                                               timingParam[2],
                                               timingParam[3])
        timingFunctions.append(timingFunc)
      }
    }

    scaleAnimation.values = values
    scaleAnimation.keyTimes = keyTimes
    scaleAnimation.timingFunctions = timingFunctions
    return scaleAnimation
  }

  // Generates a translate keyframe animation from the given parameters.
  private func translateAnimationWithParams(_ params: [AnimationParameters])
      -> CAKeyframeAnimation {
    let indicatorWidth = bounds.size.width
    let translateAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    var values = [NSNumber]()
    var keyTimes = [NSNumber]()
    var timingFunctions = [CAMediaTimingFunction]()
    for (index, param) in params.enumerated() {
      // Adjust width since values were initially based on a view with width of `defaultWidth`.
      values.append(NSNumber(value: Float(param.value / defaultWidth * indicatorWidth)))
      keyTimes.append(NSNumber(value: param.keyTime / animateTotalDuration))
      if index < params.count - 1, let timingParam = param.timingFunctionParameters {
        let timingFunc = CAMediaTimingFunction(controlPoints: timingParam[0],
                                               timingParam[1],
                                               timingParam[2],
                                               timingParam[3])
        timingFunctions.append(timingFunc)
      }
    }

    translateAnimation.values = values
    translateAnimation.keyTimes = keyTimes
    translateAnimation.timingFunctions = timingFunctions
    return translateAnimation
  }

  // Applies properties to layers without animating the changes.
  private func applyPropertiesWithoutAnimation(properties: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    properties()
    CATransaction.commit()
  }

}
