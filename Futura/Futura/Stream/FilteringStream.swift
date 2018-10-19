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

public extension Stream {
    
    /// Map stream to other type or modify value passed further.
    /// Transformation may throw to propagate error instad of value.
    /// Returns new instance of stream.
    func filter(_ filter: @escaping (Value) -> Bool) -> Stream<Value> {
        return FilteringStream.init(source: self, filter: filter)
    }
}

internal final class FilteringStream<Value> : ForwardingStream<Value, Value> {
    
    internal init(source: Stream<Value>, filter: @escaping (Value) -> Bool) {
        super.init(source: source, collector: source.collector)
        collect(source.subscribe {
            switch $0 {
            case let .value(value):
                guard filter(value) else { return }
                self.broadcast(.value(value))
            case let .error(error):
                self.broadcast(.error(error))
            case .close:
                self.broadcast(.close)
            case let .terminate(reason):
                self.broadcast(.terminate(reason))
            }
        })
    }
}
