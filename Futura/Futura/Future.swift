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

#if FUTURA_DEBUG
import os.log

let logger = OSLog(subsystem: "Futura", category: "Async")
#endif

/// Read only container for async value. Future will remain in memory until its parent (Promise or other Future) completes.
/// Cancels automatically on deinit when not completed before.
public final class Future<Value> {
    
    private let lock: Lock = Lock()
    private let executionContext: ExecutionContext
    private var observers: [(State) -> Void] = []
    private var state: State
    
    public init(with result: Result<Value>? = nil, executionContext: ExecutionContext = .inheritWorker) {
        self.executionContext = executionContext
        if let result = result {
            self.state = .resulted(with: result)
        } else {
            self.state = .waiting
        }
    }
    
    deinit {
        guard case .waiting = state else { return }
        #if FUTURA_DEBUG
        os_log("Deallocating %{public}@", log: logger, type: .debug, debugDescription)
        #endif
        cancel()
    }
}

public extension Future {
    
    /// Access value when future completes with success
    @discardableResult
    func then(_ handler: @escaping (Value) -> Void) -> Self {
        #if FUTURA_DEBUG
        os_log("Handling value on %{public}@", log: logger, type: .debug, debugDescriptionSynchronized)
        #endif
        handle { (res) in
            switch res {
            case let .success(val):
                handler(val)
            case .error: break
            }
        }
        return self
    }
    
    /// Access error when future completes with error
    @discardableResult
    func fail(_ handler: @escaping (Error) -> Void) -> Self {
        #if FUTURA_DEBUG
        os_log("Handling error on %{public}@", log: logger, type: .debug, debugDescriptionSynchronized)
        #endif
        handle { (res) in
            switch res {
            case .success: break
            case let .error(err):
                handler(err)
            }
        }
        return self
    }
    
    /// Access error when future completes with error. Returns new Future instance.
    /// If it handles error without throwing it cancels all further futures preventing error propagation.
    @discardableResult
    func `catch`(_ handler: @escaping (Error) throws -> Void) -> Future<Value> {
        let future = Future(executionContext: .inheritWorker)
        #if FUTURA_DEBUG
        os_log("Catching error on %{public}@", log: logger, type: .debug, debugDescriptionSynchronized)
        #endif
        observe { state in
            switch state {
            case let .resulted(result):
                switch result {
                case let .success(val):
                    future.become(.resulted(with: .success(val)))
                case let .error(val):
                    do {
                        try handler(val)
                        future.become(.canceled)
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                }
            case .canceled:
                future.become(.canceled)
            case .waiting: break
            }
        }
        return future
    }
    
    /// Try recover from error providing valid value. Returns new Future instance.
    func recover(_ transformation: @escaping (Error) throws -> Value) -> Future {
        let future = Future(executionContext: .inheritWorker)
        #if FUTURA_DEBUG
        os_log("Recoverable on %{public}@ => %{public}@", log: logger, type: .debug, debugDescriptionSynchronized, future.debugDescriptionSynchronized)
        #endif
        observe { state in
            switch state {
            case let .resulted(result):
                switch result {
                case let .success(val):
                    future.become(.resulted(with: .success(val)))
                case let .error(val):
                    do {
                        try future.become(.resulted(with: .success(transformation(val))))
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                }
            case .canceled:
                future.become(.canceled)
            case .waiting: break
            }
        }
        return future
    }
    
    /// Execute when future completes with result. It is omited when future is canceled.
    @discardableResult
    func resulted(_ handler: @escaping () -> Void) -> Self {
        #if FUTURA_DEBUG
        os_log("Handling done on %{public}@", log: logger, type: .debug, debugDescriptionSynchronized)
        #endif
        handle { _ in
            handler()
        }
        return self
    }
    
    /// Execute always when future completes. Includes completion by cancelation.
    @discardableResult
    func always(_ handler: @escaping () -> ()) -> Self {
        #if FUTURA_DEBUG
        os_log("Handling always on %{public}@", log: logger, type: .debug, debugDescriptionSynchronized)
        #endif
        observe { _ in
            handler()
        }
        return self
    }
    
    /// Map container to other type or do some value changes. Returns new Future instance.
    /// Transformation may throw to propagate error instad of value.
    func map<T>(_ transformation: @escaping (Value) throws -> (T)) -> Future<T> {
        let future = Future<T>(executionContext: .inheritWorker)
        #if FUTURA_DEBUG
        os_log("Mapping on %{public}@ => %{public}@", log: logger, type: .debug, debugDescriptionSynchronized, future.debugDescriptionSynchronized)
        #endif
        observe { state in
            switch state {
            case let .resulted(result):
                switch result {
                case let .success(val):
                    do {
                        try future.become(.resulted(with: .success(transformation(val))))
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case let .error(err):
                    future.become(.resulted(with: .error(err)))
                }
            case .canceled:
                future.become(.canceled)
            case .waiting: break
            }
        }
        return future
    }
    
    /// Map container to other type or do some value changes flattening future inside. Returns new Future instance.
    /// Transformation may throw to propagate error instad of value.
    func flatMap<T>(_ transformation: @escaping (Value) throws -> (Future<T>)) -> Future<T> {
        let future = Future<T>(executionContext: .inheritWorker)
        #if FUTURA_DEBUG
        os_log("Flat mapping on %{public}@ => %{public}@", log: logger, type: .debug, debugDescriptionSynchronized, future.debugDescriptionSynchronized)
        #endif
        observe { state in
            switch state {
            case let .resulted(result):
                switch result {
                case let .success(val):
                    do {
                        try transformation(val).handle {
                            future.become(.resulted(with: $0))
                        }
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case let .error(err):
                    future.become(.resulted(with: .error(err)))
                }
            case .canceled:
                future.become(.canceled)
            case .waiting: break
            }
        }
        return future
    }
    
    /// Returns new Future instance with given execution context. Futures inherit execution context by default.
    func `switch`(to worker: Worker) -> Future<Value> {
        let future = Future(executionContext: .async(using: worker))
        #if FUTURA_DEBUG
        os_log("Switching to %{public}@ on %{public}@", log: logger, type: .debug, String(describing: worker) as! CVarArg, debugDescriptionSynchronized)
        #endif
        observe { future.become($0) }
        return future
    }
    
    /// Cancels future without triggering any handlers (except always and canceled). Cancellation is propagated.
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
        lock.synchronized {
            switch self.state {
            case .resulted, .canceled:
                #if FUTURA_DEBUG
                os_log("Ignoring completion with %{public}@ on %{public}@", log: logger, type: .debug, String(describing: state) as! CVarArg, debugDescription)
                #endif
                return
            case .waiting:
                #if FUTURA_DEBUG
                os_log("Completing with %{public}@ on %{public}@", log: logger, type: .debug, String(describing: state) as! CVarArg, debugDescription)
                #endif
                self.state = state
                executionContext.execute {
                    self.observers.forEach { $0(state) }
                    self.observers.removeAll()
                    #if FUTURA_DEBUG
                    os_log("Finished completing with %{public}@ on %{public}@", log: logger, type: .debug, String(describing: state) as! CVarArg, self.debugDescription)
                    #endif
                }
            }
        }
    }
}

fileprivate extension Future {
    
    @discardableResult @inline(__always)
    func observe(with observer: @escaping (State) -> Void) -> Self {
        lock.synchronized {
            switch state {
            case .waiting:
                observers.append(observer)
            case let .resulted(result):
                executionContext.execute { observer(.resulted(with: result)) }
            case .canceled:
                observer(.canceled)
            }
        }
        return self
    }
    
    @discardableResult @inline(__always)
    func handle(with handler: @escaping (Result<Value>) -> ()) -> Self {
        observe { state in
            guard case let .resulted(result) = state else { return }
            handler(result)
        }
        return self
    }
}

#if FUTURA_DEBUG
fileprivate extension Future {
    
    var debugDescription: CVarArg {
        return "\(statusDescription) Future<\(typeDescription)>[0x\(memoryAddress)]" as! CVarArg
    }
    
    var debugDescriptionSynchronized: CVarArg {
        return lock.synchronized { debugDescription }
    }
    
    var statusDescription: String {
        switch state {
        case .resulted:
            return "COMPLETED"
        case .waiting:
            return "WAITING"
        case .canceled:
            return "CANCELED"
        }
    }
    
    var memoryAddress: String {
        return String(unsafeBitCast(self, to: Int.self), radix: 16)
    }
    
    var typeDescription: String {
        return String(describing: Value.self)
    }
}
#endif
