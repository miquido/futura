/* Copyright 2019 Miquido
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */


/// Zip two futures to access joined both values.
/// Execution context of returned Future is undefined. It will be inherited from completion of last of provided Futures.
/// If you need explicit execution context use switch(to:) to ensure usage of specific Worker.
/// Result Future will fail or become canceled if any of provided Futures fails or becomes canceled without waiting for other result.
///
/// - Parameter f1: Future to zip.
/// - Parameter f2: Future to zip.
/// - Returns: New Future instance with that is combination of both Futures.
public func zip<T, U>(_ f1: Future<T>, _ f2: Future<U>) -> Future<(T, U)> {
    #if FUTURA_DEBUG
    let future: Future<(T, U)> = .init(executionContext: .undefined, debug: f1.debugMode.combined(with: f2.debugMode))
    future.debugLog("+zip from [\(f1.debugDescription)][\(f2.debugDescription)]")
    #else
    let future: Future<(T, U)> = .init(executionContext: .undefined)
    #endif
    let lock: RecursiveLock = .init()
    var results: (T?, U?)
    
    f1.observe { [weak f1] state in
        #if FUTURA_DEBUG
        future.debugLog("zip([\(f1?.debugDescription ?? "[dealocated]")])")
        #endif
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
    f2.observe { [weak f2] state in
        #if FUTURA_DEBUG
        future.debugLog("zip([\(f2?.debugDescription ?? "[dealocated]")])")
        #endif
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
    #if FUTURA_DEBUG
    let zippedFuture = Future<[T]>(executionContext: .undefined,
                                   debug: futures.reduce(DebugMode.disabled) { $0.combined(with: $1.debugMode) })
    zippedFuture.debugLog("+zip from \(futures.map { "[\($0.debugDescription)]" })")
    #else
    let zippedFuture = Future<[T]>(executionContext: .undefined)
    #endif
    let lock: RecursiveLock = .init()
    let count: Int = futures.count
    var results: Array<T> = .init()
    
    for future in futures {
        future.observe { [weak future] state in
            #if FUTURA_DEBUG
            zippedFuture.debugLog("zip([\(future?.debugDescription ?? "[dealocated]")])")
            #endif
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
