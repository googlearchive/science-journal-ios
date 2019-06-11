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

// TODO: Implement visual design. http://b/135037267
class LaunchFailureViewController: UIViewController {

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

    let label = UILabel()
    label.text = "Something went wrong"
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)

    label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

    if feedbackViewController != nil {
      let button = UIButton(type: .custom)
      button.setTitle("Send Feedback", for: .normal)
      button.setTitleColor(.black, for: .normal)
      button.addTarget(self, action: #selector(sendFeedback), for: .touchUpInside)
      button.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(button)
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
      button.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: -20).isActive = true
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
