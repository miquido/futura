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
    /// Flattens Future and maps producing it Signal to other type or transforms
    /// its value using Future.
    /// Returns new instance of Signal that will pass tokens
    /// transformed with given function combined with returned Future.
    /// Future value will be passed as value, error as error.
    /// Finishing Future does not affects resulted Signal.
    /// Handling subsequent Futures will not cancel previous ones.
    /// It might throw to indicate error - throwed error will
    /// be automatically switched to Signal error.
    ///
    /// - Parameter transform: Value transformation function.
    /// Returned Future will be flattened. Might throw to pass errors.
    /// - Returns: New Signal instance passing flattened Futures.
    func flatMapFuture<T>(_ transform: @escaping (Value) throws -> Future<T>) -> Signal<T> {
        let next: SignalFutureFlatMapper = .init(source: self, transform: transform)
        #if FUTURA_DEBUG
        next.debugMode = self.debugMode.propagated
        self.debugLog("+flatMapFuture -> \(next.debugDescription)")
        #endif
        return next
    }
}

internal final class SignalFutureFlatMapper<SourceValue, Value>: SignalForwarder<SourceValue, Value> {
    internal init(source: Signal<SourceValue>, transform: @escaping (SourceValue) throws -> Future<Value>) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe { [weak source] event in
            #if FUTURA_DEBUG
            source?.debugLog("flatMapFuture() -> \(self.debugDescription)")
            #endif
            switch event {
                case let .token(.success(value)):
                    do {
                        let future = try transform(value)
                        #if FUTURA_DEBUG
                            future.debug(source?.debugMode.propagated ?? .disabled)
                            source?.debugLog("flatMapFutureInner() -\(future.debugDescription)-> \(self.debugDescription)")
                        #endif
                        future
                            .value { value in
                                self.broadcast(.success(value))
                            }
                            .error { error in
                                self.broadcast(.failure(error))
                            }
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
