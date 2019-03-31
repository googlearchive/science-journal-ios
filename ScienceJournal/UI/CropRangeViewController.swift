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

import UIKit

import MaterialComponents

protocol CropRangeViewControllerDelegate: class {
  /// Informs delegate that a new timestamp was selected for one of the crop positions.
  ///
  /// - Parameters:
  ///   - timestamp: A timestamp.
  ///   - markerType: A marker type.
  func cropRangeViewControllerDidUpdateTimestamp(_ timestamp: Int64,
                                                 markerType: CropOverlayView.MarkerType)
}

/// View controller that manages manual entry of crop timestamps.
class CropRangeViewController: UIViewController, EditTimestampViewControllerDelegate {

  // MARK: - Properties

  /// The delegate.
  weak var delegate: CropRangeViewControllerDelegate?

  /// The crop range of the trial.
  var trialCropRange: ChartAxis<Int64>?

  private var alertPresentation: TimestampAlertPresentation?
  private let trialRecordingRange: ChartAxis<Int64>
  private static let timestampFormatter = TimestampFormatter()
  private let cropValidator: CropValidator

  /// Designated initializer
  ///
  /// - Parameters:
  ///   - trialCropRange: The trial's crop range.
  ///   - trialRecordingRange: The trial's recording range.
  init(trialCropRange: ChartAxis<Int64>?, trialRecordingRange: ChartAxis<Int64>) {
    self.trialCropRange = trialCropRange
    self.trialRecordingRange = trialRecordingRange
    cropValidator = CropValidator(trialRecordingRange: trialRecordingRange)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  /// Shows an alert that allows the user to manually input a timestamp for the given crop marker.
  ///
  /// - Parameter marker: A crop marker type.
  func showTimestampEditAlert(forCropMarkerType markerType: CropOverlayView.MarkerType) {
    guard let trialCropRange = trialCropRange else {
      return
    }

    let editTimestampVC = EditTimestampViewController()
    editTimestampVC.delegate = self

    switch markerType {
    case .start:
      editTimestampVC.editTimestampView.headerLabel.text = String.editCropStartTime
      let relativeStartTimestamp = trialCropRange.min - trialRecordingRange.min
      editTimestampVC.editTimestampView.textField.text =
          CropRangeViewController.timestampFormatter.string(fromTimestamp: relativeStartTimestamp)
    case .end:
      editTimestampVC.editTimestampView.headerLabel.text = String.editCropEndTime
      let relativeEndTimestamp = trialCropRange.max - trialRecordingRange.min
      editTimestampVC.editTimestampView.textField.text =
          CropRangeViewController.timestampFormatter.string(fromTimestamp: relativeEndTimestamp)
    }

    alertPresentation = TimestampAlertPresentation(editTimestampViewController: editTimestampVC,
                                                   markerType: markerType)

    let dialogController = MDCDialogTransitionController()
    editTimestampVC.modalPresentationStyle = .custom
    editTimestampVC.transitioningDelegate = dialogController
    editTimestampVC.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
    present(editTimestampVC, animated: true)
  }

  // MARK: - EditTimestampViewControllerDelegate

  func editTimestampViewSavePressed() {
    guard let alertPresentation = alertPresentation, let trialCropRange = trialCropRange else {
      return
    }

    // Get timestamp string
    let editTimestampView = alertPresentation.editTimestampViewController.editTimestampView
    guard let timestampString = editTimestampView.textField.text else {
      // No text.
      editTimestampView.showValidationError(withMessage: String.timestampPickerFormatError)
      return
    }

    guard let relativeTimestamp =
        CropRangeViewController.timestampFormatter.timestamp(fromString: timestampString) else {
      // Timestamp format is not correct.
      editTimestampView.showValidationError(withMessage: String.timestampPickerFormatError)
      return
    }

    // Adjust relative timestamp to absolute.
    let timestamp = relativeTimestamp + trialRecordingRange.min

    var newCropRange = trialCropRange
    switch alertPresentation.markerType {
    case .start: newCropRange.min = timestamp
    case .end: newCropRange.max = timestamp
    }

    guard cropValidator.isRangeAtLeastMinimumForCrop(newCropRange) else {
      editTimestampView.showValidationError(withMessage: String.timestampPickerCropRangeError)
      return
    }

    guard cropValidator.isCropRangeValid(newCropRange) else {
      editTimestampView.showValidationError(withMessage: String.timestampPickerRecordingRangeError)
      return
    }

    // Update the crop position.
    self.trialCropRange = newCropRange

    delegate?.cropRangeViewControllerDidUpdateTimestamp(timestamp,
                                                        markerType: alertPresentation.markerType)

    self.alertPresentation = nil
    dismiss(animated: true)
  }

  func editTimestampViewCancelPressed() {
    alertPresentation = nil
    dismiss(animated: true)
  }

  // MARK: - TimestampAlertPresentation

  /// Allows for capturing an edit timestamp view controller along with which marker type it is
  /// editing.
  struct TimestampAlertPresentation {
    let editTimestampViewController: EditTimestampViewController
    let markerType: CropOverlayView.MarkerType
  }

}
