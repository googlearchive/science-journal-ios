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

import third_party_objective_c_material_components_ios_components_Buttons_Buttons
import third_party_objective_c_material_components_ios_components_Palettes_Palettes
import third_party_objective_c_material_components_ios_components_Typography_Typography

protocol TrialDetailSensorsViewDelegate: class {
  /// Informs the delegate a sensor view will be shown, most likely because the user tapped a
  /// previous or next button.
  ///
  /// - Parameter sensor: The sensor that will show.
  func trialDetailSensorsViewWillShowSensor(_ sensor: DisplaySensor)

  /// Informs the delegate the user tapped the stats view.
  func trialDetailSensorsViewDidTapStats()
}

/// The paginating sticky view showing information about sensors recorded in a trial, along
/// with a chart for each.
class TrialDetailSensorsView: UICollectionReusableView {

  // MARK: - Constants

  static let chartPlaybackHeight = PlaybackViewController.viewHeight
  static let edgeInsets = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 16.0)
  static let iconDimension: CGFloat = 24.0
  static let innerVerticalSpacing = TrialDetailSensorsView.edgeInsets.top
  static let titleFontSize: CGFloat = 14.0
  let titleHorizontalSpacing: CGFloat = 10.0

  // MARK: - Properties

  /// The delegate.
  weak var delegate: TrialDetailSensorsViewDelegate?

  private var statsTapGestureRecognizer: UITapGestureRecognizer!

  private var currentPage = 0 {
    didSet {
      // Notify delegate.
      let sensor = sensors[currentPage]
      delegate?.trialDetailSensorsViewWillShowSensor(sensor)

      // Update button states and scoll to page.
      updatePaginationButtons()
      scrollSensorsToCurrentPage()
    }
  }
  private var pageConstraints = [NSLayoutConstraint]()
  private var pages = [UIView]()
  let nextSensorButton = MDCFlatButton()
  let previousSensorButton = MDCFlatButton()
  private let sensorIcon = UIImageView()
  private let sensorPageView = UIScrollView()
  let sensorStatsView = SensorStatsView(min: "0", average: "0", max: "0")
  private let sensorTitle = UILabel()

  /// The sensors array.
  var sensors = [DisplaySensor]() {
    didSet {
      // Clean up previous pages.
      pages.forEach { $0.removeFromSuperview() }
      pages.removeAll()

      guard sensors.count > 0 else { return }

      // Adjust current page if it is beyond new page bounds.
      if currentPage > sensors.count - 1 {
        currentPage = sensors.count - 1
      }

      // Update metadata.
      updateMetadataWithSensor(sensors[currentPage])

      // Add the sensors to the page view.
      for sensor in sensors {
        // Add an empty view for each sensor. As the user pages to new sensors, chart presentation
        // views will be added to these via `updateChartViewForSensor(_:)`.
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        sensorPageView.addSubview(containerView)
        pages.append(containerView)

        // If the display sensor already has a chart view, add it now.
        guard let chartPresentationView = sensor.chartPresentationView else { continue }
        chartPresentationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chartPresentationView)
        chartPresentationView.pinToEdgesOfView(containerView)
      }
      // Lay out the sensors in the page view.
      layoutSensors()
      // Update pagination based on pages.
      updatePaginationButtons()
      scrollSensorsToCurrentPage()
      delegate?.trialDetailSensorsViewWillShowSensor(currentSensor)
    }
  }

  /// The total height of this view. Ideally, controllers would cache this value as it will not
  /// change for different instances of this view type.
  static let height: CGFloat = {
    // Padding at the top of the title.
    var totalHeight = TrialDetailSensorsView.edgeInsets.top
    let titleFont =
        MDCTypography.fontLoader().boldFont!(ofSize: TrialDetailSensorsView.titleFontSize)
    let titleHeight = String.decibel.labelHeight(withConstrainedWidth: 0, font: titleFont)
    // Either the height of the title or the sensor icon, whichever if taller.
    totalHeight += max(titleHeight, TrialDetailSensorsView.iconDimension)
    // Separator.
    totalHeight += SeparatorView.Metrics.dimension
    // Stats view.
    totalHeight += SensorStatsView.height
    // Chart view.
    totalHeight += TrialDetailSensorsView.chartPlaybackHeight
    // Total plus the vertical padding between sections of the outer vertical stack view.
    return ceil(totalHeight + TrialDetailSensorsView.innerVerticalSpacing * 3)
  }()

  /// Returns the currently displaying sensor.
  var currentSensor: DisplaySensor {
    return sensors[currentPage]
  }

  private let contentView = UIView()
  private var contentViewLeadingConstraint: NSLayoutConstraint?
  private var contentViewTrailingConstraint: NSLayoutConstraint?

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    sensors.removeAll()
    pages.removeAll()
    let sensorSubviews = sensorPageView.subviews
    sensorSubviews.forEach { $0.removeFromSuperview() }
    NSLayoutConstraint.deactivate(pageConstraints)
    updatePaginationButtons()
  }

  override func safeAreaInsetsDidChange() {
    contentViewLeadingConstraint?.constant = safeAreaInsetsOrZero.left
    contentViewTrailingConstraint?.constant = -safeAreaInsetsOrZero.right
    layoutSensors()
  }

  /// Scroll the sensor page view to a new page, update data.
  func scrollSensorsToCurrentPage() {
    guard sensors.count > currentPage else { return }

    // Set the title and icon, stat values.
    updateMetadataWithSensor(currentSensor)

    // Change the page.
    let contentOffset = CGPoint(x: sensorPageView.bounds.size.width * CGFloat(currentPage), y: 0)
    sensorPageView.setContentOffset(contentOffset, animated: false)
  }

  /// Adds the chart view for a display sensor to the paging scroll view.
  ///
  /// - Parameters:
  ///   - chartPresentationView: A chart presentation view.
  ///   - sensorID: A sensor ID.
  func updateChartView(_ chartPresentationView: UIView, forSensorWithID sensorID: String) {
    guard let index = sensors.index(where: { sensorID == $0.ID }) else {
      return
    }
    var sensor = sensors[index]
    sensor.chartPresentationView = chartPresentationView
    let page = pages[index]
    chartPresentationView.translatesAutoresizingMaskIntoConstraints = false
    page.addSubview(chartPresentationView)
    chartPresentationView.pinToEdgesOfView(page)
  }

  // MARK: - Private

  private func configureView() {
    // The wrapping shadowed view.
    let shadowedView = ShadowedView()
    addSubview(shadowedView)
    shadowedView.backgroundColor = .white
    shadowedView.setElevation(points: ShadowElevation.cardResting.rawValue)
    shadowedView.translatesAutoresizingMaskIntoConstraints = false
    shadowedView.pinToEdgesOfView(self)

    // Content view
    contentView.clipsToBounds = true
    contentView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentView)
    contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    contentViewLeadingConstraint =
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
    contentViewLeadingConstraint?.isActive = true
    contentViewTrailingConstraint =
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
    contentViewTrailingConstraint?.isActive = true

    // The previous sensor button.
    previousSensorButton.setImage(UIImage(named: "ic_prev_arrow"), for: .normal)
    previousSensorButton.addTarget(self,
                                   action: #selector(previousSensorButtonTapped),
                                   for: .touchUpInside)
    previousSensorButton.accessibilityLabel = String.sensorPreviousContentDescription

    // The next sensor button.
    nextSensorButton.setImage(UIImage(named: "ic_next_arrow"), for: .normal)
    nextSensorButton.addTarget(self,
                               action: #selector(nextSensorButtonTapped),
                               for: .touchUpInside)
    nextSensorButton.accessibilityLabel = String.sensorNextContentDescription

    // Common config to both previous and next sensor buttons.
    for button in [previousSensorButton, nextSensorButton] {
      button.hasOpaqueBackground = true
      button.disabledAlpha = 0
      button.isEnabled = false
      button.widthAnchor.constraint(
          equalToConstant: TrialDetailSensorsView.iconDimension).isActive = true
      button.heightAnchor.constraint(
          equalToConstant: TrialDetailSensorsView.iconDimension).isActive = true
      button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
      button.tintColor = .appBarReviewBackgroundColor
      button.inkColor = .clear
      button.contentEdgeInsets = .zero
      button.imageEdgeInsets = .zero
      button.hitAreaInsets = UIEdgeInsets(top: -20, left: -40, bottom: -20, right: -40)
    }

    // The icon for the sensor.
    sensorIcon.translatesAutoresizingMaskIntoConstraints = false
    sensorIcon.widthAnchor.constraint(
        equalToConstant: TrialDetailSensorsView.iconDimension).isActive = true
    sensorIcon.heightAnchor.constraint(
        equalToConstant: TrialDetailSensorsView.iconDimension).isActive = true
    sensorIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    // Title for the sensor.
    sensorTitle.font =
        MDCTypography.fontLoader().boldFont?(ofSize: TrialDetailSensorsView.titleFontSize)
    sensorTitle.textColor = MDCPalette.grey.tint800
    sensorTitle.translatesAutoresizingMaskIntoConstraints = false

    // Stack view for the icon and title.
    let infoStack = UIStackView(arrangedSubviews: [sensorIcon, sensorTitle])
    infoStack.spacing = titleHorizontalSpacing
    infoStack.alignment = .center
    infoStack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    // Stack view for the previous and next buttons, and the icon and title stack.
    let controlStackView = UIStackView(arrangedSubviews: [
      previousSensorButton, infoStack, nextSensorButton
    ])
    controlStackView.alignment = .center
    controlStackView.distribution = .equalSpacing
    controlStackView.layoutMargins = UIEdgeInsets(top: TrialDetailSensorsView.edgeInsets.top,
                                                  left: TrialDetailSensorsView.edgeInsets.left,
                                                  bottom: 0,
                                                  right: TrialDetailSensorsView.edgeInsets.right)
    controlStackView.isLayoutMarginsRelativeArrangement = true
    controlStackView.translatesAutoresizingMaskIntoConstraints = false

    let separator = SeparatorView(direction: .horizontal, style: .dark)
    separator.translatesAutoresizingMaskIntoConstraints = false

    // Outer stack view to wrap everything with a separator between the info and sensors views.
    let outerStackView = UIStackView(arrangedSubviews: [controlStackView, separator])
    contentView.addSubview(outerStackView)
    outerStackView.axis = .vertical
    outerStackView.distribution = .equalSpacing
    outerStackView.spacing = TrialDetailSensorsView.innerVerticalSpacing
    outerStackView.translatesAutoresizingMaskIntoConstraints = false
    outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

    // The stats view.
    contentView.addSubview(sensorStatsView)
    sensorStatsView.translatesAutoresizingMaskIntoConstraints = false
    sensorStatsView.topAnchor.constraint(
        equalTo: outerStackView.bottomAnchor,
        constant: TrialDetailSensorsView.innerVerticalSpacing).isActive = true
    sensorStatsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    sensorStatsView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    let insets = TrialDetailSensorsView.edgeInsets.left + TrialDetailSensorsView.edgeInsets.right
    sensorStatsView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor,
                                           constant: -insets).isActive = true
    statsTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(handleStatsTapGesture))
    sensorStatsView.addGestureRecognizer(statsTapGestureRecognizer)

    // The paginating sensors view.
    contentView.addSubview(sensorPageView)
    sensorPageView.clipsToBounds = false  // So playback overlays can render outside their bounds.
    sensorPageView.bounces = false
    sensorPageView.isPagingEnabled = true
    sensorPageView.isScrollEnabled = false
    sensorPageView.showsVerticalScrollIndicator = false
    sensorPageView.showsHorizontalScrollIndicator = false
    sensorPageView.translatesAutoresizingMaskIntoConstraints = false
    sensorPageView.heightAnchor.constraint(
        equalToConstant: TrialDetailSensorsView.chartPlaybackHeight).isActive = true
    sensorPageView.topAnchor.constraint(
        equalTo: sensorStatsView.bottomAnchor,
        constant: TrialDetailSensorsView.innerVerticalSpacing).isActive = true
    sensorPageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    sensorPageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    sensorPageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
  }

  @objc private func handleStatsTapGesture() {
    delegate?.trialDetailSensorsViewDidTapStats()
  }

  // MARK: - Helper methods

  // Lays out the sensor chart views in the sensor page view.
  func layoutSensors() {
    NSLayoutConstraint.deactivate(pageConstraints)
    pageConstraints = []
    let pageCount = pages.count
    for (index, page) in pages.enumerated() {
      pageConstraints += [
        page.widthAnchor.constraint(equalTo: contentView.widthAnchor),
        page.heightAnchor.constraint(equalToConstant: TrialDetailSensorsView.chartPlaybackHeight),
        page.topAnchor.constraint(equalTo: sensorPageView.topAnchor),
        page.bottomAnchor.constraint(equalTo: sensorPageView.bottomAnchor)
      ]
      if pageCount == 1 {
        pageConstraints += [page.leadingAnchor.constraint(equalTo: sensorPageView.leadingAnchor)]
        pageConstraints += [page.trailingAnchor.constraint(equalTo: sensorPageView.trailingAnchor)]
      } else if index == 0 {
        pageConstraints += [page.leadingAnchor.constraint(equalTo: sensorPageView.leadingAnchor)]
      } else if index == pageCount - 1 {
        pageConstraints += [page.leadingAnchor.constraint(equalTo: pages[index-1].trailingAnchor)]
        pageConstraints += [page.trailingAnchor.constraint(equalTo: sensorPageView.trailingAnchor)]
      } else {
        pageConstraints += [page.leadingAnchor.constraint(equalTo: pages[index-1].trailingAnchor)]
      }
    }
    NSLayoutConstraint.activate(pageConstraints)
  }

  /// Handle showing/hiding pagination buttons based on the state of sensors and current page.
  func updatePaginationButtons() {
    guard sensors.count > 1 else {
      previousSensorButton.isEnabled = false
      nextSensorButton.isEnabled = false
      return
    }
    previousSensorButton.isEnabled = currentPage != 0
    nextSensorButton.isEnabled = currentPage != sensors.count - 1
  }

  // Updates the title, icon and stat values to match those of the sensor.
  private func updateMetadataWithSensor(_ sensor: DisplaySensor) {
    // TODO: Set colors based on sensor layout palette.
    sensorTitle.text = sensor.title
    sensorIcon.image = sensor.icon
    sensorStatsView.setMin(sensor.minValueString,
                           average: sensor.averageValueString,
                           max: sensor.maxValueString)
    if let color = sensor.colorPalette?.tint500 {
      sensorStatsView.textColor = color
      sensorIcon.tintColor = color
    }
  }

  // MARK: - User actions

  @objc private func previousSensorButtonTapped() {
    guard currentPage != 0 else { return }
    // A property observer on `currentPage` handles the view updates for changing a page.
    currentPage -= 1
  }

  @objc private func nextSensorButtonTapped() {
    guard currentPage != sensors.count - 1 else { return }
    // A property observer on `currentPage` handles the view updates for changing a page.
    currentPage += 1
  }

}
