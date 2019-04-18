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

import third_party_sciencejournal_ios_ScienceJournalProtos

/// Assembles the packets received from a Science Journal BLE device into sensor data. The sensor
/// sends data in a protobuf format but the data can be spread across multiple packets.
class PacketAssembler {

  var outputData = Data()

  struct DigitalValue {
    static let high = 1023.0
    static let low = 0.0
  }

  var clock = Clock()
  var timeSkew: Int64?

  /// Adds a packet of bytes to be parsed. If the last packet is reached the accumulated bytes
  /// are parsed and returned as a DataPoint.
  ///
  /// - Parameter data: Data streamed from a BLE device.
  func append(_ data: Data) -> DataPoint? {
    let bytes = [UInt8](data)
    // First byte is length of the packet.
    let length = bytes[0]
    // Second byte is a boolean indicating whether this packet is the last in a series of chunks.
    let isLast = bytes[1] == 1
    // Strip off the first two informational bytes.
    var justData = Array(bytes.dropFirst(2))
    outputData.append(&justData, count: Int(length))

    if isLast {
      return parse()
    }

    // Not the last packet, awaiting more data so return nil.
    return nil
  }

  func parse() -> DataPoint? {
    var sensorData: GSJSensorData
    let dataToParse = outputData
    outputData.count = 0
    do {
      sensorData = try GSJSensorData.parse(from: dataToParse)
    } catch {
      print("Failed to parse sensor data: \(error.localizedDescription)")
      return nil
    }

    guard sensorData.resultOneOfCase == .data_p, let data = sensorData.data_p else {
      print("Sensor data missing data.")
      return nil
    }

    guard let sensorPin = data.pin else {
      print("Sensor data missing pin.")
      return nil
    }

    var value: Double

    if sensorPin.pinOneOfCase == .analogPin && data.valueOneOfCase == .analogValue {
      value = Double(data.analogValue.value)
    } else if sensorPin.pinOneOfCase == .digitalPin && data.valueOneOfCase == .digitalValue {
      value = digitalForBool(data.digitalValue.value)
    } else if sensorPin.pinOneOfCase == .virtualPin {

      if data.valueOneOfCase == .floatValue, let floatValue = data.floatValue {
        value = Double(floatValue.value)
      } else if data.valueOneOfCase == .intValue, let intValue = data.intValue {
        value = Double(intValue.value)
      } else {
        // String values are supported by the proto but cannot be used in a meaningful way, so
        // they are considered an unsupported type.
        print("Sensor data has unsupported virtual pin type")
        return nil
      }
    } else {
      print("Sensor data has unknown pin or is missing sensor values")
      return nil
    }

    var timestamp: Int64 = 0
    if sensorData.hasTimestampKey {
      let relativeTime = Int64(sensorData.timestampKey)
      if let timeSkew = timeSkew {
        timestamp = relativeTime + timeSkew
      } else {
        timeSkew = clock.millisecondsSince1970 - relativeTime
        timestamp = relativeTime + timeSkew!
      }
    }

    return DataPoint(x: timestamp, y: value)
  }

  func digitalForBool(_ digitalValue: Bool) -> Double {
    return digitalValue ? DigitalValue.high : DigitalValue.low
  }

}
