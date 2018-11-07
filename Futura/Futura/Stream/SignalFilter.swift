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
    func filter(_ filter: @escaping (Value) -> Bool) -> Signal<Value> {
        return SignalFilter(source: self, filter: filter)
    }
}

internal final class SignalFilter<Value>: SignalForwarder<Value, Value> {
    internal init(source: Signal<Value>, filter: @escaping (Value) -> Bool) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe {
            switch $0 {
                case let .right(.right(value)):
                    guard filter(value) else { return }
                    self.broadcast(.right(value))
                case let .right(.left(error)):
                    self.broadcast(.left(error))
                case let .left(reason):
                    self.finish(reason)
            }
        })
    }
}
