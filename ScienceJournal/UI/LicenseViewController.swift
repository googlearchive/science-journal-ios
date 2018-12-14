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

class LicenseViewController: MaterialHeaderViewController {

  // MARK: - Properties

  private let license: LicenseData
  private let webView = UIWebView()

  override var trackedScrollView: UIScrollView? { return webView.scrollView }

  // MARK: - Public

  init(license: LicenseData, analyticsReporter: AnalyticsReporter) {
    self.license = license
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(webView)
    view.isAccessibilityElement = false
    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.pinToEdgesOfView(view)

    if isPresented {
      appBar.hideStatusBarOverlay()
    }

    title = license.title
    let backMenuItem = MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    navigationItem.leftBarButtonItem = backMenuItem

    if let licenseFile =
        Bundle.currentBundle.path(forResource: license.filename, ofType: nil) {
      do {
        let licenseString = try String(contentsOfFile: licenseFile,
                                       encoding: String.Encoding.utf8)
        webView.loadHTMLString(licenseString, baseURL: nil)
      }
      catch {
        print("Could not read license file: \(license.filename).html, error: " +
            error.localizedDescription)
      }
    }
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

}
