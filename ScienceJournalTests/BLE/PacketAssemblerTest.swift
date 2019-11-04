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

import XCTest

@testable import third_party_sciencejournal_ios_ScienceJournalOpen
@testable import third_party_sciencejournal_ios_ScienceJournalProtos

class PacketAssemblerTest: XCTestCase {

  var packetAssembler: PacketAssembler!
  var dataPoints = [DataPoint]()

  // Setting clock to 42 so we can test the time skew.
  var testClock = SettableClock(now: 42)

  let largeTestValue: UInt32 = 314159
  let smallTestValue: UInt32 = 1

  let floatTestValue: Float = 10.0
  let intTestValue: Int32 = 20
  let digitalTestValue = false
  let analogTestValue: UInt32 = 30
  let stringTestValue = "Test"

  let packetStream = [5, 10, 15, 20, 25, 30]

  override func setUp() {
    super.setUp()
    packetAssembler = PacketAssembler()
    packetAssembler.clock = testClock
  }

  override func tearDown() {
    packetAssembler = nil
    dataPoints.removeAll()
    super.tearDown()
  }

  func testSinglePacket() {
    let builder = SensorDataBuilder()
    builder.analogValue = smallTestValue
    builder.addAnalogPin()

    // Test a chunk size that is larger than data length so there is only one data frame.
    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(1, dataPoints.count)

    XCTAssertEqual(Double(smallTestValue), dataPoints[0].y)
    XCTAssertEqual(42, dataPoints[0].x)
  }

  func testMultiPacket() {
    let builder = SensorDataBuilder()
    builder.analogValue = largeTestValue
    builder.addAnalogPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: true,
                         expectedPacketCount: 2)

    XCTAssertEqual(1, dataPoints.count)

    XCTAssertEqual(Double(largeTestValue), dataPoints[0].y)
    XCTAssertEqual(42, dataPoints[0].x)
  }

  func testFloatValuePacket() {
    let builder = SensorDataBuilder()
    builder.floatValue = floatTestValue
    builder.addVirtualPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(1, dataPoints.count)

    XCTAssertEqual(Double(floatTestValue), dataPoints[0].y)
    XCTAssertEqual(42, dataPoints[0].x)
  }

  func testIntValuePacket() {
    let builder = SensorDataBuilder()
    builder.intValue = intTestValue
    builder.addVirtualPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(1, dataPoints.count)

    XCTAssertEqual(Double(intTestValue), dataPoints[0].y)
    XCTAssertEqual(42, dataPoints[0].x)
  }

  func testAnalogValuePacket() {
    let builder = SensorDataBuilder()
    builder.analogValue = analogTestValue
    builder.addAnalogPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(1, dataPoints.count)
    XCTAssertEqual(Double(analogTestValue), dataPoints[0].y)
    XCTAssertEqual(42, dataPoints[0].x)
  }

  func testDigitalValuePacket() {
    let builder = SensorDataBuilder()
    builder.digitalValue = digitalTestValue
    builder.addDigitalPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(1, dataPoints.count)
    XCTAssertEqual(packetAssembler.digitalForBool(digitalTestValue), dataPoints[0].y)
    XCTAssertEqual(42, dataPoints[0].x)
  }

  func testStringValuePacket() {
    let builder = SensorDataBuilder()
    builder.stringValue = stringTestValue
    builder.addVirtualPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    // Strings are not supported, so they should not parse.
    XCTAssertEqual(0, dataPoints.count)
  }

  func testMismatchValuePinPacket() {
    let builder = SensorDataBuilder()
    builder.floatValue = floatTestValue
    builder.addAnalogPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(0, dataPoints.count)
  }

  func testMissingValuePacket() {
    let builder = SensorDataBuilder()
    builder.addAnalogPin()

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(0, dataPoints.count)
  }

  func testMissingPinPacket() {
    let builder = SensorDataBuilder()
    builder.analogValue = analogTestValue

    fakeFramedSensorData(packetAssembler: packetAssembler,
                         sensorData: builder.sensorData,
                         chunked: false,
                         expectedPacketCount: 1)

    XCTAssertEqual(0, dataPoints.count)
  }

  func testPacketStream() {
    for packet in packetStream {
      let builder = SensorDataBuilder()
      builder.analogValue = UInt32(packet)
      builder.addAnalogPin()
      // For easy verification, set the timestamp to the packet value.
      builder.timestamp = UInt32(packet)

      fakeFramedSensorData(packetAssembler: packetAssembler,
                           sensorData: builder.sensorData,
                           chunked: false,
                           expectedPacketCount: 1)
    }

    XCTAssertEqual(packetStream.count, dataPoints.count)

    let expectedTimeSkew = 42 - packetStream[0]

    var index = 0
    for point in dataPoints {
      let packet = packetStream[index]
      XCTAssertEqual(Double(packet), point.y)
      XCTAssertEqual(Int64(packet + expectedTimeSkew), point.x)
      index += 1
    }
  }

  func testMultiPacketStream() {
    for packet in packetStream {
      let builder = SensorDataBuilder()
      builder.analogValue = UInt32(packet)
      builder.addAnalogPin()
      // For easy verification, set the timestamp to the packet value.
      builder.timestamp = UInt32(packet)

      fakeFramedSensorData(packetAssembler: packetAssembler,
                           sensorData: builder.sensorData,
                           chunked: true,
                           expectedPacketCount: 1)
    }

    XCTAssertEqual(packetStream.count, dataPoints.count)

    let expectedTimeSkew = 42 - packetStream[0]

    var index = 0
    for point in dataPoints {
      let packet = packetStream[index]
      XCTAssertEqual(Double(packet), point.y)
      XCTAssertEqual(Int64(packet + expectedTimeSkew), point.x)
      index += 1
    }
  }

  // MARK: - Helpers

  func fakeFramedSensorData(packetAssembler: PacketAssembler,
                            sensorData: GSJSensorData,
                            chunked isChunked: Bool,
                            expectedPacketCount: Int) {
    guard let protoData = sensorData.data() else {
      XCTAssert(false, "Failed to get data from sensor data proto.")
      return
    }

    let bytes = [UInt8](protoData)
    let chunkSize = UInt8(isChunked ? bytes.count - 1 : bytes.count + 1)

    let potentialLength = Int(exactly: ceil(Double(bytes.count) / Double(chunkSize)))
    guard let length = potentialLength else {
      return
    }

    var start = 0
    for index in 0..<length {
      var outputBytes = [UInt8]()
      let last = index == length - 1
      var l: UInt8 = chunkSize
      if last {
        l = UInt8(bytes.count) % chunkSize
      }
      outputBytes.append(l)
      let lastBit: UInt8 = last ? 1 : 0
      outputBytes.append(lastBit)
      for _ in 0..<l {
        let nextBit = bytes[start]
        outputBytes.append(nextBit)
        start += 1
      }
      let data = Data(outputBytes)
      if let dataPoint = packetAssembler.append(data) {
        self.dataPoints.append(dataPoint)
      }
    }
  }

  // MARK: - SensorDataBuilder

  class SensorDataBuilder {
    let sensorData = GSJSensorData()

    var analogValue: UInt32? {
      get {
        return sensorData.data_p.analogValue.value
      }
      set {
        guard let newValue = newValue else {
          sensorData.data_p.analogValue = nil
          return
        }
        sensorData.data_p.analogValue = GSJAnalogValue()
        sensorData.data_p.analogValue.value = newValue
      }
    }

    var digitalValue: Bool? {
      get {
        return sensorData.data_p.digitalValue.value
      }
      set {
        guard let newValue = newValue else {
          sensorData.data_p.digitalValue = nil
          return
        }
        sensorData.data_p.digitalValue = GSJDigitalValue()
        sensorData.data_p.digitalValue.value = newValue
      }
    }

    var floatValue: Float? {
      get {
        return sensorData.data_p.floatValue.value
      }
      set {
        guard let newValue = newValue else {
          sensorData.data_p.floatValue = nil
          return
        }
        sensorData.data_p.floatValue = GSJFloatValue()
        sensorData.data_p.floatValue.value = newValue
      }
    }

    var intValue: Int32? {
      get {
        return sensorData.data_p.intValue.value
      }
      set {
        guard let newValue = newValue else {
          sensorData.data_p.intValue = nil
          return
        }
        sensorData.data_p.intValue = GSJIntValue()
        sensorData.data_p.intValue.value = newValue
      }
    }

    var stringValue: String? {
      get {
        return sensorData.data_p.stringValue.value
      }
      set {
        guard let newValue = newValue else {
          sensorData.data_p.stringValue = nil
          return
        }
        sensorData.data_p.stringValue = GSJStringValue()
        sensorData.data_p.stringValue.value = newValue
      }
    }

    var timestamp: UInt32 {
      get {
        return sensorData.timestampKey
      }
      set {
        sensorData.timestampKey = newValue
      }
    }

    init() {
      sensorData.timestampKey = 0
      sensorData.data_p = GSJData()
      sensorData.data_p.pin = GSJPin()
    }

    func addAnalogPin() {
      sensorData.data_p.pin = GSJPin()
      sensorData.data_p.pin.analogPin = GSJAnalogPin()
      sensorData.data_p.pin.analogPin.pin = 1
    }

    func addDigitalPin() {
      sensorData.data_p.pin = GSJPin()
      sensorData.data_p.pin.digitalPin = GSJDigitalPin()
      sensorData.data_p.pin.digitalPin.pin = 1
    }

    func addVirtualPin() {
      sensorData.data_p.pin = GSJPin()
      sensorData.data_p.pin.virtualPin = GSJVirtualPin()
      sensorData.data_p.pin.virtualPin.pin = 1
    }
  }

}
