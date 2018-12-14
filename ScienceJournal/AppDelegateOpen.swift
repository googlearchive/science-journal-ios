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

/// A subclass of the AppDelegate allowing for customization of injectable classes.
open class AppDelegateOpen: AppDelegate {

  open override var analyticsReporter: AnalyticsReporter {
    return _analyticsReporter
  }

  open override var feedbackReporter: FeedbackReporter {
    return _feedbackReporter
  }

  open override var accountsManager: AccountsManager {
    return _accountsManager
  }

  open override var drawerConfig: DrawerConfig {
    return _drawerConfig
  }

  open override var driveConstructor: DriveConstructor {
    return _driveConstructor
  }

  open override var commonUIComponents: CommonUIComponents {
    return _commonUIComponents
  }

  open override var networkAvailability: NetworkAvailability {
    return _networkAvailability
  }

  private let _analyticsReporter = AnalyticsReporterOpen()
  private let _feedbackReporter = FeedbackReporterOpen()
  private let _accountsManager = AccountsManagerDisabled()
  private let _drawerConfig = DrawerConfigOpen()
  private let _driveConstructor = DriveConstructorDisabled()
  private let _commonUIComponents = CommonUIComponentsOpen()
  private let _networkAvailability = NetworkAvailabilityDisabled()
}
