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

import googlemac_iPhone_Shared_SSOAuth_SSOAuth

public enum SignInResult {
  /// The account changed.
  case accountChanged

  /// Sign in failed, the user should be forced to sign in again.
  case forceSignIn

  /// No change occured while signing in, leave the existing signed in user signed in.
  case noAccountChange
}

public enum SignInType {
  /// A sign in is occuring.
  case newSignIn

  /// An account is already signed in, but is being restored on launch.
  case restoreCachedAccount
}

public enum PermissionState {
  /// Permission is granted.
  case granted

  /// Permission is denied.
  case denied
}

public protocol AccountsManagerDelegate: class {
  /// Tells the delegate to delete all user data for the identity with the specified ID.
  func deleteAllUserDataForIdentity(withID identityID: String)

  func accountsManagerWillBeginSignIn(signInType: SignInType)

  func accountsManagerSignInComplete(signInResult: SignInResult, signInType: SignInType)

  func accountsManagerPermissionCheckComplete(permissionState: PermissionState,
                                              signInType: SignInType)
}

/// Protocol for managing Google user accounts.
public protocol AccountsManager: class {

  /// The delegate for an AccountsManager object.
  var delegate: AccountsManagerDelegate? { get set }

  /// If accounts are supported, Google Sign-in and Drive Sync will be available to the user. If
  /// not, these features are completely hidden from the UI and no data is synced.
  var supportsAccounts: Bool { get }

  /// The current account selected for use by the app.
  var currentAccount: AuthAccount? { get }

  /// This should check for a saved account and sign in as this account if the account is valid.
  /// Should call the delegate when complete.
  func signInAsCurrentAccount()

  /// Signs the current account out of Science Journal, but does not remove it from SSO. Needed
  /// when permission has been denied by the server for a specific account, which means the user
  /// will be required to switch accounts. But in this case, we don't want to delete the user's
  /// data.
  func signOutCurrentAccount()

  /// Presents a view controller that allows the user to select an existing account or sign into
  /// a new account. Should call the delegate when sign in is complete.
  ///
  /// - Parameter viewController: The view controller from which to present the sign in view
  ///                             controller.
  func presentSignIn(fromViewController viewController: UIViewController)

  /// Reauthenticates the current user account.
  ///
  /// - Returns: True if successful, false if not.
  @discardableResult func reauthenticateCurrentAccount() -> Bool

  /// Removes accounts no longer available in SSO, which might have been deleted while the app was
  /// not active.
  func removeLingeringAccounts()

}

public extension Notification.Name {
  /// The name of a notification posted when a user will be signed out immediately.
  static let userWillBeSignedOut = Notification.Name("GSJNotificationUserWillBeSignedOut")
}

/// A protocol representing an auth account.
public protocol AuthAccount {

  /// The account ID.
  var ID: String { get }

  /// The account email.
  var email: String { get }

  /// The account display name.
  var displayName: String { get }

  /// The account profile image.
  var profileImage: UIImage? { get }

  /// The authorization for the account.
  var authorization: GTMFetcherAuthorizationProtocol? { get set }

}
