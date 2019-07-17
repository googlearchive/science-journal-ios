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

/// A view that shows notes in a trial card.
class TrialCardNotesView: UIView {

  // MARK: - Properties

  /// The picture card views being displayed.
  var pictureCardViews = [PictureCardView]()

  /// The trial card note view pool.
  var trialCardNoteViewPool: TrialCardNoteViewPool?

  private var views = [UIView]()

  // MARK: - Public

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    var height: CGFloat = 0
    for view in views {
      view.frame.size.width = size.width
      view.sizeToFit()
      height += view.frame.height
    }
    return CGSize(width: size.width, height: height)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    var originY: CGFloat = 0
    for view in views {
      view.frame = CGRect(x: 0, y: originY, width: bounds.width, height: bounds.height)
      view.sizeToFit()
      originY = view.frame.maxY
    }
  }

  /// Adds a separator if needed and then creates the appropriate view from a trial note and adds it
  /// to the trial card notes view.
  ///
  /// - Parameter trialNote: The trial note.
  func addTrialNote(_ trialNote: DisplayNote, experimentDisplay: ExperimentDisplay) {
    guard let trialCardNoteViewPool = trialCardNoteViewPool else { return }

    if views.count > 0 {
      addView(trialCardNoteViewPool.separatorView())
    }

    var caption: String?
    switch trialNote.noteType {
    case .textNote(let displayTextNote):
      addView(trialCardNoteViewPool.textNoteView(withTextNote: displayTextNote,
                                                 preferredWidth: bounds.width))
    case .snapshotNote(let displaySnapshotNote):
      for snapshot in displaySnapshotNote.snapshots {
        addView(trialCardNoteViewPool.snapshotView(withSnapshot: snapshot,
                                                   preferredWidth: bounds.width))
      }
      caption = displaySnapshotNote.caption
    case .pictureNote(let displayPictureNote):
      let pictureView = trialCardNoteViewPool.pictureView(
        withPictureNote: displayPictureNote,
        pictureStyle: experimentDisplay.trialPictureStyle)
      addView(pictureView)
      caption = displayPictureNote.caption
      pictureCardViews.append(pictureView)
    case .triggerNote(let displayTriggerNote):
      addView(trialCardNoteViewPool.triggerNoteView(withTriggerNote: displayTriggerNote,
                                                    preferredWidth: bounds.width))
      caption = displayTriggerNote.caption
    }

    guard caption != nil else { return }
    addView(trialCardNoteViewPool.captionView(withText: caption))
  }

  /// Removes all notes from the trial card notes view.
  func removeAllNotes() {
    pictureCardViews.removeAll()
    views.forEach { $0.removeFromSuperview() }
    trialCardNoteViewPool?.storeViews(views)
    views.removeAll()
  }

  // MARK: - Private

  private func addView(_ view: UIView) {
    addSubview(view)
    views.append(view)
  }

}
