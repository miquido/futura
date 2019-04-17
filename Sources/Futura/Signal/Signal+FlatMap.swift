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
    /// Transforms Signal into new Signal instance using provided function.
    /// Flattens and maps Signal to other type or transforms
    /// its value using other Signal.
    /// Returns new instance of Signal that will pass tokens
    /// transformed with given function combined with returned Signal.
    /// It will keep all subsequent signals and merge its results.
    /// If any of inner signals finishes resulting signal also finishes.
    /// It might throw to indicate error - throwed error will
    /// be automatically switched to Signal error.
    ///
    /// - Parameter transform: Value transformation function.
    /// Returned Signal will be flattened. Might throw to pass errors.
    /// - Returns: New Signal instance passing transformed tokens.
    func flatMap<T>(_ transform: @escaping (Value) throws -> Signal<T>) -> Signal<T> {
        let next: SignalFlatMapper = .init(source: self, transform: transform)
        #if FUTURA_DEBUG
        next.debugMode = self.debugMode.propagated
        self.debugLog("+flatMap -> \(next.debugDescription)")
        #endif
        return next
    }
}

internal final class SignalFlatMapper<SourceValue, Value>: SignalForwarder<SourceValue, Value> {

    internal init(source: Signal<SourceValue>, transform: @escaping (SourceValue) throws -> Signal<Value>) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe { [weak source] event in
            #if FUTURA_DEBUG
            source?.debugLog("flatMap() -> \(self.debugDescription)")
            #endif
            switch event {
                case let .token(.success(value)):
                    do {
                        let subscribtion = try transform(value).subscribe { [weak self] event in
                            #if FUTURA_DEBUG
                            source?.debugLog("flatMapInner() -> \(self.debugDescription)")
                            #endif
                            guard let self = self else { return }
                            switch event {
                                case let .token(.success(value)):
                                    self.broadcast(.success(value))
                                case let .token(.failure(error)):
                                    self.broadcast(.failure(error))
                                case let .finish(reason):
                                    self.finish(reason)
                            }
                        }
                        guard let sub = subscribtion else { return }
                        self.collect(sub)
                    } catch {
                        self.broadcast(.failure(error))
                    }
                case let .token(.failure(error)):
                    self.broadcast(.failure(error))
                case let .finish(reason):
                    self.finish(reason)
            }
        })
    }
}
