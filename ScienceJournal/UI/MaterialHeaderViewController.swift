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

import third_party_objective_c_material_components_ios_components_AppBar_AppBar
import third_party_objective_c_material_components_ios_components_Dialogs_ColorThemer
import third_party_objective_c_material_components_ios_components_private_Overlay_Overlay

/// Boilerplate view controller for setting up a Material header view.
class MaterialHeaderViewController: ScienceJournalViewController, UIScrollViewDelegate,
                                    UIGestureRecognizerDelegate {

  // MARK: - Properties

  let appBar = MDCAppBar()
  var trackedScrollView: UIScrollView? { return nil }
  private weak var existingInteractivePopGestureRecognizerDelegate : UIGestureRecognizerDelegate?

  // MARK: - MaterialHeader

  override var hasMaterialHeader: Bool { return true }

  // MARK: - Public

  override func viewDidLoad() {
    super.viewDidLoad()
    appBar.configure(attachTo: self, scrollView: trackedScrollView)
    trackedScrollView?.delegate = appBar.headerViewController

    MDCAlertColorThemer.apply(ViewConstants.alertColorScheme)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let popDelegate = navigationController?.interactivePopGestureRecognizer?.delegate {
      // When using MDCFlexibileHeaderController within a UINavigationController, setting the
      // UINavigationController's navigationBarHidden property to YES results in the loss of the
      // swipe-to-go-back feature associated with the controller.
      //
      // To re-enable this feature when hiding the navigation controller's navigationBar,
      // set a pointer to the current interactivePopGestureRecognizer's delegate before setting
      // the navigationBarHidden property to YES, set the interactivePopGestureRecognizer's delegate
      // to nil while MDCFlexibileHeaderController's parent controller is actively on-screen in
      // viewDidAppear:, then re-set the interactivePopGestureRecognizer's delegate to the stored
      // pointer in viewWillDisappear: (see below).
      //
      // See https://goo.gl/BU5fmO for more details.
      existingInteractivePopGestureRecognizerDelegate = popDelegate
    }
    navigationController?.setNavigationBarHidden(true, animated: animated)

    // Bring the app bar to the front.
    view.bringSubviewToFront(appBar.headerViewController.headerView)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Watch for back swipe events so subclasses can do stuff before pops if necessary.
    navigationController?.interactivePopGestureRecognizer?.delegate = self
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let popDelegate = existingInteractivePopGestureRecognizerDelegate {
      // Return interactivePopGestureRecognizer delegate to previously held object.
      navigationController?.interactivePopGestureRecognizer?.delegate = popDelegate
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    MDCOverlayObserver(for: .main).removeTarget(self)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    if #available(iOS 10.0, *) { return }

    // In iOS 9, a bug in MDCNavigationBar will cause right bar items to disappear on rotation
    // unless we layout the subviews once rotation animation is complete.
    coordinator.animate(alongsideTransition: nil) { _ in
      self.appBar.navigationBar.layoutSubviews()
    }
  }

  // MARK: - UIGestureRecognizerDelegate

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
      return interactivePopGestureShouldBegin()
    }
    return true
  }

  /// Subclasses can override this if they need to do something before the pop occurs.
  func interactivePopGestureShouldBegin() -> Bool {
    return true
  }

  // MARK: - UIScrollViewDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == appBar.headerViewController.headerView.trackingScrollView {
      appBar.headerViewController.headerView.trackingScrollDidScroll()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView == appBar.headerViewController.headerView.trackingScrollView {
      appBar.headerViewController.headerView.trackingScrollDidEndDecelerating()
    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                willDecelerate decelerate: Bool) {
    if scrollView == appBar.headerViewController.headerView.trackingScrollView {
      let headerView = appBar.headerViewController.headerView
      headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
    }
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                 withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if scrollView == appBar.headerViewController.headerView.trackingScrollView {
      let headerView = appBar.headerViewController.headerView
      headerView.trackingScrollWillEndDragging(withVelocity: velocity,
                                               targetContentOffset: targetContentOffset)
    }
  }

}
