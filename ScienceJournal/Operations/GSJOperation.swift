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

import Foundation

/// GSJOperation extends the functionality of `Operation` by adding conditions and observers. Its
/// use is similar but slightly different than `Operation`. Instead of overriding `start()` and
/// `main()` subclasses should override `execute()` and call `finish()` when the code has finished.
/// `finish()` must be called whether the operation completed successfully or in an error state. As
/// long as these methods are called, all other state is managed automatically.
///
/// Conditions are added to an operation to establish criteria required in order for the operation
/// to successfully run. For example an operation that required location data could add a
/// condition that made sure access had been granted to location services.
///
/// Observers are added to an operation and can react to the starting and ending of an operation.
/// For example an observer could start and stop an activity indicator while the operation is
/// executing.
open class GSJOperation: Operation {

  // MARK: - Properties

  public var userInfo: Any?

  /// True if the operation finished without any errors and was not cancelled, otherwise false.
  public private(set) var didFinishSuccessfully = false

  /// An array of conditions for the operation.
  private(set) var conditions = [OperationCondition]()

  /// An array of observers for the operation.
  private(set) var observers = [OperationObserver]()

  /// The array that backs the `errors` property.
  private var _errors = [Error]()

  /// The accumulated errors for all states of execution.
  private var errors: [Error] {
    get {
      errorsLock.lock()
      let returnValue = _errors
      errorsLock.unlock()
      return returnValue
    }
    set {
      errorsLock.lock()
      _errors = newValue
      errorsLock.unlock()
    }
  }

  /// Internal state var that backs the `state` property.
  private var _state = State.initialized

  /// A lock to guard reading and writing the private `_state` property.
  private let stateLock = NSLock()

  /// A lock to guard reading and writing the `_errors` property.
  private let errorsLock = NSLock()

  /// A Bool that tracks whether `evaluteConditions()` has been called.
  private var hasEvaluatedConditions = false

  /// A private serial queue to lock access to code related to evaluating conditions.
  private let evaluatedConditionsQueue =
      DispatchQueue(label: "com.google.ScienceJournal.GSJOperation.evaluateConditions")

  // MARK: - Errors

  /// Adds an error to collected operation errors.
  ///
  /// - Parameter error: An error.
  func addError(_ error: Error) {
    addErrors([error])
  }

  /// Adds errors to collected operation errors.
  ///
  /// - Parameter errors: An array of errors.
  func addErrors(_ errors: [Error]) {
    errorsLock.lock()
    _errors.append(contentsOf: errors)
    errorsLock.unlock()
  }

  // MARK: - Conditions

  /// Adds a condition to the operation.
  ///
  /// - Parameter condition: An operation condition.
  public func addCondition(_ condition: OperationCondition) {
    assert(state < .evaluatingConditions,
           "Cannot add conditions after condition evaluation has started.")
    conditions.append(condition)
  }

  // MARK: - Observers

  /// Adds an observer to the operation.
  ///
  /// - Parameter observer: An operation observer.
  public func addObserver(_ observer: OperationObserver) {
    assert(state < .executing, "Cannot add observers after starting execution.")
    observers.append(observer)
  }

  // MARK: - Execution

  /// Informs the operation it will be added to a queue. Must be called for the operation to run.
  func willEnqueue() {
    state = .pending
  }

  public override final func start() {
    super.start()

    if isCancelled {
      finish()
    }
  }

  public override final func main() {
    assert(state == .ready)

    if errors.isEmpty && !isCancelled {
      state = .executing

      observers.forEach { $0.operationDidStart(self) }

      execute()
    } else {
      finish()
    }
  }

  /// Subclasses should override this method and put all code to execute here. `finish()` must be
  /// called when the execution is complete.
  open func execute() {
    finish()
  }

  /// Adds a new operation to the queue. This allows operations to spawn new operations as a
  /// reaction to failure or other events.
  ///
  /// - Parameter operation: An operation.
  public func spawnOperation(_ operation: Operation) {
    observers.forEach { $0.operation(self, didSpawnOperation: operation) }
  }

  // MARK: - Cancelling

  /// Cancels the operation with an associated error.
  ///
  /// - Parameter error: An error.
  public func cancelWithError(_ error: Error) {
    addError(error)
    cancel()
  }

  // MARK: - Finishing

  /// Marks the execution of the operation as complete. This must be called when an operation's
  /// execution is done, regardless of success or failure.
  ///
  /// - Parameter finishErrors: An optional array of errors associated with finishing.
  public final func finish(withErrors finishErrors: [Error]? = nil) {
    // Only the first call to finish does anything. Subsequent calls are a no-op.
    guard state < .finishing else {
      return
    }

    state = .finishing

    var allErrors: [Error]
    if let finishErrors = finishErrors {
      allErrors = errors + finishErrors
    } else {
      allErrors = errors
    }

    didFinishSuccessfully = allErrors.count == 0 && !isCancelled

    // Notify observers
    observers.forEach { $0.operationDidFinish(self, withErrors: allErrors) }

    finished(withErrors: allErrors)

    state = .finished
  }

  /// Subclasses may override this method if they need to do anything in reaction to an error.
  open func finished(withErrors errors: [Error]) {}

  // MARK: - Dependencies

  /// Returns a dependency if there is a single operation of type `T`.
  ///
  /// - Returns: The dependency if found.
  public func typedDependency<T>() -> T? {
    let deps = dependencies.compactMap { $0 as? T }

    // This method requires there is exactly one dependency of the required type.
    guard deps.count == 1, let dependency = deps.first else {
      return nil
    }

    return dependency
  }

  /// Returns a dependency if there is a single operation dependency of type `T` that has no errors.
  ///
  /// - Returns: The successful dependency if found.
  public func successfulDependency<T>() -> T? {
    guard let dependency: T = typedDependency() else {
      return nil
    }

    // The type must be a `GSJOperation` for this method to work.
    guard let fileListOperation = dependency as? GSJOperation else {
      return nil
    }

    // If the dependency has any errors, return nil.
    if fileListOperation.errors.count > 0 {
      return nil
    } else {
      return dependency
    }
  }

  // MARK: - Private

  private func evaluateConditions() {
    // Conditions should only be evaluated once.
    evaluatedConditionsQueue.sync {
      guard !hasEvaluatedConditions else {
        return
      }
      hasEvaluatedConditions = true

      assert(state == .pending && !isCancelled)

      state = .evaluatingConditions

      OperationConditionEvaluator.evaluate(conditions: conditions,
                                           forOperation: self) { (conditionErrors) in
        self.addErrors(conditionErrors)
        self.state = .ready
      }
    }
  }

  // MARK: - State

  private enum State: Int, Comparable {

    /// The initial, default state of the operation.
    case initialized

    /// The operation has been added to the queue and can start evaluating conditions.
    case pending

    /// The operation is evaluating conditions.
    case evaluatingConditions

    /// The operation's conditions have all passed. Entering this state informs the queue the
    /// operation is ready to execute.
    case ready

    /// The operation is executing.
    case executing

    /// The operation has stopped executing but hasn't notified the queue yet.
    case finishing

    // The operation has finished.
    case finished

    /// Whether the state is allowed to transition to a target state.
    ///
    /// - Parameter targetState: A target state.
    /// - Returns: A Boolean indicating whether the target state is valid.
    func canTransitionTo(_ targetState: State) -> Bool {
      switch (self, targetState) {
      case (.initialized, .pending):
        return true
      case (.pending, .evaluatingConditions):
        return true
      case (.pending, .finishing):
        return true
      case (.evaluatingConditions, .ready):
        return true
      case (.ready, .executing):
        return true
      case (.ready, .finishing):
        return true
      case (.executing, .finishing):
        return true
      case (.finishing, .finished):
        return true
      default:
        return false
      }
    }

    // Comparable
    static func < (lhs: GSJOperation.State, rhs: GSJOperation.State) -> Bool {
      return lhs.rawValue < rhs.rawValue
    }

  }

  // Thread safe state property.
  private var state: State {
    get {
      var returnValue: State
      stateLock.lock()
      returnValue = _state
      stateLock.unlock()
      return returnValue
    }
    set {
      willChangeValue(forKey: "state")

      stateLock.lock()
      guard _state != .finished else {
        return
      }

      assert(_state.canTransitionTo(newValue), "[GSJOperation] Invalid state transition")
      _state = newValue
      stateLock.unlock()

      didChangeValue(forKey: "state")
    }
  }

  // Changes to this property inform the queue the operation can be executed.
  open override var isReady: Bool {
    // `isReady` signals to an operation queue that it is ready to be run. Once it returns true
    // the queue can execute the operation at any time. If an operation is cancelled it is
    // considered ready because there is nothing for the operation to do but progress through its
    // states and complete.
    switch state {
    case .initialized:
      return isCancelled
    case .pending:
      guard !isCancelled else {
        return true
      }

      if super.isReady {
        evaluateConditions()
      }

      return false
    case .ready:
      return super.isReady || isCancelled
    default:
      return false
    }
  }

  // Changes to this property inform the queue the operation is executing.
  open override var isExecuting: Bool {
    return state == .executing
  }

  // Changes to this property inform the queue the operation is finished.
  open override var isFinished: Bool {
    return state == .finished
  }

  // This tells any key-value observers for `isReady`, `isExecuting` or `isFinished`
  // (i.e. the queue) that changes to the state property indicate changes to these properties.
  open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
    guard key == "isReady" || key == "isExecuting" || key == "isFinished" else {
      return []
    }
    return ["state"]
  }

}
