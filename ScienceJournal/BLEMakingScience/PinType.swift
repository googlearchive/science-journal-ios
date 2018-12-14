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

import Foundation

/// An enum with cases for pin signal types.
///
/// - analog: An analog pin.
/// - digital: A digital pin.
/// - virtual: A virtual pin.
enum PinSignalType {
  case analog
  case digital
  case virtual
}

/// Describes a pin on a Making Science Arduino board.
struct PinType {

  /// The pin signal type.
  let signalType: PinSignalType

  /// The pin number.
  let number: Int

  /// The default pin.
  static let `default` = PinType(signalType: .analog, number: 0)

  /// An array of all known pins.
  static let knownPins = [PinType.default,
                          PinType(signalType: .analog, number: 1),
                          PinType(signalType: .analog, number: 2),
                          PinType(signalType: .analog, number: 3),
                          PinType(signalType: .analog, number: 4),
                          PinType(signalType: .analog, number: 5),
                          PinType(signalType: .analog, number: 6),
                          PinType(signalType: .analog, number: 7),
                          PinType(signalType: .analog, number: 8),
                          PinType(signalType: .analog, number: 9),
                          PinType(signalType: .analog, number: 10),
                          PinType(signalType: .analog, number: 11),
                          PinType(signalType: .digital, number: 2),
                          PinType(signalType: .digital, number: 3),
                          PinType(signalType: .digital, number: 4),
                          PinType(signalType: .digital, number: 5),
                          PinType(signalType: .digital, number: 6),
                          PinType(signalType: .digital, number: 7),
                          PinType(signalType: .digital, number: 8),
                          PinType(signalType: .digital, number: 9),
                          PinType(signalType: .digital, number: 10),
                          PinType(signalType: .digital, number: 11),
                          PinType(signalType: .digital, number: 12),
                          PinType(signalType: .digital, number: 13)]

  /// Returns a string representation of a pin type.
  var string: String {
    var prefix: String
    switch signalType {
    case .analog: prefix = "A"
    case .digital: prefix = "D"
    case .virtual: prefix = "V"
    }
    return prefix + String(number)
  }

}
