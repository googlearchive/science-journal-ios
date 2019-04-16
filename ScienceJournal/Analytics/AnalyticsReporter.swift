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

import Foundation

/// A protocol for reporting analytics in Science Journal.
public protocol AnalyticsReporter {

  /// Sets the opt out setting for analytics tracking.
  ///
  /// - Parameter isOptedOut: True if the user opted out of analytics tracking, otherwise false.
  func setOptOut(_ isOptedOut: Bool)

  /// Tracks a view with screen named `screenName`.
  func trackScreenView(named screenName: String)

  /// Tracks an AnalyticsEvent, which is a struct for an event with a category and an optional
  /// label and value.
  ///
  /// - Parameter analyticsEvent: The event to track.
  func track(_ analyticsEvent: AnalyticsEvent)

}
