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

public extension Signal {
    /// Transforms Signal into new Signal instance using provided error catcher.
    /// Catches errors passed by Signal and stops error propagation if not throwing.
    /// Returns new instance of Signal that will pass only errors thrown by catcher.
    /// Catcher does not affect value flow.
    /// You can think about it as filter for errors.
    /// - Warning: It does not affect signal termination.
    ///
    /// - Parameter catcher: Error catching function, may throw to pass error further.
    /// - Returns: New Signal instance passing all values and filtered errors.
    func `catch`(_ catcher: @escaping (Error) throws -> Void) -> Signal<Value> {
        return SignalErrorCatcher(source: self, catcher: catcher)
    }
}

internal final class SignalErrorCatcher<Value>: SignalForwarder<Value, Value> {
    internal init(source: Signal<Value>, catcher: @escaping (Error) throws -> Void) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe { event in
            switch event {
                case let .token(.value(value)):
                    self.broadcast(.value(value))
                case let .token(.error(error)):
                    do {
                        try catcher(error)
                    } catch {
                        self.broadcast(.error(error))
                    }
                case let .finish(reason):
                    self.finish(reason)
            }
        })
    }
}
