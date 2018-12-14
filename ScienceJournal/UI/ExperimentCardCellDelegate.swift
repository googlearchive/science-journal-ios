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

protocol ExperimentCardCellDelegate: class {

  /// Informs the delegate the comment button was pressed.
  ///
  /// - Parameter cell: The cell.
  func experimentCardCellCommentButtonPressed(_ cell: MaterialCardCell)

  /// Informs the delegate the menu button was pressed.
  ///
  /// - Parameters:
  ///   - cell: The cell.
  ///   - button: The menu button that was pressed.
  func experimentCardCellMenuButtonPressed(_ cell: MaterialCardCell, button: MenuButton)

  /// Informs the delegate the timestamp button was pressed.
  ///
  /// - Parameter cell: The cell.
  func experimentCardCellTimestampButtonPressed(_ cell: MaterialCardCell)

}
