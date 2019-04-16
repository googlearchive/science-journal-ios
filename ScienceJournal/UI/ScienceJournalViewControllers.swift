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

import third_party_objective_c_material_components_ios_components_Collections_Collections

/// A wrapping class for MDCCollectionViewController, which will be extended to add analytics
/// tracking.
open class ScienceJournalCollectionViewController: VisibilityTrackingCollectionViewController {

  let analyticsReporter: AnalyticsReporter

  public init(collectionViewLayout: UICollectionViewLayout, analyticsReporter: AnalyticsReporter) {
    self.analyticsReporter = analyticsReporter
    super.init(collectionViewLayout: collectionViewLayout)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    analyticsReporter.trackScreenView(named: analyticsViewName)
  }

}

/// A base class for all non-Material view controllers to subclass, which will be extended to add
/// analytics tracking.
open class ScienceJournalViewController: VisibilityTrackingViewController {

  let analyticsReporter: AnalyticsReporter

  public init(analyticsReporter: AnalyticsReporter) {
    self.analyticsReporter = analyticsReporter
    super.init(nibName: nil, bundle: nil)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    analyticsReporter.trackScreenView(named: analyticsViewName)
  }

}
