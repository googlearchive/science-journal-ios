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

import AVFoundation
import UIKit

/// A protocol for drawer item view controller management.
public protocol DrawerItemViewController {

  /// Configures a view controller's drawer panner.
  ///
  /// - Parameter drawerViewController: The view controller to configure.
  func setUpDrawerPanner(with drawerViewController: DrawerViewController)

  /// Resets the view controller.
  func reset()

}

/// A protocol to update view controllers about the position of the drawer.
public protocol DrawerPositionListener: AnyObject {

  /// Called when the drawer is about to change position.
  ///
  /// - Parameters:
  ///   - drawerViewController: The drawer view controller.
  ///   - position: The drawer position.
  func drawerViewController(_ drawerViewController: DrawerViewController,
                            willChangeDrawerPosition position: DrawerPosition)

  /// Called when the drawer changed position.
  ///
  /// - Parameters:
  ///   - drawerViewController: The drawer view controller.
  ///   - position: The drawer position.
  func drawerViewController(_ drawerViewController: DrawerViewController,
                            didChangeDrawerPosition position: DrawerPosition)

  /// Called when the drawer is panning.
  ///
  /// - Parameters:
  ///   - drawerViewController: The drawer view controller.
  ///   - position: The drawer position.
  func drawerViewController(_ drawerViewController: DrawerViewController,
                            isPanningDrawerView drawerView: DrawerView)

  /// Called when the drawer pans upward beyond its bounds.
  ///
  /// - Parameters:
  ///   - drawerViewController: The drawer view controller.
  ///   - panDistance: The distance of the pan upward beyond the drawer's bounds.
  func drawerViewController(_ drawerViewController: DrawerViewController,
                            didPanBeyondBounds panDistance: CGFloat)

}

/// Extends UIViewController for drawer contained view controllers.
extension UIViewController {

  /// If the receiver is contained by a drawer view controller and is in the current hierarchy, this
  /// returns the drawer view controller.
  var drawerViewController: DrawerViewController? {
    var vcParent = parent
    while vcParent != nil {
      if let drawerViewController = vcParent as? DrawerViewController {
        return drawerViewController
      }
      vcParent = vcParent?.parent
    }
    return nil
  }

  /// Returns true if the receiver is the current view controller being displayed in the drawer.
  var isDisplayedInDrawer: Bool {
    return drawerViewController?.currentViewController == self
  }

}

/// A container view controller that switches between view controllers by pressing buttons in the
/// `DrawerView`'s tab bar.
open class DrawerViewController: UIViewController, DrawerViewDelegate {

  // MARK: - Properties

  /// The notes view controller.
  var notesViewController: NotesViewController {
    // swiftlint:disable force_cast
    return drawerItems.viewControllerForKey(DrawerItemKeys.notesViewControllerKey)
        as! NotesViewController
    // swiftlint:enable force_cast
  }

  /// The observe view controller.
  var observeViewController: ObserveViewController {
    // swiftlint:disable force_cast
    return drawerItems.viewControllerForKey(DrawerItemKeys.observeViewControllerKey)
        as! ObserveViewController
    // swiftlint:enable force_cast
  }

  /// The camera view controller.
  var cameraViewController: CameraViewController {
    // swiftlint:disable force_cast
    return drawerItems.viewControllerForKey(DrawerItemKeys.cameraViewControllerKey)
        as! CameraViewController
    // swiftlint:enable force_cast
  }

  /// The photo library view controller.
  var photoLibraryViewController: PhotoLibraryViewController {
    // swiftlint:disable force_cast
    return drawerItems.viewControllerForKey(DrawerItemKeys.photoLibraryViewControllerKey)
        as! PhotoLibraryViewController
    // swiftlint:enable force_cast
  }

  /// The view controller currently being shown.
  var currentViewController: UIViewController?

  /// The drawer view.
  var drawerView: DrawerView {
    // swiftlint:disable force_cast
    return view as! DrawerView
    // swiftlint:enable force_cast
  }

  /// Whether or not the drawer is being displayed as a sidebar.
  var isDisplayedAsSidebar = false {
    didSet {
      drawerView.isDisplayedAsSidebar = isDisplayedAsSidebar
    }
  }

  /// Whether or not the camera item in the tab bar should have an enabled or disabled appearance.
  var isCameraItemEnabled = true {
    didSet {
      guard oldValue != isCameraItemEnabled else { return }
      let cameraTabItem = drawerView.tabBar.items[cameraItemIndex]
      cameraTabItem.image =
          UIImage(named: isCameraItemEnabled ? "ic_camera_alt" : "ic_camera_alt_disabled")
    }
  }

  /// Drawer items.
  public let drawerItems: DrawerItems

  private var notesDrawerItem: DrawerItem {
    return drawerItems.drawerItemForKey(DrawerItemKeys.notesViewControllerKey)
  }

  private var observeDrawerItem: DrawerItem {
    return drawerItems.drawerItemForKey(DrawerItemKeys.observeViewControllerKey)
  }

  private let cameraItemIndex = 2
  private let analyticsReporter: AnalyticsReporter

  /// Objects to be called with DrawerPositionListener methods. Uses a weak hash table to avoid
  /// creating retain cycles.
  private var drawerPositionListeners = NSHashTable<AnyObject>.weakObjects()

  // MARK: - Public

  /// Public initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: An instance of AnalyticsReporter to inject into all related classes.
  ///   - drawerConfig: An instance of a DrawerConfig class to configure drawer items and their view
  ///                   controllers.
  ///   - preferenceManager: A preference manager.
  ///   - sensorController: A sensor controller.
  ///   - sensorDataManager: A sensor data manager.
  init(analyticsReporter: AnalyticsReporter,
       drawerConfig: DrawerConfig,
       preferenceManager: PreferenceManager,
       sensorController: SensorController,
       sensorDataManager: SensorDataManager) {
    self.analyticsReporter = analyticsReporter
    drawerItems = DrawerItems(analyticsReporter: analyticsReporter,
                              drawerConfig: drawerConfig,
                              preferenceManager: preferenceManager,
                              sensorController: sensorController,
                              sensorDataManager: sensorDataManager)

    super.init(nibName: nil, bundle: nil)

    // Set up position tracking and drawer panners on drawer item VCs that require it.
    for case let listener as DrawerPositionListener & DrawerItemViewController
        in drawerItems.viewControllers {
      addDrawerPositionListener(listener)
      listener.setUpDrawerPanner(with: self)
    }
  }

  deinit {
    // Remove position tracking on drawer item VCs that require it.
    for case let listener as DrawerPositionListener in drawerItems.viewControllers {
      removeDrawerPositionListener(listener)
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override open func loadView() {
    super.loadView()
    view = DrawerView(items: drawerItems.allItems, delegate: self)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    updateItemViewController()

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionWasInterrupted(_:)),
                                           name: .AVCaptureSessionWasInterrupted,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionInterruptionEnded(_:)),
                                           name: .AVCaptureSessionInterruptionEnded,
                                           object: nil)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isCameraItemEnabled = CaptureSessionInterruptionObserver.shared.isCameraUseAllowed
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updateAllowedDrawerPositions(for: view.bounds.size)
  }

  override open func viewWillTransition(to size: CGSize,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    updateAllowedDrawerPositions(for: size)
    // TODO: Fix the layout when there is an in-call status bar. http://b/62135678
  }

  /// Resets the drawer to be used for a new experiment.
  func reset() {
    drawerView.resetHeight()
    drawerItems.viewControllers.forEach { $0.reset() }
    selectNotes()
  }

  // MARK: - Drawer Position

  /// Sets the drawer position to full.
  ///
  /// - Parameter: animated: Whether or not to animate. Default is true.
  func setPositionToFull(animated: Bool = true) {
    setPosition(drawerView.openFullPosition, animated: animated)
  }

  /// Sets the drawer position to half.
  ///
  /// - Parameters:
  ///   - animated: Whether or not to animate. Default is true.
  ///   - completion: Called when setting the position to half completes, if it can open to half.
  ///                 Otherwise called immediately.
  func setPositionToHalf(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard drawerView.canOpenHalf && !isDisplayedAsSidebar else {
      completion?()
      return
    }
    setPosition(drawerView.openHalfPosition, animated: animated, completion: completion)
  }

  /// Sets the drawer position to peeking.
  ///
  /// - Parameters:
  ///   - animated: Whether or not to animate. Default is true.
  ///   - completion: Called when setting the position to peeking completes, if it can open to
  ///                 peeking. Otherwise called immediately.
  func setPositionToPeeking(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard !isDisplayedAsSidebar else { completion?(); return }
    setPosition(drawerView.peekingPosition, animated: animated, completion: completion)
  }

  /// If the drawer can open halfway, open it halfway. Otherwise open it full. If the drawer is not
  /// in the peeking position, this method does nothing.
  func showContent() {
    guard isPeeking else { return }
    if drawerView.canOpenHalf {
      setPositionToHalf()
    } else {
      setPositionToFull()
    }
  }

  /// If the drawer can open halfway, open it halfway. Otherwise set it to the peeking position.
  ///
  /// - Parameter animated: Whether or not to animate.
  func setPositionToHalfOrPeeking(animated: Bool) {
    if drawerView.canOpenHalf {
      setPositionToHalf(animated: animated)
    } else {
      setPositionToPeeking(animated: animated)
    }
  }

  /// If the drawer can open halfway, open it halfway. Otherwise, set it to peeking. If the drawer
  /// is displayed as a sidebar or is not open full, this method does nothing and calls completion
  /// immediately.
  ///
  /// - Parameter completion: Called when the drawer position is set or immediately if there will be
  ///                         no position change.
  func minimizeFromFull(completion: (() -> Void)? = nil) {
    guard !isDisplayedAsSidebar && isOpenFull else { completion?(); return }
    if drawerView.canOpenHalf {
      setPositionToHalf(completion: completion)
    } else {
      setPositionToPeeking(completion: completion)
    }
  }

  /// Sets the drawer to the custom position if it is full.
  ///
  /// - Parameter completion: Called when setting the position to half completes if it was full.
  ///                         Otherwise called immediately.
  func setToCustomPositionIfFull(completion: (() -> Void)? = nil) {
    if isOpenFull {
      setPositionToCustom(completion: completion)
    } else {
      completion?()
    }
  }

  /// Sets the drawer to the custom position, if it exists.
  ///
  /// - Parameters:
  ///   - animated: Whether or not to animate. Default is true.
  ///   - completion: Called when setting the position to custom completes, if it can open to
  ///                 custom. Otherwise called immediately.
  func setPositionToCustom(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard !isDisplayedAsSidebar && drawerView.canOpenToCustomPosition,
        let customDrawerPosition = drawerView.customPosition else { completion?(); return }
    setPosition(customDrawerPosition, animated: animated, completion: completion)
  }

  /// Sets the drawer to open half if it is open to the custom position.
  func setPositionToHalfIfCustom() {
    if isCustomPosition {
      setPositionToHalf()
    }
  }

  /// Whether or not the drawer's current position is full.
  var isOpenFull: Bool {
    return isPositionOpenFull(drawerView.currentPosition)
  }

  /// Whether or not the drawer view's current position is half.
  var isOpenHalf: Bool {
    return isPositionOpenHalf(drawerView.currentPosition)
  }

  /// Whether or not the drawer view's current position is peeking.
  var isPeeking: Bool {
    return isPositionPeeking(drawerView.currentPosition)
  }

  /// Whether or not the drawer view's current position is the custom one.
  var isCustomPosition: Bool {
    return isPositionCustom(drawerView.currentPosition)
  }

  /// Whether or not the positon is open full.
  ///
  /// - Parameter position: The position.
  /// - Returns: True if it is open full, otherwise false.
  func isPositionOpenFull(_ position: DrawerPosition) -> Bool {
    return position == drawerView.openFullPosition
  }

  /// Whether or not the positon is open half.
  ///
  /// - Parameter position: The position.
  /// - Returns: True if it is open half, otherwise false.
  func isPositionOpenHalf(_ position: DrawerPosition) -> Bool {
    return position == drawerView.openHalfPosition
  }

  /// Whether or not the positon is peeking.
  ///
  /// - Parameter position: The position.
  /// - Returns: True if it is peeking, otherwise false.
  func isPositionPeeking(_ position: DrawerPosition) -> Bool {
    return position == drawerView.peekingPosition
  }

  /// Whether or not the positon is the custom one.
  ///
  /// - Parameter position: The position.
  /// - Returns: True if it is open to the custom position, otherwise false.
  func isPositionCustom(_ position: DrawerPosition) -> Bool {
    return position == drawerView.customPosition
  }

  /// Whether or not partial drawer positions are supported.
  var canOpenPartially: Bool {
    return !view.bounds.size.isWiderThanTall
  }

  // MARK: Item selection

  /// Selects notes in the drawer.
  func selectNotes() {
    select(item: notesDrawerItem)
  }

  /// Selects observe in the drawer.
  func selectObserve() {
    select(item: observeDrawerItem)
  }

  // MARK: - Private

  /// Sets the drawer position.
  ///
  /// - Parameters:
  ///   - position: The position.
  ///   - animated: Whether or not to animate the change.
  ///   - completion: Called when setting the position completes.
  private func setPosition(_ position: DrawerPosition,
                           animated: Bool = true,
                           completion: (() -> Void)? = nil) {
    drawerView.panToPosition(position, animated: animated, completion: completion)
  }

  /// Selects a drawer view tab bar item and shows its view controller.
  ///
  /// - Parameter item: The item to select.
  func select(item: DrawerItem) {
    guard let index = drawerItems.allItems.firstIndex(where: { $0 === item }) else { return }
    show(viewController: item.viewController)
    drawerView.tabBar.selectedItem = drawerView.tabBar.items[index]
  }

  /// Shows a view controller in the drawer view's content view.
  ///
  /// - Parameter viewController: The view controller to show.
  func show(viewController: UIViewController) {
    guard viewController != currentViewController else {
      // Do nothing if `viewController` is already being shown.
      return
    }

    // If a VC's view was already added to the drawer, remove it.
    if let currentViewController = currentViewController {
      currentViewController.view.removeFromSuperview()
      currentViewController.removeFromParent()
    }

    // Add the VC's view to the drawer.
    currentViewController = viewController
    addChild(currentViewController!)
    drawerView.displayViewInContentView(currentViewController!.view)

    if currentViewController == cameraViewController {
      cameraViewController.setPreviewHeightAnchor(equalTo: drawerView.panningView.heightAnchor)
    }
  }

  // Shows the first view controller if nothing has loaded yet. Also, updates the selected item for
  // whether the drawer is open or not.
  func updateItemViewController(for drawerPosition: DrawerPosition? = nil) {
    /// Determines if the content view is visible, based on either the drawer's position or by
    /// asking the drawer view.
    var isContentViewVisible: Bool {
      if let position = drawerPosition {
        return position != drawerView.peekingPosition
      } else {
        return drawerView.isContentViewVisible
      }
    }

    if currentViewController == nil {
      selectNotes()
    }

    // Deleselect the tab bar only if the drawer is in peeking position or if nothing has been
    // selected (e.g. on initial launch).
    var shouldDeselectItem = !isContentViewVisible
    if let drawerPosition = drawerPosition {
      shouldDeselectItem = drawerPosition == drawerView.peekingPosition
    }
    if shouldDeselectItem {
      drawerView.tabBar.selectedItem = nil
    } else if let currentViewController = currentViewController {
      if let index = drawerItems.allItems.firstIndex(where: { (drawerItem) -> Bool in
        return drawerItem.viewController === currentViewController
      }) {
        drawerView.tabBar.selectedItem = drawerView.tabBar.items[index]
      }
    }
  }

  // MARK: - Drawer position listeners

  /// Adds a drawer position listener.
  ///
  /// - Parameter listener: The drawer position listener object.
  func addDrawerPositionListener(_ listener: DrawerPositionListener) {
    drawerPositionListeners.add(listener)
  }

  /// Removes a drawer position listener.
  ///
  /// - Parameter listener: The drawer position listener object.
  func removeDrawerPositionListener(_ listener: DrawerPositionListener) {
    drawerPositionListeners.remove(listener)
  }

  func updateAllowedDrawerPositions(for viewSize: CGSize, animated: Bool = false) {
    drawerView.canOpenHalf = !viewSize.isWiderThanTall
    drawerView.canOpenToCustomPosition = !viewSize.isWiderThanTall
  }

  // MARK: - DrawerViewDelegate

  public func drawerView(_ drawerView: DrawerView, didSelectItemAtIndex index: Int) {
    // Perform without animation to avoid undesirable animations when showing a view controller.
    UIView.performWithoutAnimation {
      show(viewController: drawerItems.allItems[index].viewController)
    }

    showContent()
  }

  public func drawerView(_ drawerView: DrawerView, willChangePosition position: DrawerPosition) {
    updateItemViewController(for: position)
    drawerPositionListeners.allObjects.forEach { (object) in
      guard let listener = object as? DrawerPositionListener else { return }
      listener.drawerViewController(self, willChangeDrawerPosition: position)
    }
  }

  public func drawerView(_ drawerView: DrawerView, didChangePosition position: DrawerPosition) {
    drawerPositionListeners.allObjects.forEach { (object) in
      guard let listener = object as? DrawerPositionListener else { return }
      listener.drawerViewController(self, didChangeDrawerPosition: position)
    }

    drawerView.updateDrawerShadow(for: position)
  }

  public func drawerViewIsPanning(_ drawerView: DrawerView) {
    updateItemViewController()
    drawerPositionListeners.allObjects.forEach { (object) in
      guard let listener = object as? DrawerPositionListener else { return }
      listener.drawerViewController(self, isPanningDrawerView: drawerView)
    }
  }

  public func drawerView(_ drawerView: DrawerView, didPanBeyondBounds panDistance: CGFloat) {
    drawerPositionListeners.allObjects.forEach { (object) in
      guard let listener = object as? DrawerPositionListener else { return }
      listener.drawerViewController(self, didPanBeyondBounds: panDistance)
    }
  }

  // MARK: - Notifications

  @objc private func captureSessionWasInterrupted(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionWasInterrupted(notification)
      }
      return
    }

    guard AVCaptureSession.InterruptionReason(notificationUserInfo: notification.userInfo) ==
        .videoDeviceNotAvailableWithMultipleForegroundApps else { return }
    isCameraItemEnabled = false
  }

  @objc private func captureSessionInterruptionEnded(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionInterruptionEnded(notification)
      }
      return
    }

    isCameraItemEnabled = !CaptureSessionInterruptionObserver.shared.isBrightnessSensorInUse
  }

}
