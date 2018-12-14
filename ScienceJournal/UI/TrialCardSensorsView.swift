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

/// The view that shows sensors in a trial card.
class TrialCardSensorsView: UIView {

  // MARK: - Properties

  /// The sensors to display.
  var sensors = [DisplaySensor]() {
    didSet {
      // Remove any views that are not needed.
      if sensorViews.count > sensors.count {
        let rangeOfSensorViewsToRemove = sensors.count..<sensorViews.count
        sensorViews[rangeOfSensorViewsToRemove].forEach { $0.removeFromSuperview() }
        sensorViews.removeSubrange(rangeOfSensorViewsToRemove)

        let rangeOfSeparatorViewsToRemove = sensors.count - 1..<sensorViews.count - 1
        separatorViews[rangeOfSeparatorViewsToRemove].forEach { $0.removeFromSuperview() }
        separatorViews.removeSubrange(rangeOfSeparatorViewsToRemove)
      }

      // Add any views that are needed.
      for _ in sensorViews.count..<sensors.count {
        if sensorViews.count > 0 {
          let separatorView = SeparatorView(direction: .horizontal, style: .light)
          separatorViews.append(separatorView)
          addSubview(separatorView)
        }

        let sensorView = TrialCardSensorView()
        sensorViews.append(sensorView)
        addSubview(sensorView)
      }

      // Update sensor views with sensors.
      for (index, sensor) in sensors.enumerated() {
        sensorViews[index].displaySensor = sensor
      }

      setNeedsLayout()
    }
  }

  private var sensorViews = [TrialCardSensorView]()
  private var separatorViews = [SeparatorView]()

  // MARK: - Public

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let height = TrialCardSensorView.height * CGFloat(sensorViews.count) +
        SeparatorView.Metrics.dimension * CGFloat(separatorViews.count)
    return CGSize(width: size.width, height: height)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    var originY: CGFloat = 0
    for (index, sensorView) in sensorViews.enumerated() {
      sensorView.frame = CGRect(x: 0,
                                y: originY,
                                width: bounds.width,
                                height: TrialCardSensorView.height)
      originY = sensorView.frame.maxY

      if index < separatorViews.count {
        let separatorView = separatorViews[index]
        separatorView.frame = CGRect(x: 0,
                                     y: originY,
                                     width: bounds.width,
                                     height: SeparatorView.Metrics.dimension)
        originY = separatorView.frame.maxY
      }
    }
  }

}
