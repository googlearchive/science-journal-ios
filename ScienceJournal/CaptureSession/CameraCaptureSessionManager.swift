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

/// Manages objects that use a camera capture sessions by informing them when they can begin use and
/// when they have to resign use of their capture session.
class CameraCaptureSessionManager {

  // MARK: - Properties

  /// Camera capture session manager singleton.
  static let shared = CameraCaptureSessionManager()

  /// The queue to use for camera capture session activity.
  let sessionQueue = DispatchQueue(label: "com.google.ScienceJournal.CameraCaptureSessionManager")

  private var currentUserObject: CaptureSessionUser?
  private var userObjects = [AnyHashable : CaptureSessionUser]()

  // MARK: - Public

  /// Use `shared`.
  private init() {}

  /// Registers an object to be allowed use of its capture session.
  ///
  /// - Parameters:
  ///   - object: The object using a capture session.
  ///   - beginUsingBlock: The block called when the user object can begin using the capture
  ///                      session. Called on a private queue.
  ///   - endUsingBlock: The block called when the user object must end using the capture session.
  ///                    Called on a private queue.
  func registerUser(_ object: AnyObject,
                    beginUsingBlock: @escaping () -> Void,
                    endUsingBlock: @escaping () -> Void) {
    userObjects[ObjectIdentifier(object)] =
        CaptureSessionUser(beginUsingBlock: beginUsingBlock, endUsingBlock: endUsingBlock)
  }

  /// Removes an object as a capture session user.
  ///
  /// - Parameter object: The object that is being removed as a capture session user.
  func removeUser(_ object: AnyObject) {
    userObjects[ObjectIdentifier(object)] = nil
  }

  /// A capture session user object should call this method when it wants to begin using the capture
  /// session. The object must wait until its begin using block is called.
  func beginUsing(withObject object: AnyObject) {
    sessionQueue.async {
      self.currentUserObject?.endUsingBlock()
      self.currentUserObject = self.userObjects[ObjectIdentifier(object)]
      self.currentUserObject?.beginUsingBlock()
    }
  }

  /// A capture session user object should call this method when it wants to end using the capture
  /// session. The object should wait until its end using block is called to it tear down.
  func endUsing(withObject object: AnyObject) {
    sessionQueue.async {
      let userObject = self.userObjects[ObjectIdentifier(object)]
      userObject?.endUsingBlock()
    }
  }

}
