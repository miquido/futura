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
    
    internal let executionContext: ExecutionContext
    #if FUTURA_DEBUG
    internal var debugMode: DebugMode
    internal let mtx: Mutex.Pointer = Mutex.make(recursive: true)
    internal var state: State
    #else
    private let mtx: Mutex.Pointer = Mutex.make(recursive: true)
    private var state: State
    #endif
    private var observers: Array < (State) -> Void> = .init()

    /// Creates already finished Future with given value and context.
    ///
    /// - Parameter value: Value finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on this Future. Default is .undefined.
    public convenience init(succeededWith result: Value, executionContext: ExecutionContext = .undefined) {
        self.init(.resulted(with: .success(result)), executionContext: executionContext)
    }

    /// Creates already finished Future with given error and context.
    ///
    /// - Parameter value: Value finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on this Future. Default is .undefined.
    public convenience init(failedWith reason: Error, executionContext: ExecutionContext = .undefined) {
        self.init(.resulted(with: .failure(reason)), executionContext: executionContext)
    }
    
    #if FUTURA_DEBUG
    internal init(_ state: State = .waiting, executionContext: ExecutionContext, debug: DebugMode = .disabled) {
        self.executionContext = executionContext
        self.debugMode = debug
        self.state = state
    }
    
    #else
    internal init(_ state: State = .waiting, executionContext: ExecutionContext) {
        self.executionContext = executionContext
        self.state = state
    }
    #endif

    deinit {
        defer { Mutex.destroy(mtx) }
        guard case .waiting = state else { return }
        let observers = self.observers
        executionContext.execute {
            for observer in observers {
                observer(.canceled)
            }
        }
    }
}

public extension Future {

    /// Cancels Future without triggering any handlers (except always). Cancellation is propagated.
    /// Cancelation is ignored by predecessors.
    func cancel() {
        become(.canceled)
    }
    
    /// Creates new precanceled Future.
    static func canceled(executionContext: ExecutionContext = .undefined) -> Future {
        Future(.canceled, executionContext: executionContext)
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
