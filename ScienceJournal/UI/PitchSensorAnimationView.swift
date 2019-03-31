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

import QuartzCore
import UIKit
import MaterialComponents

fileprivate extension MDCTypography {

  static func boldFont(withSize size: CGFloat) -> UIFont {
    // This font should load unless something is wrong with Material's fonts.
    return MDCTypography.fontLoader().boldFont!(ofSize: size)
  }

  static var fontName: String {
    // Arbitrary size to get the font name.
    return boldFont(withSize: 10).fontName
  }

}

/// Animation view for the pitch sensor.
class PitchSensorAnimationView: SensorAnimationView {

  // MARK: - Nested

  private enum Metrics {
    static let backgroundColorValueBlueHigh: CGFloat = 175
    static let backgroundColorValueBlueLow: CGFloat = 248
    static let backgroundColorValueGreenHigh: CGFloat = 97
    static let backgroundColorValueGreenLow: CGFloat = 202
    static let backgroundColorValueRedHigh: CGFloat = 13
    static let backgroundColorValueRedLow: CGFloat = 113
    static let backgroundRadiusRatio: CGFloat = 0.38
    static let dotAngleTop = CGFloat(Double.pi / 2)
    static let dotEllipseRadiusRatio: CGFloat = 0.44
    static let dotRadiusRatio: CGFloat = 0.05
    static let musicSignFlat = "\u{266D} "
    static let musicSignSharp = "\u{266F} "
    static let noteFontSizeRatio: CGFloat = 0.48
    static let noteRatioX: CGFloat = 0.42
    static let noteRatioY: CGFloat = 0.46
    static let noteLeftTextColor =
        UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 1).cgColor
    static let noteRightTextColor =
        UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
    static let numberOfPianoKeys = 88
    static let octaveFontSizeRatio: CGFloat = 0.2
    static let octaveRatioX: CGFloat = 0.67
    static let octaveRatioY: CGFloat = 0.67
    static let octaveTextColor =
        UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
    static let signFontSizeRatio: CGFloat = 0.25
    static let signRatioX: CGFloat = 0.62
    static let signRatioY: CGFloat = 0.43
    static let signTextColor =
        UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
    static let textShadowColor = UIColor(white: 0, alpha: 0.61).cgColor
    static let textShadowOffset = CGSize(width: 1, height: 2)
    static let textShadowRadius: CGFloat = 4
  }

  private struct MusicalNote {
    let letter: String
    let octave: String
    let sign: String

    var shouldCenter: Bool {
      // "-" and "+" should be centered.
      return letter == "-" || letter == "+"
    }

  }

  // MARK: - Properties

  private let backgroundShapeLayer = CAShapeLayer()
  private let dotShapeLayer = CAShapeLayer()
  private let noteLeftTextLayer = CATextLayer()
  private let noteRightTextLayer = CATextLayer()
  private let signTextLayer = CATextLayer()
  private let octaveTextLayer = CATextLayer()

  // The angle of the dot indicating how close the detected pitch is to the nearest musical note. A
  // value of 0 positions the dot at the far right. A value of PI/2 positions the dot at the top. A
  // value of PI positions the dot at the far left.
  private var angleOfDot = Metrics.dotAngleTop

  private var level: Int?

  private var musicalNote: MusicalNote? {
    guard let level = level else { return nil }
    return musicalNotes[level]
  }

  private let musicalNotes: [MusicalNote] = {
    let natural = ""

    var musicalNotes = [MusicalNote]()
    musicalNotes.append(MusicalNote(letter: "-", octave: "", sign: ""))
    for i in 1...Metrics.numberOfPianoKeys {
      var letter = ""
      var sign = ""
      switch (i + 8) % 12 {
      case 0:
        letter = "C"
        sign = natural
      case 1:
        letter = "C"
        sign = Metrics.musicSignSharp
      case 2:
        letter = "D"
        sign = natural
      case 3:
        letter = "E"
        sign = Metrics.musicSignFlat
      case 4:
        letter = "E"
        sign = natural
      case 5:
        letter = "F"
        sign = natural
      case 6:
        letter = "F"
        sign = Metrics.musicSignSharp
      case 7:
        letter = "G"
        sign = natural
      case 8:
        letter = "A"
        sign = Metrics.musicSignFlat
      case 9:
        letter = "A"
        sign = natural
      case 10:
        letter = "B"
        sign = Metrics.musicSignFlat
      case 11:
        letter = "B"
        sign = natural
      default:
        break
      }
      let octave = (i + 8) / 12
      musicalNotes.append(MusicalNote(letter: letter, octave: String(octave), sign: sign))
    }
    musicalNotes.append(MusicalNote(letter: "+", octave: "", sign: ""))
    return musicalNotes
  }()

  /// The frequencies of notes of a piano at indices 1-88. Each value is a half step more than the
  /// previous value.
  private let noteFrequencies: [Double] = {
    var noteFrequencies = [Double]()
    var multiplier = 1.0

    while (noteFrequencies.count < Metrics.numberOfPianoKeys) {
      for note in SoundUtils.highNotes {
        guard noteFrequencies.count < Metrics.numberOfPianoKeys else { break }
        noteFrequencies.append(note * multiplier)
      }
      multiplier /= 2.0
    }
    noteFrequencies.reverse()
    // Add first and last items to make lookup easier. Use the approximate half-step ratio to
    // determine the first and last items.
    noteFrequencies.insert(noteFrequencies[0] / SoundUtils.halfStepFrequencyRatio, at: 0)
    noteFrequencies.append(
      noteFrequencies[noteFrequencies.endIndex - 1] * SoundUtils.halfStepFrequencyRatio
    )
    return noteFrequencies
  }()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Background shape layer.
    let backgroundShapeRadius = bounds.width * Metrics.backgroundRadiusRatio
    let backgroundShapeRect = CGRect(x: bounds.midX - backgroundShapeRadius,
                                     y: bounds.midY - backgroundShapeRadius,
                                     width: backgroundShapeRadius * 2,
                                     height: backgroundShapeRadius * 2)
    backgroundShapeLayer.path = UIBezierPath(ovalIn: backgroundShapeRect).cgPath

    // Dot shape layer will be at a point on an invisible ellipse.
    let ellipseRadius = bounds.width * Metrics.dotEllipseRadiusRatio
    let dotX = bounds.midX + ellipseRadius * cos(angleOfDot)
    let dotY = bounds.midY - ellipseRadius * sin(angleOfDot)
    let dotRadius = bounds.width * Metrics.dotRadiusRatio
    let dotShapeRect = CGRect(x: dotX - dotRadius,
                              y: dotY - dotRadius,
                              width: dotRadius * 2,
                              height: dotRadius * 2)
    dotShapeLayer.path = UIBezierPath(ovalIn: dotShapeRect).cgPath

    // Text layers.
    if let musicalNote = musicalNote {
      // Letter
      let noteFontSize = floor(bounds.height * Metrics.noteFontSizeRatio)
      noteLeftTextLayer.fontSize = noteFontSize
      noteRightTextLayer.fontSize = noteFontSize
      let noteSize = musicalNote.letter.boundingRect(
          with: .zero,
          options: [],
          attributes: [NSAttributedString.Key.font: MDCTypography.boldFont(withSize: noteFontSize)],
          context: nil).size
      var noteX: CGFloat
      var noteY: CGFloat
      if musicalNote.shouldCenter {
        noteX = bounds.midX - ceil(noteSize.width) / 2
        noteY = bounds.midY - ceil(noteSize.height) / 2
      } else {
        noteX = bounds.width * Metrics.noteRatioX - ceil(noteSize.width) / 2
        noteY = bounds.height * Metrics.noteRatioY -  ceil(noteSize.height) / 2
      }

      // The note layer on the left is half width.
      noteLeftTextLayer.frame = CGRect(x: floor(noteX),
                                       y: floor(noteY),
                                       width: ceil(noteSize.width / 2),
                                       height: ceil(noteSize.height))
      noteRightTextLayer.frame = CGRect(x: floor(noteX),
                                        y: floor(noteY),
                                        width: ceil(noteSize.width),
                                        height: ceil(noteSize.height))

      // Sign.
      signTextLayer.fontSize = floor(bounds.height * Metrics.signFontSizeRatio)
      let signFont = MDCTypography.boldFont(withSize: signTextLayer.fontSize)
      let signSize = musicalNote.sign.boundingRect(
          with: .zero,
          options: [],
          attributes: [NSAttributedString.Key.font: signFont],
          context: nil).size
      signTextLayer.frame =
          CGRect(x: floor(bounds.width * Metrics.signRatioX - signSize.width / 2),
                 y: floor(bounds.height * Metrics.signRatioY - signSize.height / 2),
                 width: ceil(signSize.width),
                 height: ceil(signSize.height))

      // Octave
      octaveTextLayer.fontSize = floor(bounds.height * Metrics.octaveFontSizeRatio)
      let octaveFont = MDCTypography.boldFont(withSize: octaveTextLayer.fontSize)
      let octaveSize =
          musicalNote.octave.boundingRect(with: .zero,
                                          options: [],
                                          attributes: [NSAttributedString.Key.font: octaveFont],
                                          context: nil).size
      octaveTextLayer.frame =
          CGRect(x: floor(bounds.width * Metrics.octaveRatioX - octaveSize.width / 2),
                 y: floor(bounds.height * Metrics.octaveRatioY - octaveSize.height / 2),
                 width: ceil(octaveSize.width),
                 height: ceil(octaveSize.height))
    }
  }

  override func setValue(_ value: Double, minValue: Double, maxValue: Double) {
    guard let level = noteIndex(fromFrequency: value), level != self.level else { return }

    // Store the level.
    self.level = level

    // Set the fill color of the background shape layer.
    backgroundShapeLayer.fillColor = backgroundColor(forLevel: level).cgColor

    // The the angle of the dot.
    let difference = differenceBetween(pitch: value, andLevel: level)
    angleOfDot = CGFloat((1 - 2 * difference) * (Double.pi / 2))

    // Set the musical note letter, sign and octave.
    let musicalNote = musicalNotes[level]
    noteLeftTextLayer.string = musicalNote.letter
    noteRightTextLayer.string = musicalNote.letter
    signTextLayer.string = musicalNote.sign
    octaveTextLayer.string = musicalNote.octave

    setNeedsLayout()

    setAccessibilityLabel(withMusicalNote: musicalNote,
                          level: level,
                          differenceBetweenNoteAndPitch: difference)
  }

  override func reset() {
    setValue(0, minValue: 0, maxValue: 0)
  }

  /// Returns an image snapshot and an accessibility label for this view, showing a given value.
  ///
  /// - Parameters:
  ///   - size: The size of the image on screen.
  ///   - value: The value to display the pitch at.
  /// - Returns: A tuple containing an optional image snapshot and an optional accessibility label.
  static func imageAttributes(atSize size: CGSize, withValue value: Double) -> (UIImage?, String?) {
    let pitchSensorAnimationView =
      PitchSensorAnimationView(frame: CGRect(origin: .zero, size: size))
    pitchSensorAnimationView.setValue(value, minValue: 0, maxValue: 1)
    return (pitchSensorAnimationView.imageSnapshot, pitchSensorAnimationView.accessibilityLabel)
  }

  // MARK: - Private

  private func backgroundColor(forLevel level: Int) -> UIColor {
    if (level == 0) {
      return UIColor(red: Metrics.backgroundColorValueRedLow / 255,
                     green: Metrics.backgroundColorValueGreenLow / 255,
                     blue: Metrics.backgroundColorValueBlueLow / 255, alpha: 1)
    } else if level == noteFrequencies.endIndex - 1 {
      return UIColor(red: Metrics.backgroundColorValueRedHigh / 255,
                     green: Metrics.backgroundColorValueGreenHigh / 255,
                     blue: Metrics.backgroundColorValueBlueHigh / 255, alpha: 1)
    } else {
      let red = round(Metrics.backgroundColorValueRedLow +
          (Metrics.backgroundColorValueRedHigh - Metrics.backgroundColorValueRedLow) *
          CGFloat(level) / CGFloat(noteFrequencies.endIndex - 1))
      let green = round(Metrics.backgroundColorValueGreenLow +
          (Metrics.backgroundColorValueGreenHigh - Metrics.backgroundColorValueGreenLow) *
          CGFloat(level) / CGFloat(noteFrequencies.endIndex - 1))
      let blue = round(Metrics.backgroundColorValueBlueLow +
          (Metrics.backgroundColorValueBlueHigh - Metrics.backgroundColorValueBlueLow) *
          CGFloat(level) / CGFloat(noteFrequencies.endIndex - 1))
      return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
  }

  private func configureView() {
    isAccessibilityElement = true

    // Background image view.
    let imageView = UIImageView(image: UIImage(named: "sensor_sound_frequency_0"))
    imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    imageView.frame = bounds
    addSubview(imageView)

    // Background shape layer.
    backgroundShapeLayer.fillColor = backgroundColor(forLevel: 0).cgColor
    layer.addSublayer(backgroundShapeLayer)

    // Dot shape layer.
    dotShapeLayer.fillColor = UIColor.red.cgColor
    layer.addSublayer(dotShapeLayer)

    // Text layer common configuration.
    [noteRightTextLayer, noteLeftTextLayer, signTextLayer, octaveTextLayer].forEach {
      $0.alignmentMode = .center
      $0.contentsScale = UIScreen.main.scale
      $0.font = CGFont(MDCTypography.fontName as CFString)
      $0.shadowColor = Metrics.textShadowColor
      $0.shadowOffset = Metrics.textShadowOffset
      $0.shadowRadius = Metrics.textShadowRadius
      layer.addSublayer($0)
    }

    // Right note.
    noteRightTextLayer.foregroundColor = Metrics.noteRightTextColor

    // Left note.
    noteLeftTextLayer.foregroundColor = Metrics.noteLeftTextColor
    noteLeftTextLayer.masksToBounds = true

    // Sign.
    signTextLayer.foregroundColor = Metrics.signTextColor

    // Octave.
    octaveTextLayer.foregroundColor = Metrics.octaveTextColor

    // Set the lowest detectable value initially.
    reset()
  }

  // The difference, in half steps, between the detected pitch and the note associated with the
  // level.
  func differenceBetween(pitch: Double, andLevel level: Int) -> Double {
    if (level == 0 || level == noteFrequencies.endIndex - 1) {
      // If the nearest musical note is more than one half step lower than the lowest musical note
      // or more than one half step higher than the highest musical note, don't calculate the
      // difference.
      return 0
    }

    // If the detected pitch equals a musical note the dot is at the top, which is 90 degrees or
    // Double.pi / 2 radians. If the detected pitch is half way between the nearest musical note and
    // the next lower musical note, the dot is at the far left, which is 180 degrees, or Double.pi
    // radians. If the detected pitch is half way between the nearest musical note and the next
    // higher musical note, the dot is at the far right, which is 0 degrees, or 0 radians.
    let nearestNote = noteFrequencies[level]
    var difference = pitch - nearestNote
    if (difference < 0) {
      // The detected pitch is lower than the nearest musical note. Adjust the difference to the
      // range of -1 to 0, where -1 is the next lower note. The difference should never be less than
      // -0.5, since that would indicate that the  pitch was actually closer to the lower note.
      let lowerNote = noteFrequencies[level - 1]
      difference /= nearestNote - lowerNote
    } else {
      // The detected pitch is higher than the nearest musical note. Adjust the difference to the
      // range of 0 to 1, where 1 is the next higher note. The difference should never be greater
      // than 0.5, since that would indicate that the pitch was actually closer to the higher note.
      let higherNote = noteFrequencies[level + 1]
      difference /= higherNote - nearestNote
    }
    return difference
  }

  /// The index of the note corresponding to the given sound frequency, where indices 1-88 represent
  /// the notes of keys on a piano.
  private func noteIndex(fromFrequency frequency: Double) -> Int? {
    if frequency < noteFrequencies[0] {
      // `frequency` is lower than the lowest note.
      return 0
    } else if frequency > noteFrequencies[noteFrequencies.endIndex - 1] {
      // `frequency` is higher than the highest note.
      return noteFrequencies.endIndex - 1
    } else {
      var previousNote: Double?
      for (index, note) in noteFrequencies.enumerated() {
        if note == frequency {
          // `frequency` matched a note.
          return index
        }

        if let previousNote = previousNote, frequency > previousNote && frequency < note {
          // `frequency` is between two notes.
          let midpoint = (previousNote + note) / 2
          return frequency < midpoint ? index - 1 : index
        }
        previousNote = note
      }
    }
    return nil
  }

  private func setAccessibilityLabel(withMusicalNote musicalNote: MusicalNote,
                                     level: Int,
                                     differenceBetweenNoteAndPitch difference: Double) {
    let accessibilityLabel: String
    if level == 0 {
      accessibilityLabel = String.pitchLowContentDescription
    } else if (level == noteFrequencies.endIndex - 1) {
      accessibilityLabel = String.pitchHighContentDescription
    } else {
      let formatString: String
      let differenceString = String.localizedStringWithFormat("%.2f", abs(difference))
      if difference < 0 {
        if musicalNote.sign == Metrics.musicSignFlat {
          formatString = String.pitchFlatterThanFlatNoteContentDescription
        } else if musicalNote.sign == Metrics.musicSignSharp {
          formatString = String.pitchFlatterThanSharpNoteContentDescription
        } else {
          // Natural note
          formatString = String.pitchFlatterThanNaturalNoteContentDescription
        }
        accessibilityLabel =
            String(format: formatString, differenceString, musicalNote.letter, musicalNote.octave)
      } else if difference > 0 {
        if musicalNote.sign == Metrics.musicSignFlat {
          formatString = String.pitchSharperThanFlatNoteContentDescription
        } else if musicalNote.sign == Metrics.musicSignSharp {
          formatString = String.pitchSharperThanSharpNoteContentDescription
        } else {
          // Natural note
          formatString = String.pitchSharperThanNaturalNoteContentDescription
        }
        accessibilityLabel =
            String(format: formatString, differenceString, musicalNote.letter, musicalNote.octave)
      } else {
        // difference == 0
        if musicalNote.sign == Metrics.musicSignFlat {
          formatString = String.pitchFlatNoteContentDescription
        } else if musicalNote.sign == Metrics.musicSignSharp {
          formatString = String.pitchSharpNoteContentDescription
        } else {
          // Natural note
          formatString = String.pitchNaturalNoteContentDescription
        }
        accessibilityLabel = String(format: formatString, musicalNote.letter, musicalNote.octave)
      }
    }
    self.accessibilityLabel = accessibilityLabel
  }

}
