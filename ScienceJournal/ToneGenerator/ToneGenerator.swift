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

import AVFoundation
import Foundation

/// Generates tones at a specified frequency.
class ToneGenerator {

  /// Schedules and plays tones for ToneGenerator.
  fileprivate class TonePlayerNode: AVAudioPlayerNode {

    // MARK: Properties

    /// The audio format.
    fileprivate let audioFormat: AVAudioFormat?

    /// The current frequency of the tone generator.
    fileprivate var frequency = 0.0

    /// Whether or not the tone is audible.
    fileprivate var isAudible: Bool = true {
      didSet {
        amplitude = isAudible ? maxAmplitude : minAmplitude
      }
    }

    /// The sample rate of the audio.
    private let sampleRate = 44100.0
    /// The curve of the audio wave.
    private var theta = 0.0
    /// The number of samples per buffer.
    private let samplesPerBuffer: AVAudioFrameCount = 512
    /// The number of audio buffers to schedule.
    /// Having more than one allows one to be played while the next is being filled.
    private let numberOfBuffers = 4
    /// The amplitude of the audio wave. 0.25 provides a reasonable volume.
    private var amplitude = 0.25
    /// The maximum amplitude of the tone generator.
    private var maxAmplitude = 0.25
    /// The minimum amplitude of the tone generator.
    private var minAmplitude = 0.0
    /// The private queue for scheduling the buffer.
    private let bufferQueue: DispatchQueue

    // MARK: - File Private

    fileprivate init(bufferQueue: DispatchQueue) {
      self.bufferQueue = bufferQueue
      audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
      super.init()
    }

    /// Prepares to play a tone by scheduling audio buffers.
    fileprivate func prepare() {
      for _ in 0..<numberOfBuffers {
        scheduleToneBuffer()
      }
    }

    // MARK: - Private

    /// Fills the buffer with the specified tone.
    ///
    /// - Parameter buffer: An audio buffer.
    private func fillBuffer(_ buffer: AVAudioPCMBuffer) {
      // TODO: Fix popping sound when silencing audio.
      buffer.frameLength = buffer.frameCapacity
      for frame in 0..<Int(buffer.frameLength) {
        buffer.floatChannelData?[0][frame] = Float32(sin(theta) * amplitude)
        theta += 2.0 * .pi * frequency / sampleRate
        if theta > 2.0 * .pi {
          theta -= 2.0 * .pi
        }
      }
    }

    /// Schedules a tone audio buffer.
    private func scheduleToneBuffer() {
      guard let audioFormat = audioFormat,
          let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat,
                                        frameCapacity: samplesPerBuffer) else {
        print("[TonePlayerNode] Error: Cannot create valid buffer.")
        return
      }

      fillBuffer(buffer)
      scheduleBuffer(buffer) {
        // Once the buffer is comsumed by the player, if we're still playing, schedule another tone
        // audio buffer.
        self.bufferQueue.async { [weak self] in
          guard let strongSelf = self else { return }
          if strongSelf.isPlaying {
            strongSelf.scheduleToneBuffer()
          }
        }
      }
    }
  }

  // MARK: - Tone Generator

  // MARK: - Properties

  /// The sound type of the tone generator.
  var soundType: SoundType = DefaultSoundType()

  /// Whether or not a tone is playing.
  var isPlayingTone: Bool {
    guard let tonePlayerNode = tonePlayerNode else { return false }
    return tonePlayerNode.isPlaying
  }

  /// The tone node.
  private var tonePlayerNode: TonePlayerNode?
  /// The engine that processes tone nodes.
  private var engine: AVAudioEngine?
  /// A timer used to create an animated tone to the `nextFrequency`.
  private var frequencyChangeTimer: Timer?
  /// The frequency the tone generator is starting from when animating to the `nextFrequency`.
  private var startFrequency: Double?
  /// The timestamp when the tone generator started animating to the `nextFrequency`.
  private var frequencyChangeStartTime: Int64?
  /// The amount of time (ms) to spend animating to the `nextFrequency`.
  private let frequencyChangeDuration: Int64 = 100
  /// Whether or not to resume after an interuption.
  private var resumeAfterInteruption = false
  /// Private queue to handle all audio engine activity.
  private let sessionQueue =
      DispatchQueue(label: "com.google.ScienceJournal.ToneGenerator")

  /// Block called when the tone generator starts or stops playing. Could be due to a user action,
  /// route change or interruption. It is called with true if the tone generator is playing a tone,
  /// otherwise false.
  private var playingStateUpdateBlock: ((Bool) -> Void)?

  /// The frequency the tone generator should animate to if the `soundType`
  /// `shouldAnimateToNextFrequency`, otherwise it sets the `tonePlayerNode`'s `frequency`
  /// instantly.
  private var nextFrequency = 0.0 {
    didSet {
      guard let tonePlayerNode = tonePlayerNode else { return }
      if soundType.shouldAnimateToNextFrequency {
        frequencyChangeTimer?.invalidate()
        startFrequency = tonePlayerNode.frequency
        frequencyChangeStartTime = Date().millisecondsSince1970
        frequencyChangeTimer = Timer.scheduledTimer(timeInterval: 0.0001,
                                                    target: self,
                                                    selector: #selector(frequencyChangeTimerFired),
                                                    userInfo: nil,
                                                    repeats: true)
        // Allows the timer to fire while scroll views are tracking.
        RunLoop.main.add(frequencyChangeTimer!, forMode: .common)
      } else {
        tonePlayerNode.frequency = nextFrequency
      }
    }
  }

  // MARK: - Public

  /// Plays a tone for `value` at a frequency relative to `valueMin` and `valueMax`. Audio will not
  /// be heard until `start()` is called.
  ///
  /// - Parameters:
  ///   - value: The value to play a tone for.
  ///   - valueMin: The minimum value, which represents the lowest frequency tone.
  ///   - valueMax: The maximum value, which represents the highest frequency tone.
  ///   - timestamp: The timestamp of the value to play a tone for.
  func setToneFrequency(for value: Double,
                        valueMin: Double,
                        valueMax: Double,
                        atTimestamp timestamp: Int64) {
    guard value.isFinite && valueMin.isFinite && valueMax.isFinite &&
        !value.isNaN && !valueMin.isNaN && !valueMax.isNaN else {
      return
    }

    guard isPlayingTone, let tonePlayerNode = tonePlayerNode else { return }

    let value = max(min(value, valueMax), valueMin)
    let frequency = soundType.frequency(from: value,
                                        valueMin: valueMin,
                                        valueMax: valueMax,
                                        timestamp: timestamp)
    if let frequency = frequency {
      nextFrequency = frequency
      tonePlayerNode.isAudible = true
    } else {
      tonePlayerNode.isAudible = false
    }
  }

  /// Starts playing a tone.
  func start() {
    guard !isPlayingTone else { return }

    sessionQueue.async { [weak self] in
      guard let strongSelf = self else { return }
      let success = strongSelf.setupTonePlayerNode()
      if success {
        strongSelf.tonePlayerNode?.play()
        DispatchQueue.main.async {
          strongSelf.playingStateUpdateBlock?(true)
        }
      }
    }
  }

  /// Stops playing a tone.
  func stop() {
    guard isPlayingTone else { return }
    frequencyChangeTimer?.invalidate()
    sessionQueue.async { [weak self] in
      self?.tonePlayerNode?.stop()
      self?.destroyTonePlayerNode()
      DispatchQueue.main.async {
        self?.playingStateUpdateBlock?(false)
      }
    }
  }

  /// Called immediately and when the tone generator starts or stops playing. Could be due to a user
  /// action, route change or interruption.
  ///
  /// - Parameter block: Called with true if the tone generator is playing a tone, otherwise false.
  func setPlayingStateUpdateBlock(_ block: ((Bool) -> Void)?) {
    block?(isPlayingTone)
    playingStateUpdateBlock = block
  }

  // MARK: - Private

  /// Sets up the engine and tone player node, preparing to play tones.
  ///
  /// Returns: True if setup is successful, otherwise false.
  private func setupTonePlayerNode() -> Bool {
    AudioSession.shared.startUsing()

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(audioSessionInterruptionNotification(_:)),
        name: AVAudioSession.interruptionNotification,
        object: nil)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(audioSessionRouteChangeNotification(_:)),
        name: AVAudioSession.routeChangeNotification,
        object: nil)

    let tonePlayerNode = TonePlayerNode(bufferQueue: sessionQueue)
    self.tonePlayerNode = tonePlayerNode
    let engine = AVAudioEngine()
    self.engine = engine
    engine.attach(tonePlayerNode)
    let mixer = engine.mainMixerNode
    mixer.outputVolume = 1
    engine.connect(tonePlayerNode, to: mixer, format: tonePlayerNode.audioFormat)
    do {
      try engine.start()
      tonePlayerNode.prepare()
      return true
    } catch {
      print("[ToneGenerator] Error when connecting tone player node to the engine: " +
          "\(error.localizedDescription)")
      return false
    }
  }

  // Destroys the engine and tone player node, so it does not remain in memory after playing tones.
  private func destroyTonePlayerNode() {
    tonePlayerNode = nil
    engine = nil
    AudioSession.shared.endUsing()

    // swiftlint:disable notification_center_detachment
    NotificationCenter.default.removeObserver(self)
    // swiftlint:enable notification_center_detachment
  }

  @objc private func frequencyChangeTimerFired() {
    guard let frequencyChangeStartTime = frequencyChangeStartTime,
        let startFrequency = startFrequency,
        let tonePlayerNode = tonePlayerNode else { return }

    let timeSinceFrequencyChangeStart = Date().millisecondsSince1970 - frequencyChangeStartTime
    guard timeSinceFrequencyChangeStart < frequencyChangeDuration else {
      tonePlayerNode.frequency = nextFrequency
      frequencyChangeTimer?.invalidate()
      frequencyChangeTimer = nil
      return
    }

    // Add the ratio of time spent so far to the entire animation duration * change in frequency to
    // the starting frequency.
    tonePlayerNode.frequency = startFrequency +
        (Double(timeSinceFrequencyChangeStart) / Double(frequencyChangeDuration)) *
        (nextFrequency - startFrequency)
  }

  // Stops the engine and tone player node, cretes a new tone player node, connects it and restarts
  // everything.
  private func handleRouteChange() {
    guard let engine = engine else { return }

    if let tonePlayerNode = self.tonePlayerNode {
      tonePlayerNode.stop()
      engine.stop()
      engine.disconnectNodeInput(tonePlayerNode)
      engine.detach(tonePlayerNode)
    }

    let tonePlayerNode = TonePlayerNode(bufferQueue: sessionQueue)
    self.tonePlayerNode = tonePlayerNode
    engine.attach(tonePlayerNode)
    engine.connect(tonePlayerNode, to: engine.mainMixerNode, format: tonePlayerNode.audioFormat)
    do {
      try engine.start()
      tonePlayerNode.prepare()
      tonePlayerNode.play()
    } catch {
      print("[ToneGenerator] Error when connecting tone player node to the engine during route " +
          "change: \(error.localizedDescription)")
    }
  }

  // MARK: - Notifications

  @objc private func audioSessionInterruptionNotification(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.audioSessionInterruptionNotification(notification)
      }
      return
    }

    guard let userInfo = notification.userInfo,
        let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
        let interruptionType =
            AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else { return }

    if interruptionType == .began {
      resumeAfterInteruption = true
      stop()
    } else if interruptionType == .ended {
      guard let interruptionOptionValue =
          userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
      let interruptionOptions =
          AVAudioSession.InterruptionOptions(rawValue: interruptionOptionValue)
      if interruptionOptions.contains(.shouldResume) {
        if resumeAfterInteruption {
          start()
        }
        resumeAfterInteruption = false
      }
    }
  }

  @objc private func audioSessionRouteChangeNotification(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.audioSessionRouteChangeNotification(notification)
      }
      return
    }

    guard let reason = AVAudioSession.RouteChangeReason(notificationUserInfo: notification.userInfo)
        else { return }
    if reason == .newDeviceAvailable || reason == .oldDeviceUnavailable {
      sessionQueue.async {
        self.handleRouteChange()
      }
    }
  }

}
