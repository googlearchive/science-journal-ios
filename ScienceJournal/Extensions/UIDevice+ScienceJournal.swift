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

extension UIDevice {

  /// Returns the device type code.
  class var deviceType: String {
    var sysinfo = utsname()
    uname(&sysinfo)
    return String(bytes: Data(bytes: &sysinfo.machine,
                              count: Int(_SYS_NAMELEN)),
                  encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
  }

  /// Whether or not the device is an iPhone. Otherwise, it is an iPad or iPod Touch.
  class var isPhone: Bool {
    return current.model == "iPhone"
  }

}
