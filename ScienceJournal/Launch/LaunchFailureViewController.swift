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
import third_party_objective_c_material_components_ios_components_Typography_Typography

/// A view controller displayed to the user when launch operations encounter a permanent failure.
class LaunchFailureViewController: UIViewController {

  private struct Metrics {
    static let logoDimension: CGFloat = 100
    static let stackViewSpacing: CGFloat = 10
    static let stackViewHorizontalPadding: CGFloat = 20
    static let stackViewMaxWidth: CGFloat = 280
  }

  private let feedbackReporter: FeedbackReporter
  private let feedbackViewController: UIViewController?

  init(feedbackReporter: FeedbackReporter) {
    self.feedbackReporter = feedbackReporter
    feedbackViewController = feedbackReporter.feedbackViewController(withStyleMatching: nil)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    let logo = UIImageView(image: UIImage(named: "launch_image_icon"))
    logo.translatesAutoresizingMaskIntoConstraints = false
    logo.widthAnchor.constraint(equalToConstant: Metrics.logoDimension).isActive = true
    logo.heightAnchor.constraint(equalTo: logo.widthAnchor).isActive = true

    let errorLabel = UILabel()
    errorLabel.translatesAutoresizingMaskIntoConstraints = false
    errorLabel.text = String.launchFailureMessage
    errorLabel.font = MDCTypography.subheadFont()
    errorLabel.textColor = .black
    errorLabel.textAlignment = .center
    errorLabel.numberOfLines = 0

    let wrappingStackView = UIStackView(arrangedSubviews: [logo, errorLabel])
    wrappingStackView.translatesAutoresizingMaskIntoConstraints = false
    wrappingStackView.axis = .vertical
    wrappingStackView.spacing = Metrics.stackViewSpacing
    wrappingStackView.distribution = .equalCentering
    wrappingStackView.alignment = .center
    view.addSubview(wrappingStackView)

    wrappingStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    wrappingStackView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: Metrics.stackViewHorizontalPadding).isActive = true
    wrappingStackView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -Metrics.stackViewHorizontalPadding).isActive = true
    wrappingStackView.widthAnchor.constraint(
        lessThanOrEqualToConstant: Metrics.stackViewMaxWidth).isActive = true

    if feedbackViewController != nil {
      let feedbackButton = MDCFlatButton()
      feedbackButton.translatesAutoresizingMaskIntoConstraints = false
      feedbackButton.hasOpaqueBackground = true
      feedbackButton.setTitleColor(.white, for: .normal)
      feedbackButton.setBackgroundColor(.appBarDefaultBackgroundColor, for: .normal)
      feedbackButton.setTitle(String.launchFailureSendFeedbackButton, for: .normal)
      feedbackButton.addTarget(self, action: #selector(sendFeedback), for: .touchUpInside)
      wrappingStackView.addArrangedSubview(feedbackButton)
    }
  }

  @objc
  func sendFeedback() {
    guard let feedbackViewController = feedbackViewController else {
      return
    }

    let navigationController = UINavigationController(rootViewController: feedbackViewController)
    present(navigationController, animated: true, completion: nil)
  }
}
