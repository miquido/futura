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

public extension Signal {
    /// Handler used to observe values passed through this Signal instance.
    ///
    /// - Parameter observer: Handler called every time Signal gets value.
    /// - Returns: Same Signal instance for eventual further chaining.
    @discardableResult
    func values(_ observer: @escaping (Value) -> Void) -> Signal {
        #if FUTURA_DEBUG
        self.debugLog("+values")
        #endif
        collect(subscribe { [weak self] event in
            guard case let .token(.success(value)) = event else { return }
            #if FUTURA_DEBUG
            self?.debugLog("values(\(value))")
            #endif
            observer(value)
        })
        return self
    }
    
    /// Handler used to observe errors passed through this Signal instance.
    ///
    /// - Parameter observer: Handler called every time Signal gets error.
    /// - Returns: Same Signal instance for eventual further chaining.
    @discardableResult
    func errors(_ observer: @escaping (Error) -> Void) -> Signal {
        #if FUTURA_DEBUG
        self.debugLog("+errors")
        #endif
        collect(subscribe { [weak self] event in
            guard case let .token(.failure(value)) = event else { return }
            #if FUTURA_DEBUG
            self?.debugLog("errors(\(value))")
            #endif
            observer(value)
        })
        return self
    }
    
    /// Handler used to observe all tokens passed through this Signal instance.
    ///
    /// - Parameter observer: Handler called every time Signal gets any token.
    /// - Returns: Same Signal instance for eventual further chaining.
    @discardableResult
    func tokens(_ observer: @escaping () -> Void) -> Signal {
        #if FUTURA_DEBUG
        self.debugLog("+tokens")
        #endif
        collect(subscribe { [weak self] event in
            guard case .token = event else { return }
            #if FUTURA_DEBUG
            self?.debugLog("tokens()")
            #endif
            observer()
        })
        return self
    }
    
    /// Handler used to observe finishing of this Signal by ending (without error).
    /// It will be called immediately with given context if
    /// signal already ended.
    ///
    /// - Parameter executionContext: Context used to execute handler.
    /// - Parameter observer: Handler called when Signal ends.
    /// - Returns: Same Signal instance for eventual further chaining.
    @discardableResult
    func ended(inContext executionContext: ExecutionContext = .undefined, _ observer: @escaping () -> Void) -> Signal {
        #if FUTURA_DEBUG
        self.debugLog("+ended")
        #endif
        if let subscription = (subscribe { [weak self] event in
            guard case .finish(.none) = event else { return }
            executionContext.execute {
                #if FUTURA_DEBUG
                self?.debugLog("ended()")
                #endif
                observer()
            }
        }) {
            collect(subscription)
        } else {
            guard case .some(.none) = finish else { return self }
            executionContext.execute { [weak self] in
                #if FUTURA_DEBUG
                self?.debugLog("ended()")
                #endif
                observer()
            }
        }
        return self
    }
    
    /// Handler used to observe finishing of this Signal by termination (with error).
    /// It will be called immediately with given context if
    /// signal already terminated.
    ///
    /// - Parameter executionContext: Context used to execute handler.
    /// - Parameter observer: Handler called when Signal terminates.
    /// - Returns: Same Signal instance for eventual further chaining.
    @discardableResult
    func terminated(inContext executionContext: ExecutionContext = .undefined, _ observer: @escaping (Error) -> Void) -> Signal {
        #if FUTURA_DEBUG
        self.debugLog("+terminated")
        #endif
        if let subscription = (subscribe { [weak self] event in
            guard case let .finish(.some(reason)) = event else { return }
            executionContext.execute {
                #if FUTURA_DEBUG
                self?.debugLog("terminated(\(reason))")
                #endif
                observer(reason)
            }
        }) {
            collect(subscription)
        } else {
            guard case let .some(.some(reason)) = finish else { return self }
            executionContext.execute { [weak self] in
                #if FUTURA_DEBUG
                self?.debugLog("terminated(\(reason))")
                #endif
                observer(reason)
            }
        }
        return self
    }
    
    /// Handler used to observe finishing of this Signal either by ending or termination
    /// (with or without error). It will be called immediately with given context if
    /// signal already finished.
    ///
    /// - Parameter executionContext: Context used to execute handler.
    /// - Parameter observer: Handler called when Signal finishes.
    /// - Returns: Same Signal instance for eventual further chaining.
    @discardableResult
    func finished(inContext executionContext: ExecutionContext = .undefined, _ observer: @escaping () -> Void) -> Signal {
        #if FUTURA_DEBUG
        self.debugLog("+finished")
        #endif
        if let subscription = (subscribe { [weak self] event in
            guard case .finish = event else { return }
            executionContext.execute {
                #if FUTURA_DEBUG
                self?.debugLog("finished()")
                #endif
                observer()
            }
        }) {
            collect(subscription)
        } else {
            guard case .some = finish else { return self }
            executionContext.execute { [weak self] in
                #if FUTURA_DEBUG
                self?.debugLog("finished()")
                #endif
                observer()
            }
        }
        return self
    }
}
