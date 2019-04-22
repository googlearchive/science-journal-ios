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

/// A sensor that measures the pitch of the sound reaching the microphone.
final class PitchSensor: AudioSensor {

  // MARK: - Properties
  static let ID = "PitchSensor"

  private var lastPitchCalculated: Double? {
    didSet {
      // Whenever the last pitch is set (including to nil), set the same value to the next pitch to
      // report.
      nextPitchToReport = lastPitchCalculated
    }
  }

  // The value used when calling listeners with data.
  private var nextPitchToReport: Double?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - audioCapture: The audio capture to use for measuring sound.
  ///   - sensorTimer: The sensor timer to use for this sensor.
  init(audioCapture: AudioCapture, sensorTimer: SensorTimer) {
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphPitch,
                              secondParagraph: String.sensorDescSecondParagraphPitch,
                              imageName: "learn_more_audio")
    super.init(sensorId: PitchSensor.ID,
               name: String.pitch,
               textDescription: String.sensorDescShortPitch,
               iconName: "ic_sensor_sound_frequency",
               animatingIconView: PitchSensorAnimationView(),
               unitDescription: String.hertzUnits,
               learnMore: learnMore,
               audioCapture: audioCapture,
               sensorTimer: sensorTimer)
  }

  override func start() {
    super.start()

    // Use the current sample rate.
    let audioAnalyzer = AudioAnalyzer(sampleRateInHz: AudioSession.shared.sampleRate)

    var audioAnalyzerBuffer = [Int16]()
    setSampleBufferUpdateBlock { (audioSampleBuffer) in
      var audioSampleBufferOffset = 0
      while audioSampleBufferOffset < audioSampleBuffer.count {
        // Fill the audio analyzer buffer from `audioSampleBuffer`.
        let lengthToCopy = min(audioSampleBuffer.count - audioSampleBufferOffset,
                               AudioAnalyzer.bufferSize - audioAnalyzerBuffer.count)
        let rangeToCopy = audioSampleBufferOffset...audioSampleBufferOffset + (lengthToCopy - 1)
        audioAnalyzerBuffer += audioSampleBuffer[rangeToCopy]
        audioSampleBufferOffset += lengthToCopy

        // If audioAnalyzerBuffer is full, analyze it.
        if audioAnalyzerBuffer.count == AudioAnalyzer.bufferSize {
          if let frequency =
              audioAnalyzer.detectFundamentalFrequency(samples: audioAnalyzerBuffer) {
            var shouldSkipFrequency: Bool {
              guard let lastPitchCalculated = self.lastPitchCalculated else {
                return false

              }
              // Avoid drastic changes that show as spikes in the graph between notes being played
              // on an instrument. If the new value is more than 50% different from the previous
              // value, skip it.
              return abs(frequency - lastPitchCalculated) / lastPitchCalculated > 0.5
            }
            self.lastPitchCalculated = shouldSkipFrequency ? nil : frequency
          } else {
            // If a frequency is not detected, the sound could have been too quiet. Report this as
            // 0.
            self.lastPitchCalculated = 0
          }
          // After analyzing that buffer, empty it.
          audioAnalyzerBuffer.removeAll()
        }
      }
    }
  }

  override func pause() {
    super.pause()
    removeSampleBufferUpdateBlock()
  }

  // swiftlint:disable vertical_parameter_alignment
  override func callListenerBlocksWithAudioSampleBuffer(_
    audioSampleBuffer: UnsafeBufferPointer<Int16>, atMilliseconds milliseconds: Int64) {
    guard let pitch = nextPitchToReport else { return }
    let dataPoint = DataPoint(x: milliseconds, y: pitch)
    callListenerBlocksWithDataPoint(dataPoint)
  }
  // swiftlint:enable vertical_parameter_alignment

}
