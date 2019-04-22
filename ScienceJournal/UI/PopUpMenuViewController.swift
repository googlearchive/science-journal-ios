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

import third_party_objective_c_material_components_ios_components_ShadowLayer_ShadowLayer

/// Displays and triggers actions in a collection view. Selecting a cell will call the handler and
/// dismiss the view controller.
class PopUpMenuViewController: UIViewController, UICollectionViewDataSource,
    UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

  // MARK: - Properties

  /// The collection view's container view.
  let collectionViewContainer = ShadowedView()

  /// Pop up menu content insets. This is how close to each edge of the screen it is allowed to be.
  static let contentInsets = UIEdgeInsets(top: PopUpMenuCell.height, left: 10,
                                          bottom: PopUpMenuCell.height, right: 10)

  /// Additional top inset, used to account for presenting in views containing an app bar. Pass a
  /// value in to prevent the menu from positioning itself over the app bar. Only used when
  /// passing an anchor position in to `presentFrom` and not a source view.
  var additionalTopContentInset: CGFloat = 0

  /// Dims the view behind the wrapper view.
  var isBackgroundDim: Bool = false {
    didSet {
      view.backgroundColor = isBackgroundDim ? UIColor(white: 0, alpha: 0.3) : .clear
    }
  }

  private var actions = [PopUpMenuAction]()
  private let popUpMenuCellIdentifier = "popUpMenuCellIdentifier"
  private let popUpMenuTransitionController = PopUpMenuTransitionController()
  private let popUpMenuMinimumWidth: CGFloat = 160
  private let collectionView: UICollectionView

  // The pop up menu content size.
  private var contentSize: CGSize {
    // Width, calculated to fit the largest action title, plus text insets. Does not allow a width
    // narrower than `popUpMenuMinimumWidth` or wider than the view bounds minus `contentInsets`.
    var width = popUpMenuMinimumWidth
    for action in actions {
      var actionWidth = ceil(action.title.labelWidth(font: PopUpMenuCell.textLabelFont)) +
          PopUpMenuCell.margins.left + PopUpMenuCell.margins.right
      if action.icon != nil {
        actionWidth += PopUpMenuCell.imageViewSize.width + PopUpMenuCell.textToImageSpacing
      }
      if actionWidth > width {
        width = actionWidth
      }
    }
    width = min(view.bounds.size.width - PopUpMenuViewController.contentInsets.left -
                    PopUpMenuViewController.contentInsets.right,
                width)

    // Height, calculated to fit the number of rows needed to show all actions. Does not allow a
    // height taller than the view bounds minus `contentInsets`.
    let maximumHeight = view.bounds.size.height - PopUpMenuViewController.contentInsets.top -
        PopUpMenuViewController.contentInsets.bottom
    let height = min(maximumHeight, actionsHeight)

    // Size.
    return CGSize(width: width, height: height)
  }

  // The height of the actions, if allowed infinite bounds.
  private var actionsHeight: CGFloat {
    return PopUpMenuCell.height * CGFloat(actions.count)
  }

  private var collectionViewLayout: UICollectionViewFlowLayout = {
    let collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.minimumLineSpacing = 0
    return collectionViewLayout
  }()

  // MARK: Public

  init() {
    collectionView = UICollectionView(frame: .zero,
                                      collectionViewLayout: collectionViewLayout)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    collectionView = UICollectionView(frame: .zero,
                                      collectionViewLayout: collectionViewLayout)
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView.register(PopUpMenuCell.self, forCellWithReuseIdentifier: popUpMenuCellIdentifier)

    // Shadowed wrapper view.
    view.addSubview(collectionViewContainer)
    collectionViewContainer.setElevation(points: ShadowElevation.menu.rawValue)

    // Collection view.
    collectionView.alwaysBounceVertical = false
    collectionView.backgroundColor = .white
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.frame = collectionViewContainer.bounds
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionViewContainer.addSubview(collectionView)

    // Gesture recognizer for canceling when touches occur outside the pop up menu view.
    let tapGestureRecognizer =
        UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    tapGestureRecognizer.cancelsTouchesInView = false
    view.addGestureRecognizer(tapGestureRecognizer)

    preferredContentSize = contentSize
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // If the preferred content size is too small to fit all actions on screen at a time, flash the
    // scroll indicator.
    if preferredContentSize.height < actionsHeight {
      collectionView.flashScrollIndicators()
    }
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    dismiss(animated: true)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  /// Adds a pop up menu action to be displayed.
  ///
  /// - Parameter action: The action.
  func addAction(_ action: PopUpMenuAction) {
    addActions([action])
  }

  /// Adds pop up menu actions to be displayed.
  ///
  /// - Parameter actions: The actions.
  func addActions(_ actions: [PopUpMenuAction]) {
    self.actions.append(contentsOf: actions)
  }

  /// Presents the pop up menu view controller.
  ///
  /// - Parameters:
  ///   - viewController: The presenting view controller.
  ///   - position: The position to display the pop up menu in.
  /// - Note: If a position is not passed in, the pop up menu view will be positioned in the center.
  func present(from viewController: UIViewController,
               position: PopUpMenuPosition? = nil) {
    modalPresentationStyle = .custom
    popUpMenuTransitionController.position = position
    transitioningDelegate = popUpMenuTransitionController
    viewController.present(self, animated: true)
    accessibilityViewIsModal = true
  }

  override func accessibilityPerformEscape() -> Bool {
    dismiss(animated: true)
    return true
  }

  // MARK: - UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return actions.count
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: popUpMenuCellIdentifier,
                                                  for: indexPath)
    if let popUpMenuCell = cell as? PopUpMenuCell {
      popUpMenuCell.icon = actions[indexPath.item].icon
      popUpMenuCell.textLabel.text = actions[indexPath.item].title
      popUpMenuCell.accessibilityLabel = actions[indexPath.item].accessibilityLabel
      popUpMenuCell.accessibilityHint = actions[indexPath.item].accessibilityHint
      popUpMenuCell.isEnabled = actions[indexPath.item].isEnabled
    }
    return cell
  }

  // MARK: - UICollectionViewDelegate

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let action = actions[indexPath.item]
    guard action.isEnabled else { return }

    dismiss(animated: true, completion: {
      guard let handler = action.handler else { return }
      handler(action)
    })
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.size.width, height: PopUpMenuCell.height)
  }

  // MARK: - Gesture recognizers

  @objc func handleTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {
    let point = tapGestureRecognizer.location(in: collectionView)
    if !collectionView.point(inside: point, with: nil) {
      dismiss(animated: true)
    }
  }

}
