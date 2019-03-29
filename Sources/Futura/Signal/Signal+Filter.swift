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
    /// Transforms Signal into new Signal instance using provided filter.
    /// Filters values passed by Signal.
    /// Returns new instance of Signal that will pass only matching values.
    /// Filter does not affect error flow.
    ///
    /// - Parameter filter: Filtering function returning true for values that can be passed
    /// - Returns: New Signal instance passing filtered values and all errors.
    func filter(_ filter: @escaping (Value) -> Bool) -> Signal<Value> {
        return SignalFilter(source: self, filter: filter)
    }

    /// Transforms Signal into new Signal instance using duplicate filter
    /// based on provided equal function.
    /// Filters values passed by Signal.
    /// Returns new instance of Signal that will pass only non duplicate following values.
    /// Filter does not affect error flow.
    ///
    /// - Returns: New Signal instance passing filtered values and all errors.
    func filterDuplicates(_ equals: @escaping (Value, Value) -> Bool) -> Signal<Value> {
        var lastVal: Value?
        return SignalFilter(source: self, filter: { newVal in
            defer { lastVal = newVal }
            guard let lastVal = lastVal else { return true }
            return !equals(lastVal, newVal)
        })
    }
}

public extension Signal where Value: Equatable {
    /// Transforms Signal into new Signal instance using duplicate filter.
    /// Filters values passed by Signal.
    /// Returns new instance of Signal that will pass only non duplicate following values.
    /// Filter does not affect error flow.
    ///
    /// - Returns: New Signal instance passing filtered values and all errors.
    func filterDuplicates() -> Signal<Value> {
        var lastVal: Value?
        return SignalFilter(source: self, filter: { newVal in
            defer { lastVal = newVal }
            guard let lastVal = lastVal else { return true }
            return lastVal != newVal
        })
    }
}

internal final class SignalFilter<Value>: SignalForwarder<Value, Value> {
    internal init(source: Signal<Value>, filter: @escaping (Value) -> Bool) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe { event in
            switch event {
                case let .token(.success(value)):
                    guard filter(value) else { return }
                    self.broadcast(.success(value))
                case let .token(.failure(error)):
                    self.broadcast(.failure(error))
                case let .finish(reason):
                    self.finish(reason)
            }
        })
    }
}
