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

/// The transition controller for pop up menu presentation.
class PopUpMenuTransitionController: NSObject, UIViewControllerAnimatedTransitioning,
    UIViewControllerTransitioningDelegate {

  // MARK: - Properties

  /// The position to display the pop up menu in.
  var position: PopUpMenuPosition?

  // Whether or not the view controller is presenting (otherwise it is dismissing).
  private var isPresenting: Bool?

  // The transition transform. Reused during the dismiss animation.
  private var transitionTransform: CGAffineTransform?

  private let popUpMenuViewAlphaHidden: CGFloat = 0
  private let popUpMenuViewAlphaVisible: CGFloat = 1
  private let presentationAnimationDuration: TimeInterval = 0.2
  private let popUpMenuViewScale: CGFloat = 0.5
  private let popUpMenuViewTransformFinal = CGAffineTransform.identity
  private var popUpMenuView: UIView?
  private var containerView: UIView?
  private weak var popUpMenuViewController: UIViewController?
  private let popUpMenuViewMargin: CGFloat = 10

  // MARK: - Public

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let isPresenting = isPresenting else { return }

    let duration = transitionDuration(using: transitionContext)
    if isPresenting {
      guard let popUpMenuViewController =
          transitionContext.viewController(forKey: .to) as? PopUpMenuViewController,
          let popUpMenuContainerView = popUpMenuViewController.view else {
        transitionContext.completeTransition(false)
        return
      }

      popUpMenuView = popUpMenuViewController.collectionViewContainer
      containerView = transitionContext.containerView
      self.popUpMenuViewController = popUpMenuViewController

      // Set up the pop up menu view for pre-transition.
      popUpMenuView?.alpha = popUpMenuViewAlphaHidden
      let (frame, anchor) =
          frameForPopUpMenuView(popUpMenuViewController.collectionViewContainer,
                                in: transitionContext.containerView,
                                popUpMenuViewController: popUpMenuViewController)
      popUpMenuView?.frame = frame
      popUpMenuView?.transform = anchor.transformForTransition(to: frame, with: popUpMenuViewScale)
      popUpMenuContainerView.frame = transitionContext.containerView.bounds
      transitionContext.containerView.addSubview(popUpMenuContainerView)
      // The pre-transition transform is also the transform used during the dismiss animation.
      transitionTransform = popUpMenuView?.transform
      // Animate the transition.
      UIView.animate(withDuration: duration,
                     animations: {
                       self.popUpMenuView?.alpha = self.popUpMenuViewAlphaVisible
                       self.popUpMenuView?.transform = self.popUpMenuViewTransformFinal
      },
                     completion: { (_) in
                       transitionContext.completeTransition(true)
      })
    } else {
      guard let popUpMenuViewController =
          transitionContext.viewController(forKey: .from) as? PopUpMenuViewController,
          let popUpMenuContainerView = popUpMenuViewController.view else {
        transitionContext.completeTransition(false)
        return
      }

      let popUpMenuView = popUpMenuViewController.collectionViewContainer

      // Animate the transition.
      UIView.animate(withDuration: duration,
                     animations: {
                       popUpMenuView.alpha = self.popUpMenuViewAlphaHidden
                       if let transitionTransform = self.transitionTransform {
                         popUpMenuView.transform = transitionTransform
                       }
      },
                     completion: { (_) in
                       popUpMenuContainerView.removeFromSuperview()
                       transitionContext.completeTransition(true)
      })
    }
  }

  func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    isPresenting = true
    return self
  }

  func animationController(
      forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    isPresenting = false
    return self
  }

  func transitionDuration(
      using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return presentationAnimationDuration
  }

  /// Updates the frame and transition transform for the pop up menu view to continue pointing at
  /// the correct view if necessary. Call this again after rotation to ensure proper positioning.
  func updateFrameForPopUpMenuView() {
    guard let popUpMenuView = popUpMenuView,
        let containerView = containerView,
        let popUpMenuViewController = popUpMenuViewController else { return }
    let (frame, anchor) =
      frameForPopUpMenuView(popUpMenuView,
                            in: containerView,
                            popUpMenuViewController: popUpMenuViewController)
    popUpMenuView.frame = frame
    transitionTransform = anchor.transformForTransition(to: frame, with: popUpMenuViewScale)
  }

  // MARK: - Private

  // Returns the frame and anchor for the pop up menu transition.
  private func frameForPopUpMenuView(
      _ popUpMenuView: UIView,
      in containerView: UIView,
      popUpMenuViewController: UIViewController) -> (CGRect, PopUpMenuAnchor) {

    // The insets to use when positioning the pop up menu view. This accounts for any additional top
    // content inset passed into the pop up menu view controller.
    var insets: UIEdgeInsets {
      var insets = PopUpMenuViewController.contentInsets
      if let popUpMenuViewController = popUpMenuViewController as? PopUpMenuViewController {
        insets.top += popUpMenuViewController.additionalTopContentInset
      }
      return insets
    }

    let popUpMenuContentSize = popUpMenuViewController.preferredContentSize

    if let position = self.position {
      switch position {
      case .coveringView(let view):
        // If we have a covering view, we can position the pop up menu covering its frame.
        guard let superview = view.superview else { break }
        let coveringFrame = superview.convert(view.frame, to: containerView)

        // If we have a covering view, we can try to cover the pop up menu on each corner of it.
        let canCoverLeft = containerView.bounds.size.width - popUpMenuContentSize.width -
          coveringFrame.origin.x > 0
        let canCoverRight = coveringFrame.maxX - popUpMenuContentSize.width > 0
        let canCoverTop = containerView.bounds.size.height - popUpMenuContentSize.height -
          coveringFrame.origin.y > 0
        let canCoverBottom = coveringFrame.maxY - popUpMenuContentSize.height > 0

        // Cover with the pop up menu's origin at top left corner of the origin view.
        if canCoverLeft && canCoverTop {
          let frame = CGRect(x: coveringFrame.origin.x,
                             y: coveringFrame.origin.y,
                             width: popUpMenuContentSize.width,
                             height: popUpMenuContentSize.height)
          return (frame, .topLeft)
        }

        // Cover with the pop up menu's origin at top right corner of the origin view.
        if canCoverRight && canCoverTop {

          let frame = CGRect(x: coveringFrame.maxX - popUpMenuContentSize.width,
                             y: coveringFrame.origin.y,
                             width: popUpMenuContentSize.width,
                             height: popUpMenuContentSize.height)
          return (frame, .topRight)
        }

        // Cover with the pop up menu's origin at bottom left corner of the origin view.
        if canCoverLeft && canCoverBottom {
          let frame = CGRect(x: coveringFrame.origin.x,
                             y: coveringFrame.maxY - popUpMenuContentSize.height,
                             width: popUpMenuContentSize.width,
                             height: popUpMenuContentSize.height)
          return (frame, .bottomLeft)
        }

        // Cover with the pop up menu's origin at bottom right corner of the origin view.
        if canCoverRight && canCoverBottom {
          let frame = CGRect(x: coveringFrame.maxX - popUpMenuContentSize.width,
                             y: coveringFrame.maxY - popUpMenuContentSize.height,
                             width: popUpMenuContentSize.width,
                             height: popUpMenuContentSize.height)
          return (frame, .bottomRight)
        }
      case .sourceView(let view):
        // If we have a source view, position the pop up menu anchored to, or at least near it.
        guard let superview = view.superview else { break }
        let sourceFrame = superview.convert(view.frame, to: containerView)

        let spaceForAnchoringLeft = containerView.bounds.size.width - popUpMenuContentSize.width -
            sourceFrame.minX - popUpMenuViewMargin
        let spaceForAnchoringRight = sourceFrame.maxX - popUpMenuContentSize.width -
            popUpMenuViewMargin
        let spaceForAnchoringTop = containerView.bounds.size.height - popUpMenuContentSize.height -
            sourceFrame.maxY - popUpMenuViewMargin
        let spaceForAnchoringBottom = sourceFrame.minY - popUpMenuContentSize.height -
            popUpMenuViewMargin

        // If we shouldn't anchor left, we should anchor right. If we shouldn't anchor top, we
        // should anchor bottom.
        let shouldAnchorLeft = spaceForAnchoringLeft > spaceForAnchoringRight
        let shouldAnchorTop = spaceForAnchoringTop > spaceForAnchoringBottom

        var frame: CGRect {
          // If there is enough space for the pop up menu in a direction, this returns zero,
          // otherwise it returns the offset needed to fit the pop up menu in the direction.
          func offsetOrZero(withSpaceForAnchoringDirection space: CGFloat) -> CGFloat {
            // The space needed is any negative value.
            return space < 0 ? space : 0
          }

          var leftOffset: CGFloat {
            return offsetOrZero(withSpaceForAnchoringDirection: spaceForAnchoringLeft)
          }

          var rightOffset: CGFloat {
            return offsetOrZero(withSpaceForAnchoringDirection: spaceForAnchoringRight)
          }

          var topOffset: CGFloat {
            return offsetOrZero(withSpaceForAnchoringDirection: spaceForAnchoringTop)
          }

          var bottomOffset: CGFloat {
            return offsetOrZero(withSpaceForAnchoringDirection: spaceForAnchoringBottom)
          }

          let originX = shouldAnchorLeft ?
              sourceFrame.minX + leftOffset :
              sourceFrame.maxX - popUpMenuContentSize.width + rightOffset
          let originY = shouldAnchorTop ?
              sourceFrame.maxY + topOffset :
              sourceFrame.minY - popUpMenuContentSize.height + bottomOffset
          return CGRect(x: originX,
                        y: originY,
                        width: popUpMenuContentSize.width,
                        height: popUpMenuContentSize.height)
        }

        var anchor: PopUpMenuAnchor {
          if shouldAnchorTop {
            if shouldAnchorLeft {
              return .topLeft
            } else {
              return .topRight
            }
          } else {
            if shouldAnchorLeft {
              return .bottomLeft
            } else {
              return .bottomRight
            }
          }
        }

        return (frame, anchor)
      case .topLeft, .topRight, .bottomLeft, .bottomRight, .center:
        return (position.frame(for: popUpMenuContentSize, in: containerView.bounds, with: insets),
                position.anchor)
      }
    }

    // If there was no position, position it in the center.
    let position = PopUpMenuPosition.center
    return (position.frame(for: popUpMenuContentSize, in: containerView.bounds, with: insets),
            position.anchor)
  }

}
