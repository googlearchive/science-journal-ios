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

/// A view controller that presents options to configure a Making Science BLE device.
class MakingScienceSensorConfigViewController: ScienceJournalViewController, OptionSelectorDelegate,
    SensorConfigTypeOptionDelegate {

  private enum Metrics {
    static let viewInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
    static let verticalViewInsets = viewInsets.top + viewInsets.bottom
    static let verticalSpacing: CGFloat = 10
  }

  /// View that displays the frequency switch with a label.
  class FrequencyView: UIView {

    /// The frequency switch.
    let aSwitch = UISwitch()

    private let stackView = UIStackView()
    private let label = UILabel()

    override init(frame: CGRect) {
      super.init(frame: frame)
      configureView()
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      configureView()
    }

    private func configureView() {
      addSubview(stackView)
      isAccessibilityElement = true
      accessibilityHint = String.doubleTapToToggle

      stackView.translatesAutoresizingMaskIntoConstraints = false
      label.translatesAutoresizingMaskIntoConstraints = false
      label.text = String.deviceOptionsCustomSensorFrequencyCheckboxText
      label.font = MDCTypography.body2Font()
      aSwitch.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(label)
      stackView.addArrangedSubview(aSwitch)
      stackView.pinToEdgesOfView(self)
    }

    override func accessibilityActivate() -> Bool {
      aSwitch.isOn = !aSwitch.isOn
      return true
    }

    override var accessibilityLabel: String? {
      set {}
      get {
        return String.deviceOptionsCustomSensorFrequencyCheckboxText + ", " +
            (aSwitch.isOn ? String.switchOnContentDescription : String.switchOffContentDescription)
      }
    }

  }

  // MARK: - Properties

  let okButton = MDCFlatButton()

  /// The selected sensor type.
  var selectedType: GSJBleSensorConfig.SensorType {
    return typeSelector.configType
  }

  /// The selected pin, only relevant for custom sensor type.
  var selectedPin: PinType {
    return pinSelector.pinType
  }

  /// If frequency is enabled, only relevant for custom sensor type.
  var isFrequencyEnabled: Bool {
    return frequencyView.aSwitch.isOn
  }

  private let frequencyView = FrequencyView()
  private let headerLabel = UILabel()
  private let pinSelector = SensorConfigPinSelectorView()
  private let typeSelector = SensorConfigTypeOptionSelectorView()
  private let stackView = UIStackView()

  /// The height required to display the view's contents depending on type selection.
  private var totalHeight: CGFloat {
    let headerHeight =
        headerLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let okButtonHeight = okButton.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let typeSelectorHeight =
        typeSelector.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

    var height = headerHeight + okButtonHeight + typeSelectorHeight + Metrics.verticalViewInsets
    var verticalSpaces: CGFloat = 2
    if typeSelector.configType == .custom {
      let pinSelectorHeight =
          pinSelector.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      let frequencyViewHeight =
          frequencyView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      height += pinSelectorHeight + frequencyViewHeight
      verticalSpaces += 2
    }
    return height + Metrics.verticalSpacing * verticalSpaces
  }

  // MARK: - Public

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    accessibilityViewIsModal = true

    stackView.axis = .vertical
    stackView.spacing = Metrics.verticalSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)

    headerLabel.text = String.titleActivitySensorSettings
    headerLabel.font = MDCTypography.titleFont()
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(headerLabel)

    typeSelector.optionSelectorDelegate = self
    typeSelector.typeDelegate = self
    typeSelector.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(typeSelector)

    let buttonWrapper = UIView()
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false
    buttonWrapper.addSubview(okButton)
    okButton.translatesAutoresizingMaskIntoConstraints = false
    okButton.setTitleColor(.appBarReviewBackgroundColor, for: .normal)
    okButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor).isActive = true
    okButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor).isActive = true
    okButton.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor).isActive = true

    okButton.setTitle(String.actionOk, for: .normal)
    okButton.accessibilityHint = String.deviceOptionsOkContentDescription
    stackView.addArrangedSubview(buttonWrapper)

    stackView.pinToEdgesOfView(view)
    stackView.layoutMargins = Metrics.viewInsets
    stackView.isLayoutMarginsRelativeArrangement = true

    pinSelector.optionSelectorDelegate = self
    pinSelector.translatesAutoresizingMaskIntoConstraints = false

    frequencyView.translatesAutoresizingMaskIntoConstraints = false

    setPreferredContentSize()
  }

  override func accessibilityPerformEscape() -> Bool {
    dismiss(animated: true)
    return true
  }

  // MARK: - OptionSelectorDelegate

  func optionSelectorView(_ optionSelectorView: OptionSelectorView,
                          didPressShowOptions actions: [PopUpMenuAction],
                          coveringView: UIView) {
    // Show the actions in a pop up menu.
    let popUpMenu = PopUpMenuViewController()
    popUpMenu.addActions(actions)
    popUpMenu.present(from: self, position: .coveringView(coveringView))
  }

  // MARK: - SensorConfigTypeOptionDelegate

  func sensorConfigTypeOptionSelectionChanged() {
    switch typeSelector.configType {
    case .rotation, .raw:
      stackView.removeArrangedSubview(pinSelector)
      stackView.removeArrangedSubview(frequencyView)
      pinSelector.isHidden = true
      frequencyView.isHidden = true
    case .custom:
      pinSelector.isHidden = false
      frequencyView.isHidden = false
      stackView.insertArrangedSubview(pinSelector, at: 2)
      stackView.insertArrangedSubview(frequencyView, at: 3)
    }
    setPreferredContentSize()
  }

  // MARK: - Private

  private func setPreferredContentSize() {
    // When presented as a Material dialog, the preferred content size dictates its displayed size.
    preferredContentSize = CGSize(width: 200, height: totalHeight)
  }

}
