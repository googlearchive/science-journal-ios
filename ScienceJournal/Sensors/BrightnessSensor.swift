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
import ImageIO

extension CMSampleBuffer {

  /// Extracts the brightness value from a sample buffer's exif data.
  var exifBrightnessValue: Double? {
    let metadataDict = CMCopyDictionaryOfAttachments(
        allocator: nil,
        target: self,
        attachmentMode: kCMAttachmentMode_ShouldPropagate) as NSDictionary?
    let exifKey = kCGImagePropertyExifDictionary as NSString
    if let exifMetadata = metadataDict?[exifKey] as? NSDictionary {
      let brightnessKey = kCGImagePropertyExifBrightnessValue as NSString
      let brightnessNumber = exifMetadata[brightnessKey] as? NSNumber
      return brightnessNumber?.doubleValue
    }
    return nil
  }

}

/// A sensor that measures brightness using the front-facing camera.
class BrightnessSensor: Sensor, AVCaptureVideoDataOutputSampleBufferDelegate {

  // The front-facing camera.
  private var frontFacingCamera: AVCaptureDevice?

  private let captureSession = AVCaptureSession()
  private var currentBrightness: Double?

  /// Designated initializer.
  ///
  /// - Parameter sensorTimer: The sensor timer to use for this sensor.
  init(sensorTimer: SensorTimer) {
    // TODO: Fix the learn more text and description. http://b/64940813
    let animatingIconView = RelativeScaleAnimationView(iconName: "sensor_light")
    let learnMore = LearnMore(firstParagraph: String.sensorDescFirstParagraphBrightness,
                              secondParagraph: String.sensorDescSecondParagraphBrightness,
                              imageName: "learn_more_light")
    super.init(sensorId: "BrightnessEV",
               name: String.sensorBrightness,
               textDescription: String.sensorDescShortBrightness,
               iconName: "ic_sensor_light",
               animatingIconView: animatingIconView,
               unitDescription: String.brightnessUnits,
               learnMore: learnMore,
               sensorTimer: sensorTimer)
    frontFacingCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                         mediaType: .video,
                                                         position: .front).devices.first
    isSupported = frontFacingCamera != nil
    displaysLoadingState = true

    // Camera capture session manager.
    let captureSessionBeginUsingBlock = { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.state = .loading

      NotificationCenter.default.addObserver(
          strongSelf,
          selector: #selector(strongSelf.captureSessionWasInterrupted(_:)),
          name: .AVCaptureSessionWasInterrupted,
          object: nil)
      NotificationCenter.default.addObserver(
          strongSelf,
          selector: #selector(strongSelf.captureSessionInterruptionEnded(_:)),
          name: .AVCaptureSessionInterruptionEnded,
          object: nil)

      // Configure the capture session in begin using to avoid camera permissions showing at app
      // launch.
      if strongSelf.captureSession.outputs.count == 0 {
        guard let frontFacingCamera = strongSelf.frontFacingCamera,
            let input = try? AVCaptureDeviceInput(device: frontFacingCamera) else {
          strongSelf.state = .noPermission(.userPermissionError(.camera))
          return
        }

        strongSelf.captureSession.beginConfiguration()
        strongSelf.captureSession.addInput(input)
        let output = AVCaptureVideoDataOutput()
        let settingsKey = kCVPixelBufferPixelFormatTypeKey as String
        output.videoSettings = [settingsKey: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: CameraCaptureSessionManager.shared.sessionQueue)
        strongSelf.captureSession.addOutput(output)
        strongSelf.captureSession.commitConfiguration()
      }

      strongSelf.configureFrontCamera()

      if CaptureSessionInterruptionObserver.shared.isCaptureSessionInterrupted {
        strongSelf.state = .interrupted
      } else {
        strongSelf.state = .ready
        strongSelf.captureSession.startRunning()
      }
    }
    let captureSessionEndUsingBlock = { [weak self] in
      guard let strongSelf = self else { return }

      NotificationCenter.default.removeObserver(strongSelf)
      if strongSelf.captureSession.isRunning {
        strongSelf.captureSession.stopRunning()
        strongSelf.state = .paused
      }
    }
    CameraCaptureSessionManager.shared.registerUser(self,
                                                    beginUsingBlock: captureSessionBeginUsingBlock,
                                                    endUsingBlock: captureSessionEndUsingBlock)
  }

  deinit {
    CameraCaptureSessionManager.shared.removeUser(self)
  }

  override func start() {
    if captureSession.isRunning {
      state = .ready
      return
    }

    CameraCaptureSessionManager.shared.beginUsing(withObject: self)
  }

  override func pause() {
    CameraCaptureSessionManager.shared.endUsing(withObject: self)
  }

  override func prepareForBackground() {
    pause()
  }

  override func prepareForForeground() {
    resumeCaptureSessionIfNeeded()
  }

  override func callListenerBlocksWithData(atMilliseconds milliseconds: Int64) {
    guard let currentBrightness = currentBrightness else { return }
    let dataPoint = DataPoint(x: milliseconds, y: currentBrightness)
    DispatchQueue.main.async {
      self.callListenerBlocksWithDataPoint(dataPoint)
    }
  }

  // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

  func captureOutput(_ captureOutput: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    self.currentBrightness = sampleBuffer.exifBrightnessValue
  }

  // MARK: - Private

  // Configure the front-facing camera for brightness sensor use (locked mode).
  private func configureFrontCamera() {
    guard let device = frontFacingCamera else { return }
    do {
      try device.lockForConfiguration()
      device.whiteBalanceMode = .locked
      device.unlockForConfiguration()
    } catch {
      print("[BrightnessSensor] Error locking device for configuration: " +
        "\(error.localizedDescription)")
    }
  }

  private func resumeCaptureSessionIfNeeded() {
    // Only start the brightness sensor if it has listener blocks.
    if listenerBlocks.count > 0 {
      start()
    }
  }

  // MARK: - Notifications

  @objc private func captureSessionWasInterrupted(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionWasInterrupted(notification)
      }
      return
    }

    guard AVCaptureSession.InterruptionReason(notificationUserInfo: notification.userInfo) ==
        .videoDeviceNotAvailableWithMultipleForegroundApps else { return }
    state = .interrupted
  }

  @objc private func captureSessionInterruptionEnded(_ notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.captureSessionInterruptionEnded(notification)
      }
      return
    }

    resumeCaptureSessionIfNeeded()
  }

}
