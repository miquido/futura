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
    
    func flatMap<T>(_ transform: @escaping (Value) -> Stream<T>) -> Stream<T> {
        return FlatMappingStream(source: self, transform: transform)
    }
}

internal final class FlatMappingStream<SourceValue, Value> : ForwardingStream<SourceValue, Value> {
    
    private let transform: (SourceValue) -> Stream<Value>
    private var mappedCollector: SubscribtionCollector = .init()
    
    internal init(source: Stream<SourceValue>, transform: @escaping (SourceValue) -> Stream<Value>) {
        self.transform = transform
        super.init(source: source, collector: source.collector)
        collect(source.subscribe {
            self.mappedCollector = .init()
            switch $0 {
            case let .value(value):
                let subscribtion = transform(value).subscribe {
                    switch $0 {
                    case let .value(value):
                        self.broadcast(.value(value))
                    case let .error(error):
                        self.broadcast(.error(error))
                    case .close:
                        self.broadcast(.close)
                    case let .terminate(reason):
                        self.broadcast(.terminate(reason))
                    }
                }
                guard let sub = subscribtion else { return }
                self.mappedCollector.collect(sub)
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
