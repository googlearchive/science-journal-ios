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

/// Extensions on String for Science Journal used for formatting localized strings.
extension String {

  /// Returns the claim experiments claim all confirmation message, singular or plural based on item
  /// count, with the item count and email address included in the string.
  ///
  /// - Parameters:
  ///   - itemCount: The item count.
  ///   - email: The email address of the user.
  /// - Returns: The confirmation message.
  static func claimExperimentsClaimAllConfirmationMessage(withItemCount itemCount: Int,
                                                          email: String) -> String {
    if itemCount == 1 {
      return String(format: String.claimAllExperimentsConfirmationMessage, email)
    } else {
      return String(format: String.claimAllExperimentsConfirmationMessagePlural,
                    String(itemCount),
                    email)
    }
  }

  /// Returns the claim experiments delete all confirmation message, singular or plural based on
  /// item count, with the item count included in the string.
  ///
  /// - Parameter itemCount: The item count.
  /// - Returns: The confirmation message.
  static func claimExperimentsDeleteAllConfirmationMessage(withItemCount itemCount: Int) -> String {
    if itemCount == 1 {
      return String.claimExperimentsDeleteAllConfirmationMessage
    } else {
      return String(format: String.claimExperimentsDeleteAllConfirmationMessagePlural, itemCount)
    }
  }

  /// Returns the claim experiment confirmation message with the email address included in the
  /// string.
  ///
  /// - Parameter email: The email address.
  /// - Returns: The confirmation message.
  static func claimExperimentConfirmationMessage(withEmail email: String) -> String {
    return String(format: String.claimExperimentConfirmationMessage, email)
  }

}
