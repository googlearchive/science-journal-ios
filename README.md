<h3 align="center">
  <img src="assets/sj_lockup.png?raw=true" alt="Science Journal Logo" width="700">
</h3>

[![Twitter: @GScienceJournal](https://img.shields.io/badge/contact-@GScienceJournal-673fb4.svg?style=flat)](https://twitter.com/GScienceJournal)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[Science Journal for iOS][appstore] allows you to gather data from the world around you. It uses sensors to
measure your environment, like light and sound, so you can graph your data, record your experiments,
and organize your questions and ideas. It's the lab notebook you always have with you.

<img src="assets/image1.png?raw=true" alt="iOS screenshot showing experiments list." width="175"><img src="assets/image2.png?raw=true" alt="iOS screenshot showing `Iodine Clock` experiment." width="175"><img src="assets/image3.png?raw=true" alt="iOS screenshot showing `Iodine Clock` recording showing brightness sensor with various values." width="175"><img src="assets/image4.png?raw=true" alt="iOS screenshot showing `Iodine Clock` recording with notes alongside brightness sensor with various values." width="175">

## Features

* Visualize and graph data from a variety of sources including your device's  built-in sensor 📱
* Connect to external sensors over BLE ↭🔌
* Annotate observations with pictures 🏔 and notes 📝

## More

Science Journal is brought to you by [Making & Science][ms], an initiative by [Google](https://www.google.com/intl/en/about/). 

Open Science
Journal is not an official Google product.

---

## Required dependencies
First, you'll need a Mac. We don't support building the iOS app on anything else.

Second, you'll need the latest version of [Xcode](https://developer.apple.com/xcode/) installed.

Third, we use a few open source frameworks to build this app, so you'll need to install CocoaPods as your package manager in order to get what you need to build.

We recommend installing [CocoaPods](https://cocoapods.org/) by running:
`sudo gem install cocoapods` from your terminal.

## Building and running
Before you jump into coding, you'll need to run

`pod install` from the root of this project (the folder that contains has the `Podfile` file)

Then you can open `ScienceJournal.xcworkspace`

**Note:** there is a `ScienceJournal.xcodeproj` file, but since we use CocoaPods, you shouldn't use that project file. If you do, nothing will work 😭

[appstore]: https://itunes.apple.com/us/app/science-journal-by-google/id1251205555?mt=8
[ms]: https://makingscience.withgoogle.com

## Contribute to Science Journal iOS

Check out [CONTRIBUTING.md](https://github.com/google/science-journal-ios/blob/master/CONTRIBUTING.md) for more information on how to help with Science Journal iOS.

## Code of Conduct

Help us keep _Science Journal_ open and inclusive. Please read and follow our [Code of Conduct](https://github.com/google/science-journal-ios/blob/master/CODE_OF_CONDUCT.md).

## License

This project is licensed under the terms of the Apache 2.0 license. See the [LICENSE](https://github.com/google/science-journal-ios/blob/master/LICENSE) file.