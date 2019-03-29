/* Copyright 2018 Miquido

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

/// Read only container for async or delayed value.
/// Future will remain in memory at least until its parent Future completes.
/// It caches its result until deallocated.
/// Cancels automatically on deinit when not completed or canceled before.
public final class Future<Value> {
    private let mtx: Mutex.Pointer = Mutex.make(recursive: true)
    private let executionContext: ExecutionContext
    private var observers: Array < (State) -> Void> = .init()
    private var state: State

    /// Creates already finished Future with given value and context.
    ///
    /// - Parameter value: Value finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on this Future. Default is .undefined.
    public convenience init(succeededWith result: Value, executionContext: ExecutionContext = .undefined) {
        self.init(with: .success(result), executionContext: executionContext)
    }

    /// Creates already finished Future with given error and context.
    ///
    /// - Parameter value: Value finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on this Future. Default is .undefined.
    public convenience init(failedWith reason: Error, executionContext: ExecutionContext = .undefined) {
        self.init(with: .failure(reason), executionContext: executionContext)
    }

    internal init(with result: Result<Value, Error>? = nil, executionContext: ExecutionContext) {
        self.executionContext = executionContext
        if let result = result {
            self.state = .resulted(with: result)
        } else {
            self.state = .waiting
        }
    }

    deinit {
        guard case .waiting = state else { return }
        let observers = self.observers
        executionContext.execute {
            for observer in observers {
                observer(.canceled)
            }
        }
        Mutex.destroy(mtx)
    }
}

public extension Future {
    /// Access Future value when finishes with value or already finished with value.
    /// Given handler will be cached until Future finishes or called immediately
    /// if already finished with value. If it have already finished without value it will
    /// be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter handler: Function that will be called when finished with value.
    /// - Returns: Same Future instance.
    @discardableResult
    func value(_ handler: @escaping (Value) -> Void) -> Self {
        observe { state in
            guard case let .resulted(.success(value)) = state else { return }
            handler(value)
        }
        return self
    }

    /// Access Future error when finishes with error or already finished with error.
    /// Given handler will be cached until Future finishes or called immediately
    /// if already finished with error. If it have already finished without error it will
    /// be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter handler: Function that will be called when finished with error.
    /// - Returns: Same Future instance.
    @discardableResult
    func error(_ handler: @escaping (Error) -> Void) -> Self {
        observe { state in
            guard case let .resulted(.failure(reason)) = state else { return }
            handler(reason)
        }
        return self
    }
    
    /// Execute when future finishes with any result (value or error) or already finished with result.
    /// Given handler will be cached until Future finishes or called immediately
    /// if already finished with either value or error. If it have already finished without value or error
    /// it will be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter handler: Function that will be called when finished with value or error.
    /// - Returns: Same Future instance.
    @discardableResult
    func resulted(_ handler: @escaping () -> Void) -> Self {
        observe { state in
            guard case .resulted = state else { return }
            handler()
        }
        return self
    }
    
    /// Execute when future finishes or already finished. It will be executed
    /// even if Future was canceled.
    /// Given handler will be cached until Future finishes or called immediately
    /// if already finished. It will be called exactly once in Future lifecycle.
    ///
    /// - Parameter handler: Function that will be called always when finished.
    /// - Returns: Same Future instance.
    @discardableResult
    func always(_ handler: @escaping () -> Void) -> Self {
        observe { _ in
            handler()
        }
        return self
    }

    /// Transforms Future value into a new one using given function.
    /// Transformation may throw to propagate error instad of value.
    /// Given transformation will be cached until Future finishes or called immediately
    /// if already finished with value. If it have already finished without value
    /// it will be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter transformation: Transformation that will be performed when finished with value.
    /// - Returns: New Future instance with given transformation.
    func map<T>(_ transformation: @escaping (Value) throws -> T) -> Future<T> {
        let future: Future<T> = .init(executionContext: executionContext)
        observe { state in
            switch state {
                case let .resulted(.success(value)):
                    do {
                        try future.become(.resulted(with: .success(transformation(value))))
                    } catch {
                        future.become(.resulted(with: .failure(error)))
                    }
                case let .resulted(.failure(reason)):
                    future.become(.resulted(with: .failure(reason)))
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
        }
        return future
    }

    /// Transforms Future value into a new one using given function that returns Future.
    /// Result of returned Future will be flattened as result of Future returned by transformation.
    /// Transformation may throw to propagate error instad of value.
    /// Given transformation will be cached until Future finishes or called immediately
    /// if already finished with value. If it have already finished without value
    /// it will be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter transformation: Transformation that will be performed when finished with error.
    /// - Returns: New Future instance with given transformation.
    func flatMap<T>(_ transformation: @escaping (Value) throws -> (Future<T>)) -> Future<T> {
        let future: Future<T> = .init(executionContext: executionContext)
        observe { state in
            switch state {
                case let .resulted(.success(value)):
                    do {
                        try transformation(value).observe {
                            future.become($0)
                        }
                    } catch {
                        future.become(.resulted(with: .failure(error)))
                    }
                case let .resulted(.failure(reason)):
                    future.become(.resulted(with: .failure(reason)))
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
        }
        return future
    }

    /// Transforms Future to a new one associated with given Worker.
    /// If Future have associated worker it will be used on
    /// all its handlers and propagated through all transformations of that Future.
    ///
    /// - Parameter worker: Worker assigned to execute further transformations and handlers.
    /// - Returns: New Future instance associated with given Worker.
    func `switch`(to worker: Worker) -> Future<Value> {
        let future: Future<Value> = .init(executionContext: .explicit(worker))
        observe { future.become($0) }
        return future
    }
    
    /// Access Future error when finishes with error or already finished with error.
    /// If transformation does not throw, error will not be propagated further
    /// and Future will become canceled.
    /// If transformation throws, thrown error will be propagated instead.
    /// Given transformation will be cached until Future finishes or called immediately
    /// if already finished with error. If it have already finished without error
    /// it will be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter transformation: Transformation that will be performed when finished with error.
    /// - Returns: New Future instance with given transformation.
    func `catch`(_ transformation: @escaping (Error) throws -> Void) -> Future<Value> {
        let future: Future<Value> = .init(executionContext: executionContext)
        observe { state in
            switch state {
            case let .resulted(.success(value)):
                future.become(.resulted(with: .success(value)))
            case let .resulted(.failure(reason)):
                do {
                    try transformation(reason)
                    future.become(.canceled)
                } catch {
                    future.become(.resulted(with: .failure(error)))
                }
            case .canceled:
                future.become(.canceled)
            case .waiting: break
            }
        }
        return future
    }
    
    /// Access Future error when finishes with error or already finished with error.
    /// Transformation may provide valid value and propagate it instead of error.
    /// If transformation throws, thrown error will be propagated instead of original one.
    /// Given transformation will be cached until Future finishes or called immediately
    /// if already finished with error. If it have already finished without error
    /// it will be discarded without calling or keeping in memory.
    /// It will be called exactly once or never in Future lifecycle.
    ///
    /// - Parameter transformation: Transformation that will be performed when finished with error.
    /// - Returns: New Future instance with given transformation.
    func recover(_ transformation: @escaping (Error) throws -> Value) -> Future<Value> {
        let future: Future<Value> = .init(executionContext: executionContext)
        observe { state in
            switch state {
            case let .resulted(.success(value)):
                future.become(.resulted(with: .success(value)))
            case let .resulted(.failure(reason)):
                do {
                    try future.become(.resulted(with: .success(transformation(reason))))
                } catch {
                    future.become(.resulted(with: .failure(error)))
                }
            case .canceled:
                future.become(.canceled)
            case .waiting: break
            }
        }
        return future
    }

    /// Returns new Future instance with same execution context. 
    /// Result future is a child of cloned future instead of child of same parent.
    ///
    /// - Returns: New Future instance.
    func clone() -> Future<Value> {
        let future: Future<Value> = .init(executionContext: executionContext)
        observe { future.become($0) }
        return future
    }

    /// Cancels Future without triggering any handlers (except always). Cancellation is propagated.
    /// Cancelation is ignored by predecessors.
    func cancel() {
        become(.canceled)
    }
}

internal extension Future {
    enum State {
        case waiting
        case resulted(with: Result<Value, Error>)
        case canceled
    }

    func become(_ state: State) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        switch self.state {
            case .resulted, .canceled:
                return
            case .waiting:
                self.state = state
                executionContext.execute {
                    for observer in self.observers {
                        observer(state)
                    }
                    self.observers = .init()
                }
        }
    }
}

fileprivate extension Future {
    @inline(__always)
    func observe(with observer: @escaping (State) -> Void) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        switch state {
            case .waiting:
                observers.append(observer)
            case let .resulted(result):
                executionContext.execute { observer(.resulted(with: result)) }
            case .canceled:
                executionContext.execute { observer(.canceled) }
        }
    }
}

/// Zip two futures to access joined both values.
/// Execution context of returned Future is undefined. It will be inherited from completion of last of provided Futures.
/// If you need explicit execution context use switch(to:) to ensure usage of specific Worker.
/// Result Future will fail or become canceled if any of provided Futures fails or becomes canceled without waiting for other result.
///
/// - Parameter f1: Future to zip.
/// - Parameter f2: Future to zip.
/// - Returns: New Future instance with that is combination of both Futures.
public func zip<T, U>(_ f1: Future<T>, _ f2: Future<U>) -> Future<(T, U)> {
    let future: Future<(T, U)> = .init(executionContext: .undefined)
    let lock: RecursiveLock = .init()
    var results: (T?, U?)

    f1.observe { state in
        switch state {
            case let .resulted(.success(value)):
                lock.lock()
                defer { lock.unlock() }
                if case let (_, r2?) = results {
                    future.become(.resulted(with: .success((value, r2))))
                } else {
                    results = (value, nil)
                }
            case let .resulted(.failure(reason)):
                future.become(.resulted(with: .failure(reason)))
            case .canceled:
                future.become(.canceled)
            case .waiting: break
        }
    }
    f2.observe { state in
        switch state {
            case let .resulted(.success(value)):
                lock.lock()
                defer { lock.unlock() }
                if case let (r1?, _) = results {
                    future.become(.resulted(with: .success((r1, value))))
                } else {
                    results = (nil, value)
                }
            case let .resulted(.failure(reason)):
                future.become(.resulted(with: .failure(reason)))
            case .canceled:
                future.become(.canceled)
            case .waiting: break
        }
    }
    return future
}

/// Zip array of futures to access joined values.
/// Execution context of returned Future is undefined. It will be inherited from completion of last of provided Futures.
/// If you need explicit execution context use switch(to:) to ensure usage of specific Worker.
/// Result Future will fail or become canceled if any of provided Futures fails or becomes canceled without waiting for other results.
///
/// - Parameter futures: Array of Futures to zip.
/// - Returns: New Future instance with that is combination of all Futures. If input array is empty it returns succeeded future with empty array as result.
public func zip<T>(_ futures: [Future<T>]) -> Future<[T]> {
    guard !futures.isEmpty else { return .init(succeededWith: [], executionContext: .undefined) }
    let zippedFuture = Future<[T]>(executionContext: .undefined)
    let lock: RecursiveLock = .init()
    let count: Int = futures.count
    var results: Array<T> = .init()

    for future in futures {
        future.observe { state in
            switch state {
                case let .resulted(.success(value)):
                    lock.lock()
                    defer { lock.unlock() }
                    results.append(value)
                    guard results.count == count else { return }
                    zippedFuture.become(.resulted(with: .success(results)))
                case let .resulted(.failure(reason)):
                    zippedFuture.become(.resulted(with: .failure(reason)))
                case .canceled:
                    zippedFuture.become(.canceled)
                case .waiting: break
            }
        }
    }
    return zippedFuture
}

import Foundation

/// Schedules task using selected worker. 
/// Result of scheduled task becomes result of returned Future.
///
/// - Parameter worker: Worker used to execute task. Default is new instance of OperationQueue
/// - Parameter body: Task to execute asynchronously.
/// - Returns: New Future instance that will be result of passed function.
public func future<T>(on worker: Worker = OperationQueue(), _ body: @escaping () throws -> T) -> Future<T> {
    let future: Future<T> = .init(executionContext: .explicit(worker))
    worker.schedule {
        do {
            try future.become(.resulted(with: .success(body())))
        } catch {
            future.become(.resulted(with: .failure(error)))
        }
    }
    return future
}
