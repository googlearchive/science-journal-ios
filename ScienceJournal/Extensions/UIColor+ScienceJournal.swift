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

import third_party_objective_c_material_components_ios_components_Palettes_Palettes

/// UIColor extension for Science Journal with commonly-used static colors.
extension UIColor {

  // MARK: - App bar

  /// The default background color for the app bar.
  static let appBarDefaultBackgroundColor = MDCPalette.deepPurple.tint500

  /// The default background color for the darkend area under the status bar.
  static let appBarDefaultStatusBarBackgroundColor = UIColor(red: 0.267,
                                                             green: 0.094,
                                                             blue: 0.525,
                                                             alpha: 1.0)

  /// The background color for the app bar while reviewing trials and notes.
  static let appBarReviewBackgroundColor = UIColor(red: 0.282,
                                                   green: 0.569,
                                                   blue: 0.894,
                                                   alpha: 1.0)

  /// The background color for the darkened area under the status bar while reviewing trials and
  /// notes.
  static let appBarReviewStatusBarBackgroundColor = UIColor(red: 0.165,
                                                            green: 0.341,
                                                            blue: 0.529,
                                                            alpha: 1.0)

  /// The background color for the app bar while editing a text note in a detail view.
  static let appBarTextEditingBarBackgroundColor = UIColor(red: 0.608,
                                                           green: 0.608,
                                                           blue: 0.608,
                                                           alpha: 1.0)

  /// The background color for the darkened area under the status bar while editing a text note in
  /// a detail view.
  static let appBarTextEditingStatusBarBackgroundColor = UIColor(red: 0.365,
                                                                 green: 0.361,
                                                                 blue: 0.361,
                                                                 alpha: 1.0)

  // MARK: - Trial headers

  /// The background color for the trial cell header when not recording.
  static let trialHeaderDefaultBackgroundColor: UIColor = .appBarReviewBackgroundColor

  /// The background color for the trial cell header while recording.
  static let trialHeaderRecordingBackgroundColor = MDCPalette.red.tint600

  /// The background color for the trial cell header when archived. It is the same as
  /// `trialHeaderDefaultBackgroundColor`, but its alpha is 0.3.
  static let trialHeaderArchivedBackgroundColor = UIColor(red: 0.282,
                                                          green: 0.569,
                                                          blue: 0.894,
                                                          alpha: 0.3)

}

extension UIColor.HSBA {

  /// The standard adjustment to use to create the secondary tint color that is derived from
  /// app bar background colors.
  static let standardAdjustment = UIColor.HSBA(hue: 0.038, saturation: -0.590, brightness: 0.283)

}

extension UIColor {

  // MARK: - Tinting

  /// HSBA represents hue, saturation, brightness and alpha values.
  ///
  /// Valid values are between 0 and 1.
  struct HSBA: CustomStringConvertible, CustomDebugStringConvertible {
    let hue: CGFloat
    let saturation: CGFloat
    let brightness: CGFloat
    let alpha: CGFloat

    /// Create an HSBA.
    ///
    /// Any values not provided will default to 0.
    ///
    /// - Parameters:
    ///   - hue: The hue.
    ///   - saturation: The saturation.
    ///   - brightness: The brightness.
    ///   - alpha: The alpha.
    init(
      hue: CGFloat? = nil,
      saturation: CGFloat? = nil,
      brightness: CGFloat? = nil,
      alpha: CGFloat? = nil
    ) {
      self.hue = hue ?? 0
      self.saturation = saturation ?? 0
      self.brightness = brightness ?? 0
      self.alpha = alpha ?? 0
    }

    var description: String {
      func f(_ n: CGFloat) -> Substring { return String(describing: n).prefix(5) }
      return "\(type(of: self))(hue: \(f(hue)), " +
        "saturation: \(f(saturation)), brightness: \(f(brightness)), alpha: \(f(alpha)))"
    }

    var debugDescription: String {
      return description
    }
  }

  /// The `HSBA` values for this color, or `nil` if they could not be obtained.
  var hsba: HSBA? {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
      return HSBA(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    return nil
  }

  /// Create a new color by *adding* the specified HSBA values.
  ///
  /// Values are truncated to stay between 0 and 1.
  ///
  /// - Parameters:
  ///   - hue: The hue.
  ///   - saturation: The saturation.
  ///   - brightness: The brightness.
  ///   - alpha: The alpha.
  /// - Returns:
  ///     The new color with the specified adjustments, or the original color if the original
  ///     HSBA values could not be obtained.
  func adjusted(
    hue: CGFloat? = nil,
    saturation: CGFloat? = nil,
    brightness: CGFloat? = nil,
    alpha: CGFloat? = nil
  ) -> UIColor {
    let values = HSBA(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    return adjusted(by: values)
  }

  /// Create a new color by *adding* the specified HSBA values.
  ///
  /// Values are truncated to stay between 0 and 1.
  ///
  /// - Parameters:
  ///   - values: The HSBA values to use for the adjustment.
  /// - Returns:
  ///     The new color with the specified adjustments, or the original color if the original
  ///     HSBA values could not be obtained.
  func adjusted(by values: HSBA) -> UIColor {
    guard let hsba = hsba else { return self }

    // Ensure values are between 0 and 1.
    func limit(_ value: CGFloat) -> CGFloat { return max(0, min(value, 1)) }

    let newHue = limit(hsba.hue + values.hue)
    let newSaturation = limit(hsba.saturation + values.saturation)
    let newBrightness = limit(hsba.brightness + values.brightness)
    let newAlpha = limit(hsba.alpha + values.alpha)

    return UIColor(
      hue: newHue,
      saturation: newSaturation,
      brightness: newBrightness,
      alpha: newAlpha
    )
  }

}
