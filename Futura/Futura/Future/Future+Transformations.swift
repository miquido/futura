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

public extension Future {
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
        #if FUTURA_DEBUG
            let future: Future<T> = .init(executionContext: executionContext, debug: debugMode.propagated)
            self.debugLog("+ map -> \(future.debugDescription)")
        #else
            let future: Future<T> = .init(executionContext: executionContext)
        #endif
        observe { [weak self] state in
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
                case .waiting: assertionFailure()
            }
            #if FUTURA_DEBUG
                self?.debugLog("map() -> \(future.debugDescription)")
            #endif
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
        #if FUTURA_DEBUG
            let future: Future<T> = .init(executionContext: executionContext, debug: debugMode.propagated)
            self.debugLog("+flatMap -> \(future.debugDescription)")
        #else
            let future: Future<T> = .init(executionContext: executionContext)
        #endif
        observe { [weak self] state in
            switch state {
                case let .resulted(.value(value)):
                    do {
                        try transformation(value).observe {
                            future.become($0)
                            #if FUTURA_DEBUG
                            self?.debugLog("flatMapInner() -> \(future.debugDescription)")
                            #endif
                        }
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case let .resulted(.error(reason)):
                    future.become(.resulted(with: .error(reason)))
                case .canceled:
                    future.become(.canceled)
                case .waiting: assertionFailure()
            }
            #if FUTURA_DEBUG
                self?.debugLog("flatMap() -> \(future.debugDescription)")
            #endif
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
        #if FUTURA_DEBUG
            let future: Future<Value> = .init(executionContext: .explicit(worker), debug: debugMode.propagated)
            self.debugLog("+switch -> \(future.debugDescription)")
        #else
            let future: Future<Value> = .init(executionContext: .explicit(worker))
        #endif
        observe { [weak self] state in
            future.become(state)
            #if FUTURA_DEBUG
                self?.debugLog("switch() -> \(future.debugDescription)")
            #endif
        }
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
        #if FUTURA_DEBUG
            let future: Future<Value> = .init(executionContext: executionContext, debug: debugMode.propagated)
            self.debugLog("+catch -> \(future.debugDescription)")
        #else
            let future: Future<Value> = .init(executionContext: executionContext)
        #endif
        observe { [weak self] state in
            switch state {
                case let .resulted(.value(value)):
                    future.become(.resulted(with: .value(value)))
                case let .resulted(.error(reason)):
                    do {
                        try transformation(reason)
                        future.become(.canceled)
                    } catch {
                        future.become(.resulted(with: .error(error)))
                    }
                case .canceled:
                    future.become(.canceled)
                case .waiting: break
            }
            #if FUTURA_DEBUG
                self?.debugLog("catch() -> \(future.debugDescription)")
            #endif
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
        #if FUTURA_DEBUG
            let future: Future<Value> = .init(executionContext: executionContext, debug: debugMode.propagated)
            self.debugLog("+recover -> \(future.debugDescription)")
        #else
            let future: Future<Value> = .init(executionContext: executionContext)
        #endif
        observe { [weak self] state in
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
            #if FUTURA_DEBUG
                self?.debugLog("recover() -> \(future.debugDescription)")
            #endif
        }
        return future
    }

    /// Returns new Future instance with same execution context.
    /// Result future is a child of cloned future instead of child of same parent.
    ///
    /// - Returns: New Future instance.
    func clone() -> Future<Value> {
        #if FUTURA_DEBUG
            let future: Future<Value> = .init(executionContext: executionContext, debug: debugMode.propagated)
            self.debugLog("+clone -> \(future.debugDescription)")
        #else
            let future: Future<Value> = .init(executionContext: executionContext)
        #endif
        observe { [weak self] state in
            future.become(state)
            #if FUTURA_DEBUG
                self?.debugLog("clone() -> \(future.debugDescription)")
            #endif
        }
        return future
    }
}
