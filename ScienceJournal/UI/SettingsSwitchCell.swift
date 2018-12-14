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

import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A settings cell with a title, description and switch.
class SettingsSwitchCell: SettingsCell {

  private enum Metrics {
    static let switchWidth: CGFloat = {
      return UISwitch().frame.size.width
    }()
  }

  // MARK: - Properties

  /// The switch.
  let aSwitch = UISwitch()

  /// Calculates the height required to display this view, given the data provided.
  ///
  /// - Parameters:
  ///   - width: Maximum width for this view, used to constrain measurements.
  ///   - title: The title string to measure.
  ///   - description: The description string to measure. Optional.
  /// - Returns: The total height of this view. Ideally, controllers would cache this value as it
  ///            will not change for different instances of this view type.
  static func height(inWidth width: CGFloat, title: String, description: String?) -> CGFloat {
    // Constrained width, including padding.
    let constrainedWidth = width - SettingsCell.Metrics.cellInsets.left -
        SettingsCell.Metrics.cellInsets.right - SettingsCell.Metrics.innerHorizontalSpacing -
        Metrics.switchWidth

    var totalHeight =
        title.labelHeight(withConstrainedWidth: constrainedWidth,
                          font: SettingsCell.Metrics.textLabelFont)
    if let description = description {
      totalHeight += SettingsCell.Metrics.innerVerticalSpacing
      totalHeight += description.labelHeight(withConstrainedWidth: constrainedWidth,
                                             font: SettingsCell.Metrics.descriptionLabelFont)
    }

    // Add the vertical padding on top and bottom of the cell.
    totalHeight += SettingsCell.Metrics.cellInsets.top + SettingsCell.Metrics.cellInsets.bottom

    return totalHeight
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Measure the label widths given constraints.
    let labelWidth = contentView.bounds.size.width - SettingsCell.Metrics.cellInsets.left -
        SettingsCell.Metrics.cellInsets.right - SettingsCell.Metrics.innerHorizontalSpacing -
        Metrics.switchWidth

    // Determine the X position for the label and the switch based on RTL status.
    var labelX = SettingsCell.Metrics.cellInsets.left
    var switchX = contentView.bounds.size.width - aSwitch.frame.size.width -
        SettingsCell.Metrics.cellInsets.right
    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
      labelX = contentView.bounds.size.width - labelWidth - SettingsCell.Metrics.cellInsets.right
      switchX = SettingsCell.Metrics.cellInsets.left
    }

    // Lay out the title label first.
    if let title = titleLabel.text {
      let titleLabelHeight = title.labelHeight(withConstrainedWidth: labelWidth,
                                               font: SettingsCell.Metrics.textLabelFont)
      titleLabel.frame = CGRect(x: labelX,
                                y: SettingsCell.Metrics.cellInsets.top,
                                width: labelWidth,
                                height: titleLabelHeight)
    }

    // Lay out the description label based on the title label.
    if let description = descriptionLabel.text {
      let descriptionLabelHeight =
          description.labelHeight(withConstrainedWidth: labelWidth,
                                  font: SettingsCell.Metrics.descriptionLabelFont)
      descriptionLabel.frame = CGRect(x: titleLabel.frame.minX,
                                      y: titleLabel.frame.maxY +
                                             SettingsCell.Metrics.innerVerticalSpacing,
                                      width: labelWidth,
                                      height: descriptionLabelHeight)
    }

    // Lay out the switch.
    aSwitch.frame =
        CGRect(x: switchX,
               y: ceil((contentView.bounds.size.height - aSwitch.frame.size.height) / 2),
               width: aSwitch.frame.size.width,
               height: aSwitch.frame.size.height)
  }

  override func configureView() {
    super.configureView()
    contentView.addSubview(aSwitch)
  }

}
