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

/// Emitter is a Signal that allows broadcasting values and errors.
/// Using Emitter is the only way to pass any information through Signals.
/// Values and errors are called tokens to call any emission.
public final class Emitter<Value>: Signal<Value> {
    /// Creates Emitter instance with given type.
    public init() {
        super.init(collector: nil)
    }

    /// Broadcasts given value to all subscriptions.
    /// This method have no effect on Emitter that have finished.
    ///
    /// - Parameter value: The value that will be broadcasted from this emitter.
    public func emit(_ value: Value) {
        broadcast(.success(value))
    }

    /// Broadcasts given error to all subscriptions.
    /// This method have no effect on Emitter that have finished.
    ///
    /// - Parameter error: The error that will be broadcasted from this emitter.
    public func emit(_ error: Error) {
        broadcast(.failure(error))
    }

    /// Finishes this Emitter and all associated Signals.
    /// This method should be called to end Emitter and all associated Signals
    /// without errors when it will not emit any values or errors anymore.
    /// It will be called automatically when Emitter becomes deallocated.
    /// This method have no effect on Emitter that have already finished.
    ///
    /// - Note: Finished Signals begins to deallocate if able and releases all
    /// of its subscriptions kept by both its internal collector and external one
    /// if any (it will not affect subscriptions from other signals kept by external collector).
    public func end() {
        finish()
    }

    /// Finishes this Emitter and all associated Signals signalling some error.
    /// This method should be called to finish Emitter with eror condition
    /// that makes keeping it alive inaccurate.
    /// This method have no effect on Emitter that have already finished.
    ///
    /// - Note: Finished Signals begins to deallocate if able and releases all
    /// of its subscriptions kept by both its internal collector and external one
    /// if any (it will not affect subscriptions from other signals kept by external collector).
    ///
    /// - Parameter reason: The error that caused termination.
    public func terminate(_ reason: Error) {
        finish(reason)
    }

    /// Read only reference to this Emitter as Signal.
    public var signal: Signal<Value> {
        return self
    }
}

extension Emitter where Value == Void {
    
    /// Shortcut for emiting Void values
    public func emit() {
        self.emit(())
    }
}
