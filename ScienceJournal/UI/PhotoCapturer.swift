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
import ImageIO
import UIKit

/// Extends for access to the video orientation for a device orientation.
extension AVCaptureVideoOrientation {

  /// The video orientation for a device orientation.
  ///
  /// Note: `.faceUp` and `.faceDown` will return nil, so that the video can retain its previous
  /// orientation.
  ///
  /// - Parameter deviceOrientation: The device orientation.
  /// - Returns: The video orientation.
  static func orientation(from deviceOrientation: UIDeviceOrientation) ->
      AVCaptureVideoOrientation? {
    switch deviceOrientation {
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    case .portrait:
      return .portrait
    case .portraitUpsideDown:
      return .portraitUpsideDown
    default:
      return nil
    }
  }

}

protocol PhotoCapturerDelegate: class {
  /// Informs the delegate the camera permissions changed.
  func photoCapturerCameraPermissionsDidChange(accessGranted: Bool)

  /// Informs the delegate the capture session began.
  func photoCapturerCaptureSessionDidBegin()

  /// Informs the delegate the capture session will end.
  func photoCapturerCaptureSessionWillEnd()

  /// Informs the delegate a photo was captured.
  ///
  /// - Parameters:
  ///   - photoData: The photo data or nil if there was a problem.
  ///   - metadata: The metadata or nil if there was a problem.
  func photoCapturerDidCapturePhotoData(_ photoData: Data?, metadata: NSDictionary?)
}

/// Sets up a capture session for the device cameras and allows what is captured to be shown on
/// screen with a preview layer.
class PhotoCapturer: NSObject, AVCapturePhotoCaptureDelegate {

  enum Camera {
    case back
    case front
  }

  // MARK: - Properties

  /// The photo capturer delegate.
  weak var delegate: PhotoCapturerDelegate?

  /// The capture session.
  private let captureSession = AVCaptureSession()

  /// The photo output.
  private let photoOutput = AVCapturePhotoOutput()

  /// The back camera.
  private var backCamera: AVCaptureDevice?

  /// The front camera.
  private var frontCamera: AVCaptureDevice?

  /// The photo preview layer.
  let previewLayer: AVCaptureVideoPreviewLayer

  /// Current capture device position, used when rotating images since front-facing cameras are
  /// mirrored.
  private var currentCameraPosition: AVCaptureDevice.Position?

  /// The permissions state of the capturer.
  var isCameraPermissionGranted: Bool {
    let granted = CameraAccessHandler.checkForPermission { (permission) in
      self.delegate?.photoCapturerCameraPermissionsDidChange(accessGranted: permission)
    }
    return granted
  }

  /// Switches to a camera.
  var camera: Camera = .back {
    didSet {
      guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput,
          let captureDevice = captureDevice(for: camera) else { return }
      captureSession.removeInput(currentInput)
      do {
        let captureInput = try AVCaptureDeviceInput(device: captureDevice)
        captureSession.beginConfiguration()
        captureSession.addInput(captureInput)
        captureSession.commitConfiguration()
      } catch {
        print("Can't access camera \(error.localizedDescription)")
      }
    }
  }

  private var shouldCropCapturedPhoto = false

  // MARK: - Public

  override init() {
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill

    super.init()

    backCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                  mediaType: .video,
                                                  position: .back).devices.first
    frontCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                   mediaType: .video,
                                                   position: .front).devices.first
    currentCameraPosition = backCamera?.position
    configureSession(with: backCamera)

    CameraCaptureSessionManager.shared.registerUser(self,
                                                    beginUsingBlock: { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.captureSession.startRunning()
      strongSelf.delegate?.photoCapturerCaptureSessionDidBegin()
    },
                                                    endUsingBlock: { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.delegate?.photoCapturerCaptureSessionWillEnd()
      strongSelf.captureSession.stopRunning()
    })
  }

  /// Toggles between the front and back camera.
  func toggleCamera() {
    switch camera {
    case .back:
      camera = .front
      currentCameraPosition = .front
      configureFrontFacingCameraIfNecessary()
    case .front:
      camera = .back
      currentCameraPosition = .back
    }
  }

  deinit {
    delegate?.photoCapturerCaptureSessionWillEnd()
    CameraCaptureSessionManager.shared.removeUser(self)
  }

  /// Configures the front-facing camera to use auto settings, if it exists and is the current
  /// camera position.
  func configureFrontFacingCameraIfNecessary() {
    guard let device = frontCamera, camera == .front else { return }
    CameraCaptureSessionManager.shared.sessionQueue.async {
      do {
        try device.lockForConfiguration()
        device.whiteBalanceMode = .continuousAutoWhiteBalance
        device.exposureMode = .continuousAutoExposure
        device.unlockForConfiguration()
      } catch {
        print("[PhotoCapturer] Error locking device for configuration: " +
            "\(error.localizedDescription)")
      }
    }
  }

  /// Sets the preview layer's video orientation, based on the device orientation.
  ///
  /// - Parameter orientation: The device orientation.
  func setPreviewOrientation(from interfaceOrientation: UIDeviceOrientation) {
    guard let videoOrientation =
        AVCaptureVideoOrientation.orientation(from: interfaceOrientation) else { return }
    previewLayer.connection?.videoOrientation = videoOrientation
  }

  /// Captures the current image as data and calls the delegate when complete.
  func captureImageData(isCropping: Bool) {
    shouldCropCapturedPhoto = isCropping
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  /// Start the photo capture session if it is not running.
  func startCaptureSessionIfNecessary() {
    guard CaptureSessionInterruptionObserver.shared.isCameraUseAllowed else { return }
    CameraCaptureSessionManager.shared.sessionQueue.async {
      if !self.captureSession.isRunning {
        CameraCaptureSessionManager.shared.beginUsing(withObject: self)
      }
    }
  }

  /// Stops the current capture session if it is running.
  func stopCaptureSessionIfNecessary() {
    CameraCaptureSessionManager.shared.sessionQueue.async {
      if self.captureSession.isRunning {
        CameraCaptureSessionManager.shared.endUsing(withObject: self)
      }
    }
  }

  // MARK: - Private

  private func captureDevice(for camera: Camera) -> AVCaptureDevice? {
    switch camera {
    case .back:
      return backCamera
    case .front:
      return frontCamera
    }
  }

  /// Configures the session and adds the capture device as an input.
  ///
  /// - Parameter captureDevice: The camera input.
  private func configureSession(with captureDevice: AVCaptureDevice?) {
    guard let captureDevice = captureDevice else { return }
    CameraCaptureSessionManager.shared.sessionQueue.async {
      do {
        let captureInput = try AVCaptureDeviceInput(device: captureDevice)
        guard self.captureSession.canAddInput(captureInput),
            self.captureSession.canAddOutput(self.photoOutput) else { return }
        self.captureSession.beginConfiguration()
        self.captureSession.addInput(captureInput)
        self.captureSession.addOutput(self.photoOutput)
        self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        self.captureSession.commitConfiguration()
      } catch {
        print(error.localizedDescription)
      }
    }
  }

  // MARK: - AVCapturePhotoCaptureDelegate

  func photoOutput(_ output: AVCapturePhotoOutput,
                   didFinishProcessingPhoto photo: AVCapturePhoto,
                   error: Error?) {
    if let error = error {
      sjlog_error("Error capturing photo: \(error.localizedDescription)", category: .general)
      delegate?.photoCapturerDidCapturePhotoData(nil, metadata: nil)
      return
    }

    guard let photoData = photo.fileDataRepresentation() else {
      sjlog_error("Could not create jpeg photo data representation", category: .general)
      delegate?.photoCapturerDidCapturePhotoData(nil, metadata: nil)
      return
    }

    // Metadata
    var mutableMetadata = photo.metadata
    var exifData = mutableMetadata[kCGImagePropertyExifDictionary as String] as? [String: Any]

    guard let originalImage = UIImage(data: photoData), let cgImage = originalImage.cgImage else {
      sjlog_error("Could not create original image", category: .general)
      delegate?.photoCapturerDidCapturePhotoData(nil, metadata: nil)
      return
    }

    // Inline function for generating radians of degrees.
    func radians(_ degrees: Double) -> CGFloat { return CGFloat(degrees / 180.0 * .pi) }

    // The transform to be used in cropping.
    var cropRectTransform = CGAffineTransform.identity

    // Store the orientation we'll end up in, defaulting to handling portrait.
    var finalOrientation: UIImage.Orientation = .right
    // Metadata orientation maps to a different coordinate system than UIImageOrientation and must
    // be set manually.
    var metadataOrientation = 6  // Right, top

    // Store the original image width and height to be used in EXIF value updates after being
    // modified based on rotation if necessary.
    var finalMetadataSize = originalImage.size

    // Generate updated orientations, widths, heights and crop transforms based on the orientation
    // of the preview layer when this image was snapped.
    let isCaptureDeviceFront = currentCameraPosition == .front

    guard let connection = previewLayer.connection else {
      sjlog_error("No preview layer connection", category: .general)
      delegate?.photoCapturerDidCapturePhotoData(nil, metadata: nil)
      return
    }

    switch connection.videoOrientation {
    case .landscapeRight:
      cropRectTransform = CGAffineTransform(rotationAngle: radians(90.0))
          .translatedBy(x: 0, y: -originalImage.size.height)
      finalOrientation = .up
      if isCaptureDeviceFront {
        metadataOrientation = 3  // Bottom, right
      } else {
        metadataOrientation = 1  // Top, left
      }
      finalMetadataSize.width = originalImage.size.height
      finalMetadataSize.height = originalImage.size.width
    case .portraitUpsideDown:
      cropRectTransform = CGAffineTransform(rotationAngle: radians(-180.0))
          .translatedBy(x: -originalImage.size.width, y: -originalImage.size.height)
      finalOrientation = .left
      metadataOrientation = 8  // Left, bottom
    case .landscapeLeft:
      cropRectTransform = CGAffineTransform(rotationAngle: radians(-90.0))
          .translatedBy(x: -originalImage.size.width, y: 0)
      finalOrientation = .down
      if isCaptureDeviceFront {
        metadataOrientation = 1  // Top, left
      } else {
        metadataOrientation = 3  // Bottom, right
      }
      finalMetadataSize.width = originalImage.size.height
      finalMetadataSize.height = originalImage.size.width
    default:
        break
    }

    var renderedImage: CGImage?
    if shouldCropCapturedPhoto {
      // The capture region is 50% of the height of the original image.
      let captureRegion = originalImage.size.height * 0.5
      // Generate a crop rect from the capture region and original image size.
      let cropRect = CGRect(x: ((originalImage.size.width - captureRegion) / 2),
                            y: 0,
                            width: captureRegion,
                            height: originalImage.size.height)
      // Render the image cropped.
      renderedImage = cgImage.cropping(to: cropRect.applying(cropRectTransform))

      // Modify the metadata to change the dimensions now that they're different.
      exifData?[kCGImagePropertyExifPixelXDimension as String] = cropRect.size.width
      exifData?[kCGImagePropertyExifPixelYDimension as String] = cropRect.size.height
      mutableMetadata[kCGImagePropertyExifDictionary as String] = exifData
    } else {
      // Update dimensions based on image rotation.
      exifData?[kCGImagePropertyExifPixelXDimension as String] = finalMetadataSize.width
      exifData?[kCGImagePropertyExifPixelYDimension as String] = finalMetadataSize.height
    }
    // Set the final orientation into metadata.
    mutableMetadata[kCGImagePropertyOrientation as String] = metadataOrientation
    // Update the EXIF data.
    mutableMetadata[kCGImagePropertyExifDictionary as String] = exifData

    // Attempt to generate an orientation-correct image that is cropped if necessary, at the
    // correct scale.
    let finalImage = UIImage(cgImage: renderedImage ?? cgImage,
                             scale: originalImage.scale,
                             orientation: finalOrientation)
    guard let finalImageData = finalImage.jpegData(compressionQuality: 0.8) else {
      delegate?.photoCapturerDidCapturePhotoData(nil, metadata: nil)
      return
    }

    // Done!
    delegate?.photoCapturerDidCapturePhotoData(finalImageData,
                                               metadata: mutableMetadata as NSDictionary)
  }

}
