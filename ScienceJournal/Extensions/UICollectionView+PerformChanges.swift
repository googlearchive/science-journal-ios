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

/// A type of change for a collection view. Used to describe a batch of changes.
///
/// - reloadData: A full reload of all data.
/// - insert: Inserts the associated index paths.
/// - insertSections: Inserts the associated sections.
/// - delete: Deletes the associated index paths.
/// - deleteSections: Deletes the associated sections.
/// - reload: Reloads the associated index paths.
/// - reloadSections: Reloads the associated sections.
enum CollectionViewChange {
  case reloadData
  case insert([IndexPath])
  case insertSections(IndexSet)
  case delete([IndexPath])
  case deleteSections(IndexSet)
  case reload([IndexPath])
  case reloadSections(IndexSet)
}

extension UICollectionView {
  /// Performs the given changes.
  ///
  /// - Parameter changes: An array of changes.
  func performChanges(_ changes: [CollectionViewChange], completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates({
      changeLoop: for change in changes {
        switch change {
        case .insert(let indexPaths):
          self.insertItems(at: indexPaths)
        case .insertSections(let indexSet):
          self.insertSections(indexSet)
        case .delete(let indexPaths):
          self.deleteItems(at: indexPaths)
        case .deleteSections(let indexSet):
          self.deleteSections(indexSet)
        case .reload(let indexPaths):
          self.reloadItems(at: indexPaths)
        case .reloadSections(let indexSet):
          self.reloadSections(indexSet)
        case .reloadData:
          self.reloadData()
          break changeLoop
        }
      }
    }, completion: completion)
  }
}
