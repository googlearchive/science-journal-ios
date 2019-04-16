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

import third_party_objective_c_material_components_ios_components_ShadowLayer_ShadowLayer
import third_party_objective_c_material_components_ios_components_Tabs_Tabs

/// A protocol for the drawer view to update its delegate about selected items.
public protocol DrawerViewDelegate: class {

  /// Called when an item was selected.
  ///
  /// - Parameters:
  ///   - drawerView: The drawer view.
  ///   - index: The index of the item selected.
  func drawerView(_ drawerView: DrawerView, didSelectItemAtIndex index: Int)

  /// Called when the drawer is about to change its position.
  ///
  /// - Parameters:
  ///   - drawerView: The drawer view.
  ///   - position: The drawer position.
  func drawerView(_ drawerView: DrawerView, willChangePosition position: DrawerPosition)

  /// Called when the drawer changed its position.
  ///
  /// - Parameters:
  ///   - drawerView: The drawer view.
  ///   - position: The drawer position.
  func drawerView(_ drawerView: DrawerView, didChangePosition position: DrawerPosition)

  /// Called when the drawer is panning.
  ///
  /// - Parameters:
  ///   - drawerView: The drawer view.
  func drawerViewIsPanning(_ drawerView: DrawerView)

  /// Called when the drawer view was panned upward beyond its bounds.
  ///
  /// - Parameters:
  ///   - drawerView: The drawer view.
  ///   - panDistance: The distance of the pan upward beyond the drawer's bounds.
  func drawerView(_ drawerView: DrawerView, didPanBeyondBounds panDistance: CGFloat)

}

/// A UIView subclass to wrap the drawer's grabber in an accessibility view with a custom activation
/// action.
class GrabberWrapperView: UIView {

  var activationEvent: (() -> Void)?

  override func accessibilityActivate() -> Bool {
    activationEvent?()
    return true
  }

}

/// A container view with a tab bar that slides up from the bottom over a parent view. Can be
/// minimized (only shows the tab bar), cover the bottom half of the view or display fullscreen
/// (parent view is hidden).
open class DrawerView: UIView, MDCTabBarDelegate {

  // MARK: - Constants

  /// The background color of the drawer's main bar, which contains tabs.
  static let barBackgroundColor = UIColor(red: 0.196, green: 0.196, blue: 0.196, alpha: 1)
  /// The background color of the drawer's action bar.
  static let actionBarBackgroundColor = UIColor(red: 0.196, green: 0.196, blue: 0.196, alpha: 0.95)
  /// The background color to be used to darken the statusBar frame when the drawer is open to full.
  static let statusBarBackgroundColor = UIColor(red: 0.176, green: 0.176, blue: 0.176, alpha: 1)

  private enum Metrics {
    static let tabBarGrabberOriginY: CGFloat = 6
    static let tabBarGrabberWrapperSize = CGSize(width: 30, height: 30)
  }

  // MARK: - Properties

  /// The panning view.
  let panningView = UIView()

  /// The tab bar.
  let tabBar = MDCTabBar()

  /// The recording indicator bar.
  let recordingBar = RecordingBar()

  /// Whether or not the drawer can be open half. This should be set to false when the device is in
  /// landscape.
  var canOpenHalf = true

  /// Whether or not the drawer can be open to a custom position. This should be set to false when
  /// the device is in landscape.
  var canOpenToCustomPosition = true

  /// Position of the drawer when it is fully open.
  let openFullPosition = DrawerPosition(canShowKeyboard: true)

  /// Position of the drawer when it is halfway open.
  let openHalfPosition = DrawerPosition(canShowKeyboard: false)

  /// Position of the drawer when it is when only the tab bar is showing.
  let peekingPosition = DrawerPosition(canShowKeyboard: false) { 0 }

  /// Whether or not the drawer is in sidebar mode. While it is, panning is not supported.
  var isDisplayedAsSidebar = false {
    didSet {
      grabber.isHidden = isDisplayedAsSidebar
      grabberWrapper.accessibilityElementsHidden = isDisplayedAsSidebar
    }
  }

  /// A custom drawer position for the drawer. Valid only if its pan distance falls between peeking
  /// and open full.
  fileprivate(set) var customPosition: DrawerPosition?

  /// The current drawer position.
  var currentPosition: DrawerPosition

  private weak var delegate: DrawerViewDelegate?

  // The content view for a view controller's view to be displayed.
  private let contentView = UIView()

  private let drawerItems: [DrawerItem]

  // The total available height the drawer view can fill, set externally in
  // `updateContentViewHeight()`. Used to determine the full height drawer position, as well as
  // content view height.
  private var availableHeight: CGFloat?

  // All drawer positions.
  private var drawerPositions: [DrawerPosition] {
    var positions = [peekingPosition, openFullPosition]
    if canOpenHalf {
      positions.append(openHalfPosition)
    }
    if canOpenToCustomPosition, let customPosition = customPosition {
      positions.append(customPosition)
    }
    positions.sort { $0.panDistance > $1.panDistance }
    return positions
  }

  // The distance between peeking and open full positions.
  private var maximumPanDistance: CGFloat {
    return peekingPosition.panDistance - openFullPosition.panDistance
  }

  // The percentage of the distance between pan positions that must be traveled to move to the next
  // pan position.
  private let panPercentage: CGFloat = 0.15

  // The duration for the animation if the pan is from full to peeking.
  private let fullToPeekingAnimationDuration = 0.5

  private let minimumAnimationDuration = 0.1

  private let grabber = UIImageView(image: UIImage(named: "grabber"))
  private let grabberWrapper = GrabberWrapperView()
  private let tabBarShadowMetrics = MDCShadowMetrics(elevation: ShadowElevation.appBar.rawValue)
  private let tabBarWrapper = UIView()

  private var panningViewOriginY: CGFloat {
    return bounds.maxY - ViewConstants.toolbarHeight - safeAreaInsetsOrZero.bottom +
        currentPanDistance
  }

  private var currentPanDistance: CGFloat = 0 {
    didSet {
      // Update the panning view's y origin for the pan distance.
      panningView.frame.origin.y = panningViewOriginY

      // Pan distance is how far the panning view has moved up the screen (negative view coordinate
      // direction). The visible height of the content view is the same amount (but non-negative).
      contentView.frame.size.height = safeAreaInsetsOrZero.bottom +
          max(openHalfPosition.contentHeight, -currentPanDistance)
      updateDisplayedViewFrame()
    }
  }

  private var displayedView: UIView?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - items: The drawer items.
  ///   - delegate: The delegate.
  public init(items: [DrawerItem], delegate: DrawerViewDelegate) {
    drawerItems = items
    self.delegate = delegate

    currentPosition = peekingPosition

    super.init(frame: .zero)

    // Set drawer position content height closures.
    openFullPosition.contentHeightClosure = { [unowned self] in
      var height: CGFloat {
        // The view height is adequate when `availableHeight` has not been set. However,
        // `availableHeight` should be used when set, because the view height sometimes includes the
        // status bar.
        guard let availableHeight = self.availableHeight else { return self.bounds.size.height }
        return availableHeight
      }
      return height - ViewConstants.toolbarHeight - self.safeAreaInsetsOrZero.top -
          self.safeAreaInsetsOrZero.bottom
    }
    openHalfPosition.contentHeightClosure = { [unowned self] in
      self.openFullPosition.contentHeight / 2
    }

    let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                      action: #selector(handlePanGesture(_:)))
    addGestureRecognizer(panGestureRecognizer)

    configureView()
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    // Only count the panning view as part of the drawer view.
    return panningView.point(inside: convert(point, to: panningView), with: event)
  }

  override open func safeAreaInsetsDidChange() {
    setNeedsLayout()
    updateTabBarWrapperHeightForCurrentPosition()
    updateContentViewHeight()

    // If the safe area insets change, the drawer positions change. Pan to the correct distance for
    // the current drawer position.
    panToCurrentPosition(animated: false)
  }

  /// Adds a view as a subview of `contentView` and sets it to be full size.
  ///
  /// - Parameter view: The view to display.
  func displayViewInContentView(_ view: UIView) {
    contentView.addSubview(view)
    displayedView = view
    updateDisplayedViewFrame()
  }

  /// Pans the distance associated with the current position. Needed because the pan distance
  /// changes per position when the size of the view changes.
  ///
  /// - Parameter animated: Whether or not to animate.
  func panToCurrentPosition(animated: Bool) {
    panToPosition(currentPosition, animated: animated)
  }

  /// Pans to `position`, and captures the new position into `currentPosition`.
  ///
  /// - Parameters:
  ///   - position: The position to animate to.
  ///   - animated: Whether or not to animate.
  ///   - completion: Called when the pan completes.
  func panToPosition(_ position: DrawerPosition,
                     animated: Bool = true,
                     completion: (() -> ())? = nil) {
    // Calculate animation duration based on the remaining distance.
    let distanceRemaining = position.panDistance - currentPanDistance
    let remainingRatio = abs(distanceRemaining / maximumPanDistance)
    let duration = animated ?
        max(fullToPeekingAnimationDuration * Double(remainingRatio), minimumAnimationDuration) : 0
    delegate?.drawerView(self, willChangePosition: position)
    let previousPosition = currentPosition
    currentPosition = position
    self.updateGrabberAccessibilityLabel()

    func animatePan(completion panCompletion: (() ->())? = nil) {
      UIView.animate(withDuration: duration,
                     delay: 0,
                     options: [.curveEaseOut],
                     animations: {
        self.currentPanDistance = position.panDistance
      },
                     completion: { (_) in
        self.delegate?.drawerView(self, didChangePosition: self.currentPosition)
        self.accessibilityViewIsModal = (self.currentPosition == self.openFullPosition) &&
          UIDevice.current.userInterfaceIdiom != .pad
        panCompletion?()
        completion?()
      })
    }

    if previousPosition == peekingPosition {
      updateTabBarWrapperHeight(expanded: position == peekingPosition, animated: true)
      animatePan()
    } else {
      animatePan(completion: {
        self.updateTabBarWrapperHeight(expanded: position == self.peekingPosition, animated: true)
      })
    }

  }

  // Updates the accessibility label of the grabber wrapper based on the drawer's current position.
  private func updateGrabberAccessibilityLabel() {
    var label = "\(String.drawerGrabberContentDescription), "
    switch currentPosition {
    case openFullPosition: label += String.drawerGrabberPositionFullContentDescription
    case openHalfPosition: label += String.drawerGrabberPositionHalfContentDescription
    case peekingPosition: label += String.drawerGrabberPositionClosedContentDescription
    default: label += String.drawerGrabberPositionCustomContentDescription
    }
    grabberWrapper.accessibilityLabel = label
  }

  /// Completes the pan by snapping to the proper drawer position.
  ///
  /// - Parameter velocity: The ending velocity of the pan.
  func completePan(withVelocity velocity: CGFloat) {
    let isVelocityHigh = abs(velocity) > 500

    // Is the drawer's pan distance below the pan distance of the previous position? If not, it is
    // above or at the same position.
    let isDrawerBelowPreviousPosition = currentPanDistance > currentPosition.panDistance

    // Was the ending velocity in the opposite direction than the current pan distance of the
    // drawer? If so, return to the previous position if the velocity was high enough.
    let isVelocityOpposingPanDirection = isDrawerBelowPreviousPosition && velocity < 0 ||
       !isDrawerBelowPreviousPosition && velocity > 0
    if isVelocityOpposingPanDirection && isVelocityHigh {
      panToCurrentPosition(animated: true)
    } else {
      let position = nextPosition(below: isDrawerBelowPreviousPosition,
                                  withPanDistance: currentPanDistance,
                                  skipDistanceCheck: isVelocityHigh)
      panToPosition(position)
    }
  }

  /// Pans the drawer by a distance.
  ///
  /// - Parameter distance: The distance to pan the drawer.
  func pan(distance: CGFloat) {
    // Update the panning view's pan distance to a value clamped between open full and peeking.
    let clampedPanDistance = (openFullPosition.panDistance...peekingPosition.panDistance).clamp(
        panDistance(withAdditionalPan: distance))
    currentPanDistance = clampedPanDistance
  }

  /// Whether or not the content view is visible.
  var isContentViewVisible: Bool {
    return currentPanDistance < 0
  }

  /// The visible height of the drawer, including the toolbar.
  var visibleHeight: CGFloat {
    return alpha == 0 ? 0 : ViewConstants.toolbarHeight - currentPanDistance
  }

  /// The visible height of the drawer's content view.
  var visibleContentHeight: CGFloat {
    return alpha == 0 ? 0 : -currentPanDistance
  }

  /// Sets the available height and updates content view height. This needs to be set when the view
  /// frame is updated.
  func setAvailableHeight(_ height: CGFloat) {
    // Only update content view height if the view height is greater than 0 and is not the same as
    // it was the last time it was set.
    guard height > 0 && (availableHeight == nil || height > availableHeight! ||
        height < availableHeight!) else { return }

    availableHeight = height
    updateContentViewHeight()
  }

  /// Sets the custom drawer position. Only valid if its pan distance falls between peeking and open
  /// full.
  ///
  /// - Parameter customPosition: The custom drawer position.
  func setCustomPosition(_ position: DrawerPosition){
    guard position.panDistance < peekingPosition.panDistance &&
        position.panDistance > openFullPosition.panDistance else {
      return
    }

    customPosition = position
  }

  /// Removes the custom drawer position.
  func removeCustomPosition() {
    customPosition = nil
  }

  /// Whether or not the drawer has a custom position set.
  var hasCustomPosition: Bool {
    return customPosition != nil
  }

  /// Resets the available height, since it is shared for all experiments.
  func resetHeight() {
    availableHeight = nil
  }

  /// Updates the drawer's shadow to show or not depending on position.
  ///
  /// - Parameter position: The new drawer position.
  func updateDrawerShadow(for position: DrawerPosition) {
    var newOpacity: Float
    if position == openFullPosition {
      newOpacity = 0
    } else {
      newOpacity = tabBarShadowMetrics.bottomShadowOpacity
    }
    guard newOpacity != self.tabBarWrapper.layer.shadowOpacity else { return }
    UIView.animate(withDuration: 0.15) {
      self.tabBarWrapper.layer.shadowOpacity = newOpacity
    }
  }

  override open func accessibilityPerformEscape() -> Bool {
    // If the drawer is open full, allow the escape gesture to bring it to half.
    if currentPosition == openFullPosition {
      panToPosition(openHalfPosition)
      return true
    }
    return false
  }

  override open func layoutSubviews() {
    super.layoutSubviews()

    // Panning view.
    panningView.frame = CGRect(x: 0,
                               y: panningViewOriginY,
                               width: bounds.width,
                               height: bounds.height)

    // Tab bar.
    tabBarWrapper.frame.size.width = panningView.bounds.width
    let tabBarHeight = MDCTabBar.defaultHeight(for: .images)
    // The tab bar should be layed out at the bottom of the global toolbar height.
    let tabBarMinY = ViewConstants.toolbarHeight - tabBarHeight
    tabBar.frame = CGRect(x: safeAreaInsetsOrZero.left,
                          y: tabBarMinY,
                          width: tabBarWrapper.bounds.width - safeAreaInsetsOrZero.left -
                              safeAreaInsetsOrZero.right,
                          height: tabBarHeight)

    // Tab bar grabber.
    grabber.frame = CGRect(x: (bounds.width - grabber.frame.width) / 2,
                           y: Metrics.tabBarGrabberOriginY,
                           width: grabber.frame.width,
                           height: grabber.frame.height)
    grabberWrapper.frame =
        CGRect(x: grabber.frame.midX - Metrics.tabBarGrabberWrapperSize.width / 2,
               y: grabber.frame.midY - Metrics.tabBarGrabberWrapperSize.height / 2,
               width: Metrics.tabBarGrabberWrapperSize.width,
               height: Metrics.tabBarGrabberWrapperSize.height)

    // Content view.
    contentView.frame.origin.y = tabBarWrapper.frame.maxY
    contentView.frame.size.width = panningView.bounds.width
    displayedView?.frame = contentView.bounds

    // Recording bar.
    recordingBar.frame.origin.y = tabBarWrapper.frame.maxY
    recordingBar.frame.size.width = panningView.bounds.width
  }

  // MARK: - Private

  private func configureView() {
    // Panning view.
    addSubview(panningView)

    // Tab bar.
    tabBarWrapper.backgroundColor = DrawerView.barBackgroundColor
    panningView.addSubview(tabBarWrapper)
    updateTabBarWrapperHeightForCurrentPosition()

    tabBar.delegate = self
    tabBar.items = drawerItems.enumerated().map { (index, item) in
      UITabBarItem(title: item.accessibilityLabel, image: item.tabBarImage, tag: index)
    }
    tabBar.disableScrolling()
    tabBar.barTintColor = DrawerView.barBackgroundColor
    tabBar.inkColor = .clear
    tabBar.itemAppearance = .images
    tabBar.tintColor = .white
    tabBar.selectedItemTintColor = .white
    tabBar.unselectedItemTintColor = UIColor(red: 0.510, green: 0.518, blue: 0.522, alpha: 1.0)
    tabBarWrapper.addSubview(tabBar)

    // Customize the MDCShadow metrics to put the shadow above the tab bar, but use the same metrics
    // as a normal app bar shadow.
    tabBarWrapper.layer.shadowOffset =
        CGSize(width: tabBarShadowMetrics.bottomShadowOffset.width,
               height: -tabBarShadowMetrics.bottomShadowOffset.height)
    tabBarWrapper.layer.shadowRadius = tabBarShadowMetrics.bottomShadowRadius
    tabBarWrapper.layer.shadowOpacity = tabBarShadowMetrics.bottomShadowOpacity
    tabBarWrapper.layer.shouldRasterize = true
    tabBarWrapper.layer.rasterizationScale = UIScreen.main.scale

    // Tab bar grabber.
    panningView.addSubview(grabber)
    grabber.tintColor = UIColor(red: 0.388, green: 0.396, blue: 0.396, alpha: 1.0)

    // Tab bar wrapping view for accessibility purposes. Creates a larger tap target for the
    // grabber and gives it both a label and hint which describes its current position. Also adds
    // a custom a11y action which moves the drawer to the next best position.
    panningView.addSubview(grabberWrapper)
    grabberWrapper.isUserInteractionEnabled = false
    grabberWrapper.isAccessibilityElement = true
    grabberWrapper.accessibilityLabel = String.drawerGrabberContentDescription
    grabberWrapper.accessibilityHint = String.drawerGrabberContentDetails
    grabberWrapper.activationEvent = { [weak self] in
      self?.panToNextAccessibilityPosition()
    }

    // Content view.
    contentView.clipsToBounds = true
    contentView.backgroundColor = .white
    panningView.insertSubview(contentView, belowSubview: tabBarWrapper)

    // Recording bar.
    recordingBar.sizeToFit()
    panningView.insertSubview(recordingBar, aboveSubview: tabBarWrapper)
  }

  /// The next position for the drawer based on pan position and whether to return the next position
  /// below or above.
  ///
  /// - Parameters:
  ///   - below: Whether the next position should be below the current position. Otherwise above.
  ///   - panDistance: The pan distance of the panning view.
  ///   - isSkippingDistanceCheck: If true, the next position will be returned regardless of how far
  ///                              away it is.
  /// - Returns: The position.
  private func nextPosition(below: Bool,
                            withPanDistance panDistance: CGFloat,
                            skipDistanceCheck isSkippingDistanceCheck: Bool) -> DrawerPosition {
    // If the position is above open full, return open full.
    if panDistance < openFullPosition.panDistance {
      return openFullPosition
    }

    // If the position is below peeking, return peeking.
    if panDistance > peekingPosition.panDistance {
      return peekingPosition
    }

    // If moving to the next position below the previous one, reverse the order of the positions.
    let orderedPositions = below ? drawerPositions.reversed() : drawerPositions

    // The index of the next position.
    var nextPositionIndex: Int {
      // Current position index.
      guard let indexOfCurrentPosition =
          orderedPositions.index(where: { $0 == currentPosition }) else { return 0 }

      // Next position index is +1 from the current index.
      let nextPositionIndex = indexOfCurrentPosition + 1

      // The next index can't be beyond the last index.
      guard nextPositionIndex < orderedPositions.endIndex else {
        return orderedPositions.endIndex - 1
      }

      return nextPositionIndex
    }

    // Check positions that are beyond the pan distance.
    let positionsToCheck = orderedPositions[nextPositionIndex...orderedPositions.endIndex - 1]

    // Check each position. If it is far enough away from the current position, return it. If none
    // are, return the previous position.
    var position = currentPosition
    for nextPosition in positionsToCheck {
      if isSkippingDistanceCheck {
        if below && nextPosition.panDistance > currentPanDistance ||
            !below && nextPosition.panDistance < currentPanDistance {
          // If overriding the distance check, use this position if it is beyond the pan distance.
          return nextPosition
        } else {
          continue
        }
      }

      if below {
        let distanceBetween = nextPosition.panDistance - position.panDistance
        let farEnoughForNextPosition = position.panDistance + distanceBetween * panPercentage
        if panDistance > farEnoughForNextPosition {
          position = nextPosition
          continue
        }
      } else {
        let distanceBetween = position.panDistance - nextPosition.panDistance
        let farEnoughForNextPosition = position.panDistance - distanceBetween * panPercentage
        if panDistance < farEnoughForNextPosition {
          position = nextPosition
          continue
        }
      }
      break
    }
    return position
  }

  /// Attempts to determine the best next drawer position based on its current position and then
  /// pans to it. Only used when accessibility-based events change the drawer
  /// position.
  private func panToNextAccessibilityPosition() {
    var nextPosition = openHalfPosition
    if currentPosition == openFullPosition {
      nextPosition = peekingPosition
    } else if currentPosition == customPosition {
      nextPosition = openFullPosition
    } else if currentPosition == peekingPosition {
      nextPosition = openHalfPosition
    } else if currentPosition == openHalfPosition {
      nextPosition = openFullPosition
    }
    panToPosition(nextPosition)
  }

  // The pan distance of the panning view added to an additional pan distance.
  private func panDistance(withAdditionalPan pan: CGFloat) -> CGFloat {
    return currentPosition.panDistance + pan
  }

  /// Updates the tab bar wrapper height.
  ///
  /// - Parameters:
  ///   - expanded: Whether or not it should expand into the bottom safe area inset.
  ///   - animated: Whether or not to animate the change.
  ///   - additionalHeight: Any additional height to add to the wrapper's height.
  private func updateTabBarWrapperHeight(expanded: Bool,
                                         animated: Bool = false,
                                         additionalHeight: CGFloat = 0) {
    let newHeight = ViewConstants.toolbarHeight +
        (expanded ? safeAreaInsetsOrZero.bottom + additionalHeight : 0)
    guard newHeight < tabBarWrapper.frame.height ||
        newHeight > tabBarWrapper.frame.height else { return }

    let duration = animated ? (expanded ? 0.05 : 0.1) : 0
    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
      self.tabBarWrapper.frame.size.height = newHeight
      self.setNeedsLayout()
    })
  }

  private func updateTabBarWrapperHeightForCurrentPosition(animated: Bool = false) {
    updateTabBarWrapperHeight(expanded: currentPosition == peekingPosition, animated: animated)
  }

  private func updateContentViewHeight() {
    contentView.frame.size.height = safeAreaInsetsOrZero.bottom +
        max(openHalfPosition.contentHeight, currentPosition.contentHeight)
    updateDisplayedViewFrame()
  }

  private func updateDisplayedViewFrame() {
    displayedView?.frame = contentView.bounds
    displayedView?.layoutIfNeeded()
  }

  // MARK: - Gesture recognizer

  @objc private func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    guard !isDisplayedAsSidebar else { return }

    let gestureDistance = panGestureRecognizer.translation(in: self).y
    let totalPanDistance = panDistance(withAdditionalPan: gestureDistance)

    // Expand the tab bar wrapper when pan distance is within 1 of its original position, otherwise
    // collapse it. This is to handle showing/hiding the expanded portion while panning is still
    // occuring, before the animation to the final position has begun. Pass along the remaining
    // pan distance as additional height, to ensure the space below the tab bar is fully covered by
    // the wrapper view.
    updateTabBarWrapperHeight(expanded: totalPanDistance > -1,
                              animated: true,
                              additionalHeight: abs(totalPanDistance))

    switch panGestureRecognizer.state {
    case .changed:
      pan(distance: gestureDistance)
      delegate?.drawerViewIsPanning(self)
      let panDistanceBeyondBounds = -totalPanDistance - openFullPosition.contentHeight
      if panDistanceBeyondBounds > 0 {
        delegate?.drawerView(self, didPanBeyondBounds: panDistanceBeyondBounds)
      }
    case .ended:
      completePan(withVelocity: panGestureRecognizer.velocity(in: self).y)
    default:
      break
    }
  }

  // MARK: - MDCTabBarDelegate

  public func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
    self.delegate?.drawerView(self, didSelectItemAtIndex: item.tag)
  }

}
