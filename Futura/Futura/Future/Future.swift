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
/// Cancels automatically on deinit when not completed or cancelled before.
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
        self.init(with: .value(result), executionContext: executionContext)
    }

    /// Creates already finished Future with given error and context.
    ///
    /// - Parameter value: Value finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on this Future. Default is .undefined.
    public convenience init(failedWith reason: Error, executionContext: ExecutionContext = .undefined) {
        self.init(with: .error(reason), executionContext: executionContext)
    }

    internal init(with result: Result<Value>? = nil, executionContext: ExecutionContext) {
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
    ///
    /// - Parameter handler: Function that will be called when finished with value.
    @discardableResult
    func value(_ handler: @escaping (Value) -> Void) -> Self {
        observe { state in
            guard case let .resulted(.value(value)) = state else { return }
            handler(value)
        }
        return self
    }

    /// Access Future error when finishes with error or already finished with error.
    /// Given handler will be cached until Future finishes or called immediately
    /// if already finished with error. If it have already finished without error it will
    /// be discarded without calling or keeping in memory.
    ///
    /// - Parameter handler: Function that will be called when finished with error.
    @discardableResult
    func error(_ handler: @escaping (Error) -> Void) -> Self {
        observe { state in
            guard case let .resulted(.error(reason)) = state else { return }
            handler(reason)
        }
        return self
    }

    #warning("to complete docs")
    /// Access error when future completes with error. Returns new Future instance.
    /// If it handles error without throwing it cancels all further futures preventing error propagation.
    func `catch`(_ handler: @escaping (Error) throws -> Void) -> Future<Value> {
        let future: Future<Value> = .init(executionContext: executionContext)
        observe { state in
            switch state {
                case let .resulted(.value(value)):
                    future.become(.resulted(with: .value(value)))
                case let .resulted(.error(reason)):
                    do {
                        try handler(reason)
                        future.become(.canceled)
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
        }
        return future
    }

    #warning("to complete docs")
    /// Try recover from error providing valid value. Returns new Future instance.
    func recover(_ transformation: @escaping (Error) throws -> Value) -> Future<Value> {
        let future: Future<Value> = .init(executionContext: executionContext)
        observe { state in
            switch state {
                case let .resulted(.value(value)):
                    future.become(.resulted(with: .value(value)))
                case let .resulted(.error(reason)):
                    do {
                        try future.become(.resulted(with: .value(transformation(reason))))
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
        }
        return future
    }

    #warning("to complete docs")
    /// Execute when future completes with result. It is omited when future is canceled.
    @discardableResult
    func resulted(_ handler: @escaping () -> Void) -> Self {
        observe { state in
            guard case .resulted = state else { return }
            handler()
        }
        return self
    }

    #warning("to complete docs")
    /// Execute always when future completes. Includes completion by cancelation.
    @discardableResult
    func always(_ handler: @escaping () -> Void) -> Self {
        observe { _ in
            handler()
        }
        return self
    }

    #warning("to complete docs")
    /// Map container to other type or do some value changes. Returns new Future instance.
    /// Transformation may throw to propagate error instad of value.
    func map<T>(_ transformation: @escaping (Value) throws -> T) -> Future<T> {
        let future: Future<T> = .init(executionContext: executionContext)
        observe { state in
            switch state {
                case let .resulted(.value(value)):
                    do {
                        try future.become(.resulted(with: .value(transformation(value))))
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case let .resulted(.error(reason)):
                    future.become(.resulted(with: .error(reason)))
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
        }
        return future
    }

    #warning("to complete docs")
    /// Map container to other type or do some value changes flattening future inside. Returns new Future instance.
    /// Transformation may throw to propagate error instad of value.
    func flatMap<T>(_ transformation: @escaping (Value) throws -> (Future<T>)) -> Future<T> {
        let future: Future<T> = .init(executionContext: executionContext)
        observe { state in
            switch state {
                case let .resulted(.value(value)):
                    do {
                        try transformation(value).observe {
                            future.become($0)
                        }
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case let .resulted(.error(reason)):
                    future.become(.resulted(with: .error(reason)))
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
        }
        return future
    }

    #warning("to complete docs")
    /// Returns new Future instance with given execution context. Futures inherit execution context by default.
    func `switch`(to worker: Worker) -> Future<Value> {
        let future: Future<Value> = .init(executionContext: .explicit(worker))
        observe { future.become($0) }
        return future
    }

    #warning("to complete docs")
    /// Returns new Future instance with same parameters as cloned future. Result future is a child of cloned future instead of child of same parent.
    func clone() -> Future<Value> {
        let future: Future<Value> = .init(executionContext: executionContext)
        observe { future.become($0) }
        return future
    }

    #warning("to complete docs")
    /// Cancels future without triggering any handlers (except always). Cancellation is propagated.
    func cancel() {
        become(.canceled)
    }
}

internal extension Future {
    enum State {
        case waiting
        case resulted(with: Result<Value>)
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

#warning("to complete docs")
/// Zip futures. Returns new Future instance.
/// Execution context of returned Future is undefined. It will be inherited from completion of last of provided Futures.
/// If you need explicit execution context use switch(to:) to ensure usage of specific Worker.
/// Result Future will fail or become canceled if any of provided Futures fails or becomes canceled without waiting for other results.
public func zip<T, U>(_ f1: Future<T>, _ f2: Future<U>) -> Future<(T, U)> {
    let future: Future<(T, U)> = .init(executionContext: .undefined)
    let lock: RecursiveLock = .init()
    var results: (T?, U?)

    f1.observe { state in
        switch state {
            case let .resulted(.value(value)):
                lock.lock()
                defer { lock.unlock() }
                if case let (_, r2?) = results {
                    future.become(.resulted(with: .value((value, r2))))
                } else {
                    results = (value, nil)
                }
            case let .resulted(.error(reason)):
                future.become(.resulted(with: .error(reason)))
            case .canceled:
                future.become(.canceled)
            case .waiting: break
        }
    }
    f2.observe { state in
        switch state {
            case let .resulted(.value(value)):
                lock.lock()
                defer { lock.unlock() }
                if case let (r1?, _) = results {
                    future.become(.resulted(with: .value((r1, value))))
                } else {
                    results = (nil, value)
                }
            case let .resulted(.error(reason)):
                future.become(.resulted(with: .error(reason)))
            case .canceled:
                future.become(.canceled)
            case .waiting: break
        }
    }
    return future
}

#warning("to complete docs")
/// Zip futures. Returns new Future instance.
/// Execution context of returned Future is undefined. It will be inherited from completion of last of provided Futures.
/// If you need explicit execution context use switch(to:) to ensure usage of specific Worker.
/// Result Future will fail or become canceled if any of provided Futures fails or becomes canceled without waiting for other results.
public func zip<T>(_ futures: [Future<T>]) -> Future<[T]> {
    let zippedFuture = Future<[T]>(executionContext: .undefined)
    let lock: RecursiveLock = .init()
    let count: Int = futures.count
    var results: Array<T> = .init()

    for future in futures {
        future.observe { state in
            switch state {
                case let .resulted(.value(value)):
                    lock.lock()
                    defer { lock.unlock() }
                    results.append(value)
                    guard results.count == count else { return }
                    zippedFuture.become(.resulted(with: .value(results)))
                case let .resulted(.error(reason)):
                    zippedFuture.become(.resulted(with: .error(reason)))
                case .canceled:
                    zippedFuture.become(.canceled)
                case .waiting: break
            }
        }
    }
    return zippedFuture
}

#warning("to complete docs")
/// Schedules task using selected worker.
/// Returned Future represents result of passed body function.
/// Default worker used for execution is DispatchWorker.default.
public func future<T>(on worker: Worker = DispatchWorker.default, _ body: @escaping () throws -> T) -> Future<T> {
    let future: Future<T> = .init(executionContext: .explicit(worker))
    worker.schedule {
        do {
            try future.become(.resulted(with: .value(body())))
        } catch {
            future.become(.resulted(with: .error(error)))
        }
    }
    return future
}
