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

/// The detail view controller of a picture which shows the picture in a zooming, panning view and
/// allows for caption editing.
class PictureDetailViewController:
    MaterialHeaderViewController, UITextFieldDelegate, CaptionableNoteDetailController {

  // MARK: - Properties

  private var cancelCaptionEditTapRecognizer: UITapGestureRecognizer?
  private let captionWrapper = UIView()
  private var captionWrapperBottomConstraint: NSLayoutConstraint?
  private var textFieldLeadingConstraint: NSLayoutConstraint?
  private var textFieldTrailingConstraint: NSLayoutConstraint?
  private var textFieldBottomConstraint: NSLayoutConstraint?
  private var imageViewHeightConstraint: NSLayoutConstraint?
  private weak var delegate: ExperimentItemDelegate?
  private var displayPicture: DisplayPictureNote
  private let imageView = UIImageView()
  private var menuBarButton = MaterialMenuBarButtonItem()
  private let metadataManager: MetadataManager
  private let scrollView = UIScrollView()
  private let textField = MDCTextField()
  private var textFieldController: MDCTextInputController?
  private let preferenceManager: PreferenceManager
  private let experimentInteractionOptions: ExperimentInteractionOptions
  private let shouldAllowSharing: Bool

  private var horizontalTextFieldPaddingForDisplayType: CGFloat {
    var padding: CGFloat {
      switch displayType {
      case .compact, .compactWide:
        return 32
      case .regular:
        return 100
      case .regularWide:
        return 300
      }
    }
    return padding + view.safeAreaInsetsOrZero.left + view.safeAreaInsetsOrZero.right
  }

  // Should the view controller make the caption field first responder the first time it appears?
  private var shouldJumpToCaptionOnLoad: Bool

  // MARK: - NoteDetailController

  var displayNote: DisplayNote {
    get {
      return displayPicture
    }
    set {
      if let pictureNote = newValue as? DisplayPictureNote {
        displayPicture = pictureNote
        updateViewForDisplayNote()
      }
    }
  }

  var currentCaption: String? {
    get {
      return textField.text
    }
    set {
      textField.text = newValue
    }
  }

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - displayPicture: A display picture.
  ///   - experimentInteractionOptions: Experiment interaction options.
  ///   - shouldAllowSharing: Whether the picture should be shareable.
  ///   - delegate: The item delegate.
  ///   - jumpToCaption: Whether the view should jump to the caption on first load.
  ///   - analyticsReporter: The analytics reporter.
  ///   - metadataManager: The metadata manager.
  ///   - preferenceManager: The preference manager.
  init(displayPicture: DisplayPictureNote,
       experimentInteractionOptions: ExperimentInteractionOptions,
       shouldAllowSharing: Bool,
       delegate: ExperimentItemDelegate?,
       jumpToCaption: Bool,
       analyticsReporter: AnalyticsReporter,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager) {
    self.displayPicture = displayPicture
    self.experimentInteractionOptions = experimentInteractionOptions
    self.shouldAllowSharing = shouldAllowSharing
    self.delegate = delegate
    self.shouldJumpToCaptionOnLoad = jumpToCaption
    self.metadataManager = metadataManager
    self.preferenceManager = preferenceManager
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    appBar.headerViewController.headerView.backgroundColor = .black

    let backMenuItem = MaterialBackBarButtonItem(target: self, action: #selector(backButtonPressed))
    navigationItem.leftBarButtonItem = backMenuItem

    menuBarButton.button.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuBarButton.button.setImage(UIImage(named: "ic_more_horiz"), for: .normal)
    navigationItem.rightBarButtonItem = menuBarButton

    let doubleTapGesture = UITapGestureRecognizer()
    doubleTapGesture.numberOfTapsRequired = 2
    doubleTapGesture.addTarget(self, action: #selector(handleDoubleTapGesture(_:)))
    scrollView.addGestureRecognizer(doubleTapGesture)

    view.addSubview(scrollView)
    scrollView.delegate = self
    scrollView.maximumZoomScale = 6
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
    scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

    if let imagePath = displayPicture.imagePath {
      setImage(withPath: imagePath)
    }
    imageView.contentMode = .scaleAspectFit
    scrollView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.pinToEdgesOfView(scrollView)
    imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    imageViewHeightConstraint = imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
    imageViewHeightConstraint?.isActive = true
    if #available(iOS 11.0, *) {
      imageView.accessibilityIgnoresInvertColors = true
    }

    view.addSubview(captionWrapper)
    captionWrapper.translatesAutoresizingMaskIntoConstraints = false
    captionWrapper.backgroundColor = .white
    captionWrapper.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
    captionWrapper.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
    captionWrapperBottomConstraint = captionWrapper.bottomAnchor.constraint(
        equalTo: view.bottomAnchor)
    captionWrapperBottomConstraint?.isActive = true

    captionWrapper.addSubview(textField)
    textField.delegate = self
    textField.text = displayPicture.caption
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.placeholder = experimentInteractionOptions.shouldAllowEdits ?
        String.noteCaptionHint : String.noteCaptionHintReadOnly
    textField.isUserInteractionEnabled = experimentInteractionOptions.shouldAllowEdits
    textField.clearButtonMode = .never
    textField.topAnchor.constraint(equalTo: captionWrapper.topAnchor).isActive = true
    textFieldLeadingConstraint =
        textField.leadingAnchor.constraint(equalTo: captionWrapper.leadingAnchor)
    textFieldLeadingConstraint?.isActive = true
    textFieldTrailingConstraint =
        textField.trailingAnchor.constraint(equalTo: captionWrapper.trailingAnchor)
    textFieldTrailingConstraint?.isActive = true
    textFieldBottomConstraint = textField.bottomAnchor.constraint(
        equalTo: captionWrapper.bottomAnchor)
    textFieldBottomConstraint?.isActive = true
    textField.setContentCompressionResistancePriority(.required, for: .vertical)

    let controller = MDCTextInputControllerUnderline(textInput: textField)
    controller.floatingPlaceholderNormalColor = .appBarReviewBackgroundColor
    controller.activeColor = .appBarReviewBackgroundColor

    textFieldController = controller

    updateCaptionLayout()

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleKeyboardNotification(_:)),
        name: Notification.Name.MDCKeyboardWatcherKeyboardWillChangeFrame,
        object: nil)

    // Listen to notifications of newly downloaded assets.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(downloadedImages),
                                           name: .driveSyncManagerDownloadedImages,
                                           object: nil)
  }

  func updateCaptionLayout() {
    let scrollViewBottomConstraintConstant: CGFloat
    if !experimentInteractionOptions.shouldAllowEdits && displayPicture.caption == nil {
      captionWrapper.isHidden = true
      scrollViewBottomConstraintConstant = 0
    } else {
      // Set the scroll view bottom constraint to the height of the text field. It is not anchored
      // to the text field because we don't want it to move when the text field moves due to
      // keyboard changes.
      captionWrapper.isHidden = false
      scrollViewBottomConstraintConstant =
          textField.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }

    scrollView.bottomAnchor.constraint(
        equalTo: view.bottomAnchor, constant: -scrollViewBottomConstraintConstant).isActive = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateConstraintsForDisplayType()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if shouldJumpToCaptionOnLoad {
      textField.becomeFirstResponder()
      shouldJumpToCaptionOnLoad = false
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Save the note's caption if necessary.
    view.endEditing(true)
    let newCaptionText = textField.text?.trimmedOrNil
    if newCaptionText != displayPicture.caption {
      displayPicture.caption = textField.text?.trimmedOrNil
      delegate?.detailViewControllerDidUpdateCaptionForNote(displayPicture)
    }
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    appBar.headerViewController.updateTopLayoutGuide()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !textField.isFirstResponder {
      let bottomInset = -view.safeAreaInsetsOrZero.bottom
      textFieldBottomConstraint?.constant = bottomInset
      imageViewHeightConstraint?.constant = bottomInset
    }
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { (_) in
      self.updateConstraintsForDisplayType()
    })
  }

  override func viewSafeAreaInsetsDidChange() {
    updateConstraintsForDisplayType()
  }

  // MARK: - Private

  private func updateConstraintsForDisplayType() {
    textFieldLeadingConstraint?.constant = horizontalTextFieldPaddingForDisplayType / 2
    textFieldTrailingConstraint?.constant = -horizontalTextFieldPaddingForDisplayType / 2
  }

  // MARK: - UIScrollViewDelegate

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }

  // MARK: - UITextFieldDelegate

  func textFieldDidBeginEditing(_ textField: UITextField) {
    scrollView.isScrollEnabled = false
    let cancelTapRecognizer = UITapGestureRecognizer()
    cancelTapRecognizer.addTarget(self, action: #selector(handleTapGesture(_:)))
    scrollView.addGestureRecognizer(cancelTapRecognizer)
    cancelCaptionEditTapRecognizer = cancelTapRecognizer
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    scrollView.isScrollEnabled = true
    if let cancelCaptionEditTapRecognizer = cancelCaptionEditTapRecognizer {
      scrollView.removeGestureRecognizer(cancelCaptionEditTapRecognizer)
    }
  }

  // MARK: - Notifications

  @objc func handleKeyboardNotification(_ notification: Notification) {
    guard let captionWrapperBottomConstraint = captionWrapperBottomConstraint else { return }
    let keyboardHeight = MDCKeyboardWatcher.shared().visibleKeyboardHeight
    let duration = MDCKeyboardWatcher.animationDuration(fromKeyboardNotification: notification)
    let options = MDCKeyboardWatcher.animationCurveOption(fromKeyboardNotification: notification)
    UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
      captionWrapperBottomConstraint.constant = -keyboardHeight
      self.textFieldBottomConstraint?.constant = 0
      self.view.layoutIfNeeded()
    })
  }

  @objc private func downloadedImages(notification: Notification) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.downloadedImages(notification: notification)
      }
      return
    }

    guard let pictureImagePath = displayPicture.imagePath,
        let imagePaths = notification.userInfo?[DriveSyncUserInfoConstants.downloadedImagePathsKey]
            as? [String] else {
      return
    }

    if imagePaths.contains(pictureImagePath) {
      setImage(withPath: pictureImagePath)
    }
  }

  // MARK: - Private

  @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
    textField.endEditing(true)
  }

  @objc private func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
    scrollView.setZoomScale(scrollView.zoomScale == 1 ? 4 : 1, animated: true)
  }

  private func updateViewForDisplayNote() {
    updateCaptionFromDisplayNote()
    updateCaptionLayout()
  }

  private func setImage(withPath imagePath: String) {
    imageView.image = metadataManager.image(forFullImagePath: imagePath)
  }

  // MARK: - User actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func menuButtonPressed() {
    // Info.
    let popUpMenu = PopUpMenuViewController()
    popUpMenu.addAction(PopUpMenuAction(title: String.pictureDetailInfo,
                                        icon: UIImage(named: "ic_info")) { a -> Void in
      self.navigationController?.pushViewController(
          PictureInfoViewController(displayPicture: self.displayPicture,
                                    analyticsReporter: self.analyticsReporter,
                                    metadataManager: self.metadataManager),
          animated: true)
    })

    // Send a copy.
    if shouldAllowSharing,
        displayPicture.imageFileExists,
        let imagePath = displayPicture.imagePath {
      popUpMenu.addAction(PopUpMenuAction.share(withFilePath: imagePath,
                                                presentingViewController: self,
                                                sourceView: menuBarButton.button))
    }

    // Delete.
    func addDeleteAction() {
      popUpMenu.addAction(PopUpMenuAction(title: String.deleteNoteMenuItem,
                                          icon: UIImage(named: "ic_delete")) { a -> Void in
        self.delegate?.detailViewControllerDidDeleteNote(self.displayPicture)
        self.navigationController?.popViewController(animated: true)
      })
    }

    if experimentInteractionOptions.shouldAllowDeletes {
      addDeleteAction()
    }

    popUpMenu.present(from: self, position: .sourceView(menuBarButton.button))
  }

}
