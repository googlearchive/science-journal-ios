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
import ScienceJournalProtos

protocol TriggerTypeSelectorDelegate {
  /// Calls the delegate when the type changes.
  func triggerTypeSelectorView(_ triggerTypeSelectorView: TriggerTypeSelectorView,
                               didSelectType triggerType: GSJTriggerInformation_TriggerActionType)
}

/// A view for selecting the trigger type, in the trigger edit view.
class TriggerTypeSelectorView: TriggerOptionSelectorView {

  // The delegate.
  var triggerTypeSelectorDelegate: TriggerTypeSelectorDelegate?

  // MARK: Properties

  /// The selected trigger type.
  var triggerType = GSJTriggerInformation_TriggerActionType.triggerActionAlert {
    didSet {
      triggerTypeSelectorDelegate?.triggerTypeSelectorView(self, didSelectType: triggerType)
      updateViewForOption()
    }
  }

  /// Whether or not the only trigger action allowed should be alert. This should be false when the
  /// trigger when is above or below.
  var shouldOnlyAllowTriggerActionAlert = false {
    didSet {
      if shouldOnlyAllowTriggerActionAlert {
        triggerType = .triggerActionAlert
      }
      dropDownButton.isEnabled = !shouldOnlyAllowTriggerActionAlert
      selectionLabel.alpha =
          shouldOnlyAllowTriggerActionAlert ? 0.2 : MDCTypography.body2FontOpacity()
    }
  }

  // MARK: - Public

  override var headerLabelText: String {
    return String.triggerTypeLabel
  }

  override func updateViewForOption() {
    switch triggerType {
    case .triggerActionAlert:
      selectionLabel.text = String.triggerTypeAlert
    case .triggerActionNote:
      selectionLabel.text = String.triggerTypeNote
    case .triggerActionStartRecording:
      selectionLabel.text = String.triggerTypeStartRecording
    case .triggerActionStopRecording:
      selectionLabel.text = String.triggerTypeStopRecording
    }
  }

  override func dropDownButtonPressed() {
    guard !shouldOnlyAllowTriggerActionAlert else { return }

    super.dropDownButtonPressed()

    let startRecordingAction =
        PopUpMenuAction(title: String.triggerTypeStartRecording) { (_) in
      self.triggerType = .triggerActionStartRecording
    }
    let stopRecordingAction =
        PopUpMenuAction(title: String.triggerTypeStopRecording) { (_) in
      self.triggerType = .triggerActionStopRecording
    }
    let makeNoteAction = PopUpMenuAction(title: String.triggerTypeNote) { (_) in
      self.triggerType = .triggerActionNote
    }
    let alertMeAction = PopUpMenuAction(title: String.triggerTypeAlert) { (_) in
      self.triggerType = .triggerActionAlert
    }
    let actions = [startRecordingAction, stopRecordingAction, makeNoteAction, alertMeAction]
    optionSelectorDelegate?.optionSelectorView(self,
                                               didPressShowOptions: actions,
                                               coveringView: selectionLabel)
  }
}
