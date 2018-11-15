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
    /// It might throw to indicate error - throwed error will
    /// be automatically switched to Signal error.
    ///
    /// - Parameter transform: Value transformation function.
    /// Returned Signal will be flattened. Might throw to pass errors.
    /// - Returns: New Signal instance passing transformed tokens.
    func flatMap<T>(_ transform: @escaping (Value) throws -> Signal<T>) -> Signal<T> {
        return SignalFlatMapper(source: self, transform: transform)
    }
}

internal final class SignalFlatMapper<SourceValue, Value>: SignalForwarder<SourceValue, Value> {
    private var mappedCollector: SubscriptionCollector = .init()

    internal init(source: Signal<SourceValue>, transform: @escaping (SourceValue) throws -> Signal<Value>) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe {
            self.mappedCollector = .init()
            switch $0 {
                case let .right(.right(value)):
                    do {
                        let subscribtion = try transform(value).subscribe {
                            switch $0 {
                                case let .right(.right(value)):
                                    self.broadcast(.right(value))
                                case let .right(.left(error)):
                                    self.broadcast(.left(error))
                                case let .left(reason):
                                    self.finish(reason)
                            }
                        }
                        guard let sub = subscribtion else { return }
                        self.mappedCollector.collect(sub)
                    } catch {
                        self.broadcast(.left(error))
                    }
                case let .right(.left(error)):
                    self.broadcast(.left(error))
                case let .left(reason):
                    self.finish(reason)
            }
        })
    }
}
