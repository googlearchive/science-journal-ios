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

/// A sensor that measures the intensity of sound reaching the microphone.
class SoundIntensitySensor: AudioSensor {

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - audioCapture: The audio capture to use for measuring sound.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(audioCapture: AudioCapture, sensorTimer: SensorTimer) {
    let animatingIconView = RelativeScaleAnimationView(iconName: "sensor_audio")
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphDecibel,
                              secondParagraph: String.sensorDescSecondParagraphDecibel,
                              imageName: "learn_more_audio")
    super.init(sensorId: "DecibelSource",
               name: String.decibel,
               textDescription: String.sensorDescShortDecibel,
               iconName: "ic_sensor_audio",
               animatingIconView: animatingIconView,
               unitDescription: String.decibelUnits,
               learnMore: learnMore,
               audioCapture: audioCapture,
               sensorTimer: sensorTimer)
  }

  override func callListenerBlocksWithAudioSampleBuffer(_
      audioSampleBuffer: UnsafeBufferPointer<Int16>,
      atMilliseconds milliseconds: Int64) {
    // Calculate decibel level. Also, capture the sample count separately to avoid a potential
    // divide by zero crash if something were to happen to the unsafe buffer.
    var totalSquared: Int64 = 0
    var count: Int64 = 0
    for sample in audioSampleBuffer {
      totalSquared += Int64(sample) * Int64(sample)
      count += 1
    }

    guard count > 0 else { return }
    let quadraticMeanPressure = sqrt(Double(totalSquared / count))

    // Ensure that the quadratic mean pressure is not zero, which would result in an infinite
    // decibel level value.
    guard quadraticMeanPressure > 0 else { return }

    let decibelLevel = 20 * log10(quadraticMeanPressure)

    let dataPoint = DataPoint(x: milliseconds, y: decibelLevel)
    callListenerBlocksWithDataPoint(dataPoint)
  }

}

