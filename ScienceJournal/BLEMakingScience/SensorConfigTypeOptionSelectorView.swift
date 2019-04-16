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

protocol SensorConfigTypeOptionDelegate: class {
  /// Informs the delegate the type selection changed.
  func sensorConfigTypeOptionSelectionChanged()
}

/// An option selector view for selecting a Making Science BLE sensor type.
class SensorConfigTypeOptionSelectorView: OptionSelectorView {

  override var headerLabelText: String {
    return String.deviceOptionsSensorLabelText
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  /// The sensor config type option delegate.
  weak var typeDelegate: SensorConfigTypeOptionDelegate?

  /// The selected config type.
  var configType = GSJBleSensorConfig.SensorType.rotation {
    didSet {
      typeDelegate?.sensorConfigTypeOptionSelectionChanged()
    }
  }

  override func dropDownButtonPressed() {
    let rotationTitle = GSJBleSensorConfig.SensorType.rotation.name
    let rotationAction =
        PopUpMenuAction(title: rotationTitle, icon: UIImage(named: "ic_sensor_rotation")) { (_) in
          self.configType = .rotation
          self.selectionLabel.text = rotationTitle
        }

    let rawTitle = GSJBleSensorConfig.SensorType.raw.name
    let rawAction = PopUpMenuAction(title: rawTitle, icon: UIImage(named: "ic_sensor_raw")) { (_) in
      self.configType = .raw
      self.selectionLabel.text = rawTitle
    }

    let customTitle = GSJBleSensorConfig.SensorType.custom.name
    let customAction = PopUpMenuAction(title: customTitle,
                                       icon: UIImage(named: "ic_sensor_bluetooth")) { (_) in
      self.configType = .custom
      self.selectionLabel.text = customTitle
    }
    let actions = [rotationAction, rawAction, customAction]
    optionSelectorDelegate?.optionSelectorView(self,
                                               didPressShowOptions: actions,
                                               coveringView: selectionLabel)
  }

  private func configureView() {
    selectionLabel.text = configType.name
  }

}
