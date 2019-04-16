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

import CoreData
import Foundation

protocol Managed: class, NSFetchRequestResult {
  /// The entity name for this managed object. The `entity` property is iOS 10, so for iOS < 10,
  /// require an NSManagedObject to return its entity name on its own.
  static var entityName: String { get }

  /// Default sort descriptors for fetch requests.
  static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension Managed {
  static var defaultSortDescriptors: [NSSortDescriptor] {
    return[]
  }

  /// A default fetch request that can be use for fetch requests of managed objects. Allows for a
  /// request as such: `let request = ManagedObject.sortedFetchRequest`.
  static var sortedFetchRequest: NSFetchRequest<Self> {
    let request = NSFetchRequest<Self>(entityName: entityName)
    request.sortDescriptors = defaultSortDescriptors
    return request
  }
}
