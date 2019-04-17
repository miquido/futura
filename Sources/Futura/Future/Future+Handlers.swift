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
        #if FUTURA_DEBUG
        self.debugLog("+value")
        #endif
        observe { [weak self] state in
            guard case let .resulted(.success(value)) = state else { return }
            #if FUTURA_DEBUG
            self?.debugLog("value(\(value))")
            #endif
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
        #if FUTURA_DEBUG
        self.debugLog("+error")
        #endif
        observe { [weak self] state in
            guard case let .resulted(.failure(reason)) = state else { return }
            #if FUTURA_DEBUG
            self?.debugLog("error(\(reason))")
            #endif
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
        #if FUTURA_DEBUG
        self.debugLog("+resulted")
        #endif
        observe { [weak self] state in
            guard case .resulted = state else { return }
            #if FUTURA_DEBUG
            self?.debugLog("resulted()")
            #endif
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
        #if FUTURA_DEBUG
        self.debugLog("+always")
        #endif
        observe { [weak self] _ in
            #if FUTURA_DEBUG
            self?.debugLog("always()")
            #endif
            handler()
        }
        return self
    }
}
