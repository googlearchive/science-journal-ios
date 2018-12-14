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

import third_party_objective_c_material_components_ios_components_Collections_Collections

/// A view controller that tracks the visibility of its view.
open class VisibilityTrackingViewController: UIViewController {

  // Tracks the visiblity of the view. This property is set to true in viewWillAppear, and false in
  // viewWillDisappear.
  public private(set) var isViewVisible = false

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isViewVisible = true
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    isViewVisible = false
  }

}

/// A Material collection view controller that tracks the visibility of its view.
open class VisibilityTrackingCollectionViewController: MDCCollectionViewController {

  // Tracks the visiblity of the view. This property is set to true in viewWillAppear, and false in
  // viewWillDisappear.
  public private(set) var isViewVisible = false

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isViewVisible = true
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    isViewVisible = false
  }

}
