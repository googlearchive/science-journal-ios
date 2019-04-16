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

import UIKit

import third_party_sciencejournal_ios_ScienceJournalProtos

protocol TriggerWhenSelectorDelegate: class {
  /// Calls the delegate when the trigger when changes.
  func triggerWhenSelectorView(_ triggerWhenSelectorView: TriggerWhenSelectorView,
      didSelectWhenToTrigger triggerWhen: GSJTriggerInformation_TriggerWhen)
}

/// A view for selecting when to trigger, in the trigger edit view.
class TriggerWhenSelectorView: TriggerOptionSelectorView {

  // MARK: Properties

  // The delegate.
  weak var triggerWhenSelectorDelegate: TriggerWhenSelectorDelegate?

  /// The selected when-condition to trigger.
  var triggerWhen = GSJTriggerInformation_TriggerWhen.triggerWhenAt {
    didSet {
      triggerWhenSelectorDelegate?.triggerWhenSelectorView(self,
                                                           didSelectWhenToTrigger: triggerWhen)
      updateViewForOption()
    }
  }

  // MARK: - Public

  override var headerLabelText: String {
    return String.triggerWhenLabel
  }

  override func updateViewForOption() {
    switch triggerWhen {
    case .triggerWhenAbove:
      selectionLabel.text = String.triggerWhenIsAbove
    case .triggerWhenAt:
      selectionLabel.text = String.triggerWhenAt
    case .triggerWhenBelow:
      selectionLabel.text = String.triggerWhenIsBelow
    case .triggerWhenDropsBelow:
      selectionLabel.text = String.triggerWhenDropsBelow
    case .triggerWhenRisesAbove:
      selectionLabel.text = String.triggerWhenRisesAbove
    }
  }

  override func dropDownButtonPressed() {
    super.dropDownButtonPressed()

    let atAction = PopUpMenuAction(title: String.triggerWhenAt) { (_) in
      self.triggerWhen = .triggerWhenAt
    }
    let risesAboveAction = PopUpMenuAction(title: String.triggerWhenRisesAbove) { (_) in
      self.triggerWhen = .triggerWhenRisesAbove
    }
    let dropsBelowAction = PopUpMenuAction(title: String.triggerWhenDropsBelow) { (_) in
      self.triggerWhen = .triggerWhenDropsBelow
    }
    let isAboveAction = PopUpMenuAction(title: String.triggerWhenIsAbove) { (_) in
      self.triggerWhen = .triggerWhenAbove
    }
    let isBelowAction = PopUpMenuAction(title: String.triggerWhenIsBelow) { (_) in
      self.triggerWhen = .triggerWhenBelow
    }
    let actions = [atAction, risesAboveAction, dropsBelowAction, isAboveAction, isBelowAction]
    optionSelectorDelegate?.optionSelectorView(self,
                                               didPressShowOptions: actions,
                                               coveringView: selectionLabel)
  }

}
