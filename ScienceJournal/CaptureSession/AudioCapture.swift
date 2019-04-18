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

/// Captures audio from the microphone, and makes the audio buffer samples available to sensors.
class AudioCapture: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {

  /// The function type for sample buffer update blocks.
  typealias SampleBufferUpdateBlock = (UnsafeBufferPointer<Int16>) -> Void

  // MARK: - Properties

  /// Whether or not audio capture is supported.
  var isSupported: Bool {
    // Audio capture is supported if the device has a microphone.
    return microphone != nil
  }

  /// The last audio sample buffer. Cleared out when stop is called.
  var lastAudioSampleBuffer: UnsafeBufferPointer<Int16>? {
    didSet {
      guard let sampleBufferUpdateBlock = sampleBufferUpdateBlock,
          let lastAudioSampleBuffer = lastAudioSampleBuffer else { return }
      sampleBufferUpdateBlock(lastAudioSampleBuffer)
    }
  }

  var isInterrupted: Bool {
    return captureSession.isInterrupted
  }

  private let captureSession = AVCaptureSession()
  private let microphone = AVCaptureDevice.default(for: .audio)
  private var sampleBufferUpdateBlock: SampleBufferUpdateBlock?
  private let sessionQueue = DispatchQueue(label: "com.google.ScienceJournal.AudioCapture")

  // Tracks whether or not to start the capture session when receiving an audio session interruption
  // ended notification. This will be set to true when receiving a balanced audio session
  // interruption began notification.
  private var shouldResumeAfterInterruption = false

  // Tracks objects using the audio capture's session. When the count of this collection goes from 0
  // to 1, the capture session will be started. The capture session will be stopped when it reaches
  // 0.
  private let usageTracker = UsageTracker()

  // MARK: - Public

  override init() {
    super.init()

    let audioDataOutput = AVCaptureAudioDataOutput()
    audioDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    captureSession.beginConfiguration()
    captureSession.automaticallyConfiguresApplicationAudioSession = false
    captureSession.addOutput(audioDataOutput)
    captureSession.commitConfiguration()

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(captureSessionWasInterrupted(_:)),
                                           name: .AVCaptureSessionWasInterrupted,
                                           object: nil)
  }

  /// Prepares the audio capture to run, checks for microphone permission, and starts running the
  /// audio capture if it has microphone permission. After calling start, it must be balanced with a
  /// call to endUsing when finished using the audio capture.
  ///
  /// - Parameter completion:
  /// - Parameters:
  ///   - user: The object that will be using the audio capture.
  ///   - completion: Called when the audio capture has finished preparing and is running if it has
  ///                 microphone permission. If it does not have microphone permission, this block
  ///                 is called after the check for permission. This block is called on a private
  ///                 queue, and includes a Bool indicating whether or not there is permission
  ///                 granted to use the microphone.
  func beginUsing(_ user: AnyObject,
                  completion: @escaping (_ hasMicrophonePermission: Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission { micPermissionGranted in
      self.sessionQueue.async {
        guard micPermissionGranted,
            let microphone = self.microphone,
            let input = try? AVCaptureDeviceInput(device: microphone) else {
          completion(false)
          return
        }

        if self.captureSession.canAddInput(input) {
          self.captureSession.beginConfiguration()
          self.captureSession.addInput(input)
          self.captureSession.commitConfiguration()
        }

        if self.usageTracker.addUser(user) {
          self.startCaptureSession()
        }
        completion(true)
      }
    }
  }

  /// Stops running the audio capture.
  ///
  /// - Parameter user: The object that has ended using the audio capture.
  func endUsing(_ user: AnyObject) {
    sessionQueue.async {
      if self.usageTracker.removeUser(user) {
        self.stopCaptureSession()
      }
    }
  }

  /// Sets a block that is called with the last audio sample buffer, each time it is updated.
  ///
  /// - Parameter sampleBufferUpdateBlock: The block that is called.
  func setSampleBufferUpdateBlock(_ sampleBufferUpdateBlock: SampleBufferUpdateBlock?) {
    self.sampleBufferUpdateBlock = sampleBufferUpdateBlock
  }

  // MARK: - Private

  // This should be called from `sessionQueue`.
  private func startCaptureSession() {
    AudioSession.shared.startUsing()
    captureSession.startRunning()
  }

  // This should be called from `sessionQueue`.
  private func stopCaptureSession() {
    captureSession.stopRunning()
    AudioSession.shared.endUsing()
    lastAudioSampleBuffer = nil
  }

  // MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

  func captureOutput(_ captureOutput: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    var blockBuffer: CMBlockBuffer?
    let audioBufferList = AudioBufferList.allocate(maximumBuffers: 1)
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
      sampleBuffer,
      bufferListSizeNeededOut: nil,
      bufferListOut: audioBufferList.unsafeMutablePointer,
      bufferListSize: MemoryLayout<AudioBufferList>.size,
      blockBufferAllocator: nil,
      blockBufferMemoryAllocator: nil,
      flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
      blockBufferOut: &blockBuffer
    )
    guard blockBuffer != nil, let audioBuffer = audioBufferList.first else { return }
    let audioSampleBuffer = UnsafeBufferPointer<Int16>(audioBuffer)
    guard audioSampleBuffer.count > 0 else { return }
    lastAudioSampleBuffer = audioSampleBuffer
  }

  // MARK: - Notifications

  @objc private func captureSessionWasInterrupted(_ notification: Notification) {
    // When the capture session is interrupted, the buffer does not finish and cannot be iterated.
    lastAudioSampleBuffer = nil
  }

}
