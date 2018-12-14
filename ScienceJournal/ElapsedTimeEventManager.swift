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

import Foundation

/// For use with events that should not occur too frequently, this class tracks the elapsed time
/// since the last event and performs the next event only if enough time has elapsed. If an event is
/// attempted during the time interval, it will be performed one more time after the time interval
/// has ended.
public class ElapsedTimeEventManager {

  public typealias Event = (_ userInfo: Any?) -> Void

  // MARK: - Properties

  /// User info used when the time interval ends and the event is performed one more time.
  public var defaultAutoFireUserInfo: Any?

  private let clock: Clock
  private let event: Event
  private var dateOfLastEvent: Date?
  private let timeIntervalBetweenEvents: TimeInterval
  private var timer: Timer?

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - clock: A clock.
  ///   - timeIntervalBetweenEvents: The amount of time that must elapse before another event
  ///                                occurence.
  ///   - event: The event to perform.
  init(clock: Clock, timeIntervalBetweenEvents: TimeInterval, event: @escaping Event) {
    self.clock = clock
    self.timeIntervalBetweenEvents = timeIntervalBetweenEvents
    self.event = event
  }

  /// Initializer that uses a default clock.
  ///
  /// - Parameters:
  ///   - timeIntervalBetweenEvents: The amount of time that must elapse before another event
  ///                                can be performed.
  ///   - event: The event to perform.
  public convenience init(timeIntervalBetweenEvents: TimeInterval, event: @escaping Event) {
    self.init(clock: Clock(), timeIntervalBetweenEvents: timeIntervalBetweenEvents, event: event)
  }

  /// Performs the event if it is allowed.
  ///
  /// - Parameters:
  ///   - forced: Forces performing the event without checking if it should be allowed.
  ///   - userInfo: Values required for the event to execute.
  public func performEventIfAllowed(forced: Bool = false, userInfo: Any? = nil) {
    guard !forced, let dateOfLastEvent = dateOfLastEvent else {
      performEvent(userInfo: userInfo)
      return
    }

    let timeIntervalSinceLastEvent = clock.now.timeIntervalSince(dateOfLastEvent)
    if timeIntervalSinceLastEvent >= timeIntervalBetweenEvents {
      performEvent(userInfo: userInfo)
    } else {
      timer?.invalidate()
      let timeInterval = timeIntervalBetweenEvents - timeIntervalSinceLastEvent
      let timerUserInfo = defaultAutoFireUserInfo ?? userInfo
      timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                   target: self,
                                   selector: #selector(timerFired),
                                   userInfo: timerUserInfo,
                                   repeats: false)
      // Allows the timer to fire while scroll views are tracking.
      RunLoop.main.add(timer!, forMode: .common)
    }
  }

  /// Resets the date of the last event as if it never occured.
  public func reset() {
    dateOfLastEvent = nil
    timer?.invalidate()
  }

  // MARK: - Private

  private func performEvent(userInfo: Any? = nil) {
    event(userInfo)
    dateOfLastEvent = clock.now
    timer?.invalidate()
  }

  @objc private func timerFired() {
    performEvent(userInfo: timer?.userInfo)
  }

}
