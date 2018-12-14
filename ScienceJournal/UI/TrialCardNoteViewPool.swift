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

/// Creates and caches views used for trial card notes that are not on screen and available for
/// display.
class TrialCardNoteViewPool {

  // MARK: - Properties

  private var availableViews = [String: [UIView]]()

  // MARK: - Public

  /// Designated initializer.
  init() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationDidReceiveMemoryWarning),
                                           name: UIApplication.didReceiveMemoryWarningNotification,
                                           object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Creates or returns a cached text note card view to be used for a trial card notes view.
  ///
  /// - Parameters:
  ///   - textNote: The text note.
  ///   - preferredWidth: The preferred width.
  /// - Returns: The text note card view.
  func textNoteView(withTextNote textNote: DisplayTextNote,
                    preferredWidth: CGFloat) -> TextNoteCardView {
    if let textNoteCardView = view(forClass: TextNoteCardView.self) as? TextNoteCardView {
      textNoteCardView.textNote = textNote
      return textNoteCardView
    } else {
      return TextNoteCardView(textNote: textNote,
                              preferredMaxLayoutWidth: preferredWidth,
                              showTimestamp: true)
    }
  }

  /// Creates or returns a cached snapshot card view to be used for a trial card notes view.
  ///
  /// - Parameters:
  ///   - snapshot: The snapshot value.
  ///   - preferredWidth: The preferred width.
  /// - Returns: The snapshot card view.
  func snapshotView(withSnapshot snapshot: DisplaySnapshotValue,
                    preferredWidth: CGFloat) -> SnapshotCardView {
    if let snapshotCardView = view(forClass: SnapshotCardView.self) as? SnapshotCardView {
      snapshotCardView.snapshot = snapshot
      return snapshotCardView
    } else {
      return SnapshotCardView(snapshot: snapshot,
                              preferredMaxLayoutWidth: preferredWidth,
                              showTimestamp: true)
    }
  }

  /// Creates or returns a cached picture card view to be used for a trial card notes view.
  ///
  /// - Parameter: pictureNote: The picture note.
  /// - Returns: The picture card view.
  func pictureView(withPictureNote pictureNote: DisplayPictureNote) -> PictureCardView {
    if let pictureCardView = view(forClass: PictureCardView.self) as? PictureCardView {
      pictureCardView.pictureNote = pictureNote
      return pictureCardView
    } else {
      return PictureCardView(pictureNote: pictureNote,
                             style: PictureStyle.small,
                             showTimestamp: true)
    }
  }

  /// Creates or returns a cached trigger card view to be used for a trial card notes view.
  ///
  /// - Parameters:
  ///   - triggerNote: The trigger note.
  ///   - preferredWidth: The preferred width.
  /// - Returns: The trigger card view.
  func triggerNoteView(withTriggerNote triggerNote: DisplayTriggerNote,
                       preferredWidth: CGFloat) -> TriggerCardView {
    if let triggerCardView = view(forClass: TriggerCardView.self) as? TriggerCardView {
      triggerCardView.triggerNote = triggerNote
      return triggerCardView
    } else {
      return TriggerCardView(triggerNote: triggerNote,
                             preferredMaxLayoutWidth: preferredWidth,
                             showTimestamp: true)
    }
  }

  /// Creates or returns a cached experiment card caption view to be used for a trial card notes
  /// view.
  ///
  /// - Parameter text: The text.
  /// - Returns: The experiment card caption view.
  func captionView(withText text: String?) -> ExperimentCardCaptionView {
    let captionView: ExperimentCardCaptionView
    if let experimentCardCaptionView =
        view(forClass: ExperimentCardCaptionView.self) as? ExperimentCardCaptionView {
      captionView = experimentCardCaptionView
    } else {
      captionView = ExperimentCardCaptionView()
    }
    captionView.captionLabel.text = text
    return captionView
  }

  /// Creates or returns a cached separator view to be used for a trial card notes view.
  ///
  /// - Returns: The separator view.
  func separatorView() -> SeparatorView {
    if let separatorView = view(forClass: SeparatorView.self) as? SeparatorView {
      return separatorView
    } else {
      return SeparatorView(direction: .horizontal, style: .light)
    }
  }

  /// Caches trial card note views.
  ///
  /// - Parameter views: Trial card note views.
  func storeViews(_ views: [UIView]) {
    for view in views {
      guard view is ExperimentCardView || view is SeparatorView else { continue }

      if let experimentCardView = view as? ExperimentCardView {
        experimentCardView.reset()
      }
      storeView(view)
    }
  }

  /// Returns a view for a trial card note view class if there is one available, otherwise returns
  /// nil. Exposed for testing.
  ///
  /// - Parameter aClass: A trial card note view class.
  /// - Returns: The trial card note view or nil.
  func view(forClass aClass: AnyClass) -> UIView? {
    let key = NSStringFromClass(aClass)
    guard var views = availableViews[key], views.count > 0 else { return nil }
    let view = views.removeFirst()
    availableViews[key] = views
    return view
  }

  // MARK: - Private

  /// Stores a view for a trial card note view type.
  ///
  /// - Parameter view: A trial card note view.
  private func storeView(_ view: UIView) {
    let key = NSStringFromClass(view.classForCoder)
    var views: [UIView]
    if let availableViewsForKey = availableViews[key] {
      views = availableViewsForKey
    } else {
      views = [UIView]()
    }

    // Only store the view if we have less than the maximimum count for the class.
    let maximumViewCount: Int
    if view is SnapshotCardView || view is SeparatorView {
      maximumViewCount = 100
    } else {
      maximumViewCount = 10
    }
    guard views.count < maximumViewCount else { return }

    views.append(view)
    availableViews[key] = views
  }

  // MARK: - Notifications

  @objc func applicationDidReceiveMemoryWarning() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.applicationDidReceiveMemoryWarning()
      }
      return
    }

    availableViews.removeAll()
  }

}
