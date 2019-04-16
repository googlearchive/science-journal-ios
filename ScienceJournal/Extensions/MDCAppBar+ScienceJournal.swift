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

/// MDCAppBar extension for Science Journal, used by Material-style header view controllers.
extension MDCAppBar {

  // The view tag used to fetch the status bar background view from the headerViewController's
  // headerView subviews.
  private var statusBarBackgroundViewTag: Int { return 100 }

  // A view used to darken the status bar area of an app bar.
  private var statusBarBackgroundView: UIView? {
    return headerViewController.headerView.viewWithTag(statusBarBackgroundViewTag)
  }

  /// Configure the app bar's appearance and add it to the view hierarchy.
  ///
  /// - Parameters:
  ///   - attachTo: The view controller that should hold this app bar.
  ///   - scrollView: The scroll view this app bar should attach tracking behavior to.
  func configure(attachTo: UIViewController, scrollView: UIScrollView? = nil) {
    attachTo.addChild(headerViewController)
    headerViewController.headerView.backgroundColor = .appBarDefaultBackgroundColor

    if UIDevice.current.userInterfaceIdiom == .pad {
      // Add a darkening view to the status bar area on iPad.
      let statusBarBackgroundView = UIView()
      statusBarBackgroundView.tag = statusBarBackgroundViewTag
      statusBarBackgroundView.backgroundColor = .black
      statusBarBackgroundView.frame = UIApplication.shared.statusBarFrame
      statusBarBackgroundView.autoresizingMask = .flexibleWidth
      headerViewController.headerView.addSubview(statusBarBackgroundView)
    }

    headerViewController.headerView.trackingScrollView = scrollView

    navigationBar.titleAlignment = .leading
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    navigationBar.tintColor = .white
    addSubviewsToParent()
  }

  /// Hides the status bar darkening region and removes the height from the app bar. Used for form
  /// sheet modals.
  func hideStatusBarOverlay() {
    statusBarBackgroundView?.backgroundColor = .clear
    headerViewController.headerView.statusBarHintCanOverlapHeader = false
    headerViewController.headerView.maximumHeight = 56.0
  }

}
